# Step 4: RDS MySQL, private, with its password generated and stored by AWS Secrets Manager.
# Takes ~10 minutes to become available. Safe to re-run: an existing instance is reused.
# Usage:  .\infra\aws\04-rds.ps1        (run 03-network.ps1 first)
. "$PSScriptRoot\config.ps1"

$VpcId   = aws ec2 describe-vpcs --region $Region --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text
$rdsSgId = aws ec2 describe-security-groups --region $Region `
    --filters Name=group-name,Values=$SgRds Name=vpc-id,Values=$VpcId --query "SecurityGroups[0].GroupId" --output text
if (-not $rdsSgId -or $rdsSgId -eq "None") { throw "Security group $SgRds not found. Run 03-network.ps1 first." }

# 1) DB subnet group: which subnets (availability zones) RDS may use. RDS requires >= 2 AZs.
$subnetGroup = "$Project-db-subnets"
$subnets = (aws ec2 describe-subnets --region $Region --filters Name=vpc-id,Values=$VpcId `
    --query "Subnets[].SubnetId" --output text) -split "\s+"
$existingSg = aws rds describe-db-subnet-groups --region $Region `
    --query "DBSubnetGroups[?DBSubnetGroupName=='$subnetGroup'].DBSubnetGroupName" --output text
if (-not $existingSg) {
    aws rds create-db-subnet-group --region $Region --db-subnet-group-name $subnetGroup `
        --db-subnet-group-description "Subnets for the portfolio database" `
        --subnet-ids @subnets --tags Key=project,Value=$Project | Out-Null
    Write-Host "  + created DB subnet group $subnetGroup ($($subnets.Count) subnets)" -ForegroundColor Green
} else {
    Write-Host "  = DB subnet group $subnetGroup exists" -ForegroundColor DarkGray
}

# 2) The database instance
$existingDb = aws rds describe-db-instances --region $Region `
    --query "DBInstances[?DBInstanceIdentifier=='$DbInstanceId'].DBInstanceIdentifier" --output text
if (-not $existingDb) {
    aws rds create-db-instance --region $Region `
        --db-instance-identifier $DbInstanceId `
        --engine mysql --engine-version $DbEngineVer `
        --db-instance-class $DbClass `
        --allocated-storage 20 --storage-type gp3 --storage-encrypted `
        --db-name $DbName `
        --master-username $DbUser `
        --manage-master-user-password `
        --db-subnet-group-name $subnetGroup `
        --vpc-security-group-ids $rdsSgId `
        --no-publicly-accessible `
        --no-multi-az `
        --backup-retention-period 1 `
        --no-deletion-protection `
        --tags Key=project,Value=$Project | Out-Null
    # --manage-master-user-password: RDS generates a strong password and keeps it in
    #   Secrets Manager. No one types or sees it; ECS will read it at container start.
    # --no-publicly-accessible: no public IP; reachable only inside the VPC (and only from
    #   portfolio-ecs-sg, thanks to the security group rule).
    Write-Host "  + creating RDS instance $DbInstanceId (takes ~10 min)..." -ForegroundColor Green
} else {
    Write-Host "  = RDS instance $DbInstanceId exists" -ForegroundColor DarkGray
}

Write-Host "Waiting until the database is available..." -ForegroundColor Cyan
aws rds wait db-instance-available --region $Region --db-instance-identifier $DbInstanceId

aws rds describe-db-instances --region $Region --db-instance-identifier $DbInstanceId `
    --query "DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,Engine:EngineVersion,Class:DBInstanceClass,Public:PubliclyAccessible,SecretArn:MasterUserSecret.SecretArn}" `
    --output table
