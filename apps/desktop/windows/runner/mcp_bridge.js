#!/usr/bin/env node

/**
 * MCP Bridge Script for Flutter Desktop
 * Interfaces between C++ method channel plugin and TypeScript MCP core
 */

const fs = require('fs');
const path = require('path');

// Import the MCP core functionality  
const mcpCorePath = path.resolve(__dirname, '../../../../packages/mcp-core/dist');
let MCPManager, ChatMCPBridge;

try {
  // Try to load compiled TypeScript modules
  const mcpCore = require(path.join(mcpCorePath, 'index.js'));
  MCPManager = mcpCore.MCPManager;
  ChatMCPBridge = mcpCore.ChatMCPBridge;
  console.error('✓ MCP Core modules loaded successfully');
} catch (error) {
  console.error('✗ Failed to load MCP core modules:', error.message);
  console.error('Attempting to build TypeScript modules...');
  
  // Try to build the TypeScript modules
  const { execSync } = require('child_process');
  try {
    const buildCommand = `cd "${path.resolve(__dirname, '../../../../../packages/mcp-core')}" && npm run build`;
    execSync(buildCommand, { stdio: 'inherit' });
    
    // Try loading again
    const mcpCore = require(path.join(mcpCorePath, 'index.js'));
    MCPManager = mcpCore.MCPManager;
    ChatMCPBridge = mcpCore.ChatMCPBridge;
    console.error('✓ TypeScript build completed, MCP Core loaded');
  } catch (buildError) {
    console.error('✗ Failed to build TypeScript modules:', buildError.message);
    process.exit(1);
  }
}

class FlutterMCPBridge {
  constructor() {
    this.mcpManager = null;
    this.chatBridge = null;
    this.isInitialized = false;
    this.pendingRequests = new Map();
    this.requestIdCounter = 0;
    
    // Setup stdio communication with C++ plugin
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', this.handleMessage.bind(this));
    process.stdin.on('error', (error) => {
      this.sendError('STDIN_ERROR', `Failed to read from stdin: ${error.message}`);
    });
    
    // Handle process termination gracefully
    process.on('SIGTERM', this.cleanup.bind(this));
    process.on('SIGINT', this.cleanup.bind(this));
    process.on('uncaughtException', (error) => {
      this.sendError('UNCAUGHT_EXCEPTION', error.message);
      process.exit(1);
    });
  }

  sendMessage(message) {
    const jsonMessage = JSON.stringify(message);
    process.stdout.write(jsonMessage + '\n');
  }

  sendError(type, message) {
    this.sendMessage({
      type: 'error',
      error: {
        type,
        message
      },
      timestamp: new Date().toISOString()
    });
  }

  sendResponse(requestId, data, error = null) {
    this.sendMessage({
      type: 'response',
      requestId,
      data,
      error,
      timestamp: new Date().toISOString()
    });
  }

  sendEvent(event, data) {
    this.sendMessage({
      type: 'event',
      event,
      data,
      timestamp: new Date().toISOString()
    });
  }

  async handleMessage(rawData) {
    try {
      const lines = rawData.toString().trim().split('\n');
      
      for (const line of lines) {
        if (!line.trim()) continue;
        
        const message = JSON.parse(line);
        await this.processMessage(message);
      }
    } catch (error) {
      this.sendError('MESSAGE_PARSE_ERROR', `Failed to parse message: ${error.message}`);
    }
  }

  async processMessage(message) {
    const { method, params, requestId } = message;

    try {
      switch (method) {
        case 'initialize':
          await this.initialize(params, requestId);
          break;
        case 'processMessage':
          await this.processChatMessage(params, requestId);
          break;
        case 'streamMessage':
          await this.streamMessage(params, requestId);
          break;
        case 'testConnection':
          await this.testConnection(params, requestId);
          break;
        case 'getCapabilities':
          await this.getCapabilities(params, requestId);
          break;
        case 'injectContext':
          await this.injectContext(params, requestId);
          break;
        case 'dispose':
          await this.dispose(requestId);
          break;
        default:
          this.sendResponse(requestId, null, {
            type: 'UNKNOWN_METHOD',
            message: `Unknown method: ${method}`
          });
      }
    } catch (error) {
      this.sendResponse(requestId, null, {
        type: 'METHOD_ERROR',
        message: `Error in ${method}: ${error.message}`
      });
    }
  }

  async initialize(params, requestId) {
    try {
      const { mcpServers = {}, globalConfig = {} } = params;
      
      // Initialize with desktop mode enabled
      this.mcpManager = new MCPManager(true); // true = desktop mode
      this.chatBridge = new ChatMCPBridge(this.mcpManager);
      
      // Configure and enable MCP servers
      let enabledCount = 0;
      for (const [serverId, config] of Object.entries(mcpServers)) {
        try {
          await this.mcpManager.enableServer(serverId, {
            command: config.command,
            args: config.args || [],
            env: config.env || {},
            workingDirectory: config.cwd || process.cwd()
          });
          enabledCount++;
        } catch (serverError) {
          console.error(`Failed to enable server ${serverId}:`, serverError.message);
        }
      }
      
      this.isInitialized = true;
      
      this.sendResponse(requestId, {
        success: true,
        serverCount: Object.keys(mcpServers).length,
        enabledCount,
        availableServers: this.mcpManager.getAvailableServers().map(s => ({
          id: s.id,
          name: s.name,
          type: s.type,
          enabled: s.enabled
        }))
      });
      
      // Send initialization complete event
      this.sendEvent('initialized', {
        serverCount: Object.keys(mcpServers).length,
        enabledCount
      });
      
    } catch (error) {
      this.sendResponse(requestId, null, {
        type: 'INITIALIZATION_ERROR',
        message: error.message
      });
    }
  }

  async processChatMessage(params, requestId) {
    if (!this.isInitialized) {
      this.sendResponse(requestId, null, {
        type: 'NOT_INITIALIZED',
        message: 'MCP bridge not initialized'
      });
      return;
    }

    try {
      const { message, enabledServerIds = [], conversationMetadata = {} } = params;
      
      // Process through chat bridge
      const response = await this.chatBridge.processMessage(message, enabledServerIds);
      
      this.sendResponse(requestId, {
        response: response.response,
        usedServers: response.usedServers,
        metadata: response.metadata
      });
      
    } catch (error) {
      this.sendResponse(requestId, null, {
        type: 'PROCESSING_ERROR',
        message: error.message
      });
    }
  }

  async streamMessage(params, requestId) {
    if (!this.isInitialized) {
      this.sendResponse(requestId, null, {
        type: 'NOT_INITIALIZED',
        message: 'MCP bridge not initialized'
      });
      return;
    }

    try {
      const { message, enabledServerIds = [] } = params;
      
      // Use the ChatMCPBridge streaming method
      await this.chatBridge.streamResponse(
        message,
        (chunk) => {
          if (chunk === '[DONE]') {
            this.sendEvent('stream_complete', {
              requestId,
              message: 'Stream completed'
            });
          } else {
            this.sendEvent('stream_token', {
              requestId,
              token: chunk,
              type: 'content'
            });
          }
        },
        enabledServerIds
      );
      
      // Send final response
      this.sendResponse(requestId, {
        success: true,
        message: 'Streaming completed'
      });
      
    } catch (error) {
      this.sendResponse(requestId, null, {
        type: 'STREAMING_ERROR',
        message: error.message
      });
    }
  }

  async testConnection(params, requestId) {
    try {
      const { serverId } = params;
      
      if (!this.mcpManager) {
        this.sendResponse(requestId, {
          success: false,
          error: 'MCP manager not initialized'
        });
        return;
      }
      
      const startTime = Date.now();
      const connectionStatus = this.mcpManager.getConnectionStatus();
      const isConnected = connectionStatus[serverId] || false;
      const latency = Date.now() - startTime;
      
      // Try to execute a simple command to test the connection
      let testResult = null;
      if (isConnected) {
        try {
          testResult = await this.mcpManager.executeCommand(serverId, 'ping', []);
        } catch (error) {
          // Connection test failed
        }
      }
      
      this.sendResponse(requestId, {
        success: isConnected && testResult !== null,
        latency,
        error: isConnected ? null : 'Server not connected'
      });
      
    } catch (error) {
      this.sendResponse(requestId, {
        success: false,
        error: error.message
      });
    }
  }

  async getCapabilities(params, requestId) {
    try {
      const { serverId } = params;
      
      if (!this.mcpManager) {
        this.sendResponse(requestId, {
          tools: [],
          resources: [],
          prompts: []
        });
        return;
      }
      
      // Get available servers and find the requested one
      const availableServers = this.mcpManager.getAvailableServers();
      const server = availableServers.find(s => s.id === serverId);
      
      if (!server) {
        this.sendResponse(requestId, {
          tools: [],
          resources: [],
          error: `Server ${serverId} not found`
        });
        return;
      }
      
      // Return server capabilities based on its definition
      this.sendResponse(requestId, {
        tools: server.capabilities?.tools || [],
        resources: server.capabilities?.resources || [],
        prompts: server.capabilities?.prompts || [],
        supportsProgress: server.capabilities?.supportsProgress || false,
        supportsCancel: server.capabilities?.supportsCancel || false,
        extensions: server.capabilities?.extensions || {}
      });
      
    } catch (error) {
      this.sendResponse(requestId, null, {
        type: 'CAPABILITIES_ERROR',
        message: error.message
      });
    }
  }

  async injectContext(params, requestId) {
    try {
      const { context, conversationId } = params;
      
      if (!this.chatBridge) {
        this.sendResponse(requestId, {
          success: false,
          error: 'MCP bridge not initialized'
        });
        return;
      }
      
      // Convert context to the expected format
      const contextDocuments = Array.isArray(context) ? context : [context];
      
      await this.chatBridge.injectContext(contextDocuments);
      
      this.sendResponse(requestId, {
        success: true
      });
      
    } catch (error) {
      this.sendResponse(requestId, {
        success: false,
        error: error.message
      });
    }
  }

  async dispose(requestId) {
    try {
      if (this.mcpManager) {
        await this.mcpManager.dispose();
      }
      
      this.isInitialized = false;
      this.mcpManager = null;
      this.chatBridge = null;
      
      this.sendResponse(requestId, {
        success: true
      });
      
      // Clean exit
      setTimeout(() => process.exit(0), 100);
      
    } catch (error) {
      this.sendResponse(requestId, {
        success: false,
        error: error.message
      });
    }
  }

  async getAllCapabilities() {
    if (!this.mcpManager) return {};
    
    const servers = this.mcpManager.getConnectedServers();
    const capabilities = {};
    
    for (const serverId of servers) {
      try {
        capabilities[serverId] = await this.mcpManager.getServerCapabilities(serverId);
      } catch (error) {
        capabilities[serverId] = { error: error.message };
      }
    }
    
    return capabilities;
  }

  cleanup() {
    if (this.mcpManager) {
      this.mcpManager.dispose().catch(() => {});
    }
    process.exit(0);
  }
}

// Start the bridge
const bridge = new FlutterMCPBridge();
console.error('MCP Bridge started and ready for communication');