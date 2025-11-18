#!/bin/bash

# PenPot Plugin Development Automation Script
# Watches for file changes and rebuilds automatically

set -e

echo "🔧 Asmbli PenPot Plugin Development Mode"
echo "========================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if Ollama is running
echo -e "${YELLOW}Checking Ollama status...${NC}"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama is running${NC}"
else
    echo -e "${YELLOW}⚠ Ollama is not running (AI features will be disabled)${NC}"
    echo -e "${YELLOW}  Start with: ollama serve${NC}"
fi

# Initial build
echo -e "\n${BLUE}Building plugin...${NC}"
npm run build

echo -e "\n${GREEN}✓ Development environment ready${NC}"
echo -e "\n${YELLOW}Plugin location:${NC} $(pwd)/dist"
echo -e "${YELLOW}Watching for changes...${NC} (Press Ctrl+C to stop)\n"

# Watch for changes and rebuild
npm run dev
