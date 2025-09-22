#!/bin/bash

# Asmbli macOS Distribution Build Script
# Builds a production-ready macOS app bundle for distribution

set -e

echo "🍎 Building Asmbli macOS Distribution Package..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Asmbli"
APP_VERSION="1.0.0"
BUNDLE_ID="com.asmbli.agentengine.desktop"
BUILD_DIR="build/macos/Build/Products/Release"
DIST_DIR="dist/macos"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${APP_VERSION}-macOS"

echo -e "${BLUE}📋 Build Configuration:${NC}"
echo "  App Name: $APP_NAME"
echo "  Version: $APP_VERSION"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Build Dir: $BUILD_DIR"
echo "  Dist Dir: $DIST_DIR"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build release version
echo -e "${BLUE}🔨 Building Flutter macOS release...${NC}"
flutter build macos --release || {
    echo -e "${RED}❌ Flutter build failed. Trying with code signing disabled...${NC}"

    # Temporarily disable entitlements for unsigned build
    cp macos/Runner/DebugProfile.entitlements macos/Runner/DebugProfile.entitlements.backup
    cat > macos/Runner/DebugProfile.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
EOF

    # Try build again with minimal entitlements
    flutter build macos --release || {
        echo -e "${RED}❌ Build failed even with minimal entitlements${NC}"
        # Restore original entitlements
        mv macos/Runner/DebugProfile.entitlements.backup macos/Runner/DebugProfile.entitlements
        exit 1
    }

    # Restore original entitlements
    mv macos/Runner/DebugProfile.entitlements.backup macos/Runner/DebugProfile.entitlements
}

# Check if app bundle was created
if [ ! -d "$BUILD_DIR/desktop.app" ]; then
    echo -e "${RED}❌ App bundle not found at $BUILD_DIR/desktop.app${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter build completed successfully${NC}"

# Copy app bundle to distribution directory
echo -e "${BLUE}📦 Preparing distribution package...${NC}"
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

# Create DMG installer (optional)
echo -e "${BLUE}💿 Creating DMG installer...${NC}"
if command -v hdiutil >/dev/null 2>&1; then
    # Create temporary DMG directory
    DMG_DIR="$DIST_DIR/dmg_temp"
    mkdir -p "$DMG_DIR"

    # Copy app to DMG directory
    cp -R "$DIST_DIR/$APP_BUNDLE" "$DMG_DIR/"

    # Create Applications symlink
    ln -s /Applications "$DMG_DIR/Applications"

    # Create DMG
    hdiutil create -volname "$APP_NAME" \
                   -srcfolder "$DMG_DIR" \
                   -ov -format UDZO \
                   "$DIST_DIR/$DMG_NAME.dmg" 2>/dev/null || {
        echo -e "${YELLOW}⚠️ DMG creation failed, but app bundle is ready${NC}"
    }

    # Clean up
    rm -rf "$DMG_DIR"

    if [ -f "$DIST_DIR/$DMG_NAME.dmg" ]; then
        DMG_SIZE=$(du -sh "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)
        echo -e "${GREEN}✅ DMG created: $DMG_NAME.dmg ($DMG_SIZE)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ hdiutil not available, skipping DMG creation${NC}"
fi

# Create ZIP archive as alternative
echo -e "${BLUE}🗜️ Creating ZIP archive...${NC}"
cd "$DIST_DIR"
zip -r "$DMG_NAME.zip" "$APP_BUNDLE" >/dev/null 2>&1
cd - >/dev/null

if [ -f "$DIST_DIR/$DMG_NAME.zip" ]; then
    ZIP_SIZE=$(du -sh "$DIST_DIR/$DMG_NAME.zip" | cut -f1)
    echo -e "${GREEN}✅ ZIP created: $DMG_NAME.zip ($ZIP_SIZE)${NC}"
fi

# Security note
echo -e "${YELLOW}🔒 Security Note:${NC}"
echo "  This is an unsigned build. For distribution:"
echo "  • Code sign with Apple Developer certificate"
echo "  • Notarize with Apple for Gatekeeper approval"
echo "  • Consider Mac App Store submission"

# Installation instructions
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${BLUE}📁 Distribution files created in: $DIST_DIR${NC}"
echo ""
echo -e "${BLUE}📋 Installation Instructions:${NC}"
echo "  1. Mount the DMG or extract the ZIP"
echo "  2. Drag $APP_BUNDLE to Applications folder"
echo "  3. First launch: Right-click → Open (to bypass Gatekeeper)"
echo "  4. Grant necessary permissions when prompted"
echo ""
echo -e "${BLUE}🚀 Distribution Package Contents:${NC}"
ls -la "$DIST_DIR"

echo -e "${GREEN}✅ Asmbli macOS distribution build complete!${NC}"