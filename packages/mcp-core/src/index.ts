import type { MCPServer, MCPServerType } from '@agentengine/shared-types'

// Import all server definitions
import { CORE_MCP_SERVERS } from './servers/core'
import { ALL_ENTERPRISE_SERVERS } from './servers/enterprise'
import { MCPProcessManager } from './process-manager'

// Export server collections
export { CORE_MCP_SERVERS } from './servers/core'
export * from './servers/enterprise'
export { MCPProcessManager } from './process-manager'

// Export template system
export * from './templates'
export { ENTERPRISE_TEMPLATES } from './templates/enterprise'
export { MCPTemplateManager } from './templates/template-manager'

// Web-compatible servers (safe for browser environment)
export const WEB_COMPATIBLE_SERVERS: MCPServer[] = [
  ...CORE_MCP_SERVERS.filter((server: MCPServer) => 
    server.supportedPlatforms?.includes('web') || 
    !server.supportedPlatforms?.includes('desktop')
  ),
  ...Object.values(ALL_ENTERPRISE_SERVERS).filter((server: MCPServer) => 
    server.supportedPlatforms?.includes('web')
  )
]

// Desktop-only servers (require local system access)
export const DESKTOP_ONLY_SERVERS: MCPServer[] = [
  ...CORE_MCP_SERVERS.filter((server: MCPServer) => 
    server.supportedPlatforms?.includes('desktop') && 
    !server.supportedPlatforms?.includes('web')
  ),
  ...Object.values(ALL_ENTERPRISE_SERVERS).filter((server: MCPServer) => 
    server.supportedPlatforms?.includes('desktop') && 
    !server.supportedPlatforms?.includes('web')
  )
]

// All available servers
export const ALL_MCP_SERVERS: Record<string, MCPServer> = {
  ...CORE_MCP_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {} as Record<string, MCPServer>),
  ...ALL_ENTERPRISE_SERVERS
}

export interface MCPConfig {
  servers: MCPServer[]
  globalTimeout: number
  maxConcurrentConnections: number
  retryAttempts: number
}

export class MCPManager {
  private config: MCPConfig
  private processManager: MCPProcessManager
  private enabledServers: Set<string> = new Set()

  constructor(isDesktop: boolean = false) {
    const availableServers = isDesktop 
      ? [...WEB_COMPATIBLE_SERVERS, ...DESKTOP_ONLY_SERVERS]
      : WEB_COMPATIBLE_SERVERS

    this.config = {
      servers: availableServers,
      globalTimeout: 30000,
      maxConcurrentConnections: 5,
      retryAttempts: 3
    }

    this.processManager = new MCPProcessManager()
  }

  getAvailableServers(): MCPServer[] {
    return this.config.servers
  }

  getEnabledServers(): MCPServer[] {
    return this.config.servers.filter(server => this.enabledServers.has(server.id))
  }

  async enableServer(serverId: string, authConfig?: Record<string, any>): Promise<void> {
    const server = this.config.servers.find(s => s.id === serverId)
    if (!server) {
      throw new Error(`Server ${serverId} not found`)
    }

    // Validate required authentication
    if (server.requiredAuth && server.requiredAuth.length > 0) {
      for (const auth of server.requiredAuth) {
        if (auth.required && (!authConfig || !authConfig[auth.name])) {
          throw new Error(`Required authentication missing: ${auth.name}`)
        }
      }
    }

    // Start the actual MCP server process
    const serverConfig = { ...server.config, ...authConfig }
    const started = await this.processManager.startServer(serverId, server, serverConfig)
    
    if (started) {
      this.enabledServers.add(serverId)
      server.enabled = true
      server.config = serverConfig
    } else {
      throw new Error(`Failed to start MCP server ${serverId}`)
    }
  }

  async disableServer(serverId: string): Promise<void> {
    const server = this.config.servers.find(s => s.id === serverId)
    if (!server) {
      throw new Error(`Server ${serverId} not found`)
    }

    // Stop the MCP server process
    await this.processManager.stopServer(serverId)
    
    this.enabledServers.delete(serverId)
    server.enabled = false
  }

  async executeCommand(serverId: string, command: string, args?: any[]): Promise<any> {
    if (!this.processManager.getConnectionStatus(serverId)) {
      throw new Error(`Server ${serverId} is not connected`)
    }

    try {
      // Map common commands to MCP tool calls
      switch (command) {
        case 'ping':
          const latency = await this.processManager.ping(serverId)
          return {
            serverId,
            command,
            result: 'pong',
            latency,
            timestamp: new Date().toISOString()
          }

        case 'list_tools':
          const tools = await this.processManager.listTools(serverId)
          return {
            serverId,
            command,
            result: tools,
            timestamp: new Date().toISOString()
          }

        case 'list_resources':
          const resources = await this.processManager.listResources(serverId)
          return {
            serverId,
            command,
            result: resources,
            timestamp: new Date().toISOString()
          }

        case 'call_tool':
          if (!args || args.length < 2) {
            throw new Error('call_tool requires toolName and arguments')
          }
          const [toolName, toolArgs] = args
          const toolResult = await this.processManager.callTool(serverId, toolName, toolArgs)
          return {
            serverId,
            command,
            result: toolResult,
            timestamp: new Date().toISOString()
          }

        case 'read_resource':
          if (!args || args.length < 1) {
            throw new Error('read_resource requires resource URI')
          }
          const resourceResult = await this.processManager.readResource(serverId, args[0])
          return {
            serverId,
            command,
            result: resourceResult,
            timestamp: new Date().toISOString()
          }

        default:
          throw new Error(`Unknown command: ${command}`)
      }
    } catch (error) {
      throw new Error(`Command execution failed: ${error}`)
    }
  }

  validateConfiguration(config: MCPConfig): string[] {
    const errors: string[] = []

    if (!config.servers || config.servers.length === 0) {
      errors.push('At least one server must be configured')
    }

    if (config.globalTimeout < 1000 || config.globalTimeout > 300000) {
      errors.push('Global timeout must be between 1 and 300 seconds')
    }

    if (config.maxConcurrentConnections < 1 || config.maxConcurrentConnections > 10) {
      errors.push('Max concurrent connections must be between 1 and 10')
    }

    for (const server of config.servers) {
      if (!server.id || !server.name || !server.type) {
        errors.push(`Server missing required fields: ${JSON.stringify(server)}`)
      }
    }

    return errors
  }

  getConnectionStatus(): Record<string, boolean> {
    return this.processManager.getAllConnections()
  }

  async testConnection(serverId: string): Promise<{ success: boolean, latency?: number, error?: string }> {
    try {
      const latency = await this.processManager.ping(serverId)
      return { success: true, latency }
    } catch (error) {
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' }
    }
  }

  async getServerCapabilities(serverId: string): Promise<{ tools: any[], resources: any[] }> {
    try {
      const [tools, resources] = await Promise.all([
        this.processManager.listTools(serverId),
        this.processManager.listResources(serverId)
      ])
      return { tools, resources }
    } catch (error) {
      return { tools: [], resources: [] }
    }
  }

  getConnectedServers(): string[] {
    return Array.from(this.enabledServers).filter(serverId => 
      this.processManager.getConnectionStatus(serverId)
    )
  }

  async dispose(): Promise<void> {
    await this.processManager.dispose()
    this.enabledServers.clear()
  }
}

export class ChatMCPBridge {
  constructor(private mcpManager: MCPManager) {}

  async processMessage(message: string, enabledServerIds: string[]): Promise<{
    response: string
    usedServers: string[]
    metadata: any
  }> {
    const usedServers: string[] = []
    const metadata: any = {}
    const toolResults: any[] = []
    let contextData: any[] = []

    // Step 1: Analyze message for MCP server capabilities needed
    const requiredCapabilities = this.analyzeMessageRequirements(message)
    
    // Step 2: Get available tools and resources from connected servers
    for (const serverId of enabledServerIds) {
      try {
        if (!this.mcpManager.getConnectionStatus()[serverId]) {
          continue // Skip disconnected servers
        }

        const capabilities = await this.mcpManager.getServerCapabilities(serverId)
        metadata[serverId] = {
          tools: capabilities.tools,
          resources: capabilities.resources,
          used: false
        }

        // Step 3: Execute relevant tools based on message analysis
        const relevantTools = this.findRelevantTools(capabilities.tools, requiredCapabilities, message)
        
        for (const tool of relevantTools) {
          try {
            const toolArgs = this.extractToolArguments(message, tool)
            const result = await this.mcpManager.executeCommand(serverId, 'call_tool', [tool.name, toolArgs])
            
            toolResults.push({
              serverId,
              toolName: tool.name,
              result: result.result,
              success: true
            })
            
            usedServers.push(serverId)
            metadata[serverId].used = true
            
          } catch (toolError) {
            toolResults.push({
              serverId,
              toolName: tool.name,
              error: toolError instanceof Error ? toolError.message : 'Unknown error',
              success: false
            })
          }
        }

        // Step 4: Read relevant resources
        const relevantResources = this.findRelevantResources(capabilities.resources, requiredCapabilities, message)
        
        for (const resource of relevantResources) {
          try {
            const result = await this.mcpManager.executeCommand(serverId, 'read_resource', [resource.uri])
            contextData.push({
              serverId,
              resourceUri: resource.uri,
              content: result.result,
              success: true
            })
            
            if (!usedServers.includes(serverId)) {
              usedServers.push(serverId)
              metadata[serverId].used = true
            }
            
          } catch (resourceError) {
            contextData.push({
              serverId,
              resourceUri: resource.uri,
              error: resourceError instanceof Error ? resourceError.message : 'Unknown error',
              success: false
            })
          }
        }

      } catch (error) {
        metadata[serverId] = {
          error: error instanceof Error ? error.message : 'Unknown error',
          used: false
        }
      }
    }

    // Step 5: Generate response based on tool results and context
    const response = this.generateResponse(message, toolResults, contextData, usedServers)

    return {
      response,
      usedServers: [...new Set(usedServers)], // Remove duplicates
      metadata: {
        ...metadata,
        toolResults,
        contextData,
        requiredCapabilities,
        processingTime: Date.now()
      }
    }
  }

  async injectContext(context: { filename: string; content: string }[]): Promise<void> {
    // Store context for use in message processing
    // In a more sophisticated implementation, this would inject context into individual MCP servers
    console.log(`Injected ${context.length} context documents`)
  }

  private analyzeMessageRequirements(message: string): string[] {
    const requirements: string[] = []
    const lowerMessage = message.toLowerCase()

    // File operations
    if (lowerMessage.includes('file') || lowerMessage.includes('read') || lowerMessage.includes('write') || 
        lowerMessage.includes('directory') || lowerMessage.includes('folder')) {
      requirements.push('filesystem')
    }

    // Git operations
    if (lowerMessage.includes('git') || lowerMessage.includes('commit') || lowerMessage.includes('branch') ||
        lowerMessage.includes('repository') || lowerMessage.includes('repo')) {
      requirements.push('git')
    }

    // GitHub operations
    if (lowerMessage.includes('github') || lowerMessage.includes('pull request') || lowerMessage.includes('issue')) {
      requirements.push('github')
    }

    // Database operations
    if (lowerMessage.includes('database') || lowerMessage.includes('sql') || lowerMessage.includes('query') ||
        lowerMessage.includes('postgres') || lowerMessage.includes('table')) {
      requirements.push('database')
    }

    // Web/HTTP operations
    if (lowerMessage.includes('http') || lowerMessage.includes('api') || lowerMessage.includes('request') ||
        lowerMessage.includes('fetch') || lowerMessage.includes('url')) {
      requirements.push('web')
    }

    // Search operations
    if (lowerMessage.includes('search') || lowerMessage.includes('find') || lowerMessage.includes('look')) {
      requirements.push('search')
    }

    // Memory operations
    if (lowerMessage.includes('remember') || lowerMessage.includes('store') || lowerMessage.includes('recall')) {
      requirements.push('memory')
    }

    return requirements
  }

  private findRelevantTools(tools: any[], requirements: string[], message: string): any[] {
    if (!tools || tools.length === 0) return []

    const relevant: any[] = []
    const lowerMessage = message.toLowerCase()

    for (const tool of tools) {
      const toolName = tool.name?.toLowerCase() || ''
      const toolDescription = tool.description?.toLowerCase() || ''

      // Check if tool matches requirements
      for (const requirement of requirements) {
        if (toolName.includes(requirement) || toolDescription.includes(requirement)) {
          relevant.push(tool)
          break
        }
      }

      // Check for specific tool patterns in message
      if (toolName.includes('read') && (lowerMessage.includes('read') || lowerMessage.includes('show'))) {
        relevant.push(tool)
      }
      if (toolName.includes('write') && (lowerMessage.includes('write') || lowerMessage.includes('create'))) {
        relevant.push(tool)
      }
      if (toolName.includes('list') && (lowerMessage.includes('list') || lowerMessage.includes('show'))) {
        relevant.push(tool)
      }
      if (toolName.includes('search') && lowerMessage.includes('search')) {
        relevant.push(tool)
      }
    }

    return relevant.slice(0, 3) // Limit to 3 tools per server to avoid overwhelming
  }

  private findRelevantResources(resources: any[], requirements: string[], message: string): any[] {
    if (!resources || resources.length === 0) return []

    const relevant: any[] = []
    
    for (const resource of resources) {
      const resourceUri = resource.uri?.toLowerCase() || ''
      const resourceName = resource.name?.toLowerCase() || ''

      // Check if resource matches requirements
      for (const requirement of requirements) {
        if (resourceUri.includes(requirement) || resourceName.includes(requirement)) {
          relevant.push(resource)
          break
        }
      }
    }

    return relevant.slice(0, 2) // Limit to 2 resources per server
  }

  private extractToolArguments(message: string, tool: any): any {
    // Simple argument extraction based on tool schema
    // In a real implementation, this would use NLP or structured parsing
    
    const args: any = {}
    
    if (tool.inputSchema?.properties) {
      for (const [paramName, paramSchema] of Object.entries(tool.inputSchema.properties)) {
        const schema = paramSchema as any
        
        // Extract common parameter types from message
        switch (paramName) {
          case 'path':
          case 'file_path':
          case 'directory':
            const pathMatch = message.match(/["']([^"']+)["']/)
            if (pathMatch) {
              args[paramName] = pathMatch[1]
            }
            break
            
          case 'content':
          case 'text':
          case 'data':
            // Use the message itself as content for write operations
            if (message.toLowerCase().includes('write') || message.toLowerCase().includes('create')) {
              args[paramName] = message
            }
            break
            
          case 'query':
          case 'search_term':
            // Extract quoted strings or use the whole message
            const queryMatch = message.match(/search for ["']([^"']+)["']/) || 
                              message.match(/find ["']([^"']+)["']/)
            args[paramName] = queryMatch ? queryMatch[1] : message
            break
            
          case 'limit':
          case 'count':
            const numberMatch = message.match(/\b(\d+)\b/)
            if (numberMatch) {
              args[paramName] = parseInt(numberMatch[1])
            }
            break
        }
      }
    }

    return args
  }

  private generateResponse(message: string, toolResults: any[], contextData: any[], usedServers: string[]): string {
    if (toolResults.length === 0 && contextData.length === 0) {
      return `I couldn't find any relevant tools or resources to help with: "${message}". The following servers were checked: ${usedServers.length > 0 ? usedServers.join(', ') : 'none'}.`
    }

    let response = `Processed your request: "${message}"\n\n`

    // Add tool results
    const successfulTools = toolResults.filter(result => result.success)
    const failedTools = toolResults.filter(result => !result.success)

    if (successfulTools.length > 0) {
      response += `✅ Tool Results:\n`
      for (const result of successfulTools) {
        response += `- ${result.serverId}/${result.toolName}: ${this.formatToolResult(result.result)}\n`
      }
      response += '\n'
    }

    if (failedTools.length > 0) {
      response += `❌ Failed Tools:\n`
      for (const result of failedTools) {
        response += `- ${result.serverId}/${result.toolName}: ${result.error}\n`
      }
      response += '\n'
    }

    // Add context data
    const successfulResources = contextData.filter(data => data.success)
    if (successfulResources.length > 0) {
      response += `📄 Resource Content:\n`
      for (const data of successfulResources) {
        response += `- ${data.serverId}: ${data.resourceUri}\n`
        if (data.content) {
          const preview = typeof data.content === 'string' ? 
            data.content.substring(0, 200) + (data.content.length > 200 ? '...' : '') :
            JSON.stringify(data.content).substring(0, 200) + '...'
          response += `  ${preview}\n`
        }
      }
    }

    response += `\nUsed servers: ${usedServers.join(', ')}`
    return response
  }

  private formatToolResult(result: any): string {
    if (typeof result === 'string') {
      return result.length > 100 ? result.substring(0, 100) + '...' : result
    }
    if (typeof result === 'object') {
      return JSON.stringify(result, null, 2).substring(0, 200) + '...'
    }
    return String(result)
  }

  async streamResponse(
    message: string, 
    onChunk: (chunk: string) => void,
    enabledServerIds: string[] = []
  ): Promise<void> {
    // Mock streaming response
    const response = await this.processMessage(message, enabledServerIds)
    const chunks = response.response.split(' ')
    
    for (let i = 0; i < chunks.length; i++) {
      onChunk(chunks[i] + ' ')
      // Small delay to simulate streaming
      await new Promise(resolve => setTimeout(resolve, 50))
    }
    
    onChunk('[DONE]')
  }
}