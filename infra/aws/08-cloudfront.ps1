# Step 8: HTTPS for the site via CloudFront (AWS's CDN), using CloudFront's own certificate.
#   Visitor --https--> CloudFront (d....cloudfront.net) --http--> load balancer --> ECS
# No domain needed. When a custom domain is added later, it gets attached to this distribution.
# Safe to re-run: an existing distribution (found by its comment) is reused.
# Usage:  .\infra\aws\08-cloudfront.ps1
. "$PSScriptRoot\config.ps1"
$tmp = Join-Path $env:TEMP "portfolio-cf"; New-Item -ItemType Directory -Force $tmp | Out-Null
$Comment = "portfolio-site"

# AWS-managed policies (fixed IDs, same in every account)
$CachingDisabled  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
$CachingOptimized = "658327ea-f89d-4fab-a63d-7e88639e58f3"
$AllViewerExceptHostHeader = "b689b0a8-53d0-40ab-baf2-68738e2966ac"  # forward headers/cookies/query, not Host

$existing = aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$Comment'].[Id,DomainName]" --output text
# With no distributions at all, the CLI prints the literal text "None"
if ($existing -and $existing -ne "None") {
    $id, $domain = $existing -split "\s+"
    Write-Host "  = distribution exists: $id ($domain)" -ForegroundColor DarkGray
} else {
    $AlbDns = aws elbv2 describe-load-balancers --region $Region `
        --query "LoadBalancers[?LoadBalancerName=='$AlbName'].DNSName" --output text
    $originId = "alb"
    function Behavior($pattern, $cachePolicy, [bool]$allMethods) {
        $methods = if ($allMethods) { @("GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE") } else { @("GET","HEAD") }
        $b = [ordered]@{
            TargetOriginId        = $originId
            ViewerProtocolPolicy  = "redirect-to-https"            # http:// visitors are sent to https://
            AllowedMethods        = @{ Quantity = $methods.Count; Items = $methods
                                       CachedMethods = @{ Quantity = 2; Items = @("GET","HEAD") } }
            Compress              = $true
            CachePolicyId         = $cachePolicy
            OriginRequestPolicyId = $AllViewerExceptHostHeader
        }
        if ($pattern) { $b = [ordered]@{ PathPattern = $pattern } + $b }
        return $b
    }
    $config = [ordered]@{
        CallerReference   = "portfolio-$(Get-Date -Format yyyyMMddHHmmss)"
        Comment           = $Comment
        Enabled           = $true
        PriceClass        = "PriceClass_All"     # includes edge locations in India and Australia
        HttpVersion       = "http2and3"
        IsIPV6Enabled     = $true
        Origins           = @{ Quantity = 1; Items = @(@{
            Id         = $originId
            DomainName = $AlbDns
            CustomOriginConfig = @{
                HTTPPort = 80; HTTPSPort = 443
                OriginProtocolPolicy = "http-only"   # CloudFront -> load balancer over AWS's network
                OriginSslProtocols   = @{ Quantity = 1; Items = @("TLSv1.2") }
                OriginReadTimeout    = 30; OriginKeepaliveTimeout = 5
            }
        }) }
        # Pages: always fresh (not cached)
        DefaultCacheBehavior = (Behavior $null $CachingDisabled $false)
        CacheBehaviors = @{ Quantity = 2; Items = @(
            # API: never cached, all methods (the contact form POSTs)
            (Behavior "/api/*" $CachingDisabled $true),
            # Next.js build assets: file names contain content hashes, safe to cache at the edge
            (Behavior "/_next/static/*" $CachingOptimized $false)
        ) }
        ViewerCertificate = @{ CloudFrontDefaultCertificate = $true; MinimumProtocolVersion = "TLSv1" }
    }
    $file = Join-Path $tmp "distribution.json"
    ConvertTo-Json -InputObject $config -Depth 20 | Set-Content -Path $file -Encoding ascii
    $out = aws cloudfront create-distribution --distribution-config "file://$file" `
        --query "Distribution.[Id,DomainName]" --output text
    $id, $domain = $out -split "\s+"
    aws cloudfront tag-resource --resource "arn:aws:cloudfront::${AccountId}:distribution/$id" `
        --tags "Items=[{Key=project,Value=$Project}]" | Out-Null
    Write-Host "  + created distribution $id ($domain)" -ForegroundColor Green
}

Write-Host "Waiting until the distribution is deployed to all edge locations (5-15 min)..." -ForegroundColor Cyan
aws cloudfront wait distribution-deployed --id $id
Write-Host "`nSite over HTTPS: https://$domain/" -ForegroundColor Green
