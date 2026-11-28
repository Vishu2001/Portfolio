# Step 5: run the backend on ECS Fargate behind an Application Load Balancer.
# Safe to re-run: existing resources are reused; the service is updated to the new image.
# Usage:  .\infra\aws\05-ecs-backend.ps1                 (deploys image tagged with current git commit)
#         .\infra\aws\05-ecs-backend.ps1 -Tag 6a0d853    (deploys a specific image tag)
param([string]$Tag)
. "$PSScriptRoot\config.ps1"
if (-not $Tag) { $Tag = (git -C "$PSScriptRoot\..\.." rev-parse --short HEAD) }
$tmp = Join-Path $env:TEMP "portfolio-ecs"; New-Item -ItemType Directory -Force $tmp | Out-Null
function Write-Json($name, $obj) {          # helper: write JSON to a temp file for --cli-input-json
    $path = Join-Path $tmp $name
    # -InputObject (not a pipe): piping unwraps one-item arrays, turning [ {...} ] into {...}
    ConvertTo-Json -InputObject $obj -Depth 20 | Set-Content -Path $path -Encoding ascii
    return "file://$path"
}

$VpcId   = aws ec2 describe-vpcs --region $Region --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text
$Subnets = (aws ec2 describe-subnets --region $Region --filters Name=vpc-id,Values=$VpcId --query "Subnets[].SubnetId" --output text) -split "\s+"
function Get-SgId($name) {
    aws ec2 describe-security-groups --region $Region --filters Name=group-name,Values=$name Name=vpc-id,Values=$VpcId `
        --query "SecurityGroups[0].GroupId" --output text
}

# ---------------------------------------------------------------- 1) security groups
Write-Host "`n[1/7] Security groups" -ForegroundColor Cyan
$albSgId = Get-SgId $SgAlb
if (-not $albSgId -or $albSgId -eq "None") {
    $albSgId = aws ec2 create-security-group --region $Region --vpc-id $VpcId --group-name $SgAlb `
        --description "Portfolio public load balancer" --query GroupId --output text
    # HTTP from anywhere (IPv4 + IPv6): this is the public entry point
    aws ec2 authorize-security-group-ingress --region $Region --group-id $albSgId `
        --ip-permissions "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}],Ipv6Ranges=[{CidrIpv6=::/0}]" | Out-Null
    Write-Host "  + created $SgAlb ($albSgId): port 80 from the internet" -ForegroundColor Green
} else { Write-Host "  = $SgAlb exists ($albSgId)" -ForegroundColor DarkGray }

$ecsSgId = Get-SgId $SgEcs
$hasRule = aws ec2 describe-security-group-rules --region $Region --filters Name=group-id,Values=$ecsSgId `
    --query "SecurityGroupRules[?FromPort==``8080`` && ReferencedGroupInfo.GroupId=='$albSgId'] | length(@)" --output text
if ($hasRule -eq "0") {
    # The containers accept traffic ONLY from the load balancer, never directly from the internet
    aws ec2 authorize-security-group-ingress --region $Region --group-id $ecsSgId `
        --ip-permissions "IpProtocol=tcp,FromPort=8080,ToPort=8080,UserIdGroupPairs=[{GroupId=$albSgId,Description=HTTP from load balancer}]" | Out-Null
    Write-Host "  + rule: $SgEcs allows 8080 from $SgAlb" -ForegroundColor Green
} else { Write-Host "  = rule 8080 from $SgAlb present" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 2) IAM execution role
Write-Host "`n[2/7] IAM execution role" -ForegroundColor Cyan
$SecretArn = aws rds describe-db-instances --region $Region --db-instance-identifier $DbInstanceId `
    --query "DBInstances[0].MasterUserSecret.SecretArn" --output text
$roleExists = aws iam list-roles --query "Roles[?RoleName=='$ExecRole'].RoleName" --output text
if (-not $roleExists) {
    # Trust policy: only the ECS tasks service may use ("assume") this role
    $trust = Write-Json "trust.json" @{
        Version = "2012-10-17"
        Statement = @(@{ Effect = "Allow"; Principal = @{ Service = "ecs-tasks.amazonaws.com" }; Action = "sts:AssumeRole" })
    }
    aws iam create-role --role-name $ExecRole --assume-role-policy-document $trust `
        --tags Key=project,Value=$Project | Out-Null
    # AWS-managed policy: pull images from ECR + write logs to CloudWatch
    aws iam attach-role-policy --role-name $ExecRole `
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    Write-Host "  + created $ExecRole" -ForegroundColor Green
} else { Write-Host "  = $ExecRole exists" -ForegroundColor DarkGray }
# Read access to exactly ONE secret: the database credentials (least privilege)
$secretPolicy = Write-Json "secret-policy.json" @{
    Version = "2012-10-17"
    Statement = @(@{ Effect = "Allow"; Action = "secretsmanager:GetSecretValue"; Resource = $SecretArn })
}
aws iam put-role-policy --role-name $ExecRole --policy-name read-db-secret --policy-document $secretPolicy
$ExecRoleArn = aws iam get-role --role-name $ExecRole --query Role.Arn --output text

# ---------------------------------------------------------------- 3) logs + cluster
Write-Host "`n[3/7] Log group and cluster" -ForegroundColor Cyan
$lgExists = aws logs describe-log-groups --region $Region --log-group-name-prefix $LogGroupApi `
    --query "logGroups[?logGroupName=='$LogGroupApi'].logGroupName" --output text
if (-not $lgExists) {
    aws logs create-log-group --region $Region --log-group-name $LogGroupApi --tags project=$Project
    Write-Host "  + created log group $LogGroupApi" -ForegroundColor Green
}
aws logs put-retention-policy --region $Region --log-group-name $LogGroupApi --retention-in-days 7
aws ecs create-cluster --region $Region --cluster-name $Cluster --tags key=project,value=$Project | Out-Null  # returns the existing one if present
Write-Host "  = cluster $Cluster ready" -ForegroundColor Green

# ---------------------------------------------------------------- 4) load balancer + target group
Write-Host "`n[4/7] Load balancer" -ForegroundColor Cyan
$AlbArn = aws elbv2 describe-load-balancers --region $Region `
    --query "LoadBalancers[?LoadBalancerName=='$AlbName'].LoadBalancerArn" --output text
if (-not $AlbArn) {
    $AlbArn = aws elbv2 create-load-balancer --region $Region --name $AlbName --type application `
        --scheme internet-facing --subnets @Subnets --security-groups $albSgId `
        --tags Key=project,Value=$Project --query "LoadBalancers[0].LoadBalancerArn" --output text
    Write-Host "  + created $AlbName" -ForegroundColor Green
} else { Write-Host "  = $AlbName exists" -ForegroundColor DarkGray }
$AlbDns = aws elbv2 describe-load-balancers --region $Region --load-balancer-arns $AlbArn --query "LoadBalancers[0].DNSName" --output text

$TgArn = aws elbv2 describe-target-groups --region $Region `
    --query "TargetGroups[?TargetGroupName=='$TgApi'].TargetGroupArn" --output text
if (-not $TgArn) {
    # target-type ip: Fargate tasks register by their private IP. The health check uses
    # Spring Boot's readiness probe, so traffic only goes to a task that's fully started.
    $TgArn = aws elbv2 create-target-group --region $Region --name $TgApi `
        --protocol HTTP --port 8080 --vpc-id $VpcId --target-type ip `
        --health-check-path /actuator/health/readiness --health-check-interval-seconds 15 `
        --healthy-threshold-count 2 --unhealthy-threshold-count 3 --matcher HttpCode=200 `
        --tags Key=project,Value=$Project --query "TargetGroups[0].TargetGroupArn" --output text
    aws elbv2 modify-target-group-attributes --region $Region --target-group-arn $TgArn `
        --attributes Key=deregistration_delay.timeout_seconds,Value=30 | Out-Null
    Write-Host "  + created target group $TgApi" -ForegroundColor Green
} else { Write-Host "  = target group $TgApi exists" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 5) listener + routing rule
Write-Host "`n[5/7] Listener and routing" -ForegroundColor Cyan
$ListenerArn = aws elbv2 describe-listeners --region $Region --load-balancer-arn $AlbArn `
    --query "Listeners[?Port==``80``].ListenerArn" --output text
if (-not $ListenerArn) {
    # Default (for now): 404. The frontend becomes the default target in the next step.
    $default = Write-Json "default-action.json" @(@{
        Type = "fixed-response"
        FixedResponseConfig = @{ StatusCode = "404"; ContentType = "text/plain"; MessageBody = "Not found" }
    })
    $ListenerArn = aws elbv2 create-listener --region $Region --load-balancer-arn $AlbArn `
        --protocol HTTP --port 80 --default-actions $default --query "Listeners[0].ListenerArn" --output text
    Write-Host "  + listener on port 80" -ForegroundColor Green
}
$hasApiRule = aws elbv2 describe-rules --region $Region --listener-arn $ListenerArn `
    --query "Rules[?Priority=='10'] | length(@)" --output text
if ($hasApiRule -eq "0") {
    $conditions = Write-Json "api-conditions.json" @(@{ Field = "path-pattern"; Values = @("/api/*", "/actuator/health*") })
    $actions    = Write-Json "api-actions.json"    @(@{ Type = "forward"; TargetGroupArn = $TgArn })
    aws elbv2 create-rule --region $Region --listener-arn $ListenerArn --priority 10 `
        --conditions $conditions --actions $actions | Out-Null
    Write-Host "  + rule: /api/* and /actuator/health* -> backend" -ForegroundColor Green
} else { Write-Host "  = backend routing rule present" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 6) task definition
Write-Host "`n[6/7] Task definition (image portfolio-api:$Tag)" -ForegroundColor Cyan
$DbEndpoint = aws rds describe-db-instances --region $Region --db-instance-identifier $DbInstanceId `
    --query "DBInstances[0].Endpoint.Address" --output text
$taskDef = Write-Json "taskdef-api.json" @{
    family                  = $ServiceApi
    networkMode             = "awsvpc"
    requiresCompatibilities = @("FARGATE")
    cpu                     = "512"        # 0.5 vCPU
    memory                  = "1024"       # 1 GB (the JVM uses 75% for heap, see Dockerfile)
    runtimePlatform         = @{ cpuArchitecture = "X86_64"; operatingSystemFamily = "LINUX" }
    executionRoleArn        = $ExecRoleArn
    containerDefinitions    = @(@{
        name         = "api"
        image        = "$Registry/portfolio-api:$Tag"
        essential    = $true
        portMappings = @(@{ containerPort = 8080; protocol = "tcp" })
        # Plain (non-secret) settings
        environment  = @(
            @{ name = "SPRING_PROFILES_ACTIVE";   value = "prod" },
            @{ name = "DB_URL";                   value = "jdbc:mysql://${DbEndpoint}:3306/$DbName" },
            @{ name = "APP_CORS_ALLOWED_ORIGINS"; value = "http://$AlbDns" }
        )
        # Secrets: ECS reads these fields of the RDS secret at start and sets them as env vars.
        # The values never appear in this file, the task definition, git, or the logs.
        secrets      = @(
            @{ name = "DB_USERNAME"; valueFrom = "${SecretArn}:username::" },
            @{ name = "DB_PASSWORD"; valueFrom = "${SecretArn}:password::" }
        )
        logConfiguration = @{
            logDriver = "awslogs"
            options   = @{ "awslogs-group" = $LogGroupApi; "awslogs-region" = $Region; "awslogs-stream-prefix" = "api" }
        }
    })
}
$TaskDefArn = aws ecs register-task-definition --region $Region --cli-input-json $taskDef `
    --query "taskDefinition.taskDefinitionArn" --output text
Write-Host "  + registered $($TaskDefArn.Split('/')[-1])" -ForegroundColor Green

# ---------------------------------------------------------------- 7) service
Write-Host "`n[7/7] ECS service" -ForegroundColor Cyan
$svcStatus = aws ecs describe-services --region $Region --cluster $Cluster --services $ServiceApi `
    --query "services[0].status" --output text
if ($svcStatus -ne "ACTIVE") {
    $svc = Write-Json "service-api.json" @{
        cluster        = $Cluster
        serviceName    = $ServiceApi
        taskDefinition = $TaskDefArn
        desiredCount   = 1
        launchType     = "FARGATE"
        # Public IP so the task can pull from ECR without a (costly) NAT gateway. Inbound is
        # still locked down: the security group only accepts traffic from the load balancer.
        networkConfiguration = @{ awsvpcConfiguration = @{
            subnets = $Subnets; securityGroups = @($ecsSgId); assignPublicIp = "ENABLED" } }
        loadBalancers  = @(@{ targetGroupArn = $TgArn; containerName = "api"; containerPort = 8080 })
        healthCheckGracePeriodSeconds = 180       # Spring Boot needs time to start before health checks count
        deploymentConfiguration = @{
            minimumHealthyPercent = 100; maximumPercent = 200      # start the new task before stopping the old one
            deploymentCircuitBreaker = @{ enable = $true; rollback = $true }  # auto-rollback if the new version keeps failing
        }
        propagateTags = "SERVICE"
        tags = @(@{ key = "project"; value = $Project })
    }
    aws ecs create-service --region $Region --cli-input-json $svc | Out-Null
    Write-Host "  + created service $ServiceApi" -ForegroundColor Green
} else {
    aws ecs update-service --region $Region --cluster $Cluster --service $ServiceApi `
        --task-definition $TaskDefArn --force-new-deployment | Out-Null
    Write-Host "  = service $ServiceApi updated to $($TaskDefArn.Split('/')[-1])" -ForegroundColor Green
}

Write-Host "`nWaiting for the service to become stable (task running + healthy)..." -ForegroundColor Cyan
aws ecs wait services-stable --region $Region --cluster $Cluster --services $ServiceApi
Write-Host "`nBackend is live:" -ForegroundColor Green
Write-Host "  http://$AlbDns/actuator/health"
Write-Host "  POST http://$AlbDns/api/contact"
