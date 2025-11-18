/**
 * Bridge Client
 * Handles HTTP/WebSocket communication between PenPOT plugin and Flutter app
 */

import type { MCPToolResponse } from '../types/mcp';

export class BridgeClient {
  private baseUrl: string;
  private ws: WebSocket | null = null;
  private toolCallHandlers: Array<(toolName: string, parameters: any) => void> = [];

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
    this.initializeWebSocket();
  }

  private initializeWebSocket() {
    const wsUrl = this.baseUrl.replace('http', 'ws') + '/plugin-bridge';

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('Bridge WebSocket connected');
      };

      this.ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          this.handleMessage(message);
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
      };

      this.ws.onclose = () => {
        console.log('Bridge WebSocket disconnected, reconnecting in 3s...');
        setTimeout(() => this.initializeWebSocket(), 3000);
      };
    } catch (error) {
      console.error('Failed to initialize WebSocket:', error);
      // Retry connection after 5 seconds
      setTimeout(() => this.initializeWebSocket(), 5000);
    }
  }

  private handleMessage(message: any) {
    console.log('Bridge received message:', message);

    if (message.type === 'tool-call') {
      // Execute tool call from Flutter app
      this.toolCallHandlers.forEach((handler) => {
        handler(message.tool, message.parameters);
      });
    }
  }

  onToolCall(handler: (toolName: string, parameters: any) => void) {
    this.toolCallHandlers.push(handler);
  }

  sendToolResult(response: MCPToolResponse) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          type: 'tool-result',
          ...response,
        })
      );
    } else {
      console.warn('WebSocket not connected, cannot send tool result');
    }
  }

  sendReady() {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          type: 'plugin-ready',
          timestamp: Date.now(),
        })
      );
    } else {
      // Wait for connection and try again
      setTimeout(() => this.sendReady(), 1000);
    }
  }

  sendConnectionStatus(status: { connected: boolean; timestamp: string; message: string }) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          type: 'connection-status',
          ...status,
        })
      );
      console.log('📡 Connection status sent to Flutter:', status);
    } else {
      // Wait for WebSocket connection and try again
      console.log('⏳ Waiting for WebSocket connection to send status...');
      setTimeout(() => this.sendConnectionStatus(status), 1000);
    }
  }

  sendHealthStatus(health: {
    version: string;
    toolCount: number;
    capabilities: string[];
    status: string;
    timestamp: string;
  }) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          type: 'health-status',
          ...health,
        })
      );
    } else {
      console.log('⏳ Waiting for WebSocket to send health status...');
    }
  }

  async httpPost(endpoint: string, data: any): Promise<any> {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('HTTP POST error:', error);
      throw error;
    }
  }
}
