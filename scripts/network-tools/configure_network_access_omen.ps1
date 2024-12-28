# Omen-01 specific network configuration
$ErrorActionPreference = "Stop"
$RemoteIP = "192.168.1.100" # Main machine
$LocalIP = "192.168.1.180"  # Omen-01

# Import common functions
. .\network_monitor.ps1

# Additional Omen-01 specific configurations
$omenConfig = @{
    SharePaths = @(
        "D:\Games",
        "D:\Media",
        "D:\Downloads"
    )
    AllowedUsers = @(
        "Administrator",
        "MainUser"
    )
}

# Configure shares for Omen-01
foreach ($path in $omenConfig.SharePaths) {
    if (Test-Path $path) {
        $shareName = (Split-Path $path -Leaf)
        New-SmbShare -Name $shareName -Path $path -FullAccess $omenConfig.AllowedUsers
    }
} 