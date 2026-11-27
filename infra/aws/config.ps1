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
$SgEcs = "portfolio-ecs-sg"          # the backend containers
$SgRds = "portfolio-rds-sg"          # the database: only reachable from $SgEcs

# Stop on the first failed command instead of continuing half-done
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$AccountId = (aws sts get-caller-identity --query Account --output text)
$Registry  = "$AccountId.dkr.ecr.$Region.amazonaws.com"
Write-Host "AWS account $AccountId, region $Region" -ForegroundColor Cyan
