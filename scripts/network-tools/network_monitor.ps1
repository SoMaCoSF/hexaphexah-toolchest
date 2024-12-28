# Advanced Network and Share Monitor
using namespace System.Management.Automation.Host
using namespace System.Collections.Generic

class NetworkMonitor {
    [ConsoleColor]$HeaderColor = [ConsoleColor]::Cyan
    [ConsoleColor]$ErrorColor = [ConsoleColor]::Red
    [ConsoleColor]$SuccessColor = [ConsoleColor]::Green
    hidden [int]$CurrentSelection = 0
    hidden [array]$MenuItems
    hidden [bool]$Running = $true
    
    NetworkMonitor() {
        $this.MenuItems = @(
            "Show Active Network Connections",
            "Display Share Status",
            "Test Remote Connectivity",
            "Configure Firewall Rules",
            "Monitor Port Activity",
            "View Share Permissions",
            "Exit"
        )
        $this.InitializeConsole()
    }
    
    [void]InitializeConsole() {
        $host.UI.RawUI.WindowTitle = "Network Monitor v2.0"
        Clear-Host
    }
    
    [void]ShowHeader() {
        Write-Host "`n=== Network and Share Monitor ===`n" -ForegroundColor $this.HeaderColor
        $netInfo = Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}
        Write-Host "Local IP: $($netInfo.IPv4Address.IPAddress)"
        Write-Host "Gateway: $($netInfo.IPv4DefaultGateway.NextHop)`n"
    }
    
    [void]ShowMenu() {
        for ($i = 0; $i -lt $this.MenuItems.Count; $i++) {
            if ($i -eq $this.CurrentSelection) {
                Write-Host "→ " -NoNewline -ForegroundColor $this.SuccessColor
                Write-Host $this.MenuItems[$i] -ForegroundColor $this.SuccessColor
            } else {
                Write-Host "  $($this.MenuItems[$i])"
            }
        }
    }
    
    [void]HandleInput() {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                if ($this.CurrentSelection -gt 0) { $this.CurrentSelection-- }
            }
            40 { # Down arrow
                if ($this.CurrentSelection -lt ($this.MenuItems.Count - 1)) { $this.CurrentSelection++ }
            }
            13 { # Enter
                $this.ExecuteSelection()
            }
            27 { # Escape
                $this.Running = $false
            }
        }
    }
    
    [void]ExecuteSelection() {
        Clear-Host
        switch ($this.CurrentSelection) {
            0 { $this.ShowActiveConnections() }
            1 { $this.DisplayShareStatus() }
            2 { $this.TestRemoteConnectivity() }
            3 { $this.ConfigureFirewall() }
            4 { $this.MonitorPorts() }
            5 { $this.ViewSharePermissions() }
            6 { $this.Running = $false }
        }
        if ($this.Running) {
            Write-Host "`nPress any key to continue..."
            $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
    
    [void]ShowActiveConnections() {
        Write-Host "Active Network Connections" -ForegroundColor $this.HeaderColor
        Write-Host "------------------------`n"
        
        $connections = Get-NetTCPConnection | 
            Where-Object State -eq "Established" |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State,
                @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).Name}}
        
        $connections | Format-Table -AutoSize
    }
    
    [void]DisplayShareStatus() {
        Write-Host "Share Status" -ForegroundColor $this.HeaderColor
        Write-Host "------------`n"
        
        $shares = Get-SmbShare | Select-Object Name, Path, Description
        $shares | Format-Table -AutoSize
        
        Write-Host "`nShare Sessions:" -ForegroundColor $this.HeaderColor
        Get-SmbSession | Format-Table -AutoSize
    }
    
    [void]TestRemoteConnectivity() {
        Write-Host "Remote Connectivity Test" -ForegroundColor $this.HeaderColor
        Write-Host "----------------------`n"
        
        $remoteHosts = @(
            "192.168.1.180", # Omen-01
            "192.168.1.100"  # Other known host
        )
        
        foreach ($host in $remoteHosts) {
            Write-Host "Testing connection to $host..."
            $result = Test-NetConnection -ComputerName $host -Port 445
            if ($result.TcpTestSucceeded) {
                Write-Host "  → Success" -ForegroundColor $this.SuccessColor
            } else {
                Write-Host "  → Failed" -ForegroundColor $this.ErrorColor
            }
        }
    }
    
    # ... Additional methods for other menu items ...
    
    [void]Run() {
        while ($this.Running) {
            Clear-Host
            $this.ShowHeader()
            $this.ShowMenu()
            $this.HandleInput()
        }
    }
}

# Create and run the monitor
$monitor = [NetworkMonitor]::new()
$monitor.Run() 