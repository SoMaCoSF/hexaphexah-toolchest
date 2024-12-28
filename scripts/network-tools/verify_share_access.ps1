# Verify share access between machines
param(
    [string]$RemoteComputer = "omen-01",
    [string]$RemoteIP = "192.168.1.180"
)

function Test-ShareAccess {
    param(
        [string]$SharePath,
        [string]$Credential
    )
    
    try {
        Test-Path -Path $SharePath -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Test basic connectivity
Write-Host "Testing basic connectivity..."
$pingResult = Test-Connection -ComputerName $RemoteIP -Count 1 -Quiet
Write-Host "Ping test to $RemoteIP : $pingResult"

# Test SMB ports
Write-Host "`nTesting SMB ports..."
$ports = @(445, 139)
foreach ($port in $ports) {
    $test = Test-NetConnection -ComputerName $RemoteIP -Port $port
    Write-Host "Port $port : $($test.TcpTestSucceeded)"
}

# List shares
Write-Host "`nListing shares on local machine..."
Get-SmbShare | Format-Table Name, Path, Description

# Test remote share access
Write-Host "`nTesting access to remote shares..."
$shares = Get-SmbShare | Where-Object {$_.Name -ne "IPC$"}
foreach ($share in $shares) {
    $access = Test-ShareAccess -SharePath "\\$RemoteComputer\$($share.Name)"
    Write-Host "Access to $($share.Name) : $access"
}

# Check firewall status
Write-Host "`nChecking firewall rules..."
Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" | 
    Format-Table DisplayName, Enabled, Profile, Direction, Action

# Output diagnostic information
Write-Host "`nNetwork Configuration:"
Get-NetIPConfiguration | Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway

Write-Host "`nSMB Configuration:"
Get-SmbServerConfiguration | Format-List EnableSMB2Protocol, EncryptData 