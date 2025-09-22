#!/bin/bash
# Asmbli MCP Servers for LM Studio - Consumer Installer
# Version 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Pretty output functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 Asmbli MCP Servers for LM Studio${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is required but not installed."
        print_info "Please install Node.js from https://nodejs.org and run this installer again."
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d 'v' -f 2)
    print_success "Node.js found: v$NODE_VERSION"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is required but not installed."
        exit 1
    fi
    
    print_success "npm found: $(npm --version)"
    
    # Check LM Studio (basic check for common install locations)
    LM_STUDIO_FOUND=false
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/LM Studio.app" ]; then
            LM_STUDIO_FOUND=true
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lm-studio &> /dev/null; then
            LM_STUDIO_FOUND=true
        fi
    fi
    
    if [ "$LM_STUDIO_FOUND" = true ]; then
        print_success "LM Studio installation detected"
    else
        print_warning "LM Studio not detected - make sure it's installed before using these MCP servers"
    fi
}

# Setup Asmbli directory
setup_directory() {
    print_info "Setting up Asmbli directory..."
    
    AGENT_DIR="$HOME/Asmbli"
    mkdir -p "$AGENT_DIR/mcp-servers"
    cd "$AGENT_DIR/mcp-servers"
    
    print_success "Directory created: $AGENT_DIR/mcp-servers"
}

# Install MCP servers
install_mcp_servers() {
    print_info "Installing MCP servers..."
    
    # Initialize package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        npm init -y > /dev/null 2>&1
    fi
    
    # Install core MCP servers
    echo "📦 Installing core MCP servers..."
    npm install --silent \
        @figma/mcp-server \
        @modelcontextprotocol/server-filesystem \
        @modelcontextprotocol/server-git \
        @modelcontextprotocol/server-postgres \
        @modelcontextprotocol/server-brave-search \
        express \
        cors \
        dotenv
    
    print_success "MCP servers installed successfully"
}

# Create configuration files
create_configurations() {
    print_info "Creating configuration files..."
    
    # Create .env file for API keys
    cat > .env << 'EOF'
# Asmbli MCP Server Configuration
# Add your API keys here

# Figma Integration (get from https://www.figma.com/developers/api)
FIGMA_ACCESS_TOKEN=your_figma_token_here

# GitHub Integration (get from https://github.com/settings/tokens)
GITHUB_TOKEN=your_github_token_here

# Database Connection (if using PostgreSQL MCP)
# DATABASE_URL=postgresql://user:password@localhost:5432/database

# Brave Search (get from https://api.search.brave.com/app/keys)
BRAVE_SEARCH_API_KEY=your_brave_search_key_here

# File system paths (comma-separated, no spaces)
ALLOWED_PATHS=/Users/$USER/Documents,/Users/$USER/Desktop,/Users/$USER/Projects
EOF

    # Create LM Studio integration script
    cat > start-mcp-servers.sh << 'EOF'
#!/bin/bash
# Start Asmbli MCP Servers for LM Studio

# Load environment variables
set -a
source .env
set +a

echo "🚀 Starting Asmbli MCP servers..."

# Start Figma MCP server
if [ ! -z "$FIGMA_ACCESS_TOKEN" ] && [ "$FIGMA_ACCESS_TOKEN" != "your_figma_token_here" ]; then
    echo "📐 Starting Figma MCP server on port 3001..."
    npx @figma/mcp-server --port 3001 &
    FIGMA_PID=$!
    echo "Figma MCP server started (PID: $FIGMA_PID)"
else
    echo "⏭️  Skipping Figma MCP server (no token configured)"
fi

# Start filesystem MCP server
echo "📁 Starting filesystem MCP server on port 3002..."
npx @modelcontextprotocol/server-filesystem $ALLOWED_PATHS --port 3002 &
FILESYSTEM_PID=$!
echo "Filesystem MCP server started (PID: $FILESYSTEM_PID)"

# Start Git MCP server
echo "🔄 Starting Git MCP server on port 3003..."
npx @modelcontextprotocol/server-git --port 3003 &
GIT_PID=$!
echo "Git MCP server started (PID: $GIT_PID)"

# Start Brave Search MCP server
if [ ! -z "$BRAVE_SEARCH_API_KEY" ] && [ "$BRAVE_SEARCH_API_KEY" != "your_brave_search_key_here" ]; then
    echo "🔍 Starting Brave Search MCP server on port 3004..."
    npx @modelcontextprotocol/server-brave-search --port 3004 &
    SEARCH_PID=$!
    echo "Brave Search MCP server started (PID: $SEARCH_PID)"
else
    echo "⏭️  Skipping Brave Search MCP server (no API key configured)"
fi

echo ""
echo "✅ MCP servers are running!"
echo "🔗 Configure LM Studio to connect to these endpoints:"
echo "   • Figma: http://localhost:3001"
echo "   • Filesystem: http://localhost:3002" 
echo "   • Git: http://localhost:3003"
echo "   • Search: http://localhost:3004"
echo ""
echo "💡 Test commands for LM Studio:"
echo "   • 'List files in my Documents folder'"
echo "   • 'Show me my Figma designs'"
echo "   • 'Search for React tutorials'"
echo "   • 'Check git status of my project'"
echo ""
echo "🛑 Press Ctrl+C to stop all servers"

# Wait for interrupt
trap 'echo ""; echo "🛑 Stopping MCP servers..."; kill $FIGMA_PID $FILESYSTEM_PID $GIT_PID $SEARCH_PID 2>/dev/null; exit 0' INT
wait
EOF

    chmod +x start-mcp-servers.sh

    # Create LM Studio configuration template
    cat > lm-studio-config.json << 'EOF'
{
  "external_tools": [
    {
      "name": "Figma Integration",
      "description": "Access Figma files and design components",
      "endpoint": "http://localhost:3001",
      "enabled": true,
      "methods": ["GET", "POST"],
      "headers": {
        "Content-Type": "application/json"
      }
    },
    {
      "name": "File Manager",
      "description": "Read and write local files safely",
      "endpoint": "http://localhost:3002",
      "enabled": true,
      "methods": ["GET", "POST"],
      "headers": {
        "Content-Type": "application/json"
      }
    },
    {
      "name": "Git Operations",
      "description": "Git repository management and version control",
      "endpoint": "http://localhost:3003",
      "enabled": true,
      "methods": ["GET", "POST"],
      "headers": {
        "Content-Type": "application/json"
      }
    },
    {
      "name": "Web Search",
      "description": "Search the web for current information",
      "endpoint": "http://localhost:3004",
      "enabled": true,
      "methods": ["GET", "POST"],
      "headers": {
        "Content-Type": "application/json"
      }
    }
  ]
}
EOF

    print_success "Configuration files created"
}

# Create desktop shortcuts
create_shortcuts() {
    print_info "Creating desktop shortcuts..."
    
    # Create start script for easy access
    DESKTOP_DIR="$HOME/Desktop"
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/Start Asmbli MCP.command" << EOF
#!/bin/bash
cd "$HOME/Asmbli/mcp-servers"
./start-mcp-servers.sh
EOF
        chmod +x "$DESKTOP_DIR/Start Asmbli MCP.command"
        print_success "Desktop shortcut created"
    fi
}

# Display setup instructions
show_instructions() {
    echo ""
    print_header
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo ""
    echo -e "${BLUE}1. Configure API Keys:${NC}"
    echo "   Edit: $HOME/Asmbli/mcp-servers/.env"
    echo "   Add your Figma, GitHub, and other API tokens"
    echo ""
    echo -e "${BLUE}2. Start MCP Servers:${NC}"
    echo "   Run: $HOME/Asmbli/mcp-servers/start-mcp-servers.sh"
    echo "   Or double-click the desktop shortcut"
    echo ""
    echo -e "${BLUE}3. Configure LM Studio:${NC}"
    echo "   • Open LM Studio settings"
    echo "   • Enable external tools/plugins"
    echo "   • Import configuration from: $HOME/Asmbli/mcp-servers/lm-studio-config.json"
    echo "   • Or manually add the endpoints shown when servers start"
    echo ""
    echo -e "${BLUE}4. Test Integration:${NC}"
    echo "   Try these commands in LM Studio:"
    echo "   • 'List the files in my Documents folder'"
    echo "   • 'Show me components from my Figma design'"
    echo "   • 'Search for Python tutorials'"
    echo "   • 'Check the git status of my current project'"
    echo ""
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo "   • Keep the MCP servers running while using LM Studio"
    echo "   • MCP servers run locally - your data stays private"
    echo "   • Each API integration is optional - configure only what you need"
    echo ""
    echo -e "${GREEN}🆘 Need Help?${NC}"
    echo "   • Documentation: $HOME/Asmbli/mcp-servers/README.md"
    echo "   • Troubleshooting: Check server logs in terminal"
    echo "   • Community: https://github.com/Asmbli/discussions"
    echo ""
}

# Main installation flow
main() {
    print_header
    echo ""
    
    check_prerequisites
    echo ""
    
    setup_directory
    echo ""
    
    install_mcp_servers
    echo ""
    
    create_configurations
    echo ""
    
    create_shortcuts
    echo ""
    
    show_instructions
}

# Run the installer
main "$@"