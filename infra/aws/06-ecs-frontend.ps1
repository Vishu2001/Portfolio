# Step 6: run the Next.js frontend on ECS Fargate, as the load balancer's DEFAULT route.
#   /api/* and /actuator/health*  -> backend   (rule from 05-ecs-backend.ps1)
#   everything else               -> frontend  (this script)
# Run 05-ecs-backend.ps1 first. Safe to re-run.
# Usage:  .\infra\aws\06-ecs-frontend.ps1 -Tag <image tag in ECR>
param([string]$Tag)
. "$PSScriptRoot\config.ps1"
if (-not $Tag) { $Tag = (git -C "$PSScriptRoot\..\.." rev-parse --short HEAD) }
$tmp = Join-Path $env:TEMP "portfolio-ecs"; New-Item -ItemType Directory -Force $tmp | Out-Null
function Write-Json($name, $obj) {
    $path = Join-Path $tmp $name
    ConvertTo-Json -InputObject $obj -Depth 20 | Set-Content -Path $path -Encoding ascii
    return "file://$path"
}

$VpcId   = aws ec2 describe-vpcs --region $Region --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text
$Subnets = (aws ec2 describe-subnets --region $Region --filters Name=vpc-id,Values=$VpcId --query "Subnets[].SubnetId" --output text) -split "\s+"
function Get-SgId($name) {
    aws ec2 describe-security-groups --region $Region --filters Name=group-name,Values=$name Name=vpc-id,Values=$VpcId `
        --query "SecurityGroups[0].GroupId" --output text
}
$albSgId = Get-SgId $SgAlb
$ecsSgId = Get-SgId $SgEcs

# ---------------------------------------------------------------- 1) firewall: 3000 from the ALB
Write-Host "`n[1/6] Security group rule" -ForegroundColor Cyan
$hasRule = aws ec2 describe-security-group-rules --region $Region --filters Name=group-id,Values=$ecsSgId `
    --query "SecurityGroupRules[?FromPort==``3000`` && ReferencedGroupInfo.GroupId=='$albSgId'] | length(@)" --output text
if ($hasRule -eq "0") {
    aws ec2 authorize-security-group-ingress --region $Region --group-id $ecsSgId `
        --ip-permissions "IpProtocol=tcp,FromPort=3000,ToPort=3000,UserIdGroupPairs=[{GroupId=$albSgId,Description=Frontend from load balancer}]" | Out-Null
    Write-Host "  + rule: $SgEcs allows 3000 from $SgAlb" -ForegroundColor Green
} else { Write-Host "  = rule 3000 from $SgAlb present" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 2) log group
Write-Host "`n[2/6] Log group" -ForegroundColor Cyan
$lgExists = aws logs describe-log-groups --region $Region --log-group-name-prefix $LogGroupWeb `
    --query "logGroups[?logGroupName=='$LogGroupWeb'].logGroupName" --output text
if (-not $lgExists) {
    aws logs create-log-group --region $Region --log-group-name $LogGroupWeb --tags project=$Project
    Write-Host "  + created $LogGroupWeb" -ForegroundColor Green
} else { Write-Host "  = $LogGroupWeb exists" -ForegroundColor DarkGray }
aws logs put-retention-policy --region $Region --log-group-name $LogGroupWeb --retention-in-days 7

# ---------------------------------------------------------------- 3) target group
Write-Host "`n[3/6] Target group" -ForegroundColor Cyan
$TgArn = aws elbv2 describe-target-groups --region $Region `
    --query "TargetGroups[?TargetGroupName=='$TgWeb'].TargetGroupArn" --output text
if (-not $TgArn) {
    $TgArn = aws elbv2 create-target-group --region $Region --name $TgWeb `
        --protocol HTTP --port 3000 --vpc-id $VpcId --target-type ip `
        --health-check-path / --health-check-interval-seconds 15 `
        --healthy-threshold-count 2 --unhealthy-threshold-count 3 --matcher HttpCode=200 `
        --tags Key=project,Value=$Project --query "TargetGroups[0].TargetGroupArn" --output text
    aws elbv2 modify-target-group-attributes --region $Region --target-group-arn $TgArn `
        --attributes Key=deregistration_delay.timeout_seconds,Value=30 | Out-Null
    Write-Host "  + created $TgWeb" -ForegroundColor Green
} else { Write-Host "  = $TgWeb exists" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 4) default route -> frontend
Write-Host "`n[4/6] Load balancer default route" -ForegroundColor Cyan
$AlbArn = aws elbv2 describe-load-balancers --region $Region `
    --query "LoadBalancers[?LoadBalancerName=='$AlbName'].LoadBalancerArn" --output text
$AlbDns = aws elbv2 describe-load-balancers --region $Region --load-balancer-arns $AlbArn --query "LoadBalancers[0].DNSName" --output text
$ListenerArn = aws elbv2 describe-listeners --region $Region --load-balancer-arn $AlbArn `
    --query "Listeners[?Port==``80``].ListenerArn" --output text
# Replaces the temporary 404: anything not matched by the /api rule now goes to the frontend
$defaultAction = Write-Json "web-default-action.json" @(@{ Type = "forward"; TargetGroupArn = $TgArn })
aws elbv2 modify-listener --region $Region --listener-arn $ListenerArn --default-actions $defaultAction | Out-Null
Write-Host "  + default route -> $TgWeb (API rule still sends /api/* to the backend)" -ForegroundColor Green

# ---------------------------------------------------------------- 5) task definition
Write-Host "`n[5/6] Task definition (image portfolio-web:$Tag)" -ForegroundColor Cyan
$ExecRoleArn = aws iam get-role --role-name $ExecRole --query Role.Arn --output text
$taskDef = Write-Json "taskdef-web.json" @{
    family                  = $ServiceWeb
    networkMode             = "awsvpc"
    requiresCompatibilities = @("FARGATE")
    cpu                     = "256"        # 0.25 vCPU: the site is pre-rendered, Node mostly serves files
    memory                  = "512"        # used ~46 MB locally
    runtimePlatform         = @{ cpuArchitecture = "X86_64"; operatingSystemFamily = "LINUX" }
    executionRoleArn        = $ExecRoleArn # pull image + write logs (no secrets needed)
    containerDefinitions    = @(@{
        name         = "web"
        image        = "$Registry/portfolio-web:$Tag"
        essential    = $true
        portMappings = @(@{ containerPort = 3000; protocol = "tcp" })
        # No API URL here: it is baked in at build time (relative "/api/..."), same origin as the page
        logConfiguration = @{
            logDriver = "awslogs"
            options   = @{ "awslogs-group" = $LogGroupWeb; "awslogs-region" = $Region; "awslogs-stream-prefix" = "web" }
        }
    })
}
$TaskDefArn = aws ecs register-task-definition --region $Region --cli-input-json $taskDef `
    --query "taskDefinition.taskDefinitionArn" --output text
Write-Host "  + registered $($TaskDefArn.Split('/')[-1])" -ForegroundColor Green

# ---------------------------------------------------------------- 6) service
Write-Host "`n[6/6] ECS service" -ForegroundColor Cyan
$svcStatus = aws ecs describe-services --region $Region --cluster $Cluster --services $ServiceWeb `
    --query "services[0].status" --output text
if ($svcStatus -ne "ACTIVE") {
    $svc = Write-Json "service-web.json" @{
        cluster        = $Cluster
        serviceName    = $ServiceWeb
        taskDefinition = $TaskDefArn
        desiredCount   = 1
        launchType     = "FARGATE"
        networkConfiguration = @{ awsvpcConfiguration = @{
            subnets = $Subnets; securityGroups = @($ecsSgId); assignPublicIp = "ENABLED" } }
        loadBalancers  = @(@{ targetGroupArn = $TgArn; containerName = "web"; containerPort = 3000 })
        healthCheckGracePeriodSeconds = 60
        deploymentConfiguration = @{
            minimumHealthyPercent = 100; maximumPercent = 200
            deploymentCircuitBreaker = @{ enable = $true; rollback = $true }
        }
        propagateTags = "SERVICE"
        tags = @(@{ key = "project"; value = $Project })
    }
    aws ecs create-service --region $Region --cli-input-json $svc | Out-Null
    Write-Host "  + created service $ServiceWeb" -ForegroundColor Green
} else {
    aws ecs update-service --region $Region --cluster $Cluster --service $ServiceWeb `
        --task-definition $TaskDefArn --force-new-deployment | Out-Null
    Write-Host "  = service $ServiceWeb updated to $($TaskDefArn.Split('/')[-1])" -ForegroundColor Green
}

Write-Host "`nWaiting for the service to become stable..." -ForegroundColor Cyan
aws ecs wait services-stable --region $Region --cluster $Cluster --services $ServiceWeb
Write-Host "`nSite is live: http://$AlbDns/" -ForegroundColor Green
