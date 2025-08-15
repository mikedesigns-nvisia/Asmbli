// MVP Configuration Generator - Bulletproof configuration mechanics for beta users
// This handles the simplified MVP wizard data structure
// Tool mappings to MCP servers
const TOOL_TO_MCP_MAPPING = {
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
export function generateMVPConfigurations(mvpData) {
    const configs = {};
    try {
        // Ensure we have valid data
        const safeData = validateAndSanitizeMVPData(mvpData);
        // Generate platform-specific configurations
        configs['lm-studio'] = generateLMStudioMVPConfig(safeData);
        configs['lm-studio-mcp.json'] = configs['lm-studio'];
        configs['ollama'] = generateOllamaMVPConfig(safeData);
        configs['ollama-mcp.json'] = configs['ollama'];
        configs['vs-code'] = generateVSCodeMVPConfig(safeData);
        configs['vs-code-mcp.json'] = configs['vs-code'];
        // Generate setup instructions
        configs['lm-studio-setup.md'] = generateLMStudioMVPInstructions(safeData);
        configs['ollama-setup.md'] = generateOllamaMVPInstructions(safeData);
        configs['vs-code-setup.md'] = generateVSCodeMVPInstructions(safeData);
        return configs;
    }
    catch (error) {
        console.error('Configuration generation failed:', error);
        return generateFallbackConfigurations();
    }
}
// Validate and sanitize MVP data to prevent configuration errors
function validateAndSanitizeMVPData(data) {
    return {
        role: ['developer', 'creator', 'researcher'].includes(data?.selectedRole || data?.role) ? (data.selectedRole || data.role) : 'developer',
        tools: Array.isArray(data?.selectedTools) ? data.selectedTools : Array.isArray(data?.tools) ? data.tools : ['file-management'],
        uploadedFiles: Array.isArray(data?.uploadedFiles) ? data.uploadedFiles : [],
        extractedConstraints: Array.isArray(data?.extractedConstraints) ? data.extractedConstraints : [],
        style: {
            tone: data?.style?.tone || 'helpful',
            responseLength: data?.style?.responseLength || 'balanced',
            constraints: Array.isArray(data?.style?.constraints) ? data.style.constraints : []
        },
        deployment: {
            platform: data?.deployment?.platform || 'lm-studio',
            configuration: data?.deployment?.configuration || {}
        }
    };
}
// Generate LM Studio MCP configuration (bulletproof)
function generateLMStudioMVPConfig(data) {
    const mcpServers = {};
    // Add default essential tools
    mcpServers['filesystem'] = {
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        description: 'File system access for reading and writing files'
    };
    // Add tools based on user selection
    data.tools.forEach((toolId) => {
        const mcpPackage = TOOL_TO_MCP_MAPPING[toolId];
        if (mcpPackage) {
            const serverName = toolId.replace('-', '_');
            switch (toolId) {
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
                    mcpServers[serverName] = {
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
// Generate Ollama MCP configuration
function generateOllamaMVPConfig(data) {
    // Ollama uses the same MCP format as LM Studio
    return generateLMStudioMVPConfig(data);
}
// Helper function to create base MCP config without JSON parsing
function createBaseMCPConfigJS(data) {
    const mcpServers = {};
    
    // Add default essential tools
    mcpServers['filesystem'] = {
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        description: 'File system access for reading and writing files'
    };
    
    // Add tools based on user selection
    data.tools.forEach((toolId) => {
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

// Generate VS Code MCP configuration
function generateVSCodeMVPConfig(data) {
    const config = createBaseMCPConfigJS(data);
    // VS Code specific adjustments
    config.workspaceConfig = {
        "mcp.servers": config.mcpServers,
        "mcp.agentConfig": config.agentConfig
    };
    return JSON.stringify(config.workspaceConfig, null, 2);
}
// Generate LM Studio setup instructions
function generateLMStudioMVPInstructions(data) {
    const requiredPackages = Array.from(new Set(data.tools.map((tool) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)));
    return `# LM Studio Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install LM Studio
1. Download LM Studio from: https://lmstudio.ai/download
2. Install and launch LM Studio
3. Download a local model (recommended: Llama 3.1 8B)

### Step 2: Install MCP Server Dependencies
Open your terminal and install the required MCP servers:

\`\`\`bash
# Install Node.js dependencies
${requiredPackages.map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Step 3: Configure MCP Servers
1. In LM Studio, go to **Settings** > **Developer**
2. Enable **MCP Servers**
3. Click **Edit mcp.json**
4. Replace the contents with your downloaded configuration
5. Save and restart LM Studio

### Step 4: Set Environment Variables (if needed)
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

### Step 5: Test Your Setup
1. Open LM Studio
2. Start a chat with your local model
3. Test an MCP command like: "List files in the current directory"
4. Your assistant should now have access to all your selected tools!

## Your Assistant Configuration
- **Role**: ${data.role}
- **Communication Style**: ${data.style.tone}
- **Response Length**: ${data.style.responseLength}
- **Selected Tools**: ${data.tools.length} tools configured
- **Custom Constraints**: ${data.style.constraints.length + data.extractedConstraints.length} behavioral rules

## Troubleshooting
- If MCP servers don't work, ensure Node.js is installed: https://nodejs.org
- Restart LM Studio after configuration changes
- Check the developer console for error messages
- Verify environment variables are set correctly

Your AI assistant is now configured with your exact preferences and tools!`;
}
// Generate Ollama setup instructions
function generateOllamaMVPInstructions(data) {
    const requiredPackages = Array.from(new Set(data.tools.map((tool) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)));
    return `# Ollama Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install Ollama
\`\`\`bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a recommended model
ollama pull llama3.1:8b
\`\`\`

### Step 2: Install MCP Bridge
\`\`\`bash
# Install the MCP bridge for Ollama
npm install -g @modelcontextprotocol/ollama-bridge

# Install required MCP servers
${requiredPackages.map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Step 3: Create MCP Configuration
1. Create a file called \`mcp-config.json\` in your project directory
2. Copy your downloaded configuration into this file
3. Start the MCP bridge:

\`\`\`bash
mcp-bridge --config mcp-config.json --ollama-model llama3.1:8b
\`\`\`

### Step 4: Set Environment Variables (if needed)
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
` : ''}

### Step 5: Test Your Setup
\`\`\`bash
# Test with a simple query
curl -X POST http://localhost:11434/api/generate \\
  -d '{"model":"llama3.1:8b","prompt":"List files in current directory","stream":false}'
\`\`\`

Your ${data.role} assistant is now ready with all your selected tools!`;
}
// Generate VS Code setup instructions
function generateVSCodeMVPInstructions(data) {
    return `# VS Code + GitHub Copilot Setup Instructions

## Quick Setup for ${data.role.charAt(0).toUpperCase() + data.role.slice(1)}

### Step 1: Install VS Code
1. Download from: https://code.visualstudio.com/download
2. Install VS Code

### Step 2: Install GitHub Copilot
1. Install the GitHub Copilot extension
2. Sign in with your GitHub account
3. Ensure you have an active Copilot subscription

### Step 3: Install MCP Extension
1. Search for "MCP" in the VS Code extension marketplace
2. Install the Model Context Protocol extension
3. Reload VS Code

### Step 4: Configure MCP Servers
1. Open VS Code settings (Ctrl+,)
2. Search for "MCP"
3. Click "Edit in settings.json"
4. Add your MCP configuration from the downloaded file

### Step 5: Install Required Packages
Open the VS Code terminal and run:
\`\`\`bash
${Array.from(new Set(data.tools.map((tool) => TOOL_TO_MCP_MAPPING[tool]).filter(Boolean)))
        .map(pkg => `npm install -g ${pkg}`).join('\n')}
\`\`\`

### Your Assistant Configuration
- **Role**: ${data.role}
- **Style**: ${data.style.tone}, ${data.style.responseLength} responses
- **Tools**: ${data.tools.join(', ')}
- **Custom Rules**: ${data.style.constraints.length + data.extractedConstraints.length} constraints

Your VS Code assistant is configured for your ${data.role} workflow!`;
}
// Generate fallback configurations if main generation fails
function generateFallbackConfigurations() {
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
        'lm-studio': JSON.stringify(fallbackConfig, null, 2),
        'ollama': JSON.stringify(fallbackConfig, null, 2),
        'vs-code': JSON.stringify({ "mcp.servers": fallbackConfig.mcpServers }, null, 2),
        'lm-studio-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install Node.js and MCP servers manually.',
        'ollama-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install Ollama and MCP bridge manually.',
        'vs-code-setup.md': '# Basic Setup\n\nA basic configuration has been generated. Please install VS Code and MCP extension manually.'
    };
}
