@echo off
echo =============================================
echo    Asmbli Distribution Build Script
echo =============================================
echo.

cd /d "C:\Asmbli\apps\desktop"

echo [1/5] Cleaning previous builds...
call flutter clean
call flutter pub get

echo [2/5] Building Windows release...
call flutter build windows --release

echo [3/5] Creating distribution package...
set VERSION=1.0.0
set DIST_DIR=C:\Asmbli\dist\windows\Asmbli-%VERSION%-windows
set RELEASE_DIR=C:\Asmbli\apps\desktop\build\windows\x64\runner\Release

rmdir /s /q "%DIST_DIR%" 2>nul
mkdir "%DIST_DIR%"
xcopy "%RELEASE_DIR%\*" "%DIST_DIR%\" /E /I /H /Y

echo [4/5] Adding distribution files...
echo Asmbli - AI Agents Made Easy > "%DIST_DIR%\README.txt"
echo Version %VERSION% for Windows >> "%DIST_DIR%\README.txt"
echo. >> "%DIST_DIR%\README.txt"
echo Double-click agentengine_desktop.exe to launch. >> "%DIST_DIR%\README.txt"
echo Visit https://asmbli.ai for documentation and support. >> "%DIST_DIR%\README.txt"

echo [5/5] Creating distribution archives...
cd /d "C:\Asmbli\dist\windows"
powershell "Compress-Archive -Path 'Asmbli-%VERSION%-windows' -DestinationPath 'Asmbli-%VERSION%-windows-x64.zip' -Force"

echo.
echo =============================================
echo    Build Complete!
echo =============================================
echo Distribution created at: C:\Asmbli\dist\windows\
echo - Asmbli-%VERSION%-windows-x64.zip
echo.
echo To update website downloads:
echo 1. Copy ZIP file to apps\web\public\downloads\
echo 2. Update version in download components
echo 3. Deploy website
echo.
pause