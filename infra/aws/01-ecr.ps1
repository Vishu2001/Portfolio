# Step 1: ECR repositories (private Docker registries) for the two images.
# Safe to re-run: existing repositories are left as they are.
# Usage:  .\infra\aws\01-ecr.ps1
. "$PSScriptRoot\config.ps1"

# Keep only the newest 10 images per repo, so old images don't pile up storage costs
$lifecyclePolicy = @'
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep only the 10 most recent images",
    "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 10 },
    "action": { "type": "expire" }
  }]
}
'@
$policyFile = Join-Path $env:TEMP "ecr-lifecycle.json"
Set-Content -Path $policyFile -Value $lifecyclePolicy -Encoding ascii

# List what already exists (listing never errors, unlike asking for one missing repo)
$existing = @(aws ecr describe-repositories --region $Region --query "repositories[].repositoryName" --output text) -split "\s+"

foreach ($repo in $Repos) {
    if ($existing -contains $repo) {
        Write-Host "  = $repo already exists" -ForegroundColor DarkGray
    } else {
        # scanOnPush: AWS checks every pushed image for known vulnerabilities (free basic scan)
        # IMMUTABLE: a tag (e.g. a git commit id) can never be overwritten with different content
        aws ecr create-repository `
            --repository-name $repo `
            --region $Region `
            --image-scanning-configuration scanOnPush=true `
            --image-tag-mutability IMMUTABLE `
            --encryption-configuration encryptionType=AES256 `
            --tags Key=project,Value=$Project | Out-Null
        Write-Host "  + created $repo" -ForegroundColor Green
    }
    aws ecr put-lifecycle-policy --repository-name $repo --region $Region `
        --lifecycle-policy-text "file://$policyFile" | Out-Null
}

Write-Host "`nRepositories:" -ForegroundColor Cyan
aws ecr describe-repositories --region $Region `
    --query "repositories[].[repositoryName,repositoryUri,imageTagMutability]" --output table
