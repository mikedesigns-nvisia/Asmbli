import type { MCPServer, MCPServerType } from '@agentengine/shared-types'

// Import all server definitions
import { CORE_MCP_SERVERS } from './servers/core'
import { ALL_ENTERPRISE_SERVERS } from './servers/enterprise'

// Export server collections
export { CORE_MCP_SERVERS } from './servers/core'
export * from './servers/enterprise'

// Web-compatible servers (safe for browser environment)
export const WEB_COMPATIBLE_SERVERS: MCPServer[] = [
  ...CORE_MCP_SERVERS.filter(server => 
    server.supportedPlatforms?.includes('web') || 
    !server.supportedPlatforms?.includes('desktop')
  ),
  ...Object.values(ALL_ENTERPRISE_SERVERS).filter(server => 
    server.supportedPlatforms?.includes('web')
  )
]

// Desktop-only servers (require local system access)
export const DESKTOP_ONLY_SERVERS: MCPServer[] = [
  ...CORE_MCP_SERVERS.filter(server => 
    server.supportedPlatforms?.includes('desktop') && 
    !server.supportedPlatforms?.includes('web')
  ),
  ...Object.values(ALL_ENTERPRISE_SERVERS).filter(server => 
    server.supportedPlatforms?.includes('desktop') && 
    !server.supportedPlatforms?.includes('web')
  )
]

// All available servers
export const ALL_MCP_SERVERS = {
  ...CORE_MCP_SERVERS.reduce((acc, server) => ({ ...acc, [server.id]: server }), {}),
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
  private connectedServers: Map<string, any> = new Map()

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
  }

  getAvailableServers(): MCPServer[] {
    return this.config.servers
  }

  getEnabledServers(): MCPServer[] {
    return this.config.servers.filter(server => server.enabled)
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

    server.enabled = true
    server.config = { ...server.config, ...authConfig }
    
    // In a real implementation, this would establish the MCP connection
    this.connectedServers.set(serverId, { connected: true, config: server.config })
  }

  async disableServer(serverId: string): Promise<void> {
    const server = this.config.servers.find(s => s.id === serverId)
    if (!server) {
      throw new Error(`Server ${serverId} not found`)
    }

    server.enabled = false
    this.connectedServers.delete(serverId)
  }

  async executeCommand(serverId: string, command: string, args?: any[]): Promise<any> {
    if (!this.connectedServers.has(serverId)) {
      throw new Error(`Server ${serverId} is not connected`)
    }

    // Mock implementation - in production this would send MCP protocol messages
    return {
      serverId,
      command,
      args,
      result: `Mock result for ${command} on ${serverId}`,
      timestamp: new Date().toISOString()
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
    const status: Record<string, boolean> = {}
    for (const server of this.config.servers) {
      status[server.id] = this.connectedServers.has(server.id)
    }
    return status
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

    // In a real implementation, this would:
    // 1. Parse the message for tool/server requirements
    // 2. Execute relevant MCP commands
    // 3. Aggregate results
    // 4. Format response

    // Mock implementation
    for (const serverId of enabledServerIds) {
      try {
        const result = await this.mcpManager.executeCommand(serverId, 'process_message', [message])
        usedServers.push(serverId)
        metadata[serverId] = result
      } catch (error) {
        console.warn(`Failed to process message with ${serverId}:`, error)
      }
    }

    return {
      response: `Processed message: "${message}" using servers: ${usedServers.join(', ')}`,
      usedServers,
      metadata
    }
  }

  async injectContext(context: { filename: string; content: string }[]): Promise<void> {
    // In production, this would inject document context into the MCP session
    console.log('Injecting context:', context.map(c => c.filename))
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