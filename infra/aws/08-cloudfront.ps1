# Step 8: HTTPS for the site via CloudFront (AWS's CDN), using CloudFront's own certificate.
#   Visitor --https--> CloudFront (d....cloudfront.net) --http--> load balancer --> ECS
# No domain needed. When a custom domain is added later, it gets attached to this distribution.
# Safe to re-run: an existing distribution (found by its comment) is reused.
# Usage:  .\infra\aws\08-cloudfront.ps1
. "$PSScriptRoot\config.ps1"
$tmp = Join-Path $env:TEMP "portfolio-cf"; New-Item -ItemType Directory -Force $tmp | Out-Null
$Comment = "portfolio-site"

# AWS-managed policies, looked up by name (safer than hard-coding their IDs)
function Get-CachePolicyId($name) {
    aws cloudfront list-cache-policies --type managed `
        --query "CachePolicyList.Items[?CachePolicy.CachePolicyConfig.Name=='$name'].CachePolicy.Id | [0]" --output text
}
$CachingDisabled  = Get-CachePolicyId "Managed-CachingDisabled"
$CachingOptimized = Get-CachePolicyId "Managed-CachingOptimized"
# Forward headers/cookies/query string to the origin, but not Host
$AllViewerExceptHostHeader = aws cloudfront list-origin-request-policies --type managed `
    --query "OriginRequestPolicyList.Items[?OriginRequestPolicy.OriginRequestPolicyConfig.Name=='Managed-AllViewerExceptHostHeader'].OriginRequestPolicy.Id | [0]" --output text

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

# ---------------------------------------------------------------- lock the load balancer to CloudFront
# Port 80 on the load balancer now accepts ONLY CloudFront's servers (AWS-managed prefix list,
# kept up to date by AWS). Visitors can no longer bypass HTTPS via the elb.amazonaws.com address,
# and the backend can safely trust the X-Forwarded-For entries added by CloudFront + the ALB.
Write-Host "`nRestricting the load balancer to CloudFront only" -ForegroundColor Cyan
$VpcId    = aws ec2 describe-vpcs --region $Region --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text
$albSgId  = aws ec2 describe-security-groups --region $Region --filters Name=group-name,Values=$SgAlb Name=vpc-id,Values=$VpcId `
    --query "SecurityGroups[0].GroupId" --output text
$cfPrefix = aws ec2 describe-managed-prefix-lists --region $Region `
    --filters Name=prefix-list-name,Values=com.amazonaws.global.cloudfront.origin-facing --query "PrefixLists[0].PrefixListId" --output text
$hasCf = aws ec2 describe-security-group-rules --region $Region --filters Name=group-id,Values=$albSgId `
    --query "SecurityGroupRules[?PrefixListId=='$cfPrefix'] | length(@)" --output text
if ($hasCf -eq "0") {
    aws ec2 authorize-security-group-ingress --region $Region --group-id $albSgId `
        --ip-permissions "IpProtocol=tcp,FromPort=80,ToPort=80,PrefixListIds=[{PrefixListId=$cfPrefix,Description=CloudFront only}]" | Out-Null
    Write-Host "  + port 80 allowed from CloudFront ($cfPrefix)" -ForegroundColor Green
}
# Remove the old "anyone on the internet" rules (IPv4 0.0.0.0/0 and IPv6 ::/0)
$openRules = aws ec2 describe-security-group-rules --region $Region --filters Name=group-id,Values=$albSgId `
    --query "SecurityGroupRules[?IsEgress==``false`` && (CidrIpv4=='0.0.0.0/0' || CidrIpv6=='::/0')].SecurityGroupRuleId" --output text
if ($openRules -and $openRules -ne "None") {
    # One call per rule: the aws wrapper in config.ps1 joins list arguments with commas
    foreach ($ruleId in ($openRules -split "\s+" | Where-Object { $_ })) {
        aws ec2 revoke-security-group-ingress --region $Region --group-id $albSgId --security-group-rule-ids $ruleId | Out-Null
    }
    Write-Host "  - removed public internet access to the load balancer" -ForegroundColor Green
}

Write-Host "`nSite over HTTPS: https://$domain/" -ForegroundColor Green
