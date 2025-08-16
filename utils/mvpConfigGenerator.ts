// MVP Configuration Generator - Bulletproof configuration mechanics for beta users
// This handles the simplified MVP wizard data structure

interface MVPWizardData {
  role: 'developer' | 'creator' | 'researcher' | '';
  tools: string[];
  uploadedFiles: File[];
  extractedConstraints: string[];
  style: {
    tone: string;
    responseLength: string;
    constraints: string[];
  };
  deployment: {
    platform: string;
    configuration: any;
  };
}

// Tool mappings to MCP servers
const TOOL_TO_MCP_MAPPING: Record<string, string> = {
  // MVP Wizard Tools (direct mapping)
  'git': '@modelcontextprotocol/server-git',
  'github': '@modelcontextprotocol/server-github',
  'filesystem': '@modelcontextprotocol/server-filesystem',
  'postgres': '@modelcontextprotocol/server-postgres',
  'web-search': '@modelcontextprotocol/server-brave-search',
  'memory': '@modelcontextprotocol/server-memory',
  'figma': 'figma-mcp', // Use verified community package
  'web-fetch': '@modelcontextprotocol/server-fetch',
  'notion': '@notionhq/notion-mcp-server', // Use official Notion package
  
  // Enterprise Tools (legacy mapping)
  'code-management': '@modelcontextprotocol/server-git',
  'api-integration': '@modelcontextprotocol/server-fetch',
  'database-tools': '@modelcontextprotocol/server-postgres',
  'file-management': '@modelcontextprotocol/server-filesystem',
  'terminal-access': '@modelcontextprotocol/server-bash',
  
  // Content & Media
  'content-creation': '@modelcontextprotocol/server-fetch',
  'image-processing': '@modelcontextprotocol/server-filesystem',
  'video-tools': '@modelcontextprotocol/server-filesystem',
  'audio-editing': '@modelcontextprotocol/server-filesystem',
  'social-media': '@modelcontextprotocol/server-fetch',
  
  // Research & Data
  'research-tools': '@modelcontextprotocol/server-brave-search',
  'data-analysis': '@modelcontextprotocol/server-postgres',
  'reference-management': '@modelcontextprotocol/server-filesystem',
  'survey-tools': '@modelcontextprotocol/server-fetch',
  'academic-search': '@modelcontextprotocol/server-brave-search',
  
  // Design Tools
  'visual-design': 'figma-mcp',
  'prototyping': 'figma-mcp',
  'ui-components': 'figma-mcp'
};

// Generate bulletproof MCP configurations for MVP wizard data
export function generateMVPConfigurations(mvpData: any): Record<string, string> {
  const configs: Record<string, string> = {};
  
  try {
    // Ensure we have valid data
    const safeData = validateAndSanitizeMVPData(mvpData);
    
    // Generate platform-specific configurations
    configs['librechat'] = generateLibreChatMVPConfig(safeData);
    configs['librechat-mcp.json'] = configs['librechat'];
    
    configs['jan-ai'] = generateJanAiMVPConfig(safeData);
    configs['jan-ai-mcp.json'] = configs['jan-ai'];
    
    configs['anythingllm'] = generateAnythingLLMMVPConfig(safeData);
    configs['anythingllm-mcp.json'] = configs['anythingllm'];
    
    // Generate setup instructions
    configs['librechat-setup.md'] = generateLibreChatMVPInstructions(safeData);
    configs['jan-ai-setup.md'] = generateJanAiMVPInstructions(safeData);
    configs['anythingllm-setup.md'] = generateAnythingLLMMVPInstructions(safeData);
    
    return configs;
    
  } catch (error) {
    console.error('Configuration generation failed:', error);
    return generateFallbackConfigurations();
  }
}

// Validate and sanitize MVP data to prevent configuration errors
function validateAndSanitizeMVPData(data: any): MVPWizardData {
  // Handle both selectedRole/selectedTools (test data) and role/tools (MVP wizard data)
  const role = data?.selectedRole || data?.role;
  const tools = data?.selectedTools || data?.tools;
  
  return {
    role: ['developer', 'creator', 'researcher'].includes(role) ? role : 'developer',
    tools: Array.isArray(tools) ? tools : ['file-management'],
    uploadedFiles: Array.isArray(data?.uploadedFiles) ? data.uploadedFiles : [],
    extractedConstraints: Array.isArray(data?.extractedConstraints) ? data.extractedConstraints : [],
    style: {
      tone: data?.style?.tone || 'helpful',
      responseLength: data?.style?.responseLength || 'balanced',
      constraints: Array.isArray(data?.style?.constraints) ? data.style.constraints : []
    },
    deployment: {
      platform: data?.deployment?.platform || 'librechat',
      configuration: data?.deployment?.configuration || {}
    }
  };
}

// Generate LibreChat MCP configuration (bulletproof)
function generateLibreChatMVPConfig(data: MVPWizardData): string {
  const mcpServers: Record<string, any> = {};
  
  // Add default essential tools
  mcpServers['filesystem'] = {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
    description: 'File system access for reading and writing files'
  };
  
  // Add tools based on user selection
  data.tools.forEach((toolId: string) => {
    const mcpPackage = TOOL_TO_MCP_MAPPING[toolId];
    if (mcpPackage) {
      
      switch (toolId) {
        // MVP Tool IDs
        case 'git':
        case 'code-management':
          mcpServers['git'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-git'],
            description: 'Git repository management and version control'
          };
          break;
          
        case 'github':
          mcpServers['github'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-github'],
            env: {
              GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
            },
            description: 'GitHub API integration'
          };
          break;
          
        case 'web-fetch':
        case 'api-integration':
          mcpServers['fetch'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-fetch'],
            description: 'HTTP requests and API integration'
          };
          break;
          
        case 'web-search':
          mcpServers['brave'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-brave-search'],
            env: {
              BRAVE_API_KEY: '${BRAVE_API_KEY}'
            },
            description: 'Web search and research'
          };
          break;
          
        case 'memory':
          mcpServers['memory'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-memory'],
            description: 'Persistent memory and context'
          };
          break;
          
        case 'figma':
          mcpServers['figma'] = {
            command: 'npx',
            args: ['-y', 'figma-mcp'],
            env: {
              FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
            },
            description: 'Figma design files and components'
          };
          break;
          
        case 'filesystem':
          // Filesystem is already added by default, but update description
          mcpServers['filesystem'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-filesystem', '.'],
            description: 'File system access for reading and writing files'
          };
          break;
        case 'postgres':
        case 'database-tools':
          mcpServers['postgres'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-postgres'],
            env: {
              POSTGRES_CONNECTION_STRING: '${POSTGRES_CONNECTION_STRING}'
            },
            description: 'PostgreSQL database operations'
          };
          break;
          
        case 'research-tools':
        case 'academic-search':
          mcpServers['brave_search'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-brave-search'],
            env: {
              BRAVE_API_KEY: '${BRAVE_API_KEY}'
            },
            description: 'Web search capabilities for research'
          };
          break;
          
        case 'visual-design':
        case 'prototyping':
          mcpServers['figma'] = {
            command: 'npx',
            args: ['-y', 'figma-mcp'],
            env: {
              FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
            },
            description: 'Figma design tool integration'
          };
          break;
          
        case 'notion':
          mcpServers['notion'] = {
            command: 'npx',
            args: ['-y', '@notionhq/notion-mcp-server'],
            env: {
              NOTION_API_KEY: '${NOTION_API_KEY}'
            },
            description: 'Notion workspace integration'
          };
          break;
          
        default:
          // Generic tool mapping
          mcpServers[toolId.replace('-', '_')] = {
            command: 'npx',
            args: ['-y', mcpPackage],
            description: `${toolId.replace('-', ' ')} functionality`
          };
      }
    }
  });
  
  // Create the complete configuration
  const config = {
    mcpServers,
    agentConfig: {
      name: `${data.role} Assistant`,
      description: `AI assistant optimized for ${data.role} workflows`,
      role: data.role,
      style: {
        tone: data.style.tone,
        responseLength: data.style.responseLength,
        constraints: [
          ...data.style.constraints,
          ...data.extractedConstraints,
          `Maintain a ${data.style.tone} communication style`,
          `Provide ${data.style.responseLength} length responses`
        ]
      },
      capabilities: data.tools
    }
  };
  
  return JSON.stringify(config, null, 2);
}

// Generate Jan.ai MCP configuration
function generateJanAiMVPConfig(data: MVPWizardData): string {
  // Jan.ai uses similar MCP format but with extensions
  const baseConfig = createBaseMCPConfig(data);
  
  const janConfig = {
    extensions: {
      mcp: {
        servers: baseConfig.mcpServers,
        agentConfig: baseConfig.agentConfig
      }
    },
    modelConfig: {
      preferredModel: 'llama3.1:8b',
      fallbackModel: 'llama3.2:3b',
      temperature: 0.7,
      maxTokens: 2048
    }
  };
  
  return JSON.stringify(janConfig, null, 2);
}

// Generate AnythingLLM MCP configuration
function generateAnythingLLMMVPConfig(data: MVPWizardData): string {
  const baseConfig = createBaseMCPConfig(data);
  
  const anythingLLMConfig = {
    workspace: {
      name: `${data.role}-workspace`,
      description: `Workspace for ${data.role} with custom agent`,
      settings: {
        LLMProvider: 'native',
        AgentLLMProvider: 'native',
        hasRagEnabled: true,
        chatModel: {
          provider: 'native',
          model: 'llama3.1:8b'
        }
      },
      mcpIntegration: {
        enabled: true,
        servers: baseConfig.mcpServers,
        agentConfig: baseConfig.agentConfig
      }
    },
    agents: [{
      name: baseConfig.agentConfig.name,
      description: baseConfig.agentConfig.description,
      role: baseConfig.agentConfig.role,
      functions: Object.keys(baseConfig.mcpServers),
      prompt: `You are a ${baseConfig.agentConfig.role} assistant. ${baseConfig.agentConfig.style.constraints.join(' ')}`
    }]
  };
  
  return JSON.stringify(anythingLLMConfig, null, 2);
}

// Helper function to create base MCP config without JSON parsing
function createBaseMCPConfig(data: MVPWizardData): any {
  const mcpServers: Record<string, any> = {};
  
  // Add default essential tools
  mcpServers['filesystem'] = {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
    description: 'File system access for reading and writing files'
  };
  
  // Add tools based on user selection
  data.tools.forEach((toolId: string) => {
    const mcpPackage = TOOL_TO_MCP_MAPPING[toolId];
    if (mcpPackage) {
      
      switch (toolId) {
        case 'git':
        case 'code-management':
          mcpServers['git'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-git'],
            description: 'Git repository management'
          };
          break;
        case 'github':
          mcpServers['github'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-github'],
            env: {
              GITHUB_PERSONAL_ACCESS_TOKEN: '${GITHUB_PERSONAL_ACCESS_TOKEN}'
            },
            description: 'GitHub API integration'
          };
          break;
        case 'web-fetch':
        case 'api-integration':
          mcpServers['fetch'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-fetch'],
            description: 'HTTP requests and API calls'
          };
          break;
        case 'postgres':
        case 'database-tools':
          mcpServers['postgres'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-postgres'],
            env: {
              POSTGRES_CONNECTION_STRING: '${POSTGRES_CONNECTION_STRING}'
            },
            description: 'PostgreSQL database operations'
          };
          break;
        case 'web-search':
        case 'research-tools':
        case 'academic-search':
          mcpServers['brave'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-brave-search'],
            env: {
              BRAVE_API_KEY: '${BRAVE_API_KEY}'
            },
            description: 'Web search capabilities'
          };
          break;
        case 'figma':
        case 'visual-design':
        case 'prototyping':
        case 'ui-components':
          mcpServers['figma'] = {
            command: 'npx',
            args: ['-y', 'figma-mcp'],
            env: {
              FIGMA_ACCESS_TOKEN: '${FIGMA_ACCESS_TOKEN}'
            },
            description: 'Figma design tool integration'
          };
          break;
        case 'notion':
          mcpServers['notion'] = {
            command: 'npx',
            args: ['-y', '@notionhq/notion-mcp-server'],
            env: {
              NOTION_API_KEY: '${NOTION_API_KEY}'
            },
            description: 'Notion workspace integration'
          };
          break;
        case 'memory':
          mcpServers['memory'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-memory'],
            description: 'Persistent memory and context'
          };
          break;
        case 'filesystem':
          // Filesystem is already added by default, but update with current directory
          mcpServers['filesystem'] = {
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-filesystem', '.'],
            description: 'File system access for reading and writing files'
          };
          break;
        default:
          // Generic tool mapping for any unmapped tools
          if (mcpPackage && !mcpServers[toolId]) {
            mcpServers[toolId.replace('-', '_')] = {
              command: 'npx',
              args: ['-y', mcpPackage],
              description: `${toolId.replace('-', ' ')} functionality`
            };
          }
      }
    }
  });
  
  return {
    mcpServers,
    agentConfig: {
      name: `${data.role} Assistant`,
      description: `AI assistant optimized for ${data.role} workflows`,
      role: data.role,
      style: {
        tone: data.style.tone,
        responseLength: data.style.responseLength,
        constraints: [
          ...data.style.constraints,
          ...data.extractedConstraints,
          `Maintain a ${data.style.tone} communication style`,
          `Provide ${data.style.responseLength} length responses`
        ]
      },
      capabilities: data.tools
    }
  };
}


// Generate LibreChat setup instructions
function generateLibreChatMVPInstructions(data: MVPWizardData): string {
  const requiredPackages = Array.from(new Set(
    data.tools.map((tool: string) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)
  ));
  
  return `# LibreChat Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install LibreChat with Docker
\`\`\`bash
# Clone LibreChat repository
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat

# Copy environment template
cp .env.example .env

# Start LibreChat with Docker
docker compose up -d
\`\`\`

### Step 2: Install MCP Server Dependencies
\`\`\`bash
# Install Node.js dependencies for MCP servers
${requiredPackages.map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Step 3: Configure MCP Integration
1. Open LibreChat at http://localhost:3080
2. Create an account and sign in
3. Go to **Settings** > **Extensions**
4. Enable **MCP Support**
5. Upload your MCP configuration file

### Step 4: Set API Keys and Environment Variables
Edit your \`.env\` file to include:

\`\`\`bash
# Add your AI provider API keys
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
GOOGLE_API_KEY=your_google_key_here

# MCP server environment variables
${data.tools.includes('visual-design') || data.tools.includes('prototyping') ? `FIGMA_ACCESS_TOKEN=your_figma_token_here\n` : ''}${data.tools.includes('database-tools') ? `POSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/database\n` : ''}${data.tools.includes('research-tools') || data.tools.includes('academic-search') ? `BRAVE_API_KEY=your_brave_api_key_here\n` : ''}
\`\`\`

### Step 5: Test Your Setup
1. Restart LibreChat: \`docker compose restart\`
2. Open http://localhost:3080
3. Start a new conversation
4. Test MCP functionality: "List files in the current directory"
5. Try multiple AI providers to find your preference

## Your Assistant Configuration
- **Role**: ${data.role}
- **Communication Style**: ${data.style.tone}
- **Response Length**: ${data.style.responseLength}
- **Available Providers**: OpenAI, Anthropic, Google, and 20+ others
- **Selected Tools**: ${data.tools.length} MCP tools configured
- **Custom Constraints**: ${data.style.constraints.length + data.extractedConstraints.length} behavioral rules

## Key Features
- ✅ **Multi-user support** with role-based access control
- ✅ **20+ AI providers** - no vendor lock-in
- ✅ **Full MCP support** with UI management
- ✅ **Enterprise features** - audit logs, SSO, workspaces
- ✅ **Complete self-hosting** - your data stays private

## Troubleshooting
- Ensure Docker and Docker Compose are installed
- Check container logs: \`docker compose logs\`
- Verify API keys are correctly set in .env file
- Restart containers after configuration changes

Your LibreChat instance is now ready with your custom agent configuration!`;
}

// Generate Jan.ai setup instructions
function generateJanAiMVPInstructions(data: MVPWizardData): string {
  const requiredPackages = Array.from(new Set(
    data.tools.map((tool: string) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)
  ));
  
  return `# Jan.ai Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install Jan.ai Desktop App
1. Download Jan.ai from: https://jan.ai/download
2. Install the desktop application
3. Launch Jan.ai and complete the initial setup

### Step 2: Download AI Models
1. In Jan.ai, go to the **Hub** tab
2. Download recommended models:
   - **Llama 3.1 8B** (for general use)
   - **Llama 3.2 3B** (for faster responses)
3. Wait for models to download and install

### Step 3: Install MCP Extensions
1. Go to **Settings** > **Extensions**
2. Enable **MCP Support**
3. Install the MCP extension from the marketplace

### Step 4: Install MCP Server Dependencies
Open your terminal and install the required MCP servers:

\`\`\`bash
# Install Node.js dependencies
${requiredPackages.map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Step 5: Configure MCP Servers
1. In Jan.ai, go to **Settings** > **Extensions** > **MCP**
2. Click **Import Configuration**
3. Upload your downloaded jan-ai-mcp.json file
4. Configure environment variables as needed

### Step 6: Set Environment Variables (if needed)
${data.tools.includes('visual-design') || data.tools.includes('prototyping') ? `
**For Figma integration:**
\`\`\`bash
export FIGMA_ACCESS_TOKEN="your_figma_token_here"
\`\`\`
` : ''}${data.tools.includes('database-tools') ? `
**For Database tools:**
\`\`\`bash
export POSTGRES_CONNECTION_STRING="postgresql://user:password@localhost:5432/database"
\`\`\`
` : ''}${data.tools.includes('research-tools') || data.tools.includes('academic-search') ? `
**For Research tools:**
\`\`\`bash
export BRAVE_API_KEY="your_brave_api_key_here"
\`\`\`
` : ''}

### Step 7: Test Your Setup
1. Start a new conversation in Jan.ai
2. Test MCP functionality: "List files in the current directory"
3. Try switching between local and cloud models
4. Your assistant should now have access to all your selected tools!

## Your Assistant Configuration
- **Role**: ${data.role}
- **Communication Style**: ${data.style.tone}
- **Response Length**: ${data.style.responseLength}
- **Local + Cloud Models**: Seamless switching
- **Selected Tools**: ${data.tools.length} MCP tools configured
- **Custom Constraints**: ${data.style.constraints.length + data.extractedConstraints.length} behavioral rules

## Key Features
- ✅ **Beautiful desktop app** - no technical setup required
- ✅ **Local + API models** - switch seamlessly
- ✅ **MCP extension support** - full protocol compatibility
- ✅ **Professional development** - VC-backed with regular updates
- ✅ **Simple one-click setup** - perfect for non-technical users

## Troubleshooting
- Ensure Node.js is installed for MCP servers
- Restart Jan.ai after MCP configuration changes
- Check the Extensions tab for error messages
- Verify environment variables in Settings > Environment

Your Jan.ai assistant is now configured for your ${data.role} workflow!`;
}

// Generate AnythingLLM setup instructions
function generateAnythingLLMMVPInstructions(data: MVPWizardData): string {
  const requiredPackages = Array.from(new Set(
    data.tools.map((tool: string) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)
  ));
  
  return `# AnythingLLM Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install AnythingLLM
**Option A: Desktop App (Recommended)**
1. Download from: https://anythingllm.com/download
2. Install the desktop application
3. Launch AnythingLLM

**Option B: Docker**
\`\`\`bash
docker run -d -p 3001:3001 \\
  --cap-add SYS_ADMIN \\
  -v $(pwd)/anythingllm:/app/server/storage \\
  -v $(pwd)/anythingllm:/app/collector/hotdir \\
  --name anythingllm \\
  mintplexlabs/anythingllm
\`\`\`

### Step 2: Initial Setup
1. Open AnythingLLM (desktop app or http://localhost:3001)
2. Complete the initial setup wizard
3. Create your admin account
4. Choose your preferred LLM provider (local or API)

### Step 3: Create Your Workspace
1. Click **Create Workspace**
2. Name it: \`${data.role}-workspace\`
3. Upload your anythingllm-mcp.json configuration
4. Enable **Agent Mode** for advanced functionality

### Step 4: Install MCP Server Dependencies
\`\`\`bash
# Install Node.js dependencies for MCP integration
${requiredPackages.map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Step 5: Configure MCP Integration
1. In your workspace, go to **Settings** > **Agent Configuration**
2. Enable **MCP Support**
3. Import your MCP server configuration
4. Set up environment variables for your tools

### Step 6: Set Environment Variables
${data.tools.includes('visual-design') || data.tools.includes('prototyping') ? `
**For Figma integration:**
\`\`\`bash
FIGMA_ACCESS_TOKEN=your_figma_token_here
\`\`\`
` : ''}${data.tools.includes('database-tools') ? `
**For Database tools:**
\`\`\`bash
POSTGRES_CONNECTION_STRING=postgresql://user:password@localhost:5432/database
\`\`\`
` : ''}${data.tools.includes('research-tools') || data.tools.includes('academic-search') ? `
**For Research tools:**
\`\`\`bash
BRAVE_API_KEY=your_brave_api_key_here
\`\`\`
` : ''}

### Step 7: Test Your Custom Agent
1. Go to your workspace chat
2. Enable **Agent Mode** in the chat interface
3. Test MCP functionality: "List files in the current directory"
4. Upload documents to test RAG capabilities
5. Your custom agent should now have access to all selected tools!

## Your Assistant Configuration
- **Role**: ${data.role}
- **Communication Style**: ${data.style.tone}
- **Response Length**: ${data.style.responseLength}
- **Workspace**: Dedicated ${data.role} environment
- **Selected Tools**: ${data.tools.length} MCP tools configured
- **Custom Constraints**: ${data.style.constraints.length + data.extractedConstraints.length} behavioral rules

## Key Features
- ✅ **No-code agent builder** - perfect for business users
- ✅ **Enterprise workspace system** - organized document management
- ✅ **Advanced RAG** - upload and query your documents
- ✅ **Built-in analytics** - track usage and performance
- ✅ **Docker or desktop** - choose your deployment method

## Advanced Features
- **Document Management**: Upload PDFs, docs, and more for RAG
- **Custom Agents**: Build specialized agents for different tasks
- **Workspace Collaboration**: Share workspaces with team members
- **Analytics Dashboard**: Monitor agent performance and usage

## Troubleshooting
- Ensure Node.js is installed for MCP servers
- Check workspace settings for MCP configuration
- Verify environment variables in Agent Configuration
- Restart AnythingLLM after major configuration changes

Your AnythingLLM workspace is now configured with your custom agent!`;
}

// Generate fallback configurations if main generation fails
function generateFallbackConfigurations(): Record<string, string> {
  const fallbackConfig = {
    mcpServers: {
      filesystem: {
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        description: 'Basic file system access'
      }
    },
    agentConfig: {
      name: 'Basic AI Assistant',
      description: 'Simple AI assistant with file system access',
      role: 'assistant',
      style: {
        tone: 'helpful',
        responseLength: 'balanced',
        constraints: ['Be helpful and accurate', 'Maintain a professional tone']
      }
    }
  };
  
  return {
    'librechat': JSON.stringify(fallbackConfig, null, 2),
    'jan-ai': JSON.stringify({ extensions: { mcp: fallbackConfig } }, null, 2),
    'anythingllm': JSON.stringify({ workspace: { mcpIntegration: fallbackConfig } }, null, 2),
    'librechat-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install Docker and follow LibreChat documentation.',
    'jan-ai-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install Jan.ai desktop app and MCP extensions.',
    'anythingllm-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install AnythingLLM and configure MCP integration.'
  };
}