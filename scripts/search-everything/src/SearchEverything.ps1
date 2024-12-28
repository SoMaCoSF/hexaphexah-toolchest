# SearchEverything.ps1
# Requires -Version 7.0

# Constants and Configuration
$script:Config = @{
    LogPath        = Join-Path $PSScriptRoot "logs"
    LogFile        = "everything-search.log"
    MaxLogSize     = 10MB
    MaxLogFiles    = 5
    EverythingPath = Join-Path $PSScriptRoot "Everything"
}

# Import Terminal.GUI if available, otherwise install it
function Initialize-TerminalGUI {
    Write-Log "Initializing Terminal.Gui..." -Level Info
    
    try {
        # Check for local Terminal.Gui repository
        $localGuiPath = Join-Path $PSScriptRoot ".." "Everything" "Terminal.Gui"
        $terminalGuiProject = Join-Path $localGuiPath "Terminal.Gui" "Terminal.Gui.csproj"
        
        if (Test-Path $terminalGuiProject) {
            Write-VerboseOperation "Found local Terminal.Gui repository" -Status "Info"
            
            # Build the project
            Write-VerboseOperation "Building Terminal.Gui..." -Status "Info"
            
            try {
                Push-Location $localGuiPath
                dotnet build "Terminal.Gui/Terminal.Gui.csproj" -c Release
                
                # Get the built DLL
                $dllPath = Join-Path $localGuiPath "Terminal.Gui" "bin" "Release" "net7.0" "Terminal.Gui.dll"
                if (-not (Test-Path $dllPath)) {
                    throw "Built DLL not found at: $dllPath"
                }
                
                # Import the assembly
                Add-Type -Path $dllPath
                Write-VerboseOperation "Terminal.Gui loaded successfully" -Status "Success"
                return $true
            }
            catch {
                Write-VerboseOperation "Failed to build Terminal.Gui: $_" -Status "Error"
                return $false
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-VerboseOperation "Local Terminal.Gui repository not found or incomplete" -Status "Warning"
            Write-VerboseOperation "Falling back to console interface" -Status "Info"
            return $false
        }
    }
    catch {
        Write-VerboseOperation "Failed to initialize Terminal.Gui: $_" -Status "Error"
        Write-VerboseOperation "Falling back to console interface" -Status "Info"
        return $false
    }
}

function Write-VerboseOperation {
    param(
        [string]$Operation,
        [string]$Command = "",
        [string]$Result = "",
        [string]$Status = "Info"
    )
    
    $color = switch ($Status) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "Gray" }
    }
    
    $prefix = switch ($Status) {
        "Success" { "[✓]" }
        "Warning" { "[!]" }
        "Error" { "[✕]" }
        default { "[*]" }
    }
    
    # Format the operation message
    $message = "$prefix $Operation"
    Write-Host $message -ForegroundColor $color
    
    # Show command if provided
    if ($Command) {
        Write-Host "    > $Command" -ForegroundColor DarkGray
    }
    
    # Format and show result if provided
    if ($Result) {
        $maxWidth = [Console]::WindowWidth - 8  # Account for margin
        $lines = @()
        
        # Split result into lines and truncate if needed
        foreach ($line in $Result -split "`n") {
            if ($line.Length -gt $maxWidth) {
                $lines += $line.Substring(0, $maxWidth - 3) + "..."
            }
            else {
                $lines += $line
            }
        }
        
        # Show only first 3 lines if there are more
        if ($lines.Count -gt 3) {
            $lines = $lines[0..2]
            $lines += "    ... and $($lines.Count - 3) more lines"
        }
        
        foreach ($line in $lines) {
            Write-Host "    $line" -ForegroundColor Gray
        }
    }
}

function Show-SystemInfo {
    $everythingVersion = try { 
        & "$($script:Config.EverythingPath)\es.exe" -version 2>$null 
    }
    catch { 
        "Not installed" 
    }

    $systemInfo = [ordered]@{
        "PowerShell Version" = $PSVersionTable.PSVersion
        "OS Version"         = [System.Environment]::OSVersion.Version
        "Everything Version" = $everythingVersion
        "Cursor Path"        = $env:CURSOR_PATH ?? (Join-Path $env:USERPROFILE ".cursor")
        "Script Path"        = $PSScriptRoot
        "Log Path"           = $script:Config.LogPath
        "Everything Path"    = $script:Config.EverythingPath
    }

    $width = 60
    $header = "╔" + "═" * ($width - 2) + "╗"
    $footer = "╚" + "═" * ($width - 2) + "╝"
    $empty = "║" + " " * ($width - 2) + "║"

    Write-Host $header
    Write-Host "║" + (" System Information ".PadLeft(($width + 17) / 2).PadRight($width - 2)) + "║"
    Write-Host $empty

    foreach ($item in $systemInfo.GetEnumerator()) {
        $line = "  {0}: {1}" -f $item.Key, $item.Value
        Write-Host ("║" + $line.PadRight($width - 2) + "║")
    }

    Write-Host $empty
    Write-Host $footer
}

function Install-RequiredSoftware {
    param (
        [switch]$Force
    )

    $requirements = @(
        @{
            Name    = "PowerShell 7+"
            Test    = { Test-PowerShellVersion }
            Install = { Install-PowerShell7 }
            Url     = "https://github.com/PowerShell/PowerShell/releases"
        },
        @{
            Name    = "Everything Search"
            Test    = { Initialize-EverythingPaths }
            Install = { Install-Everything }
            Url     = "https://www.voidtools.com/downloads/"
        },
        @{
            Name    = ".NET SDK"
            Test    = { 
                $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
                if ($dotnet) {
                    $version = & dotnet --version
                    Write-Log "Found .NET SDK version: $version" -Level Debug
                    return $true
                }
                return $false
            }
            Install = { 
                Write-VerboseOperation "Please install .NET SDK from: https://dotnet.microsoft.com/download" -Status "Info"
                return $false
            }
            Url     = "https://dotnet.microsoft.com/download"
        }
    )

    $needsRerun = $false
    foreach ($req in $requirements) {
        Write-VerboseOperation "Checking $($req.Name)..." -Status "Info"
        
        if (-not (& $req.Test) -or $Force) {
            Write-VerboseOperation "$($req.Name) not found or update required" -Status "Warning"
            
            if (-not $Force) {
                $response = Read-Host "Would you like to install/update $($req.Name)? (Y/N)"
                if ($response -ne 'Y') { continue }
            }
            
            Write-VerboseOperation "Installing $($req.Name)..." -Status "Info"
            try {
                if (& $req.Install) {
                    $needsRerun = $true
                    Write-VerboseOperation "$($req.Name) installed successfully" -Status "Success"
                }
                else {
                    Write-VerboseOperation "Failed to install $($req.Name)" -Status "Error"
                    Write-VerboseOperation "Please install manually from: $($req.Url)" -Status "Info"
                }
            }
            catch {
                Write-VerboseOperation "Failed to install $($req.Name): $_" -Status "Error"
                Write-VerboseOperation "Please install manually from: $($req.Url)" -Status "Info"
            }
        }
        else {
            Write-VerboseOperation "$($req.Name) is installed" -Status "Success"
        }
    }

    return $needsRerun
}

function Initialize-EverythingPaths {
    Write-Log "Checking Everything paths..." -Level Debug
    
    # Check standard installation paths in order of preference
    $paths = @(
        "${env:ProgramFiles}\Everything", # Primary installation path
        $script:Config.EverythingPath, # Our local path
        "${env:ProgramFiles(x86)}\Everything",
        "D:\Cursor\Hexaphexah\Everything\ES-1.1.0.27.x64"  # Fallback to known location
    )

    foreach ($path in $paths) {
        $esPath = Join-Path $path "es.exe"
        if (Test-Path $esPath) {
            Write-Log "Found Everything at: $path" -Level Debug
            
            # Add to PATH if not already there
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -notlike "*$path*") {
                Write-Log "Adding Everything to PATH: $path" -Level Debug
                [Environment]::SetEnvironmentVariable(
                    "Path",
                    "$currentPath;$path",
                    "User"
                )
                $env:Path = "$env:Path;$path"
            }
            
            # Check if Everything service is running
            $service = Get-Service "Everything" -ErrorAction SilentlyContinue
            if (-not $service -or $service.Status -ne 'Running') {
                Write-VerboseOperation "Everything service not running" -Status "Warning"
                Write-VerboseOperation "Please start Everything.exe and enable the service" -Status "Info"
                return $false
            }
            
            # Verify IPC connection
            $version = & $esPath -get-everything-version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Everything IPC connection verified" -Level Debug
                return $true
            }
            else {
                Write-VerboseOperation "Everything IPC connection failed" -Status "Warning"
                Write-VerboseOperation "Please ensure Everything.exe is running" -Status "Info"
                return $false
            }
        }
    }

    Write-Log "Everything not found in standard paths" -Level Warning
    return $false
}

function Install-Everything {
    Write-Log "Installing Everything Search..." -Level Info
    
    try {
        # First check if Everything is already installed in Program Files
        $programFilesPath = "${env:ProgramFiles}\Everything"
        if (Test-Path (Join-Path $programFilesPath "es.exe")) {
            Write-VerboseOperation "Everything already installed in Program Files" -Status "Info"
            return Initialize-EverythingPaths
        }
        
        # Check if we have es.exe in our known location
        $knownPath = "D:\Cursor\Hexaphexah\Everything\ES-1.1.0.27.x64\es.exe"
        if (Test-Path $knownPath) {
            Write-VerboseOperation "Found es.exe in known location" -Status "Info"
            
            # Create Program Files directory if needed
            if (-not (Test-Path $programFilesPath)) {
                New-Item -ItemType Directory -Path $programFilesPath -Force | Out-Null
            }
            
            # Copy es.exe to Program Files
            Write-VerboseOperation "Copying es.exe to Program Files" -Status "Info"
            Copy-Item $knownPath $programFilesPath -Force
            
            # Initialize paths and verify installation
            if (Initialize-EverythingPaths) {
                Write-VerboseOperation "Everything installed successfully" -Status "Success"
                return $true
            }
        }
        
        Write-VerboseOperation "Please install Everything manually from https://www.voidtools.com" -Status "Info"
        Write-VerboseOperation "After installation, run Everything.exe and enable the service" -Status "Info"
        return $false
    }
    catch {
        Write-VerboseOperation "Failed to install Everything: $_" -Status "Error"
        return $false
    }
}

function Show-MainMenu {
    [Terminal.Gui.Application]::Init()
    
    $win = [Terminal.Gui.Window]::new()
    $win.Title = "Everything Search UI"
    
    # Create status bar
    $statusBar = [Terminal.Gui.StatusBar]::new(@(
            [Terminal.Gui.StatusItem]@{
                Title  = "Help"
                HotKey = [Terminal.Gui.Key]::F1
                Action = { Show-Help }
            },
            [Terminal.Gui.StatusItem]@{
                Title  = "Search"
                HotKey = [Terminal.Gui.Key]::F2
                Action = { Show-SearchDialog }
            },
            [Terminal.Gui.StatusItem]@{
                Title  = "Quit"
                HotKey = [Terminal.Gui.Key]::F10
                Action = { [Terminal.Gui.Application]::RequestStop() }
            }
        ))
    
    # Create main menu
    $menu = [Terminal.Gui.MenuBar]::new(@(
            [Terminal.Gui.MenuBarItem]@{
                Title    = "&File"
                Children = @(
                    [Terminal.Gui.MenuItem]@{
                        Title  = "&Search"
                        Action = { Show-SearchDialog }
                    },
                    [Terminal.Gui.MenuItem]@{
                        Title  = "&Quit"
                        Action = { [Terminal.Gui.Application]::RequestStop() }
                    }
                )
            }
        ))
    
    # Add components
    [Terminal.Gui.Application]::Top.Add($win)
    [Terminal.Gui.Application]::Top.Add($menu)
    [Terminal.Gui.Application]::Top.Add($statusBar)
    
    # Run the application
    [Terminal.Gui.Application]::Run()
}

function Show-Help {
    $helpText = @"
Everything Search UI Help
------------------------

Keyboard Shortcuts:
F1  - Show this help
F2  - Open search dialog
F10 - Exit application

Search Tips:
- Use wildcards: * and ?
- Use regex with -r flag
- Filter by extension: ext:pdf
- Filter by size: size:>1mb
- Filter by date: dm:today
"@

    $helpDialog = [Terminal.Gui.Dialog]::new()
    $helpDialog.Title = "Help"
    
    $textView = [Terminal.Gui.TextView]::new()
    $textView.Text = $helpText
    $textView.ReadOnly = $true
    $textView.Width = [Terminal.Gui.Dim]::Fill()
    $textView.Height = [Terminal.Gui.Dim]::Fill() - 1
    
    $button = [Terminal.Gui.Button]::new("OK")
    $button.Y = [Terminal.Gui.Pos]::At([Terminal.Gui.View]::LastLine)
    $button.Clicked = { $helpDialog.RequestStop() }
    
    $helpDialog.Add($textView, $button)
    [Terminal.Gui.Application]::Run($helpDialog)
}

function Show-SearchDialog {
    $dialog = [Terminal.Gui.Dialog]::new()
    $dialog.Title = "Search Everything"
    $dialog.Width = 80
    $dialog.Height = 20
    
    # Search input
    $searchLabel = [Terminal.Gui.Label]::new("Search:")
    $searchLabel.Y = 1
    
    $searchInput = [Terminal.Gui.TextField]::new()
    $searchInput.X = [Terminal.Gui.Pos]::Right($searchLabel)
    $searchInput.Y = 1
    $searchInput.Width = [Terminal.Gui.Dim]::Fill() - 2
    
    # Options
    $regexCheck = [Terminal.Gui.CheckBox]::new("Use Regex")
    $regexCheck.Y = 3
    
    $caseCheck = [Terminal.Gui.CheckBox]::new("Case Sensitive")
    $caseCheck.Y = 4
    
    # Results list
    $resultsList = [Terminal.Gui.ListView]::new()
    $resultsList.Y = 6
    $resultsList.Width = [Terminal.Gui.Dim]::Fill()
    $resultsList.Height = [Terminal.Gui.Dim]::Fill() - 3
    
    # Buttons
    $searchBtn = [Terminal.Gui.Button]::new("_Search")
    $searchBtn.Y = [Terminal.Gui.Pos]::At([Terminal.Gui.View]::LastLine)
    $searchBtn.Clicked = {
        $query = $searchInput.Text.ToString()
        $useRegex = $regexCheck.Checked
        $caseSensitive = $caseCheck.Checked
        
        $args = @($query)
        if ($useRegex) { $args += "-regex" }
        if ($caseSensitive) { $args += "-case" }
        
        $results = & es.exe @args 2>&1
        if ($LASTEXITCODE -eq 0) {
            $resultsList.SetSource($results)
        }
        else {
            $errorInfo = Format-EverythingError $results
            [Terminal.Gui.MessageBox]::ErrorQuery("Search Error", $errorInfo.Message)
        }
    }
    
    $cancelBtn = [Terminal.Gui.Button]::new("_Cancel")
    $cancelBtn.X = [Terminal.Gui.Pos]::Right($searchBtn) + 2
    $cancelBtn.Y = [Terminal.Gui.Pos]::At([Terminal.Gui.View]::LastLine)
    $cancelBtn.Clicked = { $dialog.RequestStop() }
    
    $dialog.Add(
        $searchLabel, $searchInput,
        $regexCheck, $caseCheck,
        $resultsList,
        $searchBtn, $cancelBtn
    )
    
    [Terminal.Gui.Application]::Run($dialog)
}

# Initialize logging
function Initialize-Logging {
    # Ensure log directory exists
    if (-not (Test-Path $script:Config.LogPath)) {
        New-Item -ItemType Directory -Path $script:Config.LogPath -Force | Out-Null
    }
    
    # Set full log file path
    $script:LogFile = Join-Path $script:Config.LogPath $script:Config.LogFile
    
    # Create log file if it doesn't exist
    if (-not (Test-Path $script:LogFile)) {
        New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
    }
    
    # Rotate logs if needed
    if (Test-Path $script:LogFile) {
        $logSize = (Get-Item $script:LogFile).Length
        if ($logSize -gt $script:Config.MaxLogSize) {
            $logFiles = Get-ChildItem $script:Config.LogPath -Filter "everything-search*.log"
            if ($logFiles.Count -ge $script:Config.MaxLogFiles) {
                $logFiles | Sort-Object LastWriteTime | Select-Object -First 1 | Remove-Item -Force
            }
            $newName = "everything-search-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
            Move-Item $script:LogFile (Join-Path $script:Config.LogPath $newName) -Force
        }
    }
    
    Write-Host "Logging initialized at: $script:LogFile" -ForegroundColor Gray
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $logEntry = @{
        Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Level        = $Level
        Message      = $Message
        User         = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
        ProcessId    = $PID
    }
    
    $jsonEntry = $logEntry | ConvertTo-Json
    Add-Content -Path $script:LogFile -Value $jsonEntry
    
    # Also write to console with color
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Debug' { 'Gray' }
    }
    Write-Host "[$($logEntry.Timestamp)] $Level : $Message" -ForegroundColor $color
}

function Test-EverythingService {
    try {
        $service = Get-Service "Everything" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Log "Everything service status: $($service.Status)" -Level Debug
            return $service.Status -eq 'Running'
        }
        
        # If service not found, try CLI check
        $result = & es.exe -get-everything-version 2>$null
        return $LASTEXITCODE -eq 0
    } 
    catch {
        Write-Log "Error checking Everything service: $_" -Level Error
        return $false
    }
}

function Format-EverythingError {
    param(
        [string[]]$ErrorOutput
    )
    
    # Clean and normalize error output
    $cleanError = $ErrorOutput | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    
    # Extract error code if present
    $errorCode = if ($cleanError -match 'Error (\d+):') { 
        $matches[1] 
    }
    else { 
        "0" 
    }
    
    # Known error codes and their friendly messages
    $errorMap = @{
        "0" = @{
            Message = "Unknown error occurred"
            Fix     = "Check if Everything service is running and try again"
        }
        "1" = @{
            Message = "Everything service is not running"
            Fix     = "Start the Everything service and try again"
        }
        "2" = @{
            Message = "Invalid command line syntax"
            Fix     = "Check command parameters and try again"
        }
        "3" = @{
            Message = "Invalid search path"
            Fix     = "Verify the search path exists and is accessible"
        }
        "4" = @{
            Message = "Memory error"
            Fix     = "Close some applications and try again"
        }
        "5" = @{
            Message = "Invalid request format"
            Fix     = "Check search syntax and try again"
        }
        "6" = @{
            Message = "Invalid response format"
            Fix     = "Verify Everything installation is correct"
        }
        "7" = @{
            Message = "Index not ready"
            Fix     = "Wait for Everything to finish indexing and try again"
        }
        "8" = @{
            Message = "IPC failed"
            Fix     = "Restart the Everything service"
        }
    }

    # Get error details
    $errorDetails = $errorMap[$errorCode]
    if (-not $errorDetails) {
        $errorDetails = $errorMap["0"]  # Default to unknown error
    }

    # Format the error message
    $formattedError = @{
        Code    = $errorCode
        Message = $errorDetails.Message
        Fix     = $errorDetails.Fix
        Details = $cleanError -join " "
    }

    return $formattedError
}

function Test-EverythingFunctionality {
    Write-VerboseOperation "Running Everything functionality tests..."
    
    # Test 1: Basic file search
    Write-VerboseOperation "Test 1: Basic file search" -Status "Info"
    try {
        $searchCmd = "es.exe notepad.exe -path `"%windir%`" -n 1"
        Write-VerboseOperation "Executing search" -Command $searchCmd
        
        $results = & es.exe notepad.exe -path "%windir%" -n 1 2>&1
        if ($LASTEXITCODE -eq 0 -and $results) {
            Write-VerboseOperation "Found notepad.exe" -Status "Success" -Result $results
        }
        else {
            $errorInfo = Format-EverythingError $results
            Write-VerboseOperation "Search failed: $($errorInfo.Message)" -Status "Error"
            Write-VerboseOperation "Suggested fix: $($errorInfo.Fix)" -Status "Info"
            return $false
        }
    }
    catch {
        Write-VerboseOperation "Search error: $_" -Status "Error"
        return $false
    }
    
    # Test 2: Content search
    Write-VerboseOperation "Test 2: Content search" -Status "Info"
    try {
        $searchCmd = "es.exe -content `"Windows`" -path `"%windir%`" -n 1"
        Write-VerboseOperation "Executing search" -Command $searchCmd
        
        $results = & es.exe -content "Windows" -path "%windir%" -n 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-VerboseOperation "Content search successful" -Status "Success" -Result $results
        }
        else {
            $errorInfo = Format-EverythingError $results
            Write-VerboseOperation "Content search failed: $($errorInfo.Message)" -Status "Error"
            Write-VerboseOperation "Suggested fix: $($errorInfo.Fix)" -Status "Info"
            return $false
        }
    }
    catch {
        Write-VerboseOperation "Content search error: $_" -Status "Error"
        return $false
    }
    
    return $true
}

function Test-PowerShellVersion {
    $minVersion = [version]"7.0"
    $currentVersion = $PSVersionTable.PSVersion
    
    Write-Log "Current PowerShell version: $currentVersion" -Level Debug
    return $currentVersion -ge $minVersion
}

function Install-PowerShell7 {
    Write-Log "Attempting to install PowerShell 7..." -Level Info
    
    try {
        # Check if winget is available
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw "Winget not found. Please install PowerShell 7 manually."
        }

        # Install PowerShell using winget
        $process = Start-Process winget -ArgumentList "install --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "PowerShell 7 installed successfully" -Level Info
            Write-Host "`nTo run this script with PowerShell 7, use:" -ForegroundColor Yellow
            Write-Host "pwsh -File `"$($MyInvocation.MyCommand.Path)`"" -ForegroundColor Cyan
            return $true
        }
        
        throw "Installation failed with exit code: $($process.ExitCode)"
    }
    catch {
        Write-Log "Failed to install PowerShell 7: $_" -Level Error
        Write-Host "Please install PowerShell 7 manually from:" -ForegroundColor Yellow
        Write-Host "https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Cyan
        return $false
    }
}

function Initialize-Requirements {
    Write-Log "Checking requirements..." -Level Info
    
    # Check PowerShell version
    if (-not (Test-PowerShellVersion)) {
        Write-Log "PowerShell 7+ required (Current version: $($PSVersionTable.PSVersion))" -Level Warning
        
        $response = Read-Host "Would you like to install PowerShell 7 now? (Y/N)"
        if ($response -eq 'Y') {
            if (Install-PowerShell7) {
                exit 0  # Exit cleanly after successful installation
            }
            else {
                Write-Log "Failed to install PowerShell 7" -Level Error
                return $false
            }
        }
        else {
            Write-Log "PowerShell 7 installation skipped by user" -Level Warning
            return $false
        }
    }
    
    # Check Everything paths
    if (-not (Initialize-EverythingPaths)) {
        Write-Log "Everything not found in standard paths" -Level Error
        return $false
    }
    
    # Add Everything to PATH if needed
    if ($script:EverythingPath -and ($env:Path -split ';' -notcontains $script:EverythingPath)) {
        $env:Path = "$script:EverythingPath;$env:Path"
    }
    
    return $true
}

function Show-PreflightChecks {
    Write-Host "`nRunning Pre-flight Checks..." -ForegroundColor Cyan
    Write-Host "═" * 50
    
    $checks = @(
        @{
            Name = "PowerShell 7+"
            Test = {
                $version = $PSVersionTable.PSVersion
                $required = [version]"7.0"
                @{
                    Success = $version -ge $required
                    Details = "Found version: $version"
                    Fix     = "Install from: https://github.com/PowerShell/PowerShell/releases"
                    AutoFix = { Install-PowerShell7 }
                }
            }
        },
        @{
            Name = "Everything Search Service"
            Test = {
                $service = Get-Service "Everything" -ErrorAction SilentlyContinue
                $esPath = Get-Command es.exe -ErrorAction SilentlyContinue
                $everythingRunning = Get-Process "Everything" -ErrorAction SilentlyContinue
                
                $details = @()
                if ($service) { $details += "Service: $($service.Status)" }
                if ($esPath) { $details += "CLI: $($esPath.Source)" }
                if ($everythingRunning) { $details += "Process: Running" }
                
                @{
                    Success = $service -and $service.Status -eq 'Running' -and $esPath -and $everythingRunning
                    Details = if ($details) { $details -join ", " } else { "Not installed" }
                    Fix     = if (-not $service) {
                        "Install Everything from: https://www.voidtools.com"
                    }
                    elseif ($service.Status -ne 'Running') {
                        "Start Everything service: Start-Service Everything"
                    }
                    elseif (-not $everythingRunning) {
                        "Launch Everything.exe from Start Menu"
                    }
                    else {
                        "Verify installation at: https://www.voidtools.com"
                    }
                    AutoFix = { 
                        if ($service -and $service.Status -ne 'Running') {
                            Start-Service Everything
                            Start-Process "Everything.exe"
                            Start-Sleep -Seconds 2  # Wait for startup
                            return $true
                        }
                        return $false
                    }
                }
            }
        },
        @{
            Name = ".NET SDK 8.0/9.0"
            Test = {
                try {
                    $output = dotnet --list-sdks 2>&1
                    $sdks = $output | Where-Object { $_ -match '(8\.|9\.)' }
                    @{
                        Success = $null -ne $sdks
                        Details = if ($sdks) { "Found SDK(s):`n    " + ($sdks -join "`n    ") } else { "No compatible SDK found" }
                        Fix     = "Run: winget install Microsoft.DotNet.SDK.9"
                        AutoFix = {
                            Write-Host "`nInstalling .NET SDK 9.0..." -ForegroundColor Cyan
                            $process = Start-Process "winget" -ArgumentList "install Microsoft.DotNet.SDK.9 --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow -PassThru
                            
                            # Refresh environment
                            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                            
                            return $process.ExitCode -eq 0
                        }
                    }
                }
                catch {
                    @{
                        Success = $false
                        Details = "dotnet command not found"
                        Fix     = "Run: winget install Microsoft.DotNet.SDK.9"
                        AutoFix = $null
                    }
                }
            }
        }
    )
    
    $allPassed = $true
    $needsRerun = $false
    
    foreach ($check in $checks) {
        Write-Host "`nChecking $($check.Name)..." -NoNewline
        
        $result = & $check.Test
        if ($result.Success) {
            Write-Host " [PASS]" -ForegroundColor Green
            Write-Host "  └─ $($result.Details)" -ForegroundColor Gray
        }
        else {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  ├─ $($result.Details)" -ForegroundColor Yellow
            Write-Host "  └─ $($result.Fix)" -ForegroundColor Cyan
            
            if ($result.AutoFix) {
                $response = Read-Host "  Would you like to fix this automatically? (Y/N)"
                if ($response -eq 'Y') {
                    Write-Host "  Attempting to fix..." -ForegroundColor Cyan
                    if (& $result.AutoFix) {
                        Write-Host "  ✓ Fix applied successfully" -ForegroundColor Green
                        $needsRerun = $true
                    }
                    else {
                        Write-Host "  ✕ Fix failed - please resolve manually" -ForegroundColor Red
                    }
                }
            }
            
            $allPassed = $false
        }
    }
    
    Write-Host "`n═" * 50
    if ($allPassed) {
        Write-Host "All pre-flight checks passed!" -ForegroundColor Green
    }
    else {
        if ($needsRerun) {
            Write-Host "Some components were installed. Please restart the script." -ForegroundColor Yellow
            exit 0
        }
        Write-Host "Some checks failed. Please fix the issues above." -ForegroundColor Yellow
    }
    
    Write-Host "`nPress any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
    
    return $allPassed
}

# Main execution
try {
    Clear-Host
    Write-Host "Initializing Everything Search UI..." -ForegroundColor Cyan
    
    # Initialize logging first
    Initialize-Logging
    Write-Log "Starting Everything Search UI" -Level Info
    
    # Show system info
    Show-SystemInfo
    
    # Run pre-flight checks
    $checksPass = Show-PreflightChecks
    if (-not $checksPass) {
        Write-VerboseOperation "Please fix the failed checks and restart the script" -Status "Warning"
        exit 1
    }
    
    # Initialize Terminal.GUI
    $guiInitialized = Initialize-TerminalGUI
    if ($guiInitialized) {
        # Show TUI main menu
        Show-MainMenu
    }
    else {
        # Fallback to console interface
        Write-VerboseOperation "Running in console mode" -Status "Info"
        Write-VerboseOperation "Type 'help' for available commands" -Status "Info"
        
        # Simple console loop
        while ($true) {
            $input = Read-Host "`nEnter search query (or 'help', 'exit')"
            switch ($input.ToLower()) {
                "exit" { 
                    Write-VerboseOperation "Exiting..." -Status "Info"
                    return 
                }
                "help" {
                    Write-Host @"
Available Commands:
-----------------
help        Show this help
exit        Exit the application
<query>     Search for files (examples below)

Search Examples:
- notepad.exe           Find notepad.exe
- *.txt                 Find all .txt files
- -r "test.*\.txt"     Regex search for test*.txt
- -path "C:\" *.doc    Search for .doc files in C:\
"@
                }
                default {
                    if ($input) {
                        try {
                            $results = & es.exe $input 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                $results | ForEach-Object { Write-Host $_ }
                            }
                            else {
                                $errorInfo = Format-EverythingError $results
                                Write-VerboseOperation $errorInfo.Message -Status "Error"
                                Write-VerboseOperation $errorInfo.Fix -Status "Info"
                            }
                        }
                        catch {
                            Write-VerboseOperation "Search error: $_" -Status "Error"
                        }
                    }
                }
            }
        }
    }
} 
catch {
    $errorMsg = $_.Exception.Message
    Write-Host "[✕] Fatal error occurred" -ForegroundColor Red
    Write-Host "    $errorMsg" -ForegroundColor Red
    
    # Try to log if possible
    if ($script:LogFile -and (Test-Path $script:LogFile)) {
        Write-Log "Fatal error: $errorMsg" -Level Error
    }
    exit 1
} 