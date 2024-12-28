using module Terminal.Gui

class ShareDashboard : Window {
    ShareDashboard() : base("Share Monitor") {
        $this.InitializeComponents()
    }
    
    [void]InitializeComponents() {
        # Create status bar
        $statusBar = [StatusBar]::new(@(
            [StatusItem]::new(Key: "~F1~ Help", Action: { $this.ShowHelp() }),
            [StatusItem]::new(Key: "~F2~ Menu", Action: { $this.ShowMenu() }),
            [StatusItem]::new(Key: "~F10~ Quit", Action: { Application.RequestStop() })
        ))
        
        # Create main view
        $mainView = [FrameView]::new("Network Status") {
            X = 0
            Y = 0
            Width = Dim.Fill()
            Height = Dim.Fill()
        }
        
        # Add components
        $this.Add($statusBar, $mainView)
    }
} 