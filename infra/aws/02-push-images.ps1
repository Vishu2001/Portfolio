# Step 2: push the locally built Docker images to ECR (manual push; CI will automate this).
# Tags each image with the current git commit id, so every image traces back to its code.
# Usage:  .\infra\aws\02-push-images.ps1      (build first with: docker compose build)
. "$PSScriptRoot\config.ps1"

$tag = (git -C "$PSScriptRoot\..\.." rev-parse --short HEAD)
Write-Host "Version tag: $tag" -ForegroundColor Cyan

# Docker Desktop normally stores registry logins in Windows Credential Manager, but ECR tokens
# are longer than it accepts ("The stub received bad data"). So for this push, Docker uses a
# throwaway config folder without a credential store; it is deleted at the end of the script.
$tempDockerConfig = Join-Path $env:TEMP "docker-ecr-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempDockerConfig | Out-Null
# An (empty) entry under "auths" stops Docker from auto-selecting the Windows credential store;
# with it, Docker keeps the login inside this temporary file instead.
Set-Content -Path (Join-Path $tempDockerConfig "config.json") -Encoding ascii `
    -Value "{ `"auths`": { `"$Registry`": {} } }"
$env:DOCKER_CONFIG = $tempDockerConfig
# Docker prints normal progress/warnings on stderr, which Windows PowerShell 5.1 would treat as
# failures under "Stop". Judge success by exit codes instead.
$ErrorActionPreference = "Continue"
try {

# 1) Log Docker in to ECR. AWS returns a temporary password (valid 12 hours) that is piped
#    straight into docker, so it never appears on screen or in a file.
#    The pipe runs inside cmd.exe: Windows PowerShell 5.1 re-encodes text it pipes into
#    native programs, which corrupts the token and makes ECR answer "400 Bad Request".
cmd /c "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry"
if ($LASTEXITCODE -ne 0) { throw "docker login to ECR failed" }

# 2) + 3) Tag each local image with its ECR address and push it
$images = @{ "portfolio-api" = "portfolio-api:local"; "portfolio-web" = "portfolio-web:local" }
foreach ($repo in $images.Keys) {
    $remote = "$Registry/${repo}:$tag"
    Write-Host "`nPushing $($images[$repo]) -> $remote" -ForegroundColor Cyan
    docker tag $images[$repo] $remote
    if ($LASTEXITCODE -ne 0) { throw "docker tag failed for $repo" }
    docker push $remote
    if ($LASTEXITCODE -ne 0) { throw "docker push failed for $repo" }
}
} finally {
    # Remove the temporary login (token) and restore Docker's normal config
    Remove-Item -Recurse -Force $tempDockerConfig -ErrorAction SilentlyContinue
    Remove-Item Env:\DOCKER_CONFIG -ErrorAction SilentlyContinue
}

Write-Host "`nImages now in ECR:" -ForegroundColor Cyan
foreach ($repo in $images.Keys) {
    # Only tagged images (multi-platform pushes also store untagged per-platform manifests)
    aws ecr describe-images --repository-name $repo --region $Region --filter tagStatus=TAGGED `
        --query "imageDetails[].[repositoryName, join(',', imageTags), imagePushedAt]" --output table
}
