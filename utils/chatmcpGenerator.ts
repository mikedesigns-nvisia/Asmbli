import { WizardData } from '../types/wizard';

// ChatMCP Configuration Types
interface ChatMCPConfig {
  mcpServers: Record<string, MCPServerConfig>;
  agentMetadata: {
    name: string;
    description: string;
    role: string;
    version: string;
    createdAt: string;
    generator: string;
  };
}

interface MCPServerConfig {
  command: string;
  args: string[];
  env?: Record<string, string>;
  description?: string;
}

// MVP Wizard Data Type
interface MVPWizardData {
  selectedRole?: string;
  role?: string;
  selectedTools?: string[];
  tools?: string[];
  extractedConstraints?: string[];
  style?: any;
  deployment?: any;
}

// Tool to MCP Server Mapping
const TOOL_TO_MCP_MAPPING: Record<string, {
  package: string;
  command: string;
  args: string[];
  env?: Record<string, string>;
  description: string;
}> = {
  // Core Development Tools
  'git': {
    package: '@modelcontextprotocol/server-git',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-git'],
    description: 'Git repository operations and version control'
  },
  'github': {
    package: '@modelcontextprotocol/server-github',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-github'],
    env: { 'GITHUB_PERSONAL_ACCESS_TOKEN': '${GITHUB_PERSONAL_ACCESS_TOKEN}' },
    description: 'GitHub repository access and management'
  },
  'filesystem': {
    package: '@modelcontextprotocol/server-filesystem',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-filesystem', '${HOME}/Documents', '${HOME}/Projects'],
    description: 'Local file system access and management'
  },
  'postgres': {
    package: '@modelcontextprotocol/server-postgres',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-postgres'],
    env: { 'POSTGRES_CONNECTION_STRING': '${POSTGRES_CONNECTION_STRING}' },
    description: 'PostgreSQL database operations'
  },
  'web-search': {
    package: '@modelcontextprotocol/server-brave-search',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-brave-search'],
    env: { 'BRAVE_API_KEY': '${BRAVE_API_KEY}' },
    description: 'Web search capabilities via Brave Search'
  },
  'memory': {
    package: '@modelcontextprotocol/server-memory',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-memory'],
    description: 'Persistent memory and knowledge management'
  },
  'web-fetch': {
    package: '@modelcontextprotocol/server-fetch',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-fetch'],
    description: 'Web content fetching and processing'
  },
  
  // Design & Creative Tools
  'figma': {
    package: 'figma-mcp',
    command: 'uvx',
    args: ['--from', 'git+https://github.com/modelcontextprotocol/servers.git', 'figma'],
    env: { 'FIGMA_ACCESS_TOKEN': '${FIGMA_ACCESS_TOKEN}' },
    description: 'Figma design file access and manipulation'
  },
  'visual-design': {
    package: 'figma-mcp',
    command: 'uvx',
    args: ['--from', 'git+https://github.com/modelcontextprotocol/servers.git', 'figma'],
    env: { 'FIGMA_ACCESS_TOKEN': '${FIGMA_ACCESS_TOKEN}' },
    description: 'Visual design tools and assets'
  },
  
  // Research & Data Tools
  'research-tools': {
    package: '@modelcontextprotocol/server-brave-search',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-brave-search'],
    env: { 'BRAVE_API_KEY': '${BRAVE_API_KEY}' },
    description: 'Research and information gathering tools'
  },
  'data-analysis': {
    package: '@modelcontextprotocol/server-postgres',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-postgres'],
    env: { 'POSTGRES_CONNECTION_STRING': '${POSTGRES_CONNECTION_STRING}' },
    description: 'Data analysis and database tools'
  },

  // Content & Media
  'content-creation': {
    package: '@modelcontextprotocol/server-fetch',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-fetch'],
    description: 'Content creation and web research tools'
  }
};

// Extension ID to MCP Server Mapping (for enterprise wizard)
const EXTENSION_TO_MCP_MAPPING: Record<string, {
  package: string;
  command: string;
  args: string[];
  env?: Record<string, string>;
  description: string;
}> = {
  'figma-mcp': {
    package: 'figma-mcp',
    command: 'uvx',
    args: ['--from', 'git+https://github.com/modelcontextprotocol/servers.git', 'figma'],
    env: { 'FIGMA_ACCESS_TOKEN': '${FIGMA_ACCESS_TOKEN}' },
    description: 'Figma design system integration'
  },
  'filesystem-mcp': {
    package: '@modelcontextprotocol/server-filesystem',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-filesystem', '${HOME}/Documents', '${HOME}/Projects'],
    description: 'File system operations'
  },
  'git-mcp': {
    package: '@modelcontextprotocol/server-git',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-git'],
    description: 'Git version control'
  },
  'github': {
    package: '@modelcontextprotocol/server-github',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-github'],
    env: { 'GITHUB_PERSONAL_ACCESS_TOKEN': '${GITHUB_PERSONAL_ACCESS_TOKEN}' },
    description: 'GitHub integration'
  },
  'postgres-mcp': {
    package: '@modelcontextprotocol/server-postgres',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-postgres'],
    env: { 'POSTGRES_CONNECTION_STRING': '${POSTGRES_CONNECTION_STRING}' },
    description: 'PostgreSQL database'
  },
  'memory-mcp': {
    package: '@modelcontextprotocol/server-memory',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-memory'],
    description: 'Persistent memory'
  },
  'search-mcp': {
    package: '@modelcontextprotocol/server-brave-search',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-brave-search'],
    env: { 'BRAVE_API_KEY': '${BRAVE_API_KEY}' },
    description: 'Web search'
  },
  'http-mcp': {
    package: '@modelcontextprotocol/server-fetch',
    command: 'uvx',
    args: ['@modelcontextprotocol/server-fetch'],
    description: 'HTTP requests'
  }
};

/**
 * Main entry point for ChatMCP configuration generation
 * Handles both MVP and Enterprise wizard data
 */
export function generateChatMCPConfigs(wizardData: WizardData | MVPWizardData): Record<string, string> {
  console.log('🚀 Generating ChatMCP configurations...');
  
  const configs: Record<string, string> = {};
  
  // Detect data type
  const isMVPData = detectMVPData(wizardData);
  
  if (isMVPData) {
    console.log('📱 MVP Wizard detected - generating simplified ChatMCP config');
    const chatmcpConfig = generateMVPChatMCPConfig(wizardData as MVPWizardData);
    configs['chatmcp-config.json'] = JSON.stringify(chatmcpConfig, null, 2);
    configs['chatmcp-setup.md'] = generateChatMCPSetupGuide(chatmcpConfig, 'mvp');
    configs['install-chatmcp.sh'] = generateChatMCPInstaller(chatmcpConfig, 'unix');
    configs['install-chatmcp.bat'] = generateChatMCPInstaller(chatmcpConfig, 'windows');
  } else {
    console.log('🏢 Enterprise Wizard detected - generating full ChatMCP config');
    const chatmcpConfig = generateEnterpriseChatMCPConfig(wizardData as WizardData);
    configs['chatmcp-config.json'] = JSON.stringify(chatmcpConfig, null, 2);
    configs['chatmcp-setup.md'] = generateChatMCPSetupGuide(chatmcpConfig, 'enterprise');
    configs['install-chatmcp.sh'] = generateChatMCPInstaller(chatmcpConfig, 'unix');
    configs['install-chatmcp.bat'] = generateChatMCPInstaller(chatmcpConfig, 'windows');
  }
  
  // Add environment variables guide
  configs['environment-setup.md'] = generateEnvironmentGuide(configs['chatmcp-config.json']);
  
  console.log('✅ ChatMCP configuration generation complete');
  return configs;
}

/**
 * Detect if the data is from MVP wizard or Enterprise wizard
 */
function detectMVPData(wizardData: any): boolean {
  return wizardData && 
         (('selectedRole' in wizardData && wizardData.selectedRole) || ('role' in wizardData && wizardData.role)) && 
         (('selectedTools' in wizardData && wizardData.selectedTools) || ('tools' in wizardData && wizardData.tools)) && 
         !('extensions' in wizardData);
}

/**
 * Generate ChatMCP config for MVP wizard data
 */
function generateMVPChatMCPConfig(mvpData: MVPWizardData): ChatMCPConfig {
  const role = mvpData.selectedRole || mvpData.role || 'developer';
  const tools = mvpData.selectedTools || mvpData.tools || [];
  
  const mcpServers: Record<string, MCPServerConfig> = {};
  
  // Convert tools to MCP servers
  tools.forEach(tool => {
    const mcpConfig = TOOL_TO_MCP_MAPPING[tool];
    if (mcpConfig) {
      mcpServers[tool] = {
        command: mcpConfig.command,
        args: mcpConfig.args,
        ...(mcpConfig.env && { env: mcpConfig.env })
      };
    }
  });
  
  return {
    mcpServers,
    agentMetadata: {
      name: `${role.charAt(0).toUpperCase() + role.slice(1)} Agent`,
      description: `AI agent specialized for ${role} workflows`,
      role: role,
      version: '1.0.0',
      createdAt: new Date().toISOString(),
      generator: 'AgentEngine ChatMCP'
    }
  };
}

/**
 * Generate ChatMCP config for Enterprise wizard data
 */
function generateEnterpriseChatMCPConfig(wizardData: WizardData): ChatMCPConfig {
  const mcpServers: Record<string, MCPServerConfig> = {};
  
  // Convert enabled extensions to MCP servers
  wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp').forEach(ext => {
    const mcpConfig = EXTENSION_TO_MCP_MAPPING[ext.id];
    if (mcpConfig) {
      mcpServers[ext.id] = {
        command: mcpConfig.command,
        args: mcpConfig.args,
        ...(mcpConfig.env && { env: mcpConfig.env })
      };
    }
  });
  
  return {
    mcpServers,
    agentMetadata: {
      name: wizardData.agentName || 'Custom Agent',
      description: wizardData.agentDescription || 'Custom AI agent with MCP integration',
      role: wizardData.primaryPurpose || 'general',
      version: '1.0.0',
      createdAt: new Date().toISOString(),
      generator: 'AgentEngine ChatMCP Enterprise'
    }
  };
}

/**
 * Generate setup guide for ChatMCP
 */
function generateChatMCPSetupGuide(config: ChatMCPConfig, type: 'mvp' | 'enterprise'): string {
  const serversList = Object.entries(config.mcpServers)
    .map(([name, server]) => {
      const mcpMapping = Object.values(TOOL_TO_MCP_MAPPING).find(m => 
        m.command === server.command && JSON.stringify(m.args) === JSON.stringify(server.args)
      ) || Object.values(EXTENSION_TO_MCP_MAPPING).find(m => 
        m.command === server.command && JSON.stringify(m.args) === JSON.stringify(server.args)
      );
      
      return `- **${name}**: ${mcpMapping?.description || 'MCP server integration'}`;
    }).join('\n');

  const envVars = Object.entries(config.mcpServers)
    .flatMap(([name, server]) => 
      server.env ? Object.keys(server.env).map(key => `- ${key}`) : []
    );

  return `# ${config.agentMetadata.name} - ChatMCP Setup Guide

## Overview
This agent uses ChatMCP with ${Object.keys(config.mcpServers).length} MCP server${Object.keys(config.mcpServers).length !== 1 ? 's' : ''}.

## MCP Servers Included
${serversList}

## Quick Setup

### 1. Install ChatMCP
Download ChatMCP for your platform:
- **Windows**: [Download .exe](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-windows.exe)
- **macOS**: [Download .dmg](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-macos.dmg)
- **Linux**: [Download .AppImage](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-linux.AppImage)

### 2. Install Dependencies
Run the provided installer script:
- **Unix/macOS**: \`bash install-chatmcp.sh\`
- **Windows**: \`install-chatmcp.bat\`

### 3. Configure Environment Variables
${envVars.length > 0 ? `Set up the following API keys and environment variables:
${envVars.join('\n')}

See \`environment-setup.md\` for detailed instructions.` : 'No additional environment variables required.'}

### 4. Launch ChatMCP
1. Open ChatMCP application
2. Go to Settings and load the \`chatmcp-config.json\` file
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

Generated on ${new Date().toLocaleDateString()} by ${config.agentMetadata.generator}
`;
}

/**
 * Generate installer script for ChatMCP
 */
function generateChatMCPInstaller(config: ChatMCPConfig, platform: 'unix' | 'windows'): string {
  const servers = Object.entries(config.mcpServers);
  
  if (platform === 'windows') {
    return `@echo off
echo Installing ${config.agentMetadata.name} for ChatMCP...
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
${servers.map(([name, server]) => `echo Installing ${name}...
${server.command} ${server.args.join(' ')}`).join('\n')}

echo.
echo ✅ Installation complete!
echo.
echo 📋 Next steps:
echo 1. Download ChatMCP from: https://github.com/daodao97/chatmcp/releases
echo 2. Load the chatmcp-config.json file in ChatMCP Settings
echo 3. Configure your LLM API keys
echo 4. Start using your ${config.agentMetadata.name}!
echo.
pause
`;
  } else {
    return `#!/bin/bash
set -e

echo "🚀 Installing ${config.agentMetadata.name} for ChatMCP..."
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
${servers.map(([name, server]) => `echo "Installing ${name}..."
${server.command} ${server.args.join(' ')}`).join('\n')}

echo
echo "✅ Installation complete!"
echo
echo "📋 Next steps:"
echo "1. Download ChatMCP from: https://github.com/daodao97/chatmcp/releases"
echo "2. Load the chatmcp-config.json file in ChatMCP Settings"
echo "3. Configure your LLM API keys"
echo "4. Start using your ${config.agentMetadata.name}!"
echo
`;
  }
}

/**
 * Generate environment variables setup guide
 */
function generateEnvironmentGuide(configJson: string): string {
  const config = JSON.parse(configJson);
  const envVars = new Set<string>();
  
  Object.values(config.mcpServers).forEach((server: any) => {
    if (server.env) {
      Object.keys(server.env).forEach(key => envVars.add(key));
    }
  });
  
  if (envVars.size === 0) {
    return `# Environment Setup

No additional environment variables required for this agent configuration.
`;
  }
  
  const envGuides: Record<string, string> = {
    'FIGMA_ACCESS_TOKEN': `**Figma Access Token**
- Go to: https://www.figma.com/developers/api
- Generate a personal access token
- Copy the token`,
    
    'GITHUB_PERSONAL_ACCESS_TOKEN': `**GitHub Personal Access Token**
- Go to: https://github.com/settings/tokens
- Generate a new token (classic)
- Select required scopes: repo, read:org
- Copy the token`,
    
    'POSTGRES_CONNECTION_STRING': `**PostgreSQL Connection String**
- Format: postgresql://username:password@host:port/database
- Example: postgresql://user:pass@localhost:5432/mydb`,
    
    'BRAVE_API_KEY': `**Brave Search API Key**
- Go to: https://api.search.brave.com/app/keys
- Create a new API key
- Copy the key`
  };
  
  return `# Environment Variables Setup

Configure these environment variables for your agent:

${Array.from(envVars).map(varName => {
  const guide = envGuides[varName] || `**${varName}**\n- Configure this environment variable as needed`;
  return `## ${varName}\n${guide}`;
}).join('\n\n')}

## How to Set Environment Variables

### Windows
\`\`\`cmd
set ${Array.from(envVars)[0]}=your_value_here
\`\`\`

### macOS/Linux
\`\`\`bash
export ${Array.from(envVars)[0]}=your_value_here
\`\`\`

### ChatMCP Settings
You can also configure these directly in ChatMCP's settings interface.
`;
}

// Legacy compatibility - redirect old function calls to new ChatMCP generator
export function generateDeploymentConfigs(wizardData: WizardData | MVPWizardData, promptOutput?: string): Record<string, string> {
  console.log('🔄 Legacy deployment generator called - redirecting to ChatMCP generator');
  return generateChatMCPConfigs(wizardData);
}