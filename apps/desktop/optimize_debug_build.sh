#!/bin/bash

# Optimize the debug build by removing unnecessary files

set -e

echo "🔧 Optimizing debug build..."

APP_PATH="build/macos/Build/Products/Debug/desktop.app"
OPTIMIZED_PATH="build/macos/Build/Products/Debug/desktop_optimized.app"

# Copy the app to optimize
cp -R "$APP_PATH" "$OPTIMIZED_PATH"

echo "📦 Original size: $(du -h -d 0 "$APP_PATH" | cut -f1)"

# Remove debug symbols and unnecessary files
echo "🗑️  Removing debug symbols..."
find "$OPTIMIZED_PATH" -name "*.dSYM" -exec rm -rf {} + 2>/dev/null || true
find "$OPTIMIZED_PATH" -name "*.debug" -exec rm -f {} + 2>/dev/null || true

# Remove documentation and headers
echo "🗑️  Removing docs and headers..."
find "$OPTIMIZED_PATH" -name "Headers" -type d -exec rm -rf {} + 2>/dev/null || true
find "$OPTIMIZED_PATH" -name "Documentation" -type d -exec rm -rf {} + 2>/dev/null || true
find "$OPTIMIZED_PATH" -name "*.md" -exec rm -f {} + 2>/dev/null || true
find "$OPTIMIZED_PATH" -name "README*" -exec rm -f {} + 2>/dev/null || true

# Strip executables if possible
echo "🔧 Stripping binaries..."
find "$OPTIMIZED_PATH" -type f -perm +111 -exec strip {} + 2>/dev/null || true

echo "📦 Optimized size: $(du -h -d 0 "$OPTIMIZED_PATH" | cut -f1)"

# Create ZIP
ZIP_NAME="Asmbli-Beta-0.9.0-macOS-optimized.zip"
cd "build/macos/Build/Products/Debug"
mv desktop_optimized.app Asmbli.app
zip -r -q "../../../../../build/$ZIP_NAME" Asmbli.app
cd -

echo "✅ Optimized build created: build/$ZIP_NAME"
echo "📦 ZIP size: $(du -h "build/$ZIP_NAME" | cut -f1)"