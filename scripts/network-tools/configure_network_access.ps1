# Configure Windows Firewall and SMB sharing for secure network access
# Run as Administrator

$ErrorActionPreference = "Stop"
$RemoteIP = "192.168.1.180" # omen-01
$LocalIP = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -eq "Dhcp"}).IPAddress

# Function to log actions
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
    Add-Content -Path ".\network_setup.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting network configuration..."

# 1. Enable necessary Windows features
Write-Log "Enabling Windows features..."
$features = @(
    "FileAndStorage-Services",
    "File-Services",
    "FS-FileServer",
    "Storage-Services"
)

foreach ($feature in $features) {
    if ((Get-WindowsOptionalFeature -Online -FeatureName $feature).State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
        Write-Log "Enabled feature: $feature"
    }
}

# 2. Configure Windows Firewall
Write-Log "Configuring Windows Firewall..."

# Allow File and Printer Sharing
$firewallRules = @(
    @{Name="File and Printer Sharing (SMB-In)"; Protocol="TCP"; Port="445"},
    @{Name="File and Printer Sharing (NB-Session-In)"; Protocol="TCP"; Port="139"},
    @{Name="File and Printer Sharing (NB-Name-In)"; Protocol="UDP"; Port="137"},
    @{Name="File and Printer Sharing (NB-Datagram-In)"; Protocol="UDP"; Port="138"}
)

foreach ($rule in $firewallRules) {
    $existingRule = Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
    
    if (-not $existingRule) {
        New-NetFirewallRule -DisplayName $rule.Name `
            -Direction Inbound `
            -Protocol $rule.Protocol `
            -LocalPort $rule.Port `
            -Action Allow `
            -Profile Private `
            -RemoteAddress $RemoteIP
        Write-Log "Created firewall rule: $($rule.Name)"
    } else {
        Set-NetFirewallRule -DisplayName $rule.Name `
            -RemoteAddress $RemoteIP `
            -Enabled True
        Write-Log "Updated existing firewall rule: $($rule.Name)"
    }
}

# 3. Configure SMB Settings
Write-Log "Configuring SMB settings..."

# Enable SMBv2
Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
Write-Log "Enabled SMBv2 Protocol"

# Configure SMB encryption (optional but recommended)
Set-SmbServerConfiguration -EncryptData $true -Force
Write-Log "Enabled SMB encryption"

# 4. Configure Network Discovery
Write-Log "Enabling Network Discovery..."
Get-NetFirewallRule -DisplayGroup "Network Discovery" | Set-NetFirewallRule -Profile Private -Enabled True
Write-Log "Enabled Network Discovery firewall rules"

# 5. Test Network Connectivity
Write-Log "Testing network connectivity..."
$testResult = Test-NetConnection -ComputerName $RemoteIP -Port 445
if ($testResult.TcpTestSucceeded) {
    Write-Log "Successfully connected to $RemoteIP on port 445 (SMB)"
} else {
    Write-Log "WARNING: Could not connect to $RemoteIP on port 445 (SMB)"
}

# 6. Create diagnostic info file
$diagnosticInfo = @"
Network Configuration Summary
===========================
Date: $(Get-Date)
Local IP: $LocalIP
Remote IP: $RemoteIP

SMB Status:
$(Get-SmbServerConfiguration | Format-List | Out-String)

Firewall Rules:
$(Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Format-List | Out-String)

Network Adapters:
$(Get-NetAdapter | Format-List | Out-String)
"@

$diagnosticInfo | Out-File -FilePath ".\network_diagnostic.txt"
Write-Log "Created network diagnostic file: network_diagnostic.txt"

Write-Log "Configuration complete. Please check network_diagnostic.txt for detailed information." 