# Step 3: security groups (virtual firewalls) in the default VPC.
#   portfolio-ecs-sg : attached to the backend containers (rules for public traffic come later)
#   portfolio-rds-sg : attached to the database; allows MySQL (3306) ONLY from portfolio-ecs-sg
# Safe to re-run: existing groups/rules are reused.
# Usage:  .\infra\aws\03-network.ps1
. "$PSScriptRoot\config.ps1"

$VpcId = aws ec2 describe-vpcs --region $Region --filters Name=is-default,Values=true `
    --query "Vpcs[0].VpcId" --output text
Write-Host "Default VPC: $VpcId" -ForegroundColor Cyan

function Get-OrCreateSg([string]$name, [string]$description) {
    $id = aws ec2 describe-security-groups --region $Region `
        --filters Name=group-name,Values=$name Name=vpc-id,Values=$VpcId `
        --query "SecurityGroups[0].GroupId" --output text
    if ($id -and $id -ne "None") {
        Write-Host "  = $name exists ($id)" -ForegroundColor DarkGray
        return $id
    }
    $id = aws ec2 create-security-group --region $Region --vpc-id $VpcId `
        --group-name $name --description $description `
        --tag-specifications "ResourceType=security-group,Tags=[{Key=project,Value=$Project},{Key=Name,Value=$name}]" `
        --query GroupId --output text
    Write-Host "  + created $name ($id)" -ForegroundColor Green
    return $id
}

$ecsSgId = Get-OrCreateSg $SgEcs "Portfolio backend containers (ECS)"
$rdsSgId = Get-OrCreateSg $SgRds "Portfolio MySQL - only reachable from the backend"

# Allow MySQL into the database ONLY from members of the ECS security group.
# (Referencing a group instead of an IP range means: whichever containers carry
#  portfolio-ecs-sg may connect, wherever they are running. Nothing else can.)
$hasRule = aws ec2 describe-security-group-rules --region $Region `
    --filters Name=group-id,Values=$rdsSgId `
    --query "SecurityGroupRules[?FromPort==``3306`` && ReferencedGroupInfo.GroupId=='$ecsSgId'] | length(@)" --output text
if ($hasRule -eq "0") {
    aws ec2 authorize-security-group-ingress --region $Region --group-id $rdsSgId `
        --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,UserIdGroupPairs=[{GroupId=$ecsSgId,Description=MySQL from backend}]" | Out-Null
    Write-Host "  + rule: $SgRds allows 3306 from $SgEcs" -ForegroundColor Green
} else {
    Write-Host "  = rule 3306 from $SgEcs already present" -ForegroundColor DarkGray
}

Write-Host "`nInbound rules on ${SgRds}:" -ForegroundColor Cyan
aws ec2 describe-security-group-rules --region $Region --filters Name=group-id,Values=$rdsSgId `
    --query "SecurityGroupRules[?IsEgress==``false``].[IpProtocol,FromPort,ToPort,ReferencedGroupInfo.GroupId,CidrIpv4]" --output table
