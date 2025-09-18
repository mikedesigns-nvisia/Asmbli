#!/bin/bash

# Asmbli Beta - macOS Unsigned Build Script
# Creates a development build for testing without code signing

set -e

echo "🚀 Building Asmbli Beta for macOS (Unsigned)..."
echo "📋 System Requirements:"
echo "   • Minimum RAM: 8GB"
echo "   • Recommended RAM: 16GB+"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="desktop"  # This is the actual build name from pubspec.yaml
DISPLAY_NAME="Asmbli"
VERSION="0.9.0"
BUILD_NUMBER="1"

echo -e "${BLUE}📦 Building Asmbli Beta v${VERSION} (Development Build)...${NC}"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/macos/Build/Products/Debug/*.app 2>/dev/null || true
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build the macOS app in debug mode (doesn't require signing)
echo -e "${YELLOW}🔨 Building macOS application (debug mode)...${NC}"
flutter build macos --debug

# Check if build was successful
if [ ! -d "build/macos/Build/Products/Debug/$APP_NAME.app" ]; then
    echo -e "${RED}❌ Build failed. App bundle not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"

# Create a ZIP for distribution
echo -e "${BLUE}📦 Creating ZIP archive...${NC}"

ZIP_NAME="Asmbli-Beta-${VERSION}-macOS-unsigned.zip"
APP_PATH="build/macos/Build/Products/Debug/$APP_NAME.app"
ZIP_PATH="build/$ZIP_NAME"

# Remove old ZIP if exists
rm -f "$ZIP_PATH"

# Rename the app bundle for distribution
DIST_APP_NAME="$DISPLAY_NAME.app"
cd "build/macos/Build/Products/Debug"
cp -R "$APP_NAME.app" "$DIST_APP_NAME"

# Create ZIP archive
zip -r -q "../../../../../$ZIP_PATH" "$DIST_APP_NAME"
cd -

# Display final information
echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"
echo ""
echo "📦 Package Information:"
echo "   • Name: $ZIP_NAME"
echo "   • Version: $VERSION (Beta)"
echo "   • Location: $ZIP_PATH"
echo "   • Size: $(du -h "$ZIP_PATH" | cut -f1)"
echo ""
echo "📋 System Requirements:"
echo "   • macOS 10.15 (Catalina) or later"
echo "   • Minimum 8GB RAM (16GB recommended)"
echo "   • 10GB free disk space"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "   • This is an unsigned build for testing purposes"
echo "   • Users will need to right-click → Open to bypass Gatekeeper"
echo "   • May require System Preferences → Security & Privacy approval"
echo ""
echo "🚀 Installation Instructions for Users:"
echo "   1. Extract the ZIP file"
echo "   2. Drag $DISPLAY_NAME.app to Applications folder"
echo "   3. Right-click on $DISPLAY_NAME.app and select 'Open'"
echo "   4. Click 'Open' in the security dialog"
echo ""
echo "💡 For production release:"
echo "   • Set up Apple Developer account"
echo "   • Configure code signing certificates"
echo "   • Use build_macos_beta.sh for signed builds"