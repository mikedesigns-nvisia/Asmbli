import { spawn, ChildProcess } from 'child_process';
import type { MCPServer } from '@agentengine/shared-types';

interface MCPConnection {
  process: ChildProcess;
  server: MCPServer;
  isConnected: boolean;
  lastPing: Date;
  messageQueue: string[];
  responseHandlers: Map<string, (response: any) => void>;
}

interface MCPMessage {
  jsonrpc: string;
  id?: string | number;
  method?: string;
  params?: any;
  result?: any;
  error?: any;
}

export class MCPProcessManager {
  private connections: Map<string, MCPConnection> = new Map();
  private messageIdCounter = 0;

  async startServer(serverId: string, server: MCPServer, config: any = {}): Promise<boolean> {
    if (this.connections.has(serverId)) {
      return true; // Already running
    }

    try {
      console.log(`Starting MCP server: ${server.name} (${serverId})`);
      
      // Get command and args based on server type
      const { command, args } = this.getServerCommand(server, config);
      
      // Spawn the MCP server process
      const childProcess = spawn(command, args, {
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { 
          ...process.env, 
          ...config.env,
          // Ensure Node.js PATH is available on Windows
          PATH: process.env.PATH || process.env.Path
        },
        cwd: config.workingDirectory || process.cwd(),
        shell: true // Enable shell on Windows to find npx
      });

      const connection: MCPConnection = {
        process: childProcess,
        server,
        isConnected: false,
        lastPing: new Date(),
        messageQueue: [],
        responseHandlers: new Map()
      };

      // Set up process event handlers
      this.setupProcessHandlers(serverId, connection);
      
      // Store connection
      this.connections.set(serverId, connection);

      // Wait a bit for the server to start
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Initialize MCP connection
      await this.initializeMCPConnection(serverId);

      console.log(`✓ MCP server ${serverId} started successfully`);
      return true;

    } catch (error) {
      console.error(`✗ Failed to start MCP server ${serverId}:`, error);
      return false;
    }
  }

  async stopServer(serverId: string): Promise<void> {
    const connection = this.connections.get(serverId);
    if (!connection) return;

    console.log(`Stopping MCP server: ${serverId}`);
    
    try {
      // Send shutdown notification
      await this.sendMessage(serverId, {
        jsonrpc: '2.0',
        method: 'notifications/cancelled'
      });
    } catch (error) {
      // Ignore shutdown message errors
    }

    // Kill the process
    connection.process.kill('SIGTERM');
    
    // Wait a bit, then force kill if needed
    setTimeout(() => {
      if (!connection.process.killed) {
        connection.process.kill('SIGKILL');
      }
    }, 5000);

    this.connections.delete(serverId);
    console.log(`✓ MCP server ${serverId} stopped`);
  }

  async sendMessage(serverId: string, message: MCPMessage): Promise<any> {
    const connection = this.connections.get(serverId);
    if (!connection || !connection.isConnected) {
      throw new Error(`MCP server ${serverId} is not connected`);
    }

    // Add ID for request/response tracking
    if (message.method && !message.id) {
      message.id = ++this.messageIdCounter;
    }

    return new Promise((resolve, reject) => {
      const messageStr = JSON.stringify(message) + '\n';
      
      // Set up response handler for requests
      if (message.id) {
        const timeout = setTimeout(() => {
          connection.responseHandlers.delete(message.id!.toString());
          reject(new Error(`MCP request timeout for ${serverId}`));
        }, 30000);

        connection.responseHandlers.set(message.id.toString(), (response) => {
          clearTimeout(timeout);
          if (response.error) {
            reject(new Error(`MCP Error: ${response.error.message}`));
          } else {
            resolve(response.result);
          }
        });
      }

      // Send message to MCP server
      connection.process.stdin!.write(messageStr, (error) => {
        if (error) {
          connection.responseHandlers.delete(message.id?.toString() || '');
          reject(error);
        } else if (!message.id) {
          resolve(null); // Notification sent successfully
        }
      });
    });
  }

  async callTool(serverId: string, toolName: string, arguments_: any): Promise<any> {
    return this.sendMessage(serverId, {
      jsonrpc: '2.0',
      method: 'tools/call',
      params: {
        name: toolName,
        arguments: arguments_
      }
    });
  }

  async listTools(serverId: string): Promise<any[]> {
    const result = await this.sendMessage(serverId, {
      jsonrpc: '2.0',
      method: 'tools/list'
    });
    return result.tools || [];
  }

  async listResources(serverId: string): Promise<any[]> {
    const result = await this.sendMessage(serverId, {
      jsonrpc: '2.0',
      method: 'resources/list'
    });
    return result.resources || [];
  }

  async readResource(serverId: string, uri: string): Promise<any> {
    return this.sendMessage(serverId, {
      jsonrpc: '2.0',
      method: 'resources/read',
      params: { uri }
    });
  }

  async ping(serverId: string): Promise<number> {
    const startTime = Date.now();
    
    try {
      await this.sendMessage(serverId, {
        jsonrpc: '2.0',
        method: 'ping'
      });
      
      const connection = this.connections.get(serverId);
      if (connection) {
        connection.lastPing = new Date();
      }
      
      return Date.now() - startTime;
    } catch (error) {
      throw new Error(`Ping failed for ${serverId}: ${error}`);
    }
  }

  getConnectionStatus(serverId: string): boolean {
    const connection = this.connections.get(serverId);
    return connection ? connection.isConnected : false;
  }

  getAllConnections(): Record<string, boolean> {
    const status: Record<string, boolean> = {};
    for (const [serverId, connection] of this.connections) {
      status[serverId] = connection.isConnected;
    }
    return status;
  }

  private getServerCommand(server: MCPServer, config: any): { command: string, args: string[] } {
    // If explicit command is provided in config, use it
    if (config.command && config.args) {
      return { command: config.command, args: config.args };
    }

    // Default commands based on server type
    switch (server.type) {
      case 'filesystem':
        return {
          command: 'uvx',
          args: ['@modelcontextprotocol/server-filesystem', config.rootPath || process.cwd()]
        };
      
      case 'github':
        return {
          command: 'uvx',
          args: ['@modelcontextprotocol/server-github']
        };
      
      case 'database':
        if (server.id.includes('postgres')) {
          return {
            command: 'uvx',
            args: ['@modelcontextprotocol/server-postgres', config.connectionString || '']
          };
        }
        break;
      
      case 'git':
        return {
          command: 'uvx',
          args: ['@modelcontextprotocol/server-git']
        };
      
      case 'web':
        if (server.id.includes('search')) {
          return {
            command: 'uvx',
            args: ['@modelcontextprotocol/server-brave-search']
          };
        }
        break;
      
      case 'api':
        return {
          command: 'uvx',
          args: ['@modelcontextprotocol/server-fetch']
        };
      
      default:
        // Fallback to custom server command
        if (server.command) {
          return {
            command: server.command,
            args: config.args || []
          };
        }
        break;
    }

    throw new Error(`No command configuration found for server ${server.id} of type ${server.type}`);
  }

  private setupProcessHandlers(serverId: string, connection: MCPConnection): void {
    const { process: childProcess } = connection;
    let stdoutBuffer = '';
    let stderrBuffer = '';

    // Handle stdout (MCP messages)
    childProcess.stdout!.on('data', (data: Buffer) => {
      stdoutBuffer += data.toString();
      
      // Process complete JSON messages (one per line)
      const lines = stdoutBuffer.split('\n');
      stdoutBuffer = lines.pop() || ''; // Keep incomplete line
      
      for (const line of lines) {
        if (line.trim()) {
          this.handleMCPMessage(serverId, line.trim());
        }
      }
    });

    // Handle stderr (logging)
    childProcess.stderr!.on('data', (data: Buffer) => {
      stderrBuffer += data.toString();
      
      // Log error output from MCP server
      const lines = stderrBuffer.split('\n');
      stderrBuffer = lines.pop() || '';
      
      for (const line of lines) {
        if (line.trim()) {
          console.error(`MCP ${serverId} stderr:`, line.trim());
        }
      }
    });

    // Handle process exit
    childProcess.on('exit', (code, signal) => {
      console.log(`MCP server ${serverId} exited with code ${code}, signal ${signal}`);
      connection.isConnected = false;
      this.connections.delete(serverId);
    });

    // Handle process errors
    childProcess.on('error', (error) => {
      console.error(`MCP server ${serverId} process error:`, error);
      connection.isConnected = false;
    });
  }

  private handleMCPMessage(serverId: string, messageStr: string): void {
    try {
      const message: MCPMessage = JSON.parse(messageStr);
      const connection = this.connections.get(serverId);
      
      if (!connection) return;

      // Handle responses to our requests
      if (message.id && connection.responseHandlers.has(message.id.toString())) {
        const handler = connection.responseHandlers.get(message.id.toString());
        connection.responseHandlers.delete(message.id.toString());
        handler!(message);
        return;
      }

      // Handle server-initiated messages (notifications, requests)
      if (message.method) {
        switch (message.method) {
          case 'notifications/initialized':
            connection.isConnected = true;
            console.log(`✓ MCP server ${serverId} initialized`);
            break;
          
          case 'notifications/progress':
            console.log(`MCP ${serverId} progress:`, message.params);
            break;
          
          default:
            console.log(`MCP ${serverId} notification:`, message.method, message.params);
        }
      }

    } catch (error) {
      console.error(`Failed to parse MCP message from ${serverId}:`, error, messageStr);
    }
  }

  private async initializeMCPConnection(serverId: string): Promise<void> {
    const connection = this.connections.get(serverId);
    if (!connection) {
      throw new Error(`Connection not found for server ${serverId}`);
    }

    try {
      // Send initialize request
      const initResult = await this.sendMessage(serverId, {
        jsonrpc: '2.0',
        method: 'initialize',
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {
            roots: { listChanged: true },
            sampling: {}
          },
          clientInfo: {
            name: 'AgentEngine',
            version: '1.0.0'
          }
        }
      });

      console.log(`MCP server ${serverId} initialization result:`, initResult);

      // Send initialized notification
      await this.sendMessage(serverId, {
        jsonrpc: '2.0',
        method: 'notifications/initialized'
      });

      // Mark as connected
      connection.isConnected = true;
      
    } catch (error) {
      console.error(`Failed to initialize MCP server ${serverId}:`, error);
      throw error;
    }
  }

  async dispose(): Promise<void> {
    const serverIds = Array.from(this.connections.keys());
    await Promise.all(serverIds.map(id => this.stopServer(id)));
    this.connections.clear();
  }
}