@echo off
echo Installing Developer Agent for ChatMCP...
echo.

REM Check Node.js
node --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Node.js required but not found
    echo Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

REM Install uvx
echo 📦 Installing uvx...
npm install -g @uv/uvx

REM Install MCP servers
echo 🔧 Installing MCP servers...
echo Installing git...
uvx @modelcontextprotocol/server-git
echo Installing github...
uvx @modelcontextprotocol/server-github
echo Installing filesystem...
uvx @modelcontextprotocol/server-filesystem ${HOME}/Documents ${HOME}/Projects
echo Installing web-fetch...
uvx @modelcontextprotocol/server-fetch
echo Installing postgres...
uvx @modelcontextprotocol/server-postgres
echo Installing memory...
uvx @modelcontextprotocol/server-memory

echo.
echo ✅ Installation complete!
echo.
echo 📋 Next steps:
echo 1. Download ChatMCP from: https://github.com/daodao97/chatmcp/releases
echo 2. Load the chatmcp-config.json file in ChatMCP Settings
echo 3. Configure your LLM API keys
echo 4. Start using your Developer Agent!
echo.
pause
