# Developer Agent - ChatMCP Setup Guide

## Overview
This agent uses ChatMCP with 6 MCP servers.

## MCP Servers Included
- **git**: Git repository operations and version control
- **github**: GitHub repository access and management
- **filesystem**: Local file system access and management
- **web-fetch**: Web content fetching and processing
- **postgres**: PostgreSQL database operations
- **memory**: Persistent memory and knowledge management

## Quick Setup

### 1. Install ChatMCP
Download ChatMCP for your platform:
- **Windows**: [Download .exe](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-windows.exe)
- **macOS**: [Download .dmg](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-macos.dmg)
- **Linux**: [Download .AppImage](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-linux.AppImage)

### 2. Install Dependencies
Run the provided installer script:
- **Unix/macOS**: `bash install-chatmcp.sh`
- **Windows**: `install-chatmcp.bat`

### 3. Configure Environment Variables
Set up the following API keys and environment variables:
- GITHUB_PERSONAL_ACCESS_TOKEN
- POSTGRES_CONNECTION_STRING

See `environment-setup.md` for detailed instructions.

### 4. Launch ChatMCP
1. Open ChatMCP application
2. Go to Settings and load the `chatmcp-config.json` file
3. Configure your LLM API keys (OpenAI, Anthropic, etc.)
4. Start chatting with your configured agent!

## Features
- Native MCP protocol support
- Cross-platform compatibility
- Local data synchronization
- Support for multiple LLM providers

## Support
- ChatMCP Documentation: https://github.com/daodao97/chatmcp
- MCP Protocol: https://modelcontextprotocol.io/
- AgentEngine: Your agent configuration system

Generated on 8/16/2025 by AgentEngine ChatMCP
