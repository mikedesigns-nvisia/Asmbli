#!/bin/bash
# Cleanup script for legacy code in Asmbli

echo "🧹 Asmbli Legacy Code Cleanup"
echo "============================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ] && [ ! -d "apps/desktop" ]; then
    echo "❌ Error: Run this script from the Asmbli root directory"
    exit 1
fi

# Count legacy files
LEGACY_COUNT=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | grep -E "(src/|components/)" | wc -l | tr -d ' ')
echo "Found $LEGACY_COUNT legacy TypeScript/React files"

# Create backup directory
BACKUP_DIR="legacy_backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Move legacy directories
if [ -d "src" ]; then
    echo "Moving src/ to backup..."
    mv src "$BACKUP_DIR/"
fi

if [ -d "components" ]; then
    echo "Moving components/ to backup..."
    mv components "$BACKUP_DIR/"
fi

# Clean up old config files
OLD_CONFIGS=("tsconfig.json" "webpack.config.js" ".babelrc" "package.json" "package-lock.json")
for config in "${OLD_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        echo "Moving $config to backup..."
        mv "$config" "$BACKUP_DIR/"
    fi
done

# Remove node_modules if it exists
if [ -d "node_modules" ]; then
    echo "Removing node_modules..."
    rm -rf node_modules
fi

# Clean up any stray TS/JS files in root
find . -maxdepth 1 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -exec mv {} "$BACKUP_DIR/" \;

echo ""
echo "✅ Cleanup complete!"
echo "Legacy files backed up to: $BACKUP_DIR"
echo ""
echo "To restore if needed: mv $BACKUP_DIR/* ."
echo "To permanently delete: rm -rf $BACKUP_DIR"