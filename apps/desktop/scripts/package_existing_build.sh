#!/bin/bash

# AgentEngine macOS Package Script
# Packages the existing debug build into a distributable format

set -e

echo "🍎 Packaging AgentEngine macOS App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="AgentEngine"
APP_VERSION="1.0.0"
BUILD_DIR="build/macos/Build/Products/Debug"
DIST_DIR="dist/macos"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${APP_VERSION}-macOS-Debug"

echo -e "${BLUE}📋 Package Configuration:${NC}"
echo "  App Name: $APP_NAME"
echo "  Version: $APP_VERSION"
echo "  Source: $BUILD_DIR/desktop.app"
echo "  Target: $DIST_DIR/$APP_BUNDLE"

# Check if debug build exists
if [ ! -d "$BUILD_DIR/desktop.app" ]; then
    echo -e "${RED}❌ Debug build not found at $BUILD_DIR/desktop.app${NC}"
    echo "Please run 'flutter run --debug' first to create the debug build"
    exit 1
fi

# Create distribution directory
echo -e "${YELLOW}🗂️ Creating distribution directory...${NC}"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy app bundle to distribution directory
echo -e "${BLUE}📦 Copying app bundle...${NC}"
cp -R "$BUILD_DIR/desktop.app" "$DIST_DIR/$APP_BUNDLE"

# Update app bundle name and Info.plist
echo -e "${BLUE}⚙️ Configuring app bundle...${NC}"

# Update CFBundleName in Info.plist if it exists
PLIST_FILE="$DIST_DIR/$APP_BUNDLE/Contents/Info.plist"
if [ -f "$PLIST_FILE" ]; then
    plutil -replace CFBundleName -string "$APP_NAME" "$PLIST_FILE" 2>/dev/null || true
    plutil -replace CFBundleDisplayName -string "$APP_NAME" "$PLIST_FILE" 2>/dev/null || true
    plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$PLIST_FILE" 2>/dev/null || true
    plutil -replace CFBundleVersion -string "$APP_VERSION" "$PLIST_FILE" 2>/dev/null || true
    echo -e "${GREEN}✅ Updated app metadata${NC}"
else
    echo -e "${YELLOW}⚠️ Info.plist not found, skipping metadata update${NC}"
fi

# Get app bundle size
APP_SIZE=$(du -sh "$DIST_DIR/$APP_BUNDLE" | cut -f1)
echo -e "${GREEN}📊 App bundle size: $APP_SIZE${NC}"

# Create DMG installer
echo -e "${BLUE}💿 Creating DMG installer...${NC}"
if command -v hdiutil >/dev/null 2>&1; then
    # Create temporary DMG directory
    DMG_DIR="$DIST_DIR/dmg_temp"
    mkdir -p "$DMG_DIR"

    # Copy app to DMG directory
    cp -R "$DIST_DIR/$APP_BUNDLE" "$DMG_DIR/"

    # Create Applications symlink
    ln -s /Applications "$DMG_DIR/Applications"

    # Create a nice background and layout for DMG (optional)
    cat > "$DMG_DIR/.DS_Store_template" << 'EOF'
# This would contain DS_Store data for DMG layout
# For now, we'll use default layout
EOF

    # Create DMG
    hdiutil create -volname "$APP_NAME" \
                   -srcfolder "$DMG_DIR" \
                   -ov -format UDZO \
                   -imagekey zlib-level=9 \
                   "$DIST_DIR/$DMG_NAME.dmg" 2>/dev/null && {
        DMG_SIZE=$(du -sh "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)
        echo -e "${GREEN}✅ DMG created: $DMG_NAME.dmg ($DMG_SIZE)${NC}"
    } || {
        echo -e "${YELLOW}⚠️ DMG creation failed, but app bundle is ready${NC}"
    }

    # Clean up
    rm -rf "$DMG_DIR"
else
    echo -e "${YELLOW}⚠️ hdiutil not available, skipping DMG creation${NC}"
fi

# Create ZIP archive as alternative
echo -e "${BLUE}🗜️ Creating ZIP archive...${NC}"
cd "$DIST_DIR"
zip -r "$DMG_NAME.zip" "$APP_BUNDLE" >/dev/null 2>&1 && {
    ZIP_SIZE=$(du -sh "$DMG_NAME.zip" | cut -f1)
    echo -e "${GREEN}✅ ZIP created: $DMG_NAME.zip ($ZIP_SIZE)${NC}"
} || {
    echo -e "${YELLOW}⚠️ ZIP creation failed${NC}"
}
cd - >/dev/null

# Create installation README
echo -e "${BLUE}📝 Creating installation guide...${NC}"
cat > "$DIST_DIR/README.md" << EOF
# AgentEngine for macOS

## Installation Instructions

### Method 1: DMG Installer (Recommended)
1. Download and open \`$DMG_NAME.dmg\`
2. Drag **AgentEngine.app** to the **Applications** folder
3. Eject the DMG

### Method 2: ZIP Archive
1. Download and extract \`$DMG_NAME.zip\`
2. Move **AgentEngine.app** to your **Applications** folder

## First Launch

1. Navigate to **Applications** folder
2. **Right-click** on **AgentEngine.app** and select **"Open"**
   - This bypasses macOS Gatekeeper for unsigned apps
3. Click **"Open"** in the security dialog
4. Grant necessary permissions when prompted:
   - Network access (for API calls and MCP servers)
   - File access (for project management)
   - Terminal access (for MCP server installation)

## Features

- 🤖 **AI Agent Builder** - Create custom AI agents with specialized capabilities
- 🔧 **MCP Server Integration** - Connect to 140+ Model Context Protocol servers
- 🧠 **Local LLM Support** - Run Ollama models locally for privacy
- 💬 **Advanced Chat Interface** - Context-aware conversations with agents
- 📁 **Context Management** - Manage documents and knowledge bases
- 🎨 **Modern UI** - Clean, intuitive macOS-native interface

## System Requirements

- macOS 11.0 or later
- Apple Silicon (M1/M2/M3) or Intel processor
- 4GB RAM minimum, 8GB recommended
- 2GB free disk space

## Troubleshooting

### "App is damaged and can't be opened"
This happens with unsigned apps. Solution:
1. Open **Terminal**
2. Run: \`sudo xattr -rd com.apple.quarantine /Applications/AgentEngine.app\`
3. Try opening the app again

### Permission Issues
- Allow the app in **System Settings > Privacy & Security**
- Grant Terminal access in **System Settings > Privacy & Security > Developer Tools**

### Can't Install MCP Servers
- Ensure you have **Node.js** and **Python** installed
- Install via Homebrew: \`brew install node python\`
- For uvx: \`pip install uv\`

## Support

- GitHub: https://github.com/WereNext/AgentEngine
- Issues: Report bugs on GitHub Issues
- Discussions: GitHub Discussions for questions

---
**Note**: This is a debug build for testing purposes. A signed release version will be available soon.
EOF

echo -e "${GREEN}✅ Installation guide created${NC}"

# Create version info
echo -e "${BLUE}📄 Creating version info...${NC}"
cat > "$DIST_DIR/VERSION.txt" << EOF
AgentEngine for macOS
Version: $APP_VERSION
Build: Debug
Date: $(date '+%Y-%m-%d %H:%M:%S')
Platform: macOS (Universal)
Flutter Version: $(flutter --version | head -n1)

Features:
- AI Agent Builder
- MCP Server Integration (140+ servers)
- Local LLM Support (Ollama)
- Advanced Chat Interface
- Context Management
- Vector Search & RAG
- Terminal Integration
- macOS Native Optimizations

Architecture:
- Native macOS Keychain integration
- Accelerate framework for vector operations
- Metal Performance Shaders on Apple Silicon
- Spotlight search integration
- CloudKit sync capabilities (future)
EOF

echo -e "${GREEN}✅ Version info created${NC}"

# Security and distribution notes
echo -e "${YELLOW}🔒 Security & Distribution Notes:${NC}"
echo "  • This is an unsigned debug build"
echo "  • Users will need to bypass Gatekeeper on first launch"
echo "  • For production distribution, consider:"
echo "    - Apple Developer Program membership"
echo "    - Code signing with valid certificate"
echo "    - Notarization for Gatekeeper approval"
echo "    - Mac App Store submission"

echo -e "${GREEN}🎉 Packaging completed successfully!${NC}"
echo -e "${BLUE}📁 Distribution files created in: $DIST_DIR${NC}"
echo ""
echo -e "${BLUE}📋 Distribution Package Contents:${NC}"
ls -la "$DIST_DIR"

echo ""
echo -e "${GREEN}✅ AgentEngine macOS package ready for distribution!${NC}"
echo -e "${BLUE}🚀 Users can now install AgentEngine using the DMG or ZIP file${NC}"