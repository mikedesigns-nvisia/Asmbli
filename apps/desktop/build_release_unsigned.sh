#!/bin/bash

# Asmbli Beta - Release Build (Unsigned)
# Creates an optimized release build without code signing

set -e

echo "🚀 Building Asmbli Beta Release (Unsigned)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="desktop"
DISPLAY_NAME="Asmbli"
VERSION="0.9.0"

echo -e "${BLUE}📦 Building Asmbli Beta v${VERSION} (Release/Unsigned)...${NC}"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/macos/Build/Products/Release/*.app 2>/dev/null || true
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Build release with code signing disabled via Xcode build settings
echo -e "${YELLOW}🔨 Building release application (no signing)...${NC}"
flutter build macos --release \
  --dart-define=FLUTTER_BUILD_NAME=$VERSION \
  --build-number=1 \
  --build-name=$VERSION

# Check if build was successful
if [ ! -d "build/macos/Build/Products/Release/$APP_NAME.app" ]; then
    echo -e "${RED}❌ Build failed. App bundle not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Release build successful!${NC}"

# Check the size
RELEASE_SIZE=$(du -h -d 0 "build/macos/Build/Products/Release/$APP_NAME.app" | cut -f1)
echo "📏 Release app size: $RELEASE_SIZE"

# Create ZIP for distribution
echo -e "${BLUE}📦 Creating release ZIP archive...${NC}"

ZIP_NAME="Asmbli-Beta-${VERSION}-macOS-release-unsigned.zip"
APP_PATH="build/macos/Build/Products/Release/$APP_NAME.app"
ZIP_PATH="build/$ZIP_NAME"

# Rename the app bundle for distribution
DIST_APP_NAME="$DISPLAY_NAME.app"
cd "build/macos/Build/Products/Release"
cp -R "$APP_NAME.app" "$DIST_APP_NAME"

# Create ZIP archive
zip -r -q "../../../../../$ZIP_PATH" "$DIST_APP_NAME"
cd -

# Display final information
echo ""
echo -e "${GREEN}🎉 Release build complete!${NC}"
echo ""
echo "📦 Package Information:"
echo "   • Name: $ZIP_NAME"
echo "   • Version: $VERSION (Beta Release)"
echo "   • Location: $ZIP_PATH"
echo "   • Size: $(du -h "$ZIP_PATH" | cut -f1)"
echo "   • App Size: $RELEASE_SIZE"
echo ""
echo "🔬 Build Optimizations:"
echo "   • Release mode compilation"
echo "   • Dead code elimination"
echo "   • Asset optimization"
echo "   • Smaller framework bundles"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "   • This is an unsigned release build"
echo "   • Smaller than debug build but still requires Gatekeeper bypass"
echo "   • Users will need to right-click → Open on first launch"
echo ""
echo "🚀 Ready for distribution!"