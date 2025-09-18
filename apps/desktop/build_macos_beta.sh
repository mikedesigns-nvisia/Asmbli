#!/bin/bash

# Asmbli Beta - macOS Build Script
# Creates a production-ready DMG for macOS distribution

set -e

echo "🚀 Building Asmbli Beta for macOS..."
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
APP_NAME="Asmbli"
VERSION="0.9.0"
BUILD_NUMBER="1"
BUNDLE_ID="com.asmbli.desktop"

echo -e "${BLUE}📦 Building Asmbli Beta v${VERSION}...${NC}"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/macos/Build/Products/Release/*.app 2>/dev/null || true
rm -rf build/*.dmg 2>/dev/null || true
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build the macOS app
echo -e "${YELLOW}🔨 Building macOS application...${NC}"
flutter build macos --release \
  --dart-define=FLUTTER_BUILD_NAME=$VERSION \
  --dart-define=FLUTTER_BUILD_NUMBER=$BUILD_NUMBER

# Check if build was successful
if [ ! -d "build/macos/Build/Products/Release/$APP_NAME.app" ]; then
    echo -e "${RED}❌ Build failed. App bundle not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"

# Create DMG for distribution
echo -e "${BLUE}💿 Creating DMG installer...${NC}"

DMG_NAME="Asmbli-Beta-${VERSION}-macOS.dmg"
APP_PATH="build/macos/Build/Products/Release/$APP_NAME.app"
DMG_PATH="build/$DMG_NAME"

# Create a temporary directory for DMG contents
TEMP_DMG_DIR="build/dmg_temp"
rm -rf "$TEMP_DMG_DIR" 2>/dev/null || true
mkdir -p "$TEMP_DMG_DIR"

# Copy the app to the temporary directory
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Create a symbolic link to Applications folder
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME Beta" \
  -srcfolder "$TEMP_DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

# Clean up temporary directory
rm -rf "$TEMP_DMG_DIR"

# Sign the DMG (if certificates are available)
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "🔏 Signing DMG..."
    codesign --force --sign "Developer ID Application" "$DMG_PATH"
else
    echo -e "${YELLOW}⚠️  No signing certificate found. DMG will be unsigned.${NC}"
    echo "   Users may see security warnings when opening the app."
fi

# Notarize the DMG (requires Apple Developer account)
# Uncomment if you have notarization credentials set up
# echo "📝 Notarizing DMG..."
# xcrun notarytool submit "$DMG_PATH" --wait --keychain-profile "AC_PASSWORD"

# Display final information
echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"
echo ""
echo "📦 Package Information:"
echo "   • Name: $DMG_NAME"
echo "   • Version: $VERSION (Beta)"
echo "   • Location: $DMG_PATH"
echo "   • Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "📋 System Requirements:"
echo "   • macOS 10.15 (Catalina) or later"
echo "   • Minimum 8GB RAM (16GB recommended)"
echo "   • 10GB free disk space"
echo ""
echo "🚀 Distribution:"
echo "   • The DMG is ready for distribution"
echo "   • Users can drag Asmbli to their Applications folder"
echo "   • First launch may require right-click → Open due to Gatekeeper"
echo ""
echo "💡 Next steps:"
echo "   1. Test the DMG on a clean macOS system"
echo "   2. Upload to distribution platform"
echo "   3. Update release notes with beta feedback instructions"