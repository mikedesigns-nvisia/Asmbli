# AgentEngine Windows Installer

This directory contains the Inno Setup installer configuration for AgentEngine.

## Building the Installer

### Prerequisites

1. **Install Inno Setup Compiler**
   - Download from: https://jrsoftware.org/isdl.php
   - Install the latest version (6.x or higher recommended)

2. **Build Flutter App**
   ```bash
   cd apps/desktop
   flutter build windows --release
   ```

### Creating the Installer

#### Option 1: Using Inno Setup GUI
1. Open Inno Setup Compiler
2. Open the file: `installer/windows/installer.iss`
3. Click "Build" → "Compile"
4. The installer will be created in: `build/windows/installer/AgentEngine-Windows-v1.0.1-Setup.exe`

#### Option 2: Using Command Line
```bash
# From apps/desktop directory
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\windows\installer.iss
```

### Output

The installer executable will be created at:
```
apps/desktop/build/windows/installer/AgentEngine-Windows-v1.0.1-Setup.exe
```

## Installer Features

- ✅ One-click installation
- ✅ Automatic dependency bundling (all DLLs included)
- ✅ Start menu shortcuts
- ✅ Optional desktop icon
- ✅ Clean uninstallation
- ✅ No admin privileges required (installs to user directory)
- ✅ Windows 10/11 compatible (x64)

## Distribution

After building the installer, you can:

1. Upload to GitHub Releases
2. Add to the website downloads section
3. Distribute directly to users

The installer is self-contained and includes all necessary runtime dependencies.
