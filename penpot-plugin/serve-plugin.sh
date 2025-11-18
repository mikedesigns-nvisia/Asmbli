#!/bin/bash

# Serve PenPot plugin locally for installation
# This allows PenPot to load the plugin from http://localhost:8765

echo "🚀 Starting PenPot plugin server..."
echo "=========================================="
echo ""
echo "Plugin URL: http://localhost:8765/manifest.json"
echo ""
echo "To install in PenPot:"
echo "1. Open PenPot (https://design.penpot.app)"
echo "2. Go to Plugins → Manage Plugins"
echo "3. Click 'Install from URL'"
echo "4. Enter: http://localhost:8765/manifest.json"
echo "5. Click 'INSTALL'"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

cd dist
python3 -m http.server 8765
