# 🚀 Asmbli Production Build Script (PowerShell)
# 
# Easy-to-use build script for Windows users who prefer PowerShell
# Handles the magical build process with friendly progress updates

param(
    [string]$Platforms = "windows",
    [switch]$Debug,
    [switch]$Verbose,
    [switch]$Help
)

function Write-MagicalHeader {
    Write-Host ""
    Write-Host "✨ " -ForegroundColor Cyan -NoNewline
    Write-Host "Asmbli Production Build Tool" -ForegroundColor White
    Write-Host "🚀 " -ForegroundColor Yellow -NoNewline  
    Write-Host "Building your magical AI workspace..." -ForegroundColor Gray
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "💡 " -ForegroundColor Blue -NoNewline
    Write-Host $Message -ForegroundColor Gray
}

function Show-Help {
    Write-Host @"
🚀 Asmbli Production Build Tool (PowerShell)

USAGE:
    .\build_production.ps1 [OPTIONS]

OPTIONS:
    -Platforms <list>    Comma-separated platforms (windows,macos,linux)
                        Default: windows
    
    -Debug              Build in debug mode instead of release
    
    -Verbose            Show detailed build output
    
    -Help               Show this help message

EXAMPLES:
    .\build_production.ps1
        Build for Windows in release mode
    
    .\build_production.ps1 -Platforms "windows,linux" -Verbose  
        Build for Windows and Linux with verbose output
    
    .\build_production.ps1 -Debug
        Build for Windows in debug mode

The build output will be available in the deploy/ directory.

For more advanced options, use the Dart version:
    dart build_production.dart --help
"@
    exit 0
}

function Test-Prerequisites {
    Write-Info "Checking build prerequisites..."
    
    # Check Flutter
    try {
        $flutterVersion = flutter --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter not found"
        }
        Write-Success "Flutter is installed"
    } catch {
        Write-Error "Flutter not found. Please install Flutter and add it to your PATH."
        Write-Info "Download from: https://flutter.dev/docs/get-started/install/windows"
        exit 1
    }
    
    # Check Dart
    try {
        $dartVersion = dart --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Dart not found"  
        }
        Write-Success "Dart SDK is installed"
    } catch {
        Write-Error "Dart SDK not found. This is usually installed with Flutter."
        exit 1
    }
    
    # Check if we're in the right directory
    if (!(Test-Path "pubspec.yaml")) {
        Write-Error "pubspec.yaml not found. Please run this script from the app root directory."
        exit 1
    }
    
    Write-Success "All prerequisites met"
}

function Invoke-ProductionBuild {
    param(
        [string[]]$PlatformList,
        [bool]$IsDebug,
        [bool]$IsVerbose
    )
    
    # Prepare arguments for Dart script
    $dartArgs = @()
    
    if ($PlatformList.Count -gt 0) {
        $dartArgs += "--platforms"
        $dartArgs += ($PlatformList -join ",")
    }
    
    if ($IsDebug) {
        $dartArgs += "--debug"
    }
    
    if ($IsVerbose) {
        $dartArgs += "--verbose"
    }
    
    Write-Info "Running Dart build script..."
    Write-Host "   Command: dart build_production.dart $($dartArgs -join ' ')" -ForegroundColor Gray
    Write-Host ""
    
    # Execute the Dart build script
    try {
        & dart build_production.dart @dartArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Success "🎉 Build completed successfully!"
            Write-Host ""
            Write-Info "Your Asmbli app is ready for deployment:"
            
            # Show deployment locations
            foreach ($platform in $PlatformList) {
                if (Test-Path "deploy\$platform") {
                    Write-Host "   📦 $platform`: " -ForegroundColor Gray -NoNewline
                    Write-Host "deploy\$platform\" -ForegroundColor Cyan
                }
            }
            
            Write-Host ""
            Write-Info "Next steps:"
            Write-Host "   1. Test the built application" -ForegroundColor Gray
            Write-Host "   2. Check the README files in each deploy folder" -ForegroundColor Gray
            Write-Host "   3. Distribute to your users!" -ForegroundColor Gray
            
        } else {
            Write-Error "Build failed. Check the output above for details."
            exit 1
        }
        
    } catch {
        Write-Error "Failed to execute build script: $_"
        exit 1
    }
}

# Main execution
try {
    if ($Help) {
        Show-Help
    }
    
    Write-MagicalHeader
    
    # Parse platforms
    $platformList = $Platforms -split "," | ForEach-Object { $_.Trim() }
    
    # Validate platforms
    $validPlatforms = @("windows", "macos", "linux")
    foreach ($platform in $platformList) {
        if ($platform -notin $validPlatforms) {
            Write-Warning "Unknown platform: $platform (valid: $($validPlatforms -join ', '))"
        }
    }
    
    Write-Info "Building for platforms: $($platformList -join ', ')"
    Write-Info "Mode: $(if ($Debug) { 'Debug' } else { 'Release' })"
    if ($Verbose) {
        Write-Info "Verbose output enabled"
    }
    Write-Host ""
    
    # Run the build process
    Test-Prerequisites
    Invoke-ProductionBuild -PlatformList $platformList -IsDebug $Debug -IsVerbose $Verbose
    
} catch {
    Write-Error "Build process failed: $_"
    Write-Info "Try running with -Verbose for more details"
    exit 1
}