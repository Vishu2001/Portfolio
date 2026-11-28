# Shared settings for all AWS setup scripts. Change these when moving to another account/region.
$Region  = "ap-southeast-2"          # Sydney: the region this AWS project is pinned to
$Project = "portfolio"
$Repos   = @("portfolio-api", "portfolio-web")

# Database (RDS MySQL)
$DbInstanceId  = "portfolio-mysql"
$DbName        = "portfolio"
$DbUser        = "portfolio_admin"
$DbEngineVer   = "8.4.13"            # same major version as local Docker mysql:8.4
$DbClass       = "db.t4g.micro"      # smallest instance class

# Security group names
$SgAlb = "portfolio-alb-sg"          # the public load balancer: port 80 from the internet
$SgEcs = "portfolio-ecs-sg"          # the backend containers: 8080 only from $SgAlb
$SgRds = "portfolio-rds-sg"          # the database: only reachable from $SgEcs

# ECS / load balancer
$Cluster     = "portfolio"
$AlbName     = "portfolio-alb"
$TgApi       = "portfolio-api-tg"
$ServiceApi  = "portfolio-api"
$LogGroupApi = "/ecs/portfolio-api"
$TgWeb       = "portfolio-web-tg"
$ServiceWeb  = "portfolio-web"
$LogGroupWeb = "/ecs/portfolio-web"
$ExecRole    = "portfolio-ecs-execution-role"

# Stop on the first failed command instead of continuing half-done
$ErrorActionPreference = "Stop"

# Windows PowerShell 5.1 does NOT stop a script when a native program like aws.exe fails.
# This wrapper makes every "aws ..." call in these scripts throw on a non-zero exit code,
# so a failure can never be followed by misleading "created ..." messages.
$script:AwsExe = (Get-Command aws -CommandType Application | Select-Object -First 1).Source
function aws {
    # Passing through a PowerShell function splits "Key=a,Value=b" at the comma into an array.
    # Re-join such arrays so aws.exe receives them exactly as written. (Real lists, like
    # subnet IDs, are passed with @ splatting at the call site, so they stay separate args.)
    $argv = foreach ($a in $args) { if ($a -is [array]) { $a -join ',' } else { $a } }
    & $script:AwsExe @argv
    if ($LASTEXITCODE -ne 0) { throw "aws $($args[0..1] -join ' ') failed (exit code $LASTEXITCODE)" }
}

$AccountId = (aws sts get-caller-identity --query Account --output text)
$Registry  = "$AccountId.dkr.ecr.$Region.amazonaws.com"
Write-Host "AWS account $AccountId, region $Region" -ForegroundColor Cyan
