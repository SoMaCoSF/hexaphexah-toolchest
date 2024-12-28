# Script parameters
param(
    [switch]$DryRun,
    [switch]$NoLogo
)

# Import required modules
Import-Module Microsoft.PowerShell.Security

# Function to create a dynamic ASCII box (using standard ASCII characters for better compatibility)
function Write-BoxedText {
    param(
        [string]$Title,
        [string[]]$Content,
        [ConsoleColor]$TitleColor = 'Cyan',
        [ConsoleColor]$BorderColor = 'White'
    )
    
    $width = ($Content | Measure-Object -Property Length -Maximum).Maximum + 4
    $width = [Math]::Max($width, $Title.Length + 4)
    
    Write-Host ("+-" + "-" * ($width-2) + "-+") -ForegroundColor $BorderColor
    Write-Host ("| " + $Title.PadRight($width-2) + " |") -ForegroundColor $TitleColor
    Write-Host ("+-" + "-" * ($width-2) + "-+") -ForegroundColor $BorderColor
    
    foreach($line in $Content) {
        Write-Host ("| " + $line.PadRight($width-4) + " |") -ForegroundColor $BorderColor
    }
    
    Write-Host ("+-" + "-" * ($width-2) + "-+") -ForegroundColor $BorderColor
}

# Function to get available drive letters
function Get-AvailableDriveLetters {
    $usedLetters = (Get-PSDrive -PSProvider FileSystem).Name
    $availableLetters = [char[]](67..90) | Where-Object { $_ -notin $usedLetters }
    return $availableLetters
}

# Function to validate path
function Test-ValidPath {
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try {
        $null = [System.IO.Path]::GetFullPath($Path)
        return $true
    }
    catch { return $false }
}

# Enhanced system status with more details
function Show-SystemStatus {
    Clear-Host
    
    # Get current shares with more details
    $shares = Get-SmbShare | Select-Object Name, Path, Description, 
        @{Name='CurrentConnections';Expression={$_.CurrentConnections}},
        @{Name='Permissions';Expression={
            (Get-SmbShareAccess $_.Name | ForEach-Object { "$($_.AccountName):$($_.AccessRight)" }) -join ', '
        }}
    
    $shareStatus = $shares | ForEach-Object { 
        "[$($_.Name)] -> $($_.Path) | Connections: $($_.CurrentConnections) | Access: $($_.Permissions)" 
    }
    
    # Get mapped drives with more details
    $mappedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot } | 
        Select-Object Name, DisplayRoot, @{Name='Used';Expression={
            [math]::Round($_.Used/1GB, 2)
        }}, @{Name='Free';Expression={
            [math]::Round($_.Free/1GB, 2)
        }}
    
    $driveStatus = $mappedDrives | ForEach-Object { 
        "$($_.Name): -> $($_.DisplayRoot) | Used: $($_.Used)GB | Free: $($_.Free)GB" 
    }
    
    # Get local users with more details
    $users = Get-LocalUser | Select-Object Name, Enabled, LastLogon,
        @{Name='Groups';Expression={
            (Get-LocalGroup | Where-Object { $_.Members -match $_.Name }) -join ', '
        }}
    
    $userStatus = $users | ForEach-Object { 
        "$($_.Name) [$(if($_.Enabled){'Enabled'}else{'Disabled'})] - Last: $($_.LastLogon) | Groups: $($_.Groups)" 
    }
    
    Write-BoxedText -Title "SYSTEM STATUS" -Content @(
        "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Computer: $env:COMPUTERNAME"
        "OS: $((Get-WmiObject -Class Win32_OperatingSystem).Caption)"
        "Mode: $(if($DryRun){'DRY RUN'}else{'LIVE'})"
        "Available Drive Letters: $((Get-AvailableDriveLetters) -join ', ')"
    )
    
    Write-BoxedText -Title "SHARES" -Content $shareStatus -TitleColor Yellow
    Write-BoxedText -Title "MAPPED DRIVES" -Content $driveStatus -TitleColor Green
    Write-BoxedText -Title "LOCAL USERS" -Content $userStatus -TitleColor Magenta
}

# Function to set share permissions
function Set-SharePermissions {
    $shareName = Read-Host "Enter share name"
    if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
        Write-Host "Share not found" -ForegroundColor Red
        return
    }
    
    Write-Host "`nCurrent permissions:" -ForegroundColor Cyan
    Get-SmbShareAccess -Name $shareName | Format-Table -AutoSize
    
    $account = Read-Host "Enter account name (username or group)"
    $accessLevel = Read-Host "Enter access level (Full, Change, Read)"
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would set $accessLevel access for $account on $shareName" -ForegroundColor Yellow
            return
        }
        
        Grant-SmbShareAccess -Name $shareName -AccountName $account -AccessRight $accessLevel -Force
        Write-Host "Permissions updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host ("Error setting permissions: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# Function to enable/disable user
function Set-UserStatus {
    $username = Read-Host "Enter username"
    $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
    
    if (-not $user) {
        Write-Host "User not found" -ForegroundColor Red
        return
    }
    
    $currentStatus = if ($user.Enabled) { "enabled" } else { "disabled" }
    $newStatus = if ($user.Enabled) { "disable" } else { "enable" }
    
    $confirm = Read-Host "User is currently $currentStatus. Do you want to $newStatus? (Y/N)"
    
    if ($confirm -eq 'Y') {
        try {
            if ($DryRun) {
                Write-Host "[DRY RUN] Would $newStatus user: $username" -ForegroundColor Yellow
                return
            }
            
            if ($user.Enabled) {
                Disable-LocalUser -Name $username
            } else {
                Enable-LocalUser -Name $username
            }
            Write-Host "User status updated successfully" -ForegroundColor Green
        }
        catch {
            Write-Host ("Error updating user status: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# Enhanced menu function
function Show-Menu {
    Write-BoxedText -Title "MANAGEMENT OPTIONS" -Content @(
        "1. Share Management"
        "2. Drive Management"
        "3. User Management"
        "4. System Information"
        "Q. Quit"
    )
}

# Enhanced share management menu
function Show-ShareMenu {
    Write-BoxedText -Title "SHARE MANAGEMENT" -Content @(
        "1. Create New Share"
        "2. Remove Share"
        "3. Modify Share Permissions"
        "4. Map Share to Drive Letter"
        "5. List All Shares"
        "B. Back to Main Menu"
    )
}

# Enhanced user management menu
function Show-UserMenu {
    Write-BoxedText -Title "USER MANAGEMENT" -Content @(
        "1. Create New User"
        "2. Remove User"
        "3. Reset User Password"
        "4. Enable/Disable User"
        "5. List All Users"
        "B. Back to Main Menu"
    )
}

# Function to create new user
function New-LocalUserAccount {
    $username = Read-Host "Enter username"
    $password = Read-Host "Enter password" -AsSecureString
    $fullName = Read-Host "Enter full name"
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would create user: $username" -ForegroundColor Yellow
            return
        }
        
        New-LocalUser -Name $username -Password $password -FullName $fullName -Description "Created by ShareManager" -ErrorAction Stop
        Write-Host "User created successfully" -ForegroundColor Green
    }
    catch {
        Write-Host ("Error creating user: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# Function to reset user password
function Reset-UserPassword {
    $username = Read-Host "Enter username"
    $password = Read-Host "Enter new password" -AsSecureString
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would reset password for user: $username" -ForegroundColor Yellow
            return
        }
        
        Set-LocalUser -Name $username -Password $password -ErrorAction Stop
        Write-Host "Password reset successfully" -ForegroundColor Green
    }
    catch {
        Write-Host ("Error resetting password: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# Enhanced share creation with drive mapping
function New-ShareWithMapping {
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
    $mapDrive = Read-Host "Map to drive letter? (Y/N)"
    
    if ($mapDrive -eq 'Y') {
        do {
            $driveLetter = Read-Host "Enter drive letter (C-Z)"
            if ($driveLetter -match '^[C-Z]$') {
                break
            }
            Write-Host "Please enter a valid drive letter (C-Z)" -ForegroundColor Yellow
        } while ($true)
    }
    
    try {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would create share '$shareName' at '$sharePath'" -ForegroundColor Yellow
            if ($mapDrive -eq 'Y') {
                Write-Host "[DRY RUN] Would map to drive $driveLetter" -ForegroundColor Yellow
            }
            return
        }

        New-SmbShare -Name $shareName -Path $sharePath -Description $description -FullAccess Everyone -ErrorAction Stop
        Write-Host "Share created successfully" -ForegroundColor Green
        
        if ($mapDrive -eq 'Y') {
            New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "\\localhost\$shareName" -Persist -ErrorAction Stop
            Write-Host "Drive mapped successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# Add missing function
function Get-LocalShares {
    Write-Host "`nLocal Shares:" -ForegroundColor Green
    try {
        Get-SmbShare | Select-Object Name, Path, Description | Format-Table -AutoSize
    }
    catch {
        Write-Host "Error getting shares: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Add other missing functions
function Get-LocalUserList {
    Write-Host "`nLocal Users:" -ForegroundColor Green
    try {
        Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize
    }
    catch {
        Write-Host "Error getting users: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main loop with enhanced UI
do {
    Show-SystemStatus
    Show-Menu
    $selection = Read-Host "`nEnter your choice"
    
    switch ($selection) {
        '1' {
            do {
                Show-ShareMenu
                $shareChoice = Read-Host "`nEnter your choice"
                switch ($shareChoice) {
                    '1' { New-ShareWithMapping; pause }
                    '2' { Remove-ShareFolder; pause }
                    '3' { Set-SharePermissions; pause }
                    '4' { Map-NetworkDrive; pause }
                    '5' { Get-LocalShares; pause }
                    'B' { break }
                    default { Write-Host "Invalid selection" -ForegroundColor Red; pause }
                }
            } while ($shareChoice -ne 'B')
        }
        '2' {
            Map-NetworkDrive
            pause
        }
        '3' {
            do {
                Show-UserMenu
                $userChoice = Read-Host "`nEnter your choice"
                switch ($userChoice) {
                    '1' { New-LocalUserAccount; pause }
                    '2' { Remove-LocalUser; pause }
                    '3' { Reset-UserPassword; pause }
                    '4' { Set-UserStatus; pause }
                    '5' { Get-LocalUserList; pause }
                    'B' { break }
                    default { Write-Host "Invalid selection" -ForegroundColor Red; pause }
                }
            } while ($userChoice -ne 'B')
        }
        '4' {
            Show-SystemStatus
            pause
        }
        'Q' { 
            Write-Host "Exiting..." -ForegroundColor Yellow
            return 
        }
        default { 
            Write-Host "Invalid selection" -ForegroundColor Red
            pause
        }
    }
} while ($true) 