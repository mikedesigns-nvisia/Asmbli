import { WizardData } from '../types/wizard';

export function generateDeploymentConfigs(wizardData: WizardData, promptOutput?: string): Record<string, string> {
  const configs: Record<string, string> = {};

  // Check if this is a design-focused agent
  const hasDesignExtensions = wizardData.extensions?.some(ext => 
    ext.enabled && ['figma-mcp', 'storybook-api', 'design-tokens', 'sketch-api', 'zeplin-api', 'supabase-api'].includes(ext.id)
  );

  // Generate CORRECT MCP configurations for each platform
  configs['lm-studio'] = generateLMStudioMCPConfig(wizardData);
  configs['lm-studio-mcp.json'] = configs['lm-studio'];
  
  configs['claude-desktop'] = generateClaudeDesktopConfig(wizardData);
  configs['claude_desktop_config.json'] = configs['claude-desktop'];
  
  configs['vs-code'] = generateVSCodeMCPConfig(wizardData);
  configs['mcp.json'] = configs['vs-code'];
  
  configs['cursor'] = generateCursorMCPConfig(wizardData);
  configs['cursor-mcp.json'] = configs['cursor'];

  // Generate detailed setup instructions for each platform
  configs['lm-studio-setup.md'] = generateLMStudioSetupInstructions(wizardData);
  configs['claude-desktop-setup.md'] = generateClaudeDesktopSetupInstructions(wizardData);
  configs['vs-code-setup.md'] = generateVSCodeSetupInstructions(wizardData);
  configs['cursor-setup.md'] = generateCursorSetupInstructions(wizardData);

  // Generate MCP server configurations and installers
  const mcpConfigs = generateMcpServerConfigs(wizardData);
  Object.assign(configs, mcpConfigs);

  // Legacy configurations (keeping for enterprise deployments)
  configs['docker'] = generateDockerConfig(wizardData, hasDesignExtensions);
  configs['kubernetes'] = generateKubernetesConfig(wizardData, hasDesignExtensions);
  configs['railway'] = generateRailwayConfig(wizardData, hasDesignExtensions);
  configs['render'] = generateRenderConfig(wizardData, hasDesignExtensions);

  // Desktop Extension (.dxt) - Primary Recommendation
  const desktopExtension = {
    name: wizardData.agentName || "Custom AI Agent",
    version: "1.0.0",
    description: wizardData.agentDescription || "Custom AI agent with MCP integration",
    agent_type: hasDesignExtensions ? "design_agent" : "general_agent",
    extension_config: {
      integrations: wizardData.extensions?.filter(s => s.enabled).reduce((acc, extension) => {
        acc[extension.id] = {
          platforms: extension.selectedPlatforms,
          config: extension.config,
          security_level: extension.securityLevel,
          ...(hasDesignExtensions && extension.category === 'Design & Prototyping' && {
            design_specific: {
              sync_interval: "5m",
              auto_update_tokens: true,
              component_validation: true,
              accessibility_checks: true
            }
          })
        };
        return acc;
      }, {} as Record<string, any>) || {}
    },
    security: {
      auth_method: wizardData.security.authMethod,
      permissions: wizardData.security.permissions,
      vault_integration: wizardData.security.vaultIntegration,
      audit_logging: wizardData.security.auditLogging,
      rate_limiting: wizardData.security.rateLimiting,
      session_timeout: wizardData.security.sessionTimeout
    },
    behavior: {
      tone: wizardData.tone,
      response_length: wizardData.responseLength,
      constraints: wizardData.constraints,
      constraint_documentation: wizardData.constraintDocs
    },
    ...(hasDesignExtensions && {
      design_configuration: {
        design_system_enforcement: true,
        accessibility_validation: "wcag_2_1_aa",
        responsive_design_check: true,
        brand_consistency_validation: true,
        component_library_sync: true,
        design_token_validation: true,
        figma_file_organization: {
          enforce_naming_conventions: true,
          layer_organization: true,
          component_structure_validation: true
        }
      }
    }),
    system_prompt: promptOutput
  };
  configs.desktop = JSON.stringify(desktopExtension, null, 2);

  // Modern Platform Configurations
  configs.railway = generateRailwayConfig(wizardData, hasDesignExtensions);
  configs.render = generateRenderConfig(wizardData, hasDesignExtensions);
  configs.fly = generateFlyConfig(wizardData, hasDesignExtensions);
  configs.vercel = generateVercelConfig(wizardData, hasDesignExtensions);
  configs.cloudrun = generateCloudRunConfig(wizardData, hasDesignExtensions);

  // Traditional Container Configurations
  configs.docker = generateDockerConfig(wizardData, hasDesignExtensions);
  configs.kubernetes = generateKubernetesConfig(wizardData, hasDesignExtensions);

  // Raw JSON Configuration
  configs.json = JSON.stringify({
    agent: {
      name: wizardData.agentName,
      description: wizardData.agentDescription,
      purpose: wizardData.primaryPurpose,
      environment: wizardData.targetEnvironment,
      type: hasDesignExtensions ? "design_agent" : "general_agent"
    },
    extensions: wizardData.extensions?.filter(s => s.enabled) || [],
    security: wizardData.security,
    behavior: {
      tone: wizardData.tone,
      response_length: wizardData.responseLength,
      constraints: wizardData.constraints,
      constraint_documentation: wizardData.constraintDocs
    },
    ...(hasDesignExtensions && {
      design_capabilities: {
        figma_integration: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'figma-mcp'),
        storybook_integration: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'storybook-api'),
        design_tokens: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'design-tokens'),
        supabase_backend: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'supabase-api'),
        accessibility_enforcement: wizardData.constraints?.includes('accessibility'),
        design_system_compliance: wizardData.constraints?.includes('design-system'),
        responsive_design: wizardData.constraints?.includes('responsive-design'),
        brand_consistency: wizardData.constraints?.includes('brand-consistency')
      }
    }),
    system_prompt: promptOutput,
    test_results: wizardData.testResults,
    observability: {
      metrics: "prometheus",
      tracing: "opentelemetry",
      logging: "structured-json",
      health_endpoints: ["/health", "/ready", "/metrics"]
    }
  }, null, 2);

  // Add the legacy extension config for backward compatibility
  configs['agent_extension.json'] = JSON.stringify(desktopExtension, null, 2);

  return configs;
}

// Generate LM Studio setup instructions
function generateLMStudioSetupInstructions(wizardData: WizardData): string {
  const enabledExtensions = wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp') || [];
  const agentName = wizardData.agentName || 'Your AI Agent';
  
  return `# ${agentName} - LM Studio Setup Guide

## 🎯 What You're Getting
Your custom AI agent with these capabilities:
${enabledExtensions.map(ext => `- **${ext.name}**: ${ext.description}`).join('\n')}

## ✅ Prerequisites (5 minutes)

### 1. Install LM Studio
- Download from: https://lmstudio.ai/
- **Minimum version required: 0.3.17** (for MCP support)
- Install and launch once to verify it works

### 2. Install Node.js
- Download from: https://nodejs.org/
- Choose the LTS version (recommended)
- Verify installation: Open terminal and run \`node --version\`

## 📋 Step-by-Step Setup (10 minutes)

### Step 1: Configure MCP Servers in LM Studio

1. **Open LM Studio**
2. **Go to the Program tab** (right sidebar)
3. **Click "Install" → "Edit mcp.json"** 
4. **Copy and paste this configuration:**

\`\`\`json
${generateLMStudioMCPConfig(wizardData)}
\`\`\`

5. **Save the file** (Ctrl+S / Cmd+S)

### Step 2: Install MCP Server Dependencies

Open your terminal/command prompt and run these commands:

\`\`\`bash
# Install the required MCP servers globally
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return 'npm install -g @modelcontextprotocol/server-figma';
    case 'filesystem-mcp': case 'file-manager-mcp': return 'npm install -g @modelcontextprotocol/server-filesystem';
    case 'git-mcp': return 'npm install -g @modelcontextprotocol/server-git';
    case 'github-api': return 'npm install -g @modelcontextprotocol/server-github';
    case 'postgres-mcp': return 'npm install -g @modelcontextprotocol/server-postgres';
    case 'brave-browser': return 'npm install -g @modelcontextprotocol/server-brave-search';
    case 'memory-mcp': return 'npm install -g @modelcontextprotocol/server-memory';
    case 'fetch-mcp': return 'npm install -g @modelcontextprotocol/server-fetch';
    default: return `# ${ext.name} - check documentation for install command`;
  }
}).join('\n')}
\`\`\`

### Step 3: Configure API Keys & Environment Variables

Create a \`.env\` file in your home directory with your API keys:

\`\`\`bash
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '# Get from: https://www.figma.com/developers/api\\nFIGMA_ACCESS_TOKEN=your_figma_token_here';
    case 'github-api': return '# Get from: https://github.com/settings/tokens\\nGITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here';
    case 'postgres-mcp': return '# Your database connection string\\nPOSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname';
    case 'brave-browser': return '# Get from: https://api.search.brave.com/app/keys\\nBRAVE_API_KEY=your_brave_api_key_here';
    default: return `# ${ext.name} - check documentation for required environment variables`;
  }
}).filter(Boolean).join('\n\n')}
\`\`\`

### Step 4: Test Your Setup

1. **Restart LM Studio** completely
2. **Load any chat model** you prefer  
3. **Try these test commands:**

${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '   - "Show me the components in my Figma design file [FILE_ID]"';
    case 'filesystem-mcp': case 'file-manager-mcp': return '   - "List the files in my Documents folder"';
    case 'git-mcp': return '   - "Show me the git status of my current project"';
    case 'github-api': return '   - "Show me my recent GitHub repositories"';
    case 'brave-browser': return '   - "Search the web for React best practices"';
    case 'memory-mcp': return '   - "Remember that I prefer TypeScript for new projects"';
    case 'fetch-mcp': return '   - "Fetch the content from [URL] and summarize it"';
    default: return `   - Test ${ext.name} functionality`;
  }
}).join('\n')}

## 🔧 Troubleshooting

### "MCP Server Not Found"
- Check that Node.js is installed: \`node --version\`
- Verify MCP servers are installed globally: \`npm list -g --depth=0\`
- Restart LM Studio after installing servers

### "Permission Denied" Errors
- On macOS/Linux: Try \`sudo npm install -g [package-name]\`
- On Windows: Run Command Prompt as Administrator

### "API Key Not Working"
- Double-check your API keys are correctly formatted
- Ensure no extra spaces or characters
- Some APIs require specific token formats

### Filesystem Access Issues
- The filesystem MCP server will only access directories you specify
- Default paths: Documents, Desktop, Projects folders
- Modify the \`args\` in mcp.json to change allowed directories

## 💡 Pro Tips

1. **Start Simple**: Enable one MCP server at a time to test
2. **Security First**: Only grant filesystem access to directories you need
3. **API Limits**: Most services have rate limits - use responsibly
4. **Updates**: Keep LM Studio and MCP servers updated for best performance

## 🆘 Need Help?

- **LM Studio MCP Docs**: https://lmstudio.ai/docs/app/plugins/mcp
- **MCP Protocol Docs**: https://modelcontextprotocol.io/
- **Community Forums**: https://github.com/lmstudio-ai/lmstudio.js/discussions

---

**✅ Success!** Your ${agentName} is now ready with enhanced capabilities. The AI can now interact with your ${enabledExtensions.map(ext => ext.name.toLowerCase()).join(', ')} directly through natural conversation.`;
}

// Generate Claude Desktop setup instructions
function generateClaudeDesktopSetupInstructions(wizardData: WizardData): string {
  const enabledExtensions = wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp') || [];
  const agentName = wizardData.agentName || 'Your AI Agent';
  
  return `# ${agentName} - Claude Desktop Setup Guide

## 🎯 What You're Getting
Your custom AI agent with these capabilities:
${enabledExtensions.map(ext => `- **${ext.name}**: ${ext.description}`).join('\n')}

## ✅ Prerequisites (5 minutes)

### 1. Install Claude Desktop
- Download from: https://claude.ai/download
- Install and sign in with your Anthropic account
- Verify you can chat with Claude

### 2. Install Node.js
- Download from: https://nodejs.org/
- Choose the LTS version (recommended)
- Verify installation: Open terminal and run \`node --version\`

## 📋 Step-by-Step Setup (10 minutes)

### Step 1: Locate Claude Desktop Config File

**macOS:**
\`\`\`bash
~/Library/Application Support/Claude/claude_desktop_config.json
\`\`\`

**Windows:**
\`\`\`bash
%APPDATA%\\Claude\\claude_desktop_config.json
\`\`\`

### Step 2: Install MCP Server Dependencies

Open your terminal/command prompt and run:

\`\`\`bash
# Install the required MCP servers globally
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return 'npm install -g @modelcontextprotocol/server-figma';
    case 'filesystem-mcp': case 'file-manager-mcp': return 'npm install -g @modelcontextprotocol/server-filesystem';
    case 'git-mcp': return 'npm install -g @modelcontextprotocol/server-git';
    case 'github-api': return 'npm install -g @modelcontextprotocol/server-github';
    case 'postgres-mcp': return 'npm install -g @modelcontextprotocol/server-postgres';
    case 'brave-browser': return 'npm install -g @modelcontextprotocol/server-brave-search';
    case 'memory-mcp': return 'npm install -g @modelcontextprotocol/server-memory';
    case 'fetch-mcp': return 'npm install -g @modelcontextprotocol/server-fetch';
    default: return `# ${ext.name} - check documentation for install command`;
  }
}).join('\n')}
\`\`\`

### Step 3: Update Claude Desktop Configuration

1. **Create or edit** \`claude_desktop_config.json\`
2. **Replace the contents** with this configuration:

\`\`\`json
${generateClaudeDesktopConfig(wizardData)}
\`\`\`

3. **Save the file**

### Step 4: Configure Environment Variables

**macOS/Linux:**
Add to your \`~/.zshrc\` or \`~/.bashrc\`:

\`\`\`bash
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '# Get from: https://www.figma.com/developers/api\\nexport FIGMA_ACCESS_TOKEN="your_figma_token_here"';
    case 'github-api': return '# Get from: https://github.com/settings/tokens\\nexport GITHUB_PERSONAL_ACCESS_TOKEN="your_github_token_here"';
    case 'postgres-mcp': return '# Your database connection string\\nexport POSTGRES_CONNECTION_STRING="postgresql://user:password@localhost:5432/dbname"';
    case 'brave-browser': return '# Get from: https://api.search.brave.com/app/keys\\nexport BRAVE_API_KEY="your_brave_api_key_here"';
    default: return `# ${ext.name} - check documentation for required environment variables`;
  }
}).filter(Boolean).join('\n\n')}
\`\`\`

**Windows:**
Set system environment variables through System Properties or use PowerShell:

\`\`\`powershell
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '[Environment]::SetEnvironmentVariable("FIGMA_ACCESS_TOKEN", "your_figma_token_here", "User")';
    case 'github-api': return '[Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "your_github_token_here", "User")';
    case 'postgres-mcp': return '[Environment]::SetEnvironmentVariable("POSTGRES_CONNECTION_STRING", "postgresql://user:password@localhost:5432/dbname", "User")';
    case 'brave-browser': return '[Environment]::SetEnvironmentVariable("BRAVE_API_KEY", "your_brave_api_key_here", "User")';
    default: return `# Set ${ext.name} environment variables`;
  }
}).filter(Boolean).join('\n')}
\`\`\`

### Step 5: Test Your Setup

1. **Restart Claude Desktop** completely
2. **Start a new conversation**
3. **Try these test commands:**

${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '   - "Show me the components in my Figma design file [FILE_ID]"';
    case 'filesystem-mcp': case 'file-manager-mcp': return '   - "List the files in my Documents folder"';
    case 'git-mcp': return '   - "Show me the git status of my current project"';
    case 'github-api': return '   - "Show me my recent GitHub repositories"';
    case 'brave-browser': return '   - "Search the web for React best practices"';
    case 'memory-mcp': return '   - "Remember that I prefer TypeScript for new projects"';
    case 'fetch-mcp': return '   - "Fetch the content from [URL] and summarize it"';
    default: return `   - Test ${ext.name} functionality`;
  }
}).join('\n')}

## 🔧 Troubleshooting

### "MCP Server Connection Failed"
- Check that Node.js is installed and in PATH
- Verify MCP servers are installed globally: \`npm list -g --depth=0\`
- Restart Claude Desktop after making config changes

### "Environment Variables Not Found"
- **macOS/Linux**: Restart terminal and Claude Desktop after editing shell profile
- **Windows**: Log out and back in, or restart the application
- Verify variables are set: \`echo $FIGMA_ACCESS_TOKEN\` (Unix) or \`echo %FIGMA_ACCESS_TOKEN%\` (Windows)

### "Permission Denied" Errors
- Check file permissions on claude_desktop_config.json
- Ensure Claude Desktop has necessary permissions (especially for filesystem access)
- On macOS: Grant Full Disk Access to Claude Desktop in System Preferences

## 💡 Pro Tips

1. **Tool Confirmation**: Claude Desktop shows confirmation dialogs before executing tools
2. **Security**: Only grant access to directories and services you trust
3. **Performance**: Disable unused MCP servers to improve startup time
4. **Debugging**: Check Claude Desktop logs for detailed error messages

## 🆘 Need Help?

- **Claude Desktop Docs**: https://claude.ai/help
- **MCP Protocol Docs**: https://modelcontextprotocol.io/
- **Anthropic Support**: https://support.anthropic.com/

---

**✅ Success!** Your ${agentName} is now integrated with Claude Desktop. You can have natural conversations while Claude accesses your ${enabledExtensions.map(ext => ext.name.toLowerCase()).join(', ')} seamlessly.`;
}

// Generate VS Code setup instructions  
function generateVSCodeSetupInstructions(wizardData: WizardData): string {
  const enabledExtensions = wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp') || [];
  const agentName = wizardData.agentName || 'Your AI Agent';
  
  return `# ${agentName} - VS Code Setup Guide

## 🎯 What You're Getting
Your custom AI agent with these capabilities:
${enabledExtensions.map(ext => `- **${ext.name}**: ${ext.description}`).join('\n')}

## ✅ Prerequisites (5 minutes)

### 1. Install VS Code
- Download from: https://code.visualstudio.com/
- Install the GitHub Copilot extension (required for MCP support)
- Sign in with your GitHub account

### 2. Install Node.js
- Download from: https://nodejs.org/
- Choose the LTS version (recommended)
- Verify installation: Open terminal and run \`node --version\`

## 📋 Step-by-Step Setup (10 minutes)

### Step 1: Install MCP Server Dependencies

Open VS Code terminal (Ctrl+\` / Cmd+\`) and run:

\`\`\`bash
# Install the required MCP servers globally
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return 'npm install -g @modelcontextprotocol/server-figma';
    case 'filesystem-mcp': case 'file-manager-mcp': return 'npm install -g @modelcontextprotocol/server-filesystem';
    case 'git-mcp': return 'npm install -g @modelcontextprotocol/server-git';
    case 'github-api': return 'npm install -g @modelcontextprotocol/server-github';
    case 'postgres-mcp': return 'npm install -g @modelcontextprotocol/server-postgres';
    case 'brave-browser': return 'npm install -g @modelcontextprotocol/server-brave-search';
    case 'memory-mcp': return 'npm install -g @modelcontextprotocol/server-memory';
    case 'fetch-mcp': return 'npm install -g @modelcontextprotocol/server-fetch';
    default: return `# ${ext.name} - check documentation for install command`;
  }
}).join('\n')}
\`\`\`

### Step 2: Configure MCP Servers

Choose your setup method:

#### Option A: Workspace-Specific (Recommended)

1. **Create \`.vscode/mcp.json\`** in your project root
2. **Add this configuration:**

\`\`\`json
${generateVSCodeMCPConfig(wizardData)}
\`\`\`

#### Option B: Global User Settings

1. **Open VS Code Settings** (Ctrl+, / Cmd+,)  
2. **Search for "mcp"**
3. **Edit settings.json** and add:

\`\`\`json
{
  "github.copilot.chat.mcp": {
    "servers": ${generateVSCodeMCPConfig(wizardData)}
  }
}
\`\`\`

### Step 3: Configure Environment Variables

**Create \`.env\` file** in your project root (if using workspace setup):

\`\`\`bash
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '# Get from: https://www.figma.com/developers/api\\nFIGMA_ACCESS_TOKEN=your_figma_token_here';
    case 'github-api': return '# Get from: https://github.com/settings/tokens\\nGITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here';
    case 'postgres-mcp': return '# Your database connection string\\nPOSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname';
    case 'brave-browser': return '# Get from: https://api.search.brave.com/app/keys\\nBRAVE_API_KEY=your_brave_api_key_here';
    default: return `# ${ext.name} - check documentation for required environment variables`;
  }
}).filter(Boolean).join('\n\n')}
\`\`\`

**Or set system environment variables:**

**macOS/Linux:**
\`\`\`bash
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return 'export FIGMA_ACCESS_TOKEN="your_figma_token_here"';
    case 'github-api': return 'export GITHUB_PERSONAL_ACCESS_TOKEN="your_github_token_here"';
    case 'postgres-mcp': return 'export POSTGRES_CONNECTION_STRING="postgresql://user:password@localhost:5432/dbname"';
    case 'brave-browser': return 'export BRAVE_API_KEY="your_brave_api_key_here"';
    default: return `# Export ${ext.name} environment variables`;
  }
}).filter(Boolean).join('\n')}
\`\`\`

### Step 4: Test Your Setup

1. **Reload VS Code** (Ctrl+Shift+P → "Developer: Reload Window")
2. **Open GitHub Copilot Chat** (Ctrl+Shift+I / Cmd+Shift+I)
3. **Try these test commands:**

${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '   - "@mcp Show me the components in my Figma design file [FILE_ID]"';
    case 'filesystem-mcp': case 'file-manager-mcp': return '   - "@mcp List the files in my current workspace"';
    case 'git-mcp': return '   - "@mcp Show me the git status of this project"';
    case 'github-api': return '   - "@mcp Show me my recent GitHub repositories"';
    case 'brave-browser': return '   - "@mcp Search for React best practices"';
    case 'memory-mcp': return '   - "@mcp Remember that I prefer TypeScript for this project"';
    case 'fetch-mcp': return '   - "@mcp Fetch content from [URL] and analyze it"';
    default: return `   - "@mcp Test ${ext.name} functionality"`;
  }
}).join('\n')}

## 🔧 Troubleshooting

### "MCP Server Not Found"
- Verify Node.js is installed and accessible from VS Code terminal
- Check MCP servers are installed: \`npm list -g --depth=0\`
- Restart VS Code after installing servers

### "Environment Variables Not Working"  
- If using \`.env\` file, ensure it's in the correct directory
- For system variables, restart VS Code after setting them
- Test variables in VS Code terminal: \`echo $FIGMA_ACCESS_TOKEN\`

### "GitHub Copilot Chat Not Available"
- Ensure you have an active GitHub Copilot subscription
- Install and enable the GitHub Copilot Chat extension
- Sign in to your GitHub account in VS Code

### "Permission Errors"
- On Windows: Run VS Code as Administrator for global installs
- On macOS/Linux: Use \`sudo npm install -g\` if needed
- Check file permissions for \`.vscode/mcp.json\`

## 💡 Pro Tips

1. **Use @mcp prefix**: Start chat messages with \`@mcp\` to explicitly use MCP servers
2. **Workspace Variables**: Use \`\${workspaceFolder}\` in paths for portability
3. **Debug Mode**: Enable VS Code debug logging to troubleshoot MCP issues
4. **Performance**: Only enable MCP servers you actively use

## 🆘 Need Help?

- **VS Code MCP Docs**: https://code.visualstudio.com/docs/copilot/chat/mcp-servers  
- **GitHub Copilot Support**: https://github.com/settings/copilot
- **MCP Protocol Docs**: https://modelcontextprotocol.io/

---

**✅ Success!** Your ${agentName} is now integrated with VS Code. Use GitHub Copilot Chat with \`@mcp\` to access your ${enabledExtensions.map(ext => ext.name.toLowerCase()).join(', ')} through natural conversation.`;
}

// Generate Cursor setup instructions
function generateCursorSetupInstructions(wizardData: WizardData): string {
  const enabledExtensions = wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp') || [];
  const agentName = wizardData.agentName || 'Your AI Agent';
  
  return `# ${agentName} - Cursor Setup Guide

## 🎯 What You're Getting
Your custom AI agent with these capabilities:
${enabledExtensions.map(ext => `- **${ext.name}**: ${ext.description}`).join('\n')}

## ✅ Prerequisites (5 minutes)

### 1. Install Cursor
- Download from: https://cursor.sh/
- Install and launch the application
- Sign in or create a Cursor account

### 2. Install Node.js
- Download from: https://nodejs.org/
- Choose the LTS version (recommended)
- Verify installation: Open terminal and run \`node --version\`

## 📋 Step-by-Step Setup (10 minutes)

### Step 1: Install MCP Server Dependencies

Open Cursor terminal (Ctrl+\` / Cmd+\`) and run:

\`\`\`bash
# Install the required MCP servers globally
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return 'npm install -g @modelcontextprotocol/server-figma';
    case 'filesystem-mcp': case 'file-manager-mcp': return 'npm install -g @modelcontextprotocol/server-filesystem';
    case 'git-mcp': return 'npm install -g @modelcontextprotocol/server-git';
    case 'github-api': return 'npm install -g @modelcontextprotocol/server-github';
    case 'postgres-mcp': return 'npm install -g @modelcontextprotocol/server-postgres';
    case 'brave-browser': return 'npm install -g @modelcontextprotocol/server-brave-search';
    case 'memory-mcp': return 'npm install -g @modelcontextprotocol/server-memory';
    case 'fetch-mcp': return 'npm install -g @modelcontextprotocol/server-fetch';
    default: return `# ${ext.name} - check documentation for install command`;
  }
}).join('\n')}
\`\`\`

### Step 2: Configure MCP Servers

#### Option A: Workspace Configuration (Recommended)

1. **Create \`.cursorrules/mcp.json\`** in your project root
2. **Add this configuration:**

\`\`\`json
${generateCursorMCPConfig(wizardData)}
\`\`\`

#### Option B: Global User Settings  

1. **Open Cursor Settings** (Cmd/Ctrl + ,)
2. **Go to Extensions → MCP Servers**
3. **Add the configuration** from the file above

### Step 3: Configure Environment Variables

**Create \`.env\` file** in your project root:

\`\`\`bash
${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '# Get from: https://www.figma.com/developers/api\\nFIGMA_ACCESS_TOKEN=your_figma_token_here';
    case 'github-api': return '# Get from: https://github.com/settings/tokens\\nGITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here';
    case 'postgres-mcp': return '# Your database connection string\\nPOSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname';
    case 'brave-browser': return '# Get from: https://api.search.brave.com/app/keys\\nBRAVE_API_KEY=your_brave_api_key_here';
    default: return `# ${ext.name} - check documentation for required environment variables`;
  }
}).filter(Boolean).join('\n\n')}
\`\`\`

### Step 4: Test Your Setup

1. **Reload Cursor** (Cmd/Ctrl + Shift + P → "Developer: Reload Window")
2. **Open Cursor Chat** (Cmd/Ctrl + L)
3. **Try these test commands:**

${enabledExtensions.map(ext => {
  switch (ext.id) {
    case 'figma-mcp': return '   - "Show me the components in my Figma design file [FILE_ID]"';
    case 'filesystem-mcp': case 'file-manager-mcp': return '   - "List the files in my current workspace"';
    case 'git-mcp': return '   - "Show me the git status of this project"';
    case 'github-api': return '   - "Show me my recent GitHub repositories"';
    case 'brave-browser': return '   - "Search for React best practices"';
    case 'memory-mcp': return '   - "Remember that I prefer TypeScript for this project"';
    case 'fetch-mcp': return '   - "Fetch content from [URL] and analyze it"';
    default: return `   - "Test ${ext.name} functionality"`;
  }
}).join('\n')}

## 🔧 Troubleshooting

### "MCP Server Failed to Start"
- Check that Node.js is installed and in PATH
- Verify MCP servers are installed globally: \`npm list -g --depth=0\`
- Restart Cursor after installing new servers

### "Environment Variables Not Loading"
- Ensure \`.env\` file is in the correct workspace directory
- Restart Cursor after creating/modifying \`.env\` file
- Check file encoding (should be UTF-8)

### "Connection Timeout"
- Some MCP servers may take time to initialize
- Check Cursor's developer console for detailed errors (Help → Toggle Developer Tools)
- Verify API keys are correctly formatted

### "Permission Issues"
- On Windows: Run as Administrator for global npm installs
- On macOS: Grant necessary permissions in System Preferences
- Check that Cursor has access to your project directory

## 💡 Pro Tips

1. **Smart Integration**: Cursor automatically detects when to use MCP servers based on context
2. **Workspace Rules**: Use \`.cursorrules\` to define project-specific AI behavior
3. **Performance**: Cursor caches MCP server responses for better performance
4. **Context Awareness**: MCP servers provide additional context to Cursor's AI models

## 🆘 Need Help?

- **Cursor Documentation**: https://docs.cursor.sh/
- **MCP Protocol Docs**: https://modelcontextprotocol.io/
- **Community Support**: https://cursor.sh/community

---

**✅ Success!** Your ${agentName} is now integrated with Cursor. The AI can seamlessly access your ${enabledExtensions.map(ext => ext.name.toLowerCase()).join(', ')} while you code, providing contextual assistance based on your actual project data.`;
}

// Generate LM Studio MCP configuration (correct format)
function generateLMStudioMCPConfig(wizardData: WizardData): string {
  const mcpServers: Record<string, any> = {};
  
  // Add MCP servers based on enabled extensions using correct LM Studio format
  wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp').forEach(ext => {
    switch (ext.id) {
      case 'figma-mcp':
        mcpServers['figma'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-figma'],
          env: {
            FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'filesystem-mcp':
      case 'file-manager-mcp':
        mcpServers['filesystem'] = {
          command: 'npx',
          args: [
            '-y', 
            '@modelcontextprotocol/server-filesystem', 
            '${HOME}/Documents',
            '${HOME}/Desktop',
            '${HOME}/Projects'
          ]
        };
        break;
      
      case 'git-mcp':
        mcpServers['git'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-git']
        };
        break;
      
      case 'github-api':
        mcpServers['github'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-github'],
          env: {
            GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'postgres-mcp':
        mcpServers['postgres'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-postgres'],
          env: {
            POSTGRES_CONNECTION_STRING: '${POSTGRES_CONNECTION_STRING}'
          }
        };
        break;

      case 'brave-browser':
        mcpServers['brave'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-brave-search'],
          env: {
            BRAVE_API_KEY: '${BRAVE_API_KEY}'
          }
        };
        break;

      case 'memory-mcp':
        mcpServers['memory'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-memory']
        };
        break;

      case 'fetch-mcp':
        mcpServers['fetch'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-fetch']
        };
        break;
    }
  });

  return JSON.stringify({ mcpServers }, null, 2);
}

// Generate VS Code MCP configuration
function generateVSCodeMCPConfig(wizardData: WizardData): string {
  const mcpServers: Record<string, any> = {};
  
  wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp').forEach(ext => {
    switch (ext.id) {
      case 'figma-mcp':
        mcpServers['figma'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-figma'],
          env: {
            FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'filesystem-mcp':
      case 'file-manager-mcp':
        mcpServers['filesystem'] = {
          command: 'npx',
          args: [
            '-y', 
            '@modelcontextprotocol/server-filesystem', 
            '${workspaceFolder}'
          ]
        };
        break;
      
      case 'git-mcp':
        mcpServers['git'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-git']
        };
        break;
      
      case 'github-api':
        mcpServers['github'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-github'],
          env: {
            GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'memory-mcp':
        mcpServers['memory'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-memory']
        };
        break;

      case 'fetch-mcp':
        mcpServers['fetch'] = {
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-fetch']
        };
        break;
    }
  });

  return JSON.stringify({ mcpServers }, null, 2);
}

// Generate Cursor MCP configuration
function generateCursorMCPConfig(wizardData: WizardData): string {
  // Cursor uses the same format as VS Code but might have slight differences
  return generateVSCodeMCPConfig(wizardData);
}

// Generate Claude Desktop configuration with MCP servers
function generateClaudeDesktopConfig(wizardData: WizardData): string {
  const mcpServers: Record<string, any> = {};
  
  // Add MCP servers based on enabled extensions
  wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp').forEach(ext => {
    switch (ext.id) {
      case 'figma-mcp':
        mcpServers['figma'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-figma'],
          env: {
            FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'filesystem-mcp':
      case 'file-manager-mcp':
        mcpServers['filesystem'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-filesystem', '/path/to/allowed/directory'],
          env: {}
        };
        break;
      
      case 'git-mcp':
        mcpServers['git'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-git', '--repository-path', '/path/to/repository'],
          env: {}
        };
        break;
      
      case 'github-api':
        mcpServers['github'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-github'],
          env: {
            GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
          }
        };
        break;
      
      case 'postgres-mcp':
        mcpServers['postgres'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-postgres'],
          env: {
            POSTGRES_CONNECTION_STRING: '${POSTGRES_CONNECTION_STRING}'
          }
        };
        break;

      case 'brave-browser':
        mcpServers['brave'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-brave-search'],
          env: {
            BRAVE_API_KEY: '${BRAVE_API_KEY}'
          }
        };
        break;

      case 'gmail-api':
        mcpServers['gmail'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-gmail'],
          env: {
            GMAIL_CREDENTIALS_PATH: '${GMAIL_CREDENTIALS_PATH}'
          }
        };
        break;

      case 'slack-api':
        mcpServers['slack'] = {
          command: 'npx',
          args: ['@modelcontextprotocol/server-slack'],
          env: {
            SLACK_BOT_TOKEN: '${SLACK_BOT_TOKEN}'
          }
        };
        break;

      default:
        // Generic MCP server for unknown extensions
        mcpServers[ext.id.replace('-mcp', '')] = {
          command: 'npx',
          args: [`@modelcontextprotocol/server-${ext.id.replace('-mcp', '')}`],
          env: {}
        };
    }
  });

  const claudeConfig = {
    mcpServers,
    anthropic: {
      assistantName: wizardData.agentName || 'Custom Agent',
      assistantDescription: wizardData.agentDescription || 'Custom AI agent with MCP integration',
      systemPrompt: 'You are a helpful AI assistant with access to various tools and services.',
      features: {
        fileAccess: mcpServers.filesystem ? true : false,
        gitIntegration: mcpServers.git ? true : false,
        figmaAccess: mcpServers.figma ? true : false,
        webSearch: mcpServers.brave ? true : false
      }
    }
  };

  return JSON.stringify(claudeConfig, null, 2);
}

function generateDockerConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const dockerServices: string[] = [];
  
  if (wizardData.extensions?.some(s => s.enabled && s.category === 'database')) {
    dockerServices.push(`
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: agentdb
      POSTGRES_USER: agent_user
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U agent_user -d agentdb"]
      interval: 30s
      timeout: 10s
      retries: 3

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_storage:/qdrant/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 30s
      timeout: 10s
      retries: 3`);
  }

  // Add Supabase local development setup for design agents
  if (hasDesignExtensions && wizardData.extensions?.some(s => s.enabled && s.id === 'supabase-api')) {
    dockerServices.push(`
  supabase-db:
    image: supabase/postgres:15.1.0.117
    healthcheck:
      test: pg_isready -U postgres -h localhost
      interval: 5s
      timeout: 5s
      retries: 10
    command:
      - postgres
      - -c
      - config_file=/etc/postgresql/postgresql.conf
      - -c
      - log_min_messages=fatal
    environment:
      POSTGRES_HOST: /var/run/postgresql
      PGPORT: 5432
      POSTGRES_PORT: 5432
      PGPASSWORD: \${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}
      PGDATABASE: postgres
      POSTGRES_DB: postgres
    volumes:
      - supabase_db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  supabase-storage:
    image: supabase/storage-api:v0.40.4
    depends_on:
      supabase-db:
        condition: service_healthy
    restart: unless-stopped
    environment:
      ANON_KEY: \${ANON_KEY}
      SERVICE_KEY: \${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://supabase-rest:3000
      PGRST_JWT_SECRET: \${JWT_SECRET}
      DATABASE_URL: postgresql://postgres:\${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}@supabase-db:5432/postgres
      STORAGE_BACKEND: file
      FILE_SIZE_LIMIT: 52428800
      TENANT_ID: stub
      REGION: stub
      GLOBAL_S3_BUCKET: stub
      ENABLE_IMAGE_TRANSFORMATION: true
      IMGPROXY_URL: http://supabase-imgproxy:5001
    ports:
      - "5000:5000"
    volumes:
      - supabase_storage_data:/var/lib/storage`);
  }

  if (wizardData.security.vaultIntegration === 'hashicorp') {
    dockerServices.push(`
  vault:
    image: hashicorp/vault:latest
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: \${VAULT_ROOT_TOKEN}
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    ports:
      - "8200:8200"`);
  }

  // Add design-specific services
  if (hasDesignExtensions) {
    dockerServices.push(`
  design-token-server:
    image: tokens-studio/figma-plugin:latest
    environment:
      NODE_ENV: ${wizardData.targetEnvironment}
      TOKEN_STORAGE_TYPE: database
      DATABASE_URL: postgresql://agent_user:\${POSTGRES_PASSWORD}@postgres:5432/agentdb
    ports:
      - "3001:3001"
    depends_on:
      - postgres
    volumes:
      - ./design-tokens:/app/tokens
      - ./design-system:/app/system`);
  }

  return `# ${wizardData.agentName} - Docker Compose Configuration
version: '3.8'

networks:
  agent_network:
    driver: bridge

services:${dockerServices.join('')}

  extension-orchestrator:
    build: 
      context: .
      dockerfile: Dockerfile
    environment:
      NODE_ENV: ${wizardData.targetEnvironment}
      AGENT_NAME: "${wizardData.agentName}"
      AGENT_TYPE: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
      AUTH_METHOD: ${wizardData.security.authMethod}
      VAULT_INTEGRATION: ${wizardData.security.vaultIntegration}
      AUDIT_LOGGING: ${wizardData.security.auditLogging}
      RATE_LIMITING: ${wizardData.security.rateLimiting}
      SESSION_TIMEOUT: ${wizardData.security.sessionTimeout}${hasDesignExtensions ? `
      # Design-specific environment variables
      DESIGN_SYSTEM_VALIDATION: true
      ACCESSIBILITY_CHECKS: true
      FIGMA_SYNC_INTERVAL: "5m"
      COMPONENT_VALIDATION: true` : ''}
    volumes:
      - ./config:/app/config
      - ./logs:/app/logs${hasDesignExtensions ? `
      - ./design-system:/app/design-system
      - ./design-tokens:/app/design-tokens
      - ./component-library:/app/component-library` : ''}
    ports:
      - "8080:8080"
    depends_on:${dockerServices.length > 0 ? dockerServices.map(s => 
      s.includes('postgres:') ? '\n      - postgres' :
      s.includes('supabase-db:') ? '\n      - supabase-db' :
      s.includes('qdrant:') ? '\n      - qdrant' :
      s.includes('vault:') ? '\n      - vault' : 
      s.includes('design-token-server:') ? '\n      - design-token-server' : ''
    ).filter(Boolean).join('') : ''}
    networks:
      - agent_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:${dockerServices.includes('postgres') ? '\n  postgres_data:' : ''}${dockerServices.includes('supabase_db_data') ? '\n  supabase_db_data:\n  supabase_storage_data:' : ''}${dockerServices.includes('qdrant') ? '\n  qdrant_storage:' : ''}
  agent_logs:
  agent_config:${hasDesignExtensions ? '\n  design_system_data:\n  design_tokens_data:\n  component_library_data:' : ''}`;
}

function generateKubernetesConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${agentSlug}-agent
  labels:
    app: ${agentSlug}-agent
    version: "1.0.0"
    environment: ${wizardData.targetEnvironment}
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
spec:
  replicas: ${wizardData.targetEnvironment === 'production' ? 3 : 1}
  selector:
    matchLabels:
      app: ${agentSlug}-agent
  template:
    metadata:
      labels:
        app: ${agentSlug}-agent
        agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
    spec:
      containers:
      - name: agent-container
        image: ${agentSlug}-agent:latest
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "${wizardData.targetEnvironment}"
        - name: AGENT_NAME
          value: "${wizardData.agentName}"
        - name: AGENT_TYPE
          value: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
        - name: AUTH_METHOD
          value: "${wizardData.security.authMethod}"
        - name: VAULT_INTEGRATION
          value: "${wizardData.security.vaultIntegration}"
        - name: OTEL_SERVICE_NAME
          value: "${agentSlug}"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://opentelemetry-collector:4317"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.name=${agentSlug},service.version=1.0.0,environment=${wizardData.targetEnvironment}"
        - name: PROMETHEUS_METRICS_PORT
          value: "9090"
        - name: LOG_LEVEL
          value: "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
        - name: DESIGN_SYSTEM_VALIDATION
          value: "true"
        - name: ACCESSIBILITY_CHECKS
          value: "true"
        - name: FIGMA_SYNC_INTERVAL
          value: "5m"
        - name: COMPONENT_VALIDATION
          value: "true"` : ''}
        resources:
          requests:
            memory: "${hasDesignExtensions ? '1Gi' : '512Mi'}"
            cpu: "${hasDesignExtensions ? '500m' : '250m'}"
          limits:
            memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}" 
            cpu: "${hasDesignExtensions ? '1' : '500m'}"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config${hasDesignExtensions ? `
        - name: design-system-volume
          mountPath: /app/design-system
        - name: design-tokens-volume
          mountPath: /app/design-tokens` : ''}
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config-volume
        configMap:
          name: ${agentSlug}-config${hasDesignExtensions ? `
      - name: design-system-volume
        persistentVolumeClaim:
          claimName: ${agentSlug}-design-system-pvc
      - name: design-tokens-volume
        persistentVolumeClaim:
          claimName: ${agentSlug}-design-tokens-pvc` : ''}
---
apiVersion: v1
kind: Service
metadata:
  name: ${agentSlug}-service
  labels:
    app: ${agentSlug}-agent
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
spec:
  selector:
    app: ${agentSlug}-agent
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${agentSlug}-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"${hasDesignExtensions ? `
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"  # For design asset uploads` : ''}
spec:
  tls:
  - hosts:
    - ${agentSlug}.example.com
    secretName: ${agentSlug}-tls
  rules:
  - host: ${agentSlug}.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${agentSlug}-service
            port:
              number: 80${hasDesignExtensions ? `
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${agentSlug}-design-system-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${agentSlug}-design-tokens-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${agentSlug}-design-config
data:
  design-system.yml: |
    design_system:
      validation:
        accessibility: wcag_2_1_aa
        responsive_breakpoints:
          - mobile: 320px
          - tablet: 768px
          - desktop: 1024px
          - large: 1440px
      figma:
        sync_interval: 5m
        component_validation: true
        naming_conventions: true
      storybook:
        auto_documentation: true
        visual_testing: true
      tokens:
        auto_sync: true
        validation: strict` : ''}`;
}

function generateRailwayConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Railway Configuration
[build]
  builder = "NIXPACKS"
  buildCommand = "npm ci && npm run build"

[deploy]
  startCommand = "npm start"
  healthcheckPath = "/health"
  healthcheckTimeout = 300
  restartPolicyType = "ON_FAILURE"
  restartPolicyMaxRetries = 10

[environments.production]
  NODE_ENV = "production"
  AGENT_NAME = "${wizardData.agentName}"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  PORT = { { PORT } }
  
  # Security Configuration
  AUTH_METHOD = "${wizardData.security.authMethod}"
  VAULT_INTEGRATION = "${wizardData.security.vaultIntegration}"
  AUDIT_LOGGING = "${wizardData.security.auditLogging}"
  RATE_LIMITING = "${wizardData.security.rateLimiting}"
  SESSION_TIMEOUT = "${wizardData.security.sessionTimeout}"

  # Observability
  OTEL_SERVICE_NAME = "${agentSlug}"
  OTEL_EXPORTER_OTLP_ENDPOINT = "https://api.railway.app/v1/otel"
  LOG_LEVEL = "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
  
  # Design Agent Configuration
  DESIGN_SYSTEM_VALIDATION = "true"
  ACCESSIBILITY_CHECKS = "true"
  FIGMA_SYNC_INTERVAL = "5m"
  COMPONENT_VALIDATION = "true"` : ''}

[environments.staging]
  NODE_ENV = "staging"
  AGENT_NAME = "${wizardData.agentName}-staging"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  
[networking]
  serviceName = "${agentSlug}"
  servicePort = 8080`;
}

function generateRenderConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Render Blueprint
services:
  - type: web
    name: ${agentSlug}
    runtime: node
    plan: ${wizardData.targetEnvironment === 'production' ? 'standard' : 'starter'}
    buildCommand: npm ci && npm run build
    startCommand: npm start
    healthCheckPath: /health
    
    envVars:
      - key: NODE_ENV
        value: ${wizardData.targetEnvironment}
      - key: AGENT_NAME
        value: ${wizardData.agentName}
      - key: AGENT_TYPE
        value: ${hasDesignExtensions ? 'design_agent' : 'general_agent'}
      - key: AUTH_METHOD
        value: ${wizardData.security.authMethod}
      - key: VAULT_INTEGRATION
        value: ${wizardData.security.vaultIntegration}
      - key: AUDIT_LOGGING
        value: ${wizardData.security.auditLogging}
      - key: RATE_LIMITING
        value: ${wizardData.security.rateLimiting}
      - key: SESSION_TIMEOUT
        value: ${wizardData.security.sessionTimeout}
      - key: OTEL_SERVICE_NAME
        value: ${agentSlug}
      - key: LOG_LEVEL
        value: ${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}${hasDesignExtensions ? `
      - key: DESIGN_SYSTEM_VALIDATION
        value: "true"
      - key: ACCESSIBILITY_CHECKS
        value: "true"
      - key: FIGMA_SYNC_INTERVAL
        value: "5m"
      - key: COMPONENT_VALIDATION
        value: "true"` : ''}

${wizardData.extensions?.some(ext => ext.enabled && ext.category === 'database') ? `databases:
  - name: ${agentSlug}-postgres
    databaseName: ${agentSlug}
    user: ${agentSlug}_user
    plan: starter` : ''}`;
}

function generateFlyConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Fly.io Configuration
app = "${agentSlug}"
primary_region = "sea"
kill_signal = "SIGINT"
kill_timeout = "5s"

[experimental]
  auto_rollback = true

[build]

[deploy]
  release_command = "npm run db:migrate"

[env]
  NODE_ENV = "${wizardData.targetEnvironment}"
  AGENT_NAME = "${wizardData.agentName}"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  AUTH_METHOD = "${wizardData.security.authMethod}"
  VAULT_INTEGRATION = "${wizardData.security.vaultIntegration}"
  AUDIT_LOGGING = "${wizardData.security.auditLogging}"
  RATE_LIMITING = "${wizardData.security.rateLimiting}"
  SESSION_TIMEOUT = "${wizardData.security.sessionTimeout}"
  OTEL_SERVICE_NAME = "${agentSlug}"
  LOG_LEVEL = "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
  DESIGN_SYSTEM_VALIDATION = "true"
  ACCESSIBILITY_CHECKS = "true"
  FIGMA_SYNC_INTERVAL = "5m"
  COMPONENT_VALIDATION = "true"` : ''}

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = ${wizardData.targetEnvironment === 'production' ? 1 : 0}
  processes = ["app"]

  [http_service.checks]
    [http_service.checks.health]
      grace_period = "10s"
      interval = "30s"
      method = "GET"
      timeout = "5s"
      path = "/health"

[[vm]]
  memory = "${hasDesignExtensions ? '1gb' : '512mb'}"
  cpu_kind = "shared"
  cpus = ${hasDesignExtensions ? 2 : 1}

[metrics]
  port = 9091
  path = "/metrics"`;
}

function generateVercelConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return JSON.stringify({
    name: agentSlug,
    version: 2,
    builds: [
      {
        src: "package.json",
        use: "@vercel/node",
        config: {
          maxLambdaSize: hasDesignExtensions ? "50mb" : "25mb"
        }
      }
    ],
    routes: [
      {
        src: "/health",
        dest: "/api/health"
      },
      {
        src: "/metrics",
        dest: "/api/metrics"
      },
      {
        src: "/(.*)",
        dest: "/api/agent"
      }
    ],
    env: {
      NODE_ENV: wizardData.targetEnvironment,
      AGENT_NAME: wizardData.agentName,
      AGENT_TYPE: hasDesignExtensions ? 'design_agent' : 'general_agent',
      AUTH_METHOD: wizardData.security.authMethod,
      VAULT_INTEGRATION: wizardData.security.vaultIntegration,
      AUDIT_LOGGING: wizardData.security.auditLogging,
      RATE_LIMITING: wizardData.security.rateLimiting,
      SESSION_TIMEOUT: wizardData.security.sessionTimeout,
      OTEL_SERVICE_NAME: agentSlug,
      LOG_LEVEL: wizardData.targetEnvironment === 'production' ? 'info' : 'debug',
      ...(hasDesignExtensions && {
        DESIGN_SYSTEM_VALIDATION: "true",
        ACCESSIBILITY_CHECKS: "true",
        FIGMA_SYNC_INTERVAL: "5m",
        COMPONENT_VALIDATION: "true"
      })
    },
    functions: {
      "api/agent.js": {
        runtime: "nodejs18.x",
        maxDuration: hasDesignExtensions ? 30 : 10
      }
    },
    regions: ["sea1", "iad1", "fra1"]
  }, null, 2);
}

function generateCloudRunConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Google Cloud Run Configuration
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ${agentSlug}
  labels:
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/execution-environment: gen2
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "${wizardData.targetEnvironment === 'production' ? '1' : '0'}"
        autoscaling.knative.dev/maxScale: "${wizardData.targetEnvironment === 'production' ? '10' : '3'}"
        run.googleapis.com/cpu-throttling: "false"
        run.googleapis.com/memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}"
        run.googleapis.com/cpu: "${hasDesignExtensions ? '2' : '1'}"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
      serviceAccountName: ${agentSlug}-sa
      containers:
      - name: agent
        image: gcr.io/PROJECT_ID/${agentSlug}:latest
        ports:
        - name: http1
          containerPort: 8080
        env:
        - name: NODE_ENV
          value: "${wizardData.targetEnvironment}"
        - name: AGENT_NAME
          value: "${wizardData.agentName}"
        - name: AGENT_TYPE
          value: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
        - name: AUTH_METHOD
          value: "${wizardData.security.authMethod}"
        - name: VAULT_INTEGRATION
          value: "${wizardData.security.vaultIntegration}"
        - name: AUDIT_LOGGING
          value: "${wizardData.security.auditLogging}"
        - name: RATE_LIMITING
          value: "${wizardData.security.rateLimiting}"
        - name: SESSION_TIMEOUT
          value: "${wizardData.security.sessionTimeout}"
        - name: GOOGLE_CLOUD_PROJECT
          value: "PROJECT_ID"
        - name: OTEL_SERVICE_NAME
          value: "${agentSlug}"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "https://cloudtrace.googleapis.com/v1/projects/PROJECT_ID/traces"
        - name: LOG_LEVEL
          value: "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
        - name: DESIGN_SYSTEM_VALIDATION
          value: "true"
        - name: ACCESSIBILITY_CHECKS
          value: "true"
        - name: FIGMA_SYNC_INTERVAL
          value: "5m"
        - name: COMPONENT_VALIDATION
          value: "true"` : ''}
        resources:
          limits:
            cpu: "${hasDesignExtensions ? '2000m' : '1000m'}"
            memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}"
          requests:
            cpu: "${hasDesignExtensions ? '1000m' : '500m'}"
            memory: "${hasDesignExtensions ? '1Gi' : '512Mi'}"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
  traffic:
  - percent: 100
    latestRevision: true`;
}

// Generate individual MCP server configuration files
function generateMcpServerConfigs(wizardData: WizardData): Record<string, string> {
  const configs: Record<string, string> = {};
  
  // Filter to only MCP-compatible extensions
  const mcpExtensions = wizardData.extensions?.filter(ext => ext.enabled && ext.connectionType === 'mcp') || [];
  
  mcpExtensions.forEach(ext => {
    switch (ext.id) {
      case 'figma-mcp':
        configs['mcp-figma-server.js'] = `#!/usr/bin/env node
/**
 * Figma MCP Server for ${wizardData.agentName}
 * Provides access to Figma files and design tokens
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

const FIGMA_ACCESS_TOKEN = process.env.FIGMA_ACCESS_TOKEN;

if (!FIGMA_ACCESS_TOKEN) {
  console.error('FIGMA_ACCESS_TOKEN environment variable is required');
  process.exit(1);
}

const server = new Server(
  {
    name: 'figma-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      resources: {},
      tools: {}
    }
  }
);

// Tool to get Figma file details
server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'get_figma_file',
      description: 'Get Figma file details and components',
      inputSchema: {
        type: 'object',
        properties: {
          fileKey: { type: 'string', description: 'Figma file key' }
        },
        required: ['fileKey']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  if (name === 'get_figma_file') {
    const response = await fetch(\`https://api.figma.com/v1/files/\${args.fileKey}\`, {
      headers: {
        'X-Figma-Token': FIGMA_ACCESS_TOKEN
      }
    });
    
    const data = await response.json();
    return {
      content: [{
        type: 'text',
        text: JSON.stringify(data, null, 2)
      }]
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);`;
        break;

      case 'filesystem-mcp':
      case 'file-manager-mcp':
        configs['mcp-filesystem-server.js'] = `#!/usr/bin/env node
/**
 * Filesystem MCP Server for ${wizardData.agentName}
 * Provides secure file system access
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const fs = require('fs').promises;
const path = require('path');

const ALLOWED_PATHS = process.env.ALLOWED_PATHS ? process.env.ALLOWED_PATHS.split(':') : [process.cwd()];

const server = new Server(
  {
    name: 'filesystem-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      resources: {},
      tools: {}
    }
  }
);

server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'read_file',
      description: 'Read file contents',
      inputSchema: {
        type: 'object',
        properties: {
          path: { type: 'string', description: 'File path to read' }
        },
        required: ['path']
      }
    },
    {
      name: 'write_file',
      description: 'Write file contents',
      inputSchema: {
        type: 'object',
        properties: {
          path: { type: 'string', description: 'File path to write' },
          content: { type: 'string', description: 'Content to write' }
        },
        required: ['path', 'content']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  const isPathAllowed = (filePath) => {
    const resolved = path.resolve(filePath);
    return ALLOWED_PATHS.some(allowed => resolved.startsWith(path.resolve(allowed)));
  };
  
  if (name === 'read_file') {
    if (!isPathAllowed(args.path)) {
      throw new Error('Path not allowed');
    }
    
    const content = await fs.readFile(args.path, 'utf8');
    return {
      content: [{
        type: 'text',
        text: content
      }]
    };
  }
  
  if (name === 'write_file') {
    if (!isPathAllowed(args.path)) {
      throw new Error('Path not allowed');
    }
    
    await fs.writeFile(args.path, args.content, 'utf8');
    return {
      content: [{
        type: 'text',
        text: \`File written successfully to \${args.path}\`
      }]
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);`;
        break;

      case 'git-mcp':
        configs['mcp-git-server.js'] = `#!/usr/bin/env node
/**
 * Git MCP Server for ${wizardData.agentName}
 * Provides Git repository operations
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { execSync } = require('child_process');

const server = new Server(
  {
    name: 'git-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      resources: {},
      tools: {}
    }
  }
);

server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'git_status',
      description: 'Get Git repository status',
      inputSchema: {
        type: 'object',
        properties: {}
      }
    },
    {
      name: 'git_commit',
      description: 'Create a Git commit',
      inputSchema: {
        type: 'object',
        properties: {
          message: { type: 'string', description: 'Commit message' }
        },
        required: ['message']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  
  if (name === 'git_status') {
    const output = execSync('git status --porcelain', { encoding: 'utf8' });
    return {
      content: [{
        type: 'text',
        text: output || 'Working tree clean'
      }]
    };
  }
  
  if (name === 'git_commit') {
    execSync(\`git add . && git commit -m "\${args.message}"\`, { encoding: 'utf8' });
    return {
      content: [{
        type: 'text',
        text: \`Committed with message: \${args.message}\`
      }]
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);`;
        break;
    }
  });
  
  // Add environment configuration
  configs['.env.mcp'] = mcpExtensions.map(ext => {
    switch (ext.id) {
      case 'figma-mcp':
        return 'FIGMA_ACCESS_TOKEN=your_figma_token_here';
      case 'github-api':
        return 'GITHUB_PERSONAL_ACCESS_TOKEN=your_github_token_here';
      case 'postgres-mcp':
        return 'POSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/dbname';
      case 'brave-browser':
        return 'BRAVE_API_KEY=your_brave_api_key_here';
      case 'gmail-api':
        return 'GMAIL_CREDENTIALS_PATH=/path/to/gmail/credentials.json';
      case 'slack-api':
        return 'SLACK_BOT_TOKEN=your_slack_bot_token_here';
      case 'filesystem-mcp':
      case 'file-manager-mcp':
        return 'ALLOWED_PATHS=/path/to/allowed/directory:/another/allowed/path';
      default:
        return `# Configuration for ${ext.id}`;
    }
  }).join('\n');
  
  // Add setup instructions
  configs['MCP_SETUP.md'] = `# MCP Server Setup for ${wizardData.agentName}

## Overview
This agent uses Model Context Protocol (MCP) servers to provide enhanced capabilities.

## Enabled MCP Servers
${mcpExtensions.map(ext => `- **${ext.name}**: ${ext.description}`).join('\n')}

## Setup Instructions

### 1. Install Dependencies
\\\`\\\`\\\`bash
npm install @modelcontextprotocol/sdk
\\\`\\\`\\\`

### 2. Configure Environment Variables
Copy the \`.env.mcp\` file and update with your actual credentials:
\\\`\\\`\\\`bash
cp .env.mcp .env
# Edit .env with your actual API keys and credentials
\\\`\\\`\\\`

### 3. For Claude Desktop Integration
Add the configuration from \`claude_desktop_config.json\` to your Claude Desktop settings:

**macOS**: \`~/Library/Application Support/Claude/claude_desktop_config.json\`
**Windows**: \`%APPDATA%\\Claude\\claude_desktop_config.json\`

### 4. For Docker Deployment
Use the provided \`docker-compose.yml\` to run with Docker:
\\\`\\\`\\\`bash
docker-compose up -d
\\\`\\\`\\\`

### 5. For Kubernetes Deployment
Apply the Kubernetes configuration:
\\\`\\\`\\\`bash
kubectl apply -f kubernetes-deployment.yaml
\\\`\\\`\\\`

## Security Notes
- Store all API keys and credentials securely
- Use environment variables, never hardcode credentials
- Restrict filesystem access to necessary directories only
- Enable audit logging in production environments

## Testing MCP Servers
Each MCP server can be tested individually:
\\\`\\\`\\\`bash
node mcp-figma-server.js
node mcp-filesystem-server.js
node mcp-git-server.js
\\\`\\\`\\\`
`;
  
  return configs;
}