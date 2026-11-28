# Step 7: let GitHub Actions deploy to this AWS account WITHOUT storing any AWS keys in GitHub.
#
# How it works (OIDC):
#   1. AWS is told to trust GitHub's identity service (token.actions.githubusercontent.com).
#   2. A role is created that ONLY workflows from this repo's main branch may assume.
#   3. During a run, GitHub gives the workflow a short-lived signed token ("I am a run of
#      Vishu2001/Portfolio on main"). AWS checks it and returns temporary credentials (~1 h)
#      for this role. Nothing secret is ever stored in GitHub.
#
# The role can only: push the two images to ECR, register task definitions, and update the
# two ECS services. Nothing else.
# Safe to re-run.  Usage:  .\infra\aws\07-github-oidc.ps1
. "$PSScriptRoot\config.ps1"

$GitHubRepo   = "Vishu2001/Portfolio"
$DeployRole   = "portfolio-github-deploy"
$OidcHost     = "token.actions.githubusercontent.com"
$OidcArn      = "arn:aws:iam::${AccountId}:oidc-provider/$OidcHost"
$tmp = Join-Path $env:TEMP "portfolio-oidc"; New-Item -ItemType Directory -Force $tmp | Out-Null
function Write-Json($name, $obj) {
    $path = Join-Path $tmp $name
    ConvertTo-Json -InputObject $obj -Depth 20 | Set-Content -Path $path -Encoding ascii
    return "file://$path"
}

# ---------------------------------------------------------------- 1) trust GitHub's identity provider
Write-Host "`n[1/3] GitHub OIDC identity provider" -ForegroundColor Cyan
$existing = aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, '$OidcHost')].Arn" --output text
if (-not $existing) {
    # AWS verifies GitHub's certificate itself; the thumbprint value is required by the API but not used for GitHub
    aws iam create-open-id-connect-provider --url "https://$OidcHost" `
        --client-id-list sts.amazonaws.com `
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 `
        --tags Key=project,Value=$Project | Out-Null
    Write-Host "  + created OIDC provider for $OidcHost" -ForegroundColor Green
} else { Write-Host "  = OIDC provider exists" -ForegroundColor DarkGray }

# ---------------------------------------------------------------- 2) the deploy role and who may use it
Write-Host "`n[2/3] Deploy role $DeployRole" -ForegroundColor Cyan
$trust = Write-Json "trust.json" @{
    Version   = "2012-10-17"
    Statement = @(@{
        Effect    = "Allow"
        Principal = @{ Federated = $OidcArn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = @{
            StringEquals = @{
                "$OidcHost`:aud" = "sts.amazonaws.com"
                # ONLY this repository, ONLY the main branch. Forks, other repos, other branches
                # and pull requests cannot assume this role.
                "$OidcHost`:sub" = "repo:${GitHubRepo}:ref:refs/heads/main"
            }
        }
    })
}
$roleExists = aws iam list-roles --query "Roles[?RoleName=='$DeployRole'].RoleName" --output text
if (-not $roleExists) {
    aws iam create-role --role-name $DeployRole --assume-role-policy-document $trust `
        --max-session-duration 3600 --tags Key=project,Value=$Project | Out-Null
    Write-Host "  + created role" -ForegroundColor Green
} else {
    aws iam update-assume-role-policy --role-name $DeployRole --policy-document $trust
    Write-Host "  = role exists (trust policy refreshed)" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- 3) what the role may do
Write-Host "`n[3/3] Permissions (least privilege)" -ForegroundColor Cyan
$ExecRoleArn = aws iam get-role --role-name $ExecRole --query Role.Arn --output text
$repoArns    = $Repos | ForEach-Object { "arn:aws:ecr:${Region}:${AccountId}:repository/$_" }
$serviceArns = @($ServiceApi, $ServiceWeb) | ForEach-Object { "arn:aws:ecs:${Region}:${AccountId}:service/$Cluster/$_" }
$policy = Write-Json "deploy-policy.json" @{
    Version   = "2012-10-17"
    Statement = @(
        @{ Sid = "EcrLogin";  Effect = "Allow"; Action = "ecr:GetAuthorizationToken"; Resource = "*" },
        @{ Sid = "EcrPushPortfolioImages"; Effect = "Allow"; Resource = $repoArns
           Action = @("ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:CompleteLayerUpload",
                      "ecr:DescribeImages", "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload",
                      "ecr:PutImage", "ecr:UploadLayerPart") },
        # Task definitions have no resource-level permissions for these two actions
        @{ Sid = "TaskDefinitions"; Effect = "Allow"; Resource = "*"
           Action = @("ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition") },
        @{ Sid = "UpdatePortfolioServices"; Effect = "Allow"; Resource = $serviceArns
           Action = @("ecs:DescribeServices", "ecs:UpdateService") },
        # A new task definition references the execution role; ECS needs permission to hand it on
        @{ Sid = "PassExecutionRoleToEcs"; Effect = "Allow"; Action = "iam:PassRole"; Resource = $ExecRoleArn
           Condition = @{ StringEquals = @{ "iam:PassedToService" = "ecs-tasks.amazonaws.com" } } }
    )
}
aws iam put-role-policy --role-name $DeployRole --policy-name deploy-portfolio --policy-document $policy
Write-Host "  + permissions: ECR push (2 repos), task definitions, update 2 services, pass execution role" -ForegroundColor Green

$roleArn = aws iam get-role --role-name $DeployRole --query Role.Arn --output text
Write-Host "`nDeploy role ARN (used in the GitHub workflows):" -ForegroundColor Cyan
Write-Host "  $roleArn"
