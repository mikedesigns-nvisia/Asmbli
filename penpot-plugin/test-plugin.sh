#!/bin/bash

# PenPot Plugin Test Automation Script
# Tests the AI chat interface and MCP tools integration

set -e

echo "🚀 Asmbli PenPot Plugin Test Automation"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Ollama is running
check_ollama() {
    echo -e "\n${YELLOW}Checking Ollama status...${NC}"
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama is running${NC}"
        return 0
    else
        echo -e "${RED}✗ Ollama is not running${NC}"
        echo "  Start Ollama with: ollama serve"
        return 1
    fi
}

# Check if llama3.2 model is available
check_model() {
    echo -e "\n${YELLOW}Checking for llama3.2 model...${NC}"
    if curl -s http://localhost:11434/api/tags | grep -q "llama3.2"; then
        echo -e "${GREEN}✓ llama3.2 model is available${NC}"
        return 0
    else
        echo -e "${RED}✗ llama3.2 model not found${NC}"
        echo "  Pull the model with: ollama pull llama3.2"
        return 1
    fi
}

# Build the plugin
build_plugin() {
    echo -e "\n${YELLOW}Building plugin...${NC}"
    npm run build
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Plugin built successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Plugin build failed${NC}"
        return 1
    fi
}

# Check build output
check_build_output() {
    echo -e "\n${YELLOW}Checking build output...${NC}"

    if [ -f "dist/plugin.js" ]; then
        PLUGIN_SIZE=$(du -h dist/plugin.js | cut -f1)
        echo -e "${GREEN}✓ dist/plugin.js - $PLUGIN_SIZE${NC}"
    else
        echo -e "${RED}✗ dist/plugin.js not found${NC}"
        return 1
    fi

    if [ -f "dist/index.js" ]; then
        INDEX_SIZE=$(du -h dist/index.js | cut -f1)
        echo -e "${GREEN}✓ dist/index.js - $INDEX_SIZE${NC}"
    else
        echo -e "${RED}✗ dist/index.js not found${NC}"
        return 1
    fi

    if [ -f "dist/index.html" ]; then
        echo -e "${GREEN}✓ dist/index.html exists${NC}"
    else
        echo -e "${RED}✗ dist/index.html not found${NC}"
        return 1
    fi

    return 0
}

# Run TypeScript type checking
type_check() {
    echo -e "\n${YELLOW}Running TypeScript type checking...${NC}"
    npx tsc --noEmit
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ No TypeScript errors${NC}"
        return 0
    else
        echo -e "${RED}✗ TypeScript errors found${NC}"
        return 1
    fi
}

# Test Ollama API directly
test_ollama_api() {
    echo -e "\n${YELLOW}Testing Ollama API...${NC}"

    RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d '{
            "model": "llama3.2",
            "prompt": "Say hello in 3 words",
            "stream": false,
            "options": {
                "temperature": 0.7,
                "num_predict": 10
            }
        }')

    if echo "$RESPONSE" | grep -q "response"; then
        echo -e "${GREEN}✓ Ollama API is responding${NC}"
        return 0
    else
        echo -e "${RED}✗ Ollama API test failed${NC}"
        return 1
    fi
}

# Create a test manifest for manual testing
create_test_manifest() {
    echo -e "\n${YELLOW}Creating test manifest...${NC}"

    cat > dist/manifest.json << 'EOF'
{
  "name": "Asmbli Design Agent",
  "description": "AI-powered design assistant with MCP tools",
  "version": "1.0.0",
  "permissions": [
    "content:read",
    "content:write",
    "library:read",
    "library:write",
    "user:read"
  ]
}
EOF

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test manifest created${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create manifest${NC}"
        return 1
    fi
}

# Display installation instructions
show_install_instructions() {
    echo -e "\n${YELLOW}=== Installation Instructions ===${NC}"
    echo -e "\nTo test the plugin in PenPot:"
    echo -e "1. Open PenPot in your browser"
    echo -e "2. Go to Plugins → Manage Plugins"
    echo -e "3. Click 'Install from filesystem'"
    echo -e "4. Navigate to: ${GREEN}$(pwd)/dist${NC}"
    echo -e "5. The plugin should load with the AI chat interface"
    echo -e "\nPlugin files location: ${GREEN}$(pwd)/dist${NC}"
    echo -e "\nFeatures to test:"
    echo -e "  • Ollama status indicator (should show 'AI Ready')"
    echo -e "  • Quick action buttons (4 pre-defined prompts)"
    echo -e "  • Chat input field"
    echo -e "  • Message history with suggestions and tool calls"
}

# Display next steps
show_next_steps() {
    echo -e "\n${YELLOW}=== Next Steps (Week 10) ===${NC}"
    echo -e "• Streaming responses from Ollama for real-time feedback"
    echo -e "• Multi-step design workflows with AI planning"
    echo -e "• Canvas state analysis and optimization suggestions"
    echo -e "• Design pattern recognition and recommendations"
    echo -e "• Image generation integration (Stable Diffusion/DALL-E)"
    echo -e "• Component library suggestions based on design patterns"
}

# Main test flow
main() {
    FAILED=0

    # Run all checks
    check_ollama || FAILED=$((FAILED + 1))
    check_model || FAILED=$((FAILED + 1))
    build_plugin || FAILED=$((FAILED + 1))
    check_build_output || FAILED=$((FAILED + 1))
    type_check || FAILED=$((FAILED + 1))
    test_ollama_api || FAILED=$((FAILED + 1))
    create_test_manifest || FAILED=$((FAILED + 1))

    # Summary
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo -e "${GREEN}✓ Plugin is ready for testing in PenPot${NC}"
        show_install_instructions
        show_next_steps
        exit 0
    else
        echo -e "${RED}✗ $FAILED test(s) failed${NC}"
        echo -e "\nPlease fix the issues above before testing the plugin."
        exit 1
    fi
}

# Run main function
main
