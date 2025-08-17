// Generate and demonstrate real ChatMCP deployment package output
// This shows exactly what users receive from the complete agent flow

import fs from 'fs';
import path from 'path';

// Copy the working generator functions from the test
function generateChatMCPConfigs(wizardData) {
  console.log('🚀 Generating ChatMCP configurations...');
  
  const configs = {};
  
  // Detect data type
  const isMVPData = detectMVPData(wizardData);
  
  if (isMVPData) {
    console.log('📱 MVP Wizard detected - generating simplified ChatMCP config');
    const chatmcpConfig = generateMVPChatMCPConfig(wizardData);
    configs['chatmcp-config.json'] = JSON.stringify(chatmcpConfig, null, 2);
    configs['chatmcp-setup.md'] = generateChatMCPSetupGuide(chatmcpConfig, 'mvp');
    configs['install-chatmcp.sh'] = generateChatMCPInstaller(chatmcpConfig, 'unix');
    configs['install-chatmcp.bat'] = generateChatMCPInstaller(chatmcpConfig, 'windows');
  } else {
    console.log('🏢 Enterprise Wizard detected - generating full ChatMCP config');
    const chatmcpConfig = generateEnterpriseChatMCPConfig(wizardData);
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

// Tool to MCP Server Mapping
const TOOL_TO_MCP_MAPPING = {
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
  'figma': {
    package: 'figma-mcp',
    command: 'uvx',
    args: ['--from', 'git+https://github.com/modelcontextprotocol/servers.git', 'figma'],
    env: { 'FIGMA_ACCESS_TOKEN': '${FIGMA_ACCESS_TOKEN}' },
    description: 'Figma design file access and manipulation'
  }
};

// Extension ID to MCP Server Mapping (for enterprise wizard)
const EXTENSION_TO_MCP_MAPPING = {
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
  }
};

function detectMVPData(wizardData) {
  return wizardData && 
         (('selectedRole' in wizardData && wizardData.selectedRole) || ('role' in wizardData && wizardData.role)) && 
         (('selectedTools' in wizardData && wizardData.selectedTools) || ('tools' in wizardData && wizardData.tools)) && 
         !('extensions' in wizardData);
}

function generateMVPChatMCPConfig(mvpData) {
  const role = mvpData.selectedRole || mvpData.role || 'developer';
  const tools = mvpData.selectedTools || mvpData.tools || [];
  
  const mcpServers = {};
  
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

function generateEnterpriseChatMCPConfig(wizardData) {
  const mcpServers = {};
  
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

function generateChatMCPSetupGuide(config, type) {
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

function generateChatMCPInstaller(config, platform) {
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

function generateEnvironmentGuide(configJson) {
  const config = JSON.parse(configJson);
  const envVars = new Set();
  
  Object.values(config.mcpServers).forEach(server => {
    if (server.env) {
      Object.keys(server.env).forEach(key => envVars.add(key));
    }
  });
  
  if (envVars.size === 0) {
    return `# Environment Setup

No additional environment variables required for this agent configuration.
`;
  }
  
  const envGuides = {
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

// Sample wizard data representing a realistic user scenario
const sampleWizardData = {
  selectedRole: 'developer',
  selectedTools: ['git', 'github', 'filesystem', 'web-fetch', 'postgres', 'memory'],
  style: {
    tone: 'technical',
    responseLength: 'detailed',
    constraints: ['Always include code examples when relevant', 'Use TypeScript for complex examples']
  },
  extractedConstraints: ['Follow best practices for security', 'Document all public functions', 'Use proper error handling']
};

console.log('🎯 REAL CHATMCP DEPLOYMENT PACKAGE OUTPUT');
console.log('Sample User: Full-stack Developer with Database & Git workflow');
console.log('=' .repeat(80));

try {
  // Generate the actual package
  const configs = generateChatMCPConfigs(sampleWizardData);
  
  // Create output directory
  const outputDir = './sample-chatmcp-package';
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  console.log(`\n📂 Writing complete package to: ${outputDir}`);
  
  // Write all generated files
  Object.entries(configs).forEach(([filename, content]) => {
    const filePath = path.join(outputDir, filename);
    fs.writeFileSync(filePath, content, 'utf8');
    const size = Math.round(content.length / 1024 * 100) / 100;
    const lines = content.split('\n').length;
    console.log(`   ✅ ${filename.padEnd(25)} - ${lines.toString().padStart(3)} lines, ${size.toString().padStart(5)} KB`);
  });
  
  console.log('\n🔍 COMPLETE PACKAGE ANALYSIS:');
  console.log('-'.repeat(50));
  
  // Analyze the main config
  const config = JSON.parse(configs['chatmcp-config.json']);
  console.log(`📋 Agent Configuration:`);
  console.log(`   • Name: ${config.agentMetadata.name}`);
  console.log(`   • Role: ${config.agentMetadata.role}`);
  console.log(`   • Description: ${config.agentMetadata.description}`);
  console.log(`   • Generator: ${config.agentMetadata.generator}`);
  console.log(`   • Version: ${config.agentMetadata.version}`);
  console.log(`   • Created: ${config.agentMetadata.createdAt}`);
  
  console.log(`\n🔧 MCP Servers Configured (${Object.keys(config.mcpServers).length}):`);
  Object.entries(config.mcpServers).forEach(([name, server]) => {
    const hasEnv = server.env ? `🔐 (needs ${Object.keys(server.env).length} env var${Object.keys(server.env).length !== 1 ? 's' : ''})` : '✅ (no env vars)';
    console.log(`   • ${name.padEnd(12)}: ${server.command} ${server.args.join(' ')} ${hasEnv}`);
  });
  
  // Show environment variables needed
  const envVars = new Set();
  Object.values(config.mcpServers).forEach(server => {
    if (server.env) {
      Object.keys(server.env).forEach(key => envVars.add(key));
    }
  });
  
  if (envVars.size > 0) {
    console.log(`\n🔑 Environment Variables Required (${envVars.size}):`);
    Array.from(envVars).forEach(varName => {
      const purpose = {
        'GITHUB_PERSONAL_ACCESS_TOKEN': 'GitHub API access for repos, issues, PRs',
        'POSTGRES_CONNECTION_STRING': 'Database connection for SQL operations',
        'FIGMA_ACCESS_TOKEN': 'Figma API for design file access',
        'BRAVE_API_KEY': 'Web search capabilities'
      }[varName] || 'Custom API integration';
      console.log(`   • ${varName.padEnd(30)}: ${purpose}`);
    });
  } else {
    console.log(`\n🔓 No environment variables required - ready to use!`);
  }
  
  console.log(`\n📄 Package Contents:`);
  console.log(`   🔧 chatmcp-config.json     : Main MCP server configuration for ChatMCP`);
  console.log(`   📖 chatmcp-setup.md        : Complete setup guide with download links`);
  console.log(`   🐧 install-chatmcp.sh      : Automated Unix/macOS installer script`);
  console.log(`   🪟 install-chatmcp.bat     : Automated Windows installer script`);
  console.log(`   🔐 environment-setup.md    : Step-by-step API key configuration`);
  
  console.log(`\n🚀 User Installation Flow:`);
  console.log(`   1. Download ChatMCP app (links auto-detected for user's OS)`);
  console.log(`   2. Run installer script (installs uvx + all MCP servers)`);
  console.log(`   3. Set environment variables (guided with examples)`);
  console.log(`   4. Load config in ChatMCP settings (drag & drop JSON)`);
  console.log(`   5. Configure LLM provider (OpenAI/Anthropic/Claude/etc.)`);
  console.log(`   6. Start using fully configured AI agent!`);
  
  console.log(`\n🎯 Agent Capabilities:`);
  const capabilities = Object.keys(config.mcpServers);
  capabilities.forEach(capability => {
    const descriptions = {
      'git': 'Version control operations (commit, branch, merge, status, diff)',
      'github': 'GitHub API integration (repos, issues, PRs, releases, etc.)',
      'filesystem': 'File system access (read, write, search, organize files)',
      'web-fetch': 'HTTP requests and API calls to any web service',
      'postgres': 'Database operations (queries, schema, data manipulation)',
      'memory': 'Persistent memory across chat sessions'
    };
    console.log(`   • ${capability.padEnd(12)}: ${descriptions[capability] || 'Custom functionality'}`);
  });
  
  console.log(`\n📱 ChatMCP Platform Benefits:`);
  console.log(`   • 🚀 Purpose-built for MCP protocol (not a generic AI client)`);
  console.log(`   • ⚡ Flutter-based native performance on all platforms`);
  console.log(`   • 🌐 True cross-platform: Windows, macOS, Linux, iOS, Android`);
  console.log(`   • 🔒 Privacy-first: all data stays local, no cloud lock-in`);
  console.log(`   • 🎛️ Multiple LLM providers: OpenAI, Anthropic, local models`);
  console.log(`   • 🔄 Real-time config updates without app restart`);
  
  console.log(`\n✅ DEPLOYMENT PACKAGE COMPLETE!`);
  console.log(`📂 Package Location: ${path.resolve(outputDir)}`);
  console.log(`🎉 User has everything needed for one-click ChatMCP setup`);
  console.log(`⏱️  Expected setup time: ~5 minutes for technical users`);
  
} catch (error) {
  console.error('❌ PACKAGE GENERATION FAILED:', error.message);
  console.error('Stack:', error.stack);
  process.exit(1);
}

console.log('\n' + '='.repeat(80));
console.log('🏁 CHATMCP DEPLOYMENT PACKAGE DEMONSTRATION COMPLETE');