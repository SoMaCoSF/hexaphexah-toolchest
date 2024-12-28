# Load environment variables and setup
Param([string]$EnvFilePath = ".\.env")

Write-Host "`n=== Step 1: Load Environment Variables from .env ==="

if (!(Test-Path $EnvFilePath)) {
    Write-Host "ERROR: .env file not found at path: $EnvFilePath"
    exit 1
}

function Load-DotEnv($path) {
    $content = Get-Content -Path $path
    foreach ($line in $content) {
        if ($line -match "^\s*#" -or $line -match "^\s*$") { continue }
        if ($line -match "^(.*?)=(.*)") {
            $varName = $matches[1].Trim()
            $varValue = $matches[2].Trim(' ''"')
            Set-Item "env:$varName" $varValue
        }
    }
}

Load-DotEnv $EnvFilePath

Write-Host "Using Postgres Host: $($env:DB_HOST)"
Write-Host "Using Postgres Port: $($env:DB_PORT)"
Write-Host "Using Postgres DB:   $($env:DB_NAME)"
Write-Host "Using Postgres User: $($env:DB_USER)"
Write-Host "Path to psql:        $($env:PSQL_PATH)"

Write-Host "`n=== Step 2: Create Database and Schema ==="
$env:PGPASSWORD = $env:DB_PASSWORD

# Create database if it doesn't exist
$createDbSql = "CREATE DATABASE $($env:DB_NAME);"
& $env:PSQL_PATH -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d "postgres" -c $createDbSql 2>$null

# Create the table
$createTableSql = @"
CREATE TABLE IF NOT EXISTS "UserSiteTracking" (
    "ID" SERIAL PRIMARY KEY,
    "Username" VARCHAR(255) NOT NULL,
    "SiteName" VARCHAR(255) NOT NULL,
    "ProfileURL" TEXT,
    "LastChecked" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "IsActive" BOOLEAN DEFAULT TRUE,
    "ForgotPasswordURL" TEXT,
    "OptOutURL" TEXT,
    "LastPasswordResetRequest" TIMESTAMP,
    "LastResetEmailReceived" TIMESTAMP,
    "Notes" TEXT,
    UNIQUE("Username", "SiteName")
);

CREATE INDEX IF NOT EXISTS idx_username ON "UserSiteTracking" ("Username");
CREATE INDEX IF NOT EXISTS idx_sitename ON "UserSiteTracking" ("SiteName");
"@

& $env:PSQL_PATH -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c $createTableSql

Write-Host "`n=== Step 3: Import Data from Sherlock ==="

# Build dynamic insert statements from Sherlock findings
$insertData = @()
$usernameFiles = @('sstave.txt', 'samstave.txt', 'skstave.txt', 'samkstave.txt', 'phlux.txt', 'sarah_connor.txt')

foreach ($file in $usernameFiles) {
    $username = $file.Replace('.txt', '')
    if (Test-Path $file) {
        Get-Content $file | Where-Object { $_ -match '^http' } | ForEach-Object {
            $url = $_
            $siteName = ($url -split '/')[2]
            $insertData += "('$username', '$siteName', '$url', 'Found by Sherlock')"
        }
    }
}

if ($insertData.Count -gt 0) {
    $insertSql = @"
INSERT INTO "UserSiteTracking" ("Username", "SiteName", "ProfileURL", "Notes")
VALUES $($insertData -join ",`n");
"@
    & $env:PSQL_PATH -h $env:DB_HOST -p $env:DB_PORT -U $env:DB_USER -d $env:DB_NAME -c $insertSql
}

Write-Host "Database setup complete! Schema created and data imported." 