#!/bin/bash
set -e

echo "🚀 Installing Developer Agent for ChatMCP..."
echo

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js required but not found"
    echo "Please install Node.js from: https://nodejs.org/"
    exit 1
fi

# Install uvx
echo "📦 Installing uvx..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true

# Install MCP servers
echo "🔧 Installing MCP servers..."
echo "Installing git..."
uvx @modelcontextprotocol/server-git
echo "Installing github..."
uvx @modelcontextprotocol/server-github
echo "Installing filesystem..."
uvx @modelcontextprotocol/server-filesystem ${HOME}/Documents ${HOME}/Projects
echo "Installing web-fetch..."
uvx @modelcontextprotocol/server-fetch
echo "Installing postgres..."
uvx @modelcontextprotocol/server-postgres
echo "Installing memory..."
uvx @modelcontextprotocol/server-memory

echo
echo "✅ Installation complete!"
echo
echo "📋 Next steps:"
echo "1. Download ChatMCP from: https://github.com/daodao97/chatmcp/releases"
echo "2. Load the chatmcp-config.json file in ChatMCP Settings"
echo "3. Configure your LLM API keys"
echo "4. Start using your Developer Agent!"
echo
