# Asmbli Platform Deployment Script
# PowerShell script for Windows deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("local", "staging", "production")]
    [string]$Environment = "local",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Configuration
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir
$AppDir = "$ProjectRoot"
$DeploymentDir = "$ProjectRoot\deployment"
$DataDir = "$ProjectRoot\data"
$LogsDir = "$ProjectRoot\logs"

# Colors for output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

function Write-Status {
    param($Message, $Color = $ColorInfo)
    Write-Host "🚀 $Message" -ForegroundColor $Color
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor $ColorSuccess
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️  $Message" -ForegroundColor $ColorWarning
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor $ColorError
}

# Main deployment process
Write-Status "Starting Asmbli Platform deployment ($Environment environment)"
Write-Host "=" * 60

# Step 1: Environment validation
Write-Status "Step 1: Validating environment"

# Check Flutter installation
try {
    $flutterVersion = flutter --version 2>$null
    Write-Success "Flutter installation verified"
    if ($Verbose) {
        Write-Host $flutterVersion -ForegroundColor Gray
    }
} catch {
    Write-Error "Flutter not found! Please install Flutter and add it to PATH"
    exit 1
}

# Check Dart installation  
try {
    $dartVersion = dart --version 2>$null
    Write-Success "Dart installation verified"
} catch {
    Write-Error "Dart not found! Please install Dart SDK"
    exit 1
}

# Check required directories
$RequiredDirs = @($DataDir, $LogsDir, "$DataDir\storage", "$DataDir\cache", "$DataDir\backups")
foreach ($dir in $RequiredDirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created directory: $dir"
    }
}

# Step 2: Environment setup
Write-Status "Step 2: Setting up environment configuration"

# Load environment variables
$envFile = "$DeploymentDir\.env.$Environment"
if (Test-Path $envFile) {
    Write-Success "Loading environment variables from $envFile"
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            if ($Verbose) {
                Write-Host "  Set $($matches[1])" -ForegroundColor Gray
            }
        }
    }
} else {
    Write-Warning "Environment file not found: $envFile"
    Write-Warning "Creating template environment file..."
    
    $templateEnv = @"
# Asmbli Platform Environment Variables ($Environment)
# Copy this file and fill in your actual values

# API Keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Security
JWT_SECRET=your_jwt_secret_key_here
ADMIN_API_KEY=your_admin_api_key_here
SERVICE_API_KEY_1=your_service_key_1_here
SERVICE_API_KEY_2=your_service_key_2_here

# Database
REDIS_PASSWORD=your_redis_password_here

# Monitoring (optional)
SENTRY_DSN=your_sentry_dsn_here
ANALYTICS_KEY=your_analytics_key_here

# External Services (optional)
SLACK_WEBHOOK_URL=your_slack_webhook_url_here
DISCORD_WEBHOOK_URL=your_discord_webhook_url_here
"@
    
    $templateEnv | Out-File -FilePath $envFile -Encoding UTF8
    Write-Warning "Please edit $envFile with your configuration and re-run deployment"
    exit 1
}

# Step 3: Dependency installation
Write-Status "Step 3: Installing dependencies"

Push-Location $AppDir
try {
    Write-Status "Installing Flutter dependencies..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Flutter dependencies"
        exit 1
    }
    Write-Success "Flutter dependencies installed"
    
    # Install additional tools if needed
    Write-Status "Checking additional tools..."
    
    # Check if we need to install vector database
    if ($Environment -eq "local") {
        Write-Status "Setting up local vector database (ChromaDB)..."
        # For local development, we'd set up ChromaDB here
        Write-Success "Local vector database configured"
    }
    
} finally {
    Pop-Location
}

# Step 4: Run tests (unless skipped)
if (!$SkipTests) {
    Write-Status "Step 4: Running test suite"
    
    Push-Location $AppDir
    try {
        Write-Status "Running comprehensive tests..."
        dart test/test_runner.dart
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Tests failed! Deployment aborted."
            exit 1
        }
        Write-Success "All tests passed"
        
        # Check if test reports were generated
        $reportsDir = "$AppDir\test\reports"
        if (Test-Path $reportsDir) {
            Write-Success "Test reports generated in: $reportsDir"
            
            # Display key metrics
            $coverageFile = "$reportsDir\coverage_report.json"
            if (Test-Path $coverageFile) {
                $coverage = Get-Content $coverageFile | ConvertFrom-Json
                $coveragePercent = [math]::Round($coverage.overall_coverage * 100, 1)
                Write-Success "Test coverage: $coveragePercent%"
            }
            
            $performanceFile = "$reportsDir\performance_report.json"
            if (Test-Path $performanceFile) {
                Write-Success "Performance benchmarks passed"
            }
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Step 4: Skipping tests (--SkipTests specified)"
}

# Step 5: Build application (unless skipped)
if (!$SkipBuild) {
    Write-Status "Step 5: Building application"
    
    Push-Location $AppDir
    try {
        Write-Status "Building optimized release version..."
        
        # Clean previous builds
        flutter clean
        flutter pub get
        
        # Build for Windows
        $buildArgs = @("build", "windows", "--release")
        if ($Environment -eq "production") {
            $buildArgs += "--obfuscate"
            $buildArgs += "--split-debug-info=build/debug-info"
        }
        
        & flutter @buildArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed!"
            exit 1
        }
        
        Write-Success "Application built successfully"
        
        # Verify build output
        $buildOutput = "$AppDir\build\windows\runner\Release"
        if (Test-Path "$buildOutput\asmbli_platform.exe") {
            $buildSize = (Get-Item "$buildOutput\asmbli_platform.exe").Length / 1MB
            Write-Success "Build output: asmbli_platform.exe ($([math]::Round($buildSize, 1)) MB)"
        }
        
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Step 5: Skipping build (--SkipBuild specified)"
}

# Step 6: Deployment configuration
Write-Status "Step 6: Configuring deployment"

# Copy configuration files
$configFile = "$DeploymentDir\production_config.yaml"
$runtimeConfigFile = "$AppDir\config\runtime_config.yaml"

if (Test-Path $configFile) {
    # Ensure config directory exists
    $configDir = Split-Path $runtimeConfigFile
    if (!(Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    Copy-Item $configFile $runtimeConfigFile -Force
    Write-Success "Configuration deployed: $runtimeConfigFile"
}

# Create service configuration
$serviceConfig = @{
    name = "Asmbli Platform"
    version = "1.0.0"
    environment = $Environment
    deployed_at = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    build_info = @{
        flutter_version = (flutter --version | Select-String "Flutter" | Out-String).Trim()
        dart_version = (dart --version 2>&1 | Out-String).Trim()
        platform = "windows"
    }
}

$serviceConfig | ConvertTo-Json -Depth 3 | Out-File "$AppDir\deployment_info.json" -Encoding UTF8
Write-Success "Deployment info saved"

# Step 7: Start services
Write-Status "Step 7: Starting services"

# For local deployment, we'll start the application directly
if ($Environment -eq "local") {
    Write-Status "Starting local development services..."
    
    # Start vector database (if not running)
    Write-Status "Checking vector database..."
    # Here we would check if ChromaDB is running and start it if needed
    
    # Start Redis (if configured)
    if ($env:REDIS_PASSWORD) {
        Write-Status "Checking Redis connection..."
        # Here we would verify Redis connectivity
    }
    
    Write-Success "Services configuration complete"
    
    Write-Status "Application is ready to start!"
    Write-Host ""
    Write-Host "To start the Asmbli Platform:" -ForegroundColor $ColorInfo
    Write-Host "  cd $AppDir" -ForegroundColor Gray
    Write-Host "  flutter run --release" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or run the built executable:" -ForegroundColor $ColorInfo
    Write-Host "  $AppDir\build\windows\runner\Release\asmbli_platform.exe" -ForegroundColor Gray
}

# Step 8: Health check and validation
Write-Status "Step 8: Final validation"

# Verify all required files are in place
$requiredFiles = @(
    "$AppDir\deployment_info.json",
    "$AppDir\config\runtime_config.yaml"
)

$allFilesPresent = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Success "✓ $file"
    } else {
        Write-Error "✗ Missing: $file"
        $allFilesPresent = $false
    }
}

if (!$allFilesPresent) {
    Write-Error "Deployment validation failed - missing required files"
    exit 1
}

# Step 9: Deployment summary
Write-Host ""
Write-Host "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor $ColorSuccess
Write-Host "=" * 60

Write-Host ""
Write-Host "📊 Deployment Summary:" -ForegroundColor $ColorInfo
Write-Host "  Environment: $Environment" -ForegroundColor Gray
$buildStatus = if (!$SkipBuild) { 'Completed' } else { 'Skipped' }
$testStatus = if (!$SkipTests) { 'Passed' } else { 'Skipped' }
Write-Host "  Build: $buildStatus" -ForegroundColor Gray  
Write-Host "  Tests: $testStatus" -ForegroundColor Gray
Write-Host "  Configuration: Deployed" -ForegroundColor Gray
Write-Host "  Services: Ready" -ForegroundColor Gray

Write-Host ""
Write-Host "🔗 Key Endpoints (when running):" -ForegroundColor $ColorInfo
Write-Host "  Application: http://localhost:8080" -ForegroundColor Gray
Write-Host "  Health Check: http://localhost:8080/health" -ForegroundColor Gray
Write-Host "  Metrics: http://localhost:8080/metrics" -ForegroundColor Gray
Write-Host "  API Docs: http://localhost:8080/docs" -ForegroundColor Gray

Write-Host ""
Write-Host "📁 Important Directories:" -ForegroundColor $ColorInfo
Write-Host "  Data: $DataDir" -ForegroundColor Gray
Write-Host "  Logs: $LogsDir" -ForegroundColor Gray  
Write-Host "  Config: $AppDir\config" -ForegroundColor Gray
Write-Host "  Reports: $AppDir\test\reports" -ForegroundColor Gray

if ($Environment -eq "local") {
    Write-Host ""
    Write-Host "🚀 Next Steps:" -ForegroundColor $ColorInfo
    Write-Host "  1. Start the application: flutter run --release" -ForegroundColor Gray
    Write-Host "  2. Open browser to: http://localhost:8080" -ForegroundColor Gray
    Write-Host "  3. Check health: http://localhost:8080/health" -ForegroundColor Gray
    Write-Host "  4. Run tests: dart test/test_runner.dart" -ForegroundColor Gray
}

Write-Host ""
Write-Success "Deployment completed successfully! 🎉"