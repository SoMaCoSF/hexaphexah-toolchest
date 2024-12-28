# Script parameters
param(
    [switch]$DryRun
)

# Function to write event logs
function Write-ShareLog {
    param(
        [string]$Message,
        [string]$EventId,
        [string]$EntryType = "Information"
    )
    
    if (-not $DryRun) {
        Write-EventLog -LogName "Application" -Source "ShareManagement" -EventId $EventId -EntryType $EntryType -Message $Message
    } else {
        Write-Host "[DRY RUN] Would write event log: $Message" -ForegroundColor Yellow
    }
}

# Function to display menu
function Show-Menu {
    Clear-Host
    Write-Host "=== Network Share Management Tool ===" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "[DRY RUN MODE ENABLED]" -ForegroundColor Yellow
    }
    Write-Host "1. List Local Shares"
    Write-Host "2. List Local Users"
    Write-Host "3. List Remote Shares (192.168.1.100)"
    Write-Host "4. List Remote Shares (omen-01)"
    Write-Host "5. Map Network Drive"
    Write-Host "6. Remove Network Drive"
    Write-Host "7. Create New Share"
    Write-Host "8. Remove Share"
    Write-Host "Q. Quit"
}

# Function to list local shares
function Get-LocalShares {
    Write-Host "`nLocal Shares:" -ForegroundColor Green
    Get-SmbShare | Select-Object Name, Path, Description | Format-Table -AutoSize
}

# Function to list local users
function Get-LocalUserList {
    Write-Host "`nLocal Users:" -ForegroundColor Green
    Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize
}

# Function to list remote shares with proper error handling
function Get-RemoteShares {
    param (
        [string]$ComputerName
    )
    try {
        Write-Host ("`nShares on {0}:" -f $ComputerName) -ForegroundColor Green
        if (-not $DryRun) {
            Get-WmiObject -Class Win32_Share -ComputerName $ComputerName |
                Select-Object Name, Path, Description |
                Format-Table -AutoSize
        } else {
            Write-Host "[DRY RUN] Would query shares on $ComputerName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host ("Error accessing {0}: {1}" -f $ComputerName, $_.Exception.Message) -ForegroundColor Red
    }
}

# Function to map network drive with validation
function Map-NetworkDrive {
    do {
        $driveLetter = Read-Host "Enter drive letter to map (X, Y, or Z)"
        if ($driveLetter -match '^[XYZ]$') {
            break
        }
        Write-Host "Please enter a valid drive letter (X, Y, or Z)" -ForegroundColor Yellow
    } while ($true)
    
    $sharePath = Read-Host "Enter share path (e.g., \\server\share)"
    if (-not ($sharePath -match '^\\\\\w+\\\w+')) {
        Write-Host "Invalid share path format. Should be \\server\share" -ForegroundColor Red
        return
    }
    
    $persistent = Read-Host "Make persistent? (Y/N)"
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would map drive $driveLetter to $sharePath (Persistent: $($persistent -eq 'Y'))" -ForegroundColor Yellow
            return
        }

        if ($persistent -eq 'Y') {
            New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $sharePath -Persist -ErrorAction Stop
        } else {
            New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $sharePath -ErrorAction Stop
        }
        Write-Host "Drive $driveLetter mapped successfully to $sharePath" -ForegroundColor Green
        Write-ShareLog -Message "Mapped drive $driveLetter to $sharePath" -EventId 1000
    }
    catch {
        Write-Host ("Error mapping drive: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-ShareLog -Message ("Failed to map drive {0} to {1}: {2}" -f $driveLetter, $sharePath, $_.Exception.Message) -EventId 1001 -EntryType Error
    }
}

# Function to remove network drive
function Remove-NetworkDrive {
    $driveLetter = Read-Host "Enter drive letter to remove (X, Y, or Z)"
    try {
        Remove-PSDrive -Name $driveLetter -Force
        Write-Host "Drive $driveLetter removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing drive: $_" -ForegroundColor Red
    }
}

# Function to create new share with validation
function New-ShareFolder {
    $shareName = Read-Host "Enter share name"
    if (-not ($shareName -match '^[a-zA-Z0-9_-]+$')) {
        Write-Host "Invalid share name. Use only letters, numbers, underscores, and hyphens" -ForegroundColor Red
        return
    }
    
    $sharePath = Read-Host "Enter path to share"
    if (-not (Test-Path $sharePath) -and -not $DryRun) {
        Write-Host "Path does not exist" -ForegroundColor Red
        return
    }
    
    $description = Read-Host "Enter share description"
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would create share '$shareName' at '$sharePath' with description: $description" -ForegroundColor Yellow
            return
        }

        New-SmbShare -Name $shareName -Path $sharePath -Description $description -FullAccess Everyone -ErrorAction Stop
        Write-Host "Share created successfully" -ForegroundColor Green
        Write-ShareLog -Message "Created share $shareName at $sharePath" -EventId 1002
    }
    catch {
        Write-Host ("Error creating share: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-ShareLog -Message ("Failed to create share {0}: {1}" -f $shareName, $_.Exception.Message) -EventId 1003 -EntryType Error
    }
}

# Function to remove share
function Remove-ShareFolder {
    $shareName = Read-Host "Enter share name to remove"
    try {
        Remove-SmbShare -Name $shareName -Force
        Write-Host "Share removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error removing share: $_" -ForegroundColor Red
    }
}

# Initialize event log source if not in dry run mode
if (-not $DryRun -and -not [System.Diagnostics.EventLog]::SourceExists("ShareManagement")) {
    New-EventLog -LogName "Application" -Source "ShareManagement"
}

# Main loop
do {
    Show-Menu
    $selection = Read-Host "`nEnter your choice"
    
    switch ($selection) {
        '1' {
            if ($DryRun) {
                Write-Host "[DRY RUN] Would list local shares" -ForegroundColor Yellow
            } else {
                Get-LocalShares
            }
            pause
        }
        '2' {
            if ($DryRun) {
                Write-Host "[DRY RUN] Would list local users" -ForegroundColor Yellow
            } else {
                Get-LocalUserList
            }
            pause
        }
        '3' {
            Get-RemoteShares -ComputerName "192.168.1.100"
            pause
        }
        '4' {
            Get-RemoteShares -ComputerName "omen-01"
            pause
        }
        '5' {
            Map-NetworkDrive
            pause
        }
        '6' {
            if ($DryRun) {
                $driveLetter = Read-Host "Enter drive letter to remove (X, Y, or Z)"
                Write-Host "[DRY RUN] Would remove drive $driveLetter" -ForegroundColor Yellow
            } else {
                Remove-NetworkDrive
            }
            pause
        }
        '7' {
            New-ShareFolder
            pause
        }
        '8' {
            if ($DryRun) {
                $shareName = Read-Host "Enter share name to remove"
                Write-Host "[DRY RUN] Would remove share $shareName" -ForegroundColor Yellow
            } else {
                Remove-ShareFolder
            }
            pause
        }
        'Q' {
            return
        }
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
            pause
        }
    }
} while ($true) 