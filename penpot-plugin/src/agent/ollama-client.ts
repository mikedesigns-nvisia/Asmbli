/**
 * Ollama Client
 * HTTP client for communicating with local Ollama instance
 */

import type {
  OllamaGenerateRequest,
  OllamaGenerateResponse,
  OllamaChatRequest,
  OllamaChatResponse,
  OllamaListResponse,
} from '../types/ollama';

export class OllamaClient {
  private baseUrl: string;
  private defaultModel: string;

  constructor(baseUrl: string = 'http://localhost:11434', defaultModel: string = 'llama3.2') {
    this.baseUrl = baseUrl;
    this.defaultModel = defaultModel;
  }

  /**
   * Check if Ollama is running and accessible
   */
  async isAvailable(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/api/tags`);
      return response.ok;
    } catch (error) {
      console.error('Ollama connection error:', error);
      return false;
    }
  }

  /**
   * List all available models
   */
  async listModels(): Promise<OllamaListResponse> {
    const response = await fetch(`${this.baseUrl}/api/tags`);
    if (!response.ok) {
      throw new Error(`Failed to list models: ${response.statusText}`);
    }
    return response.json();
  }

  /**
   * Generate completion from prompt
   */
  async generate(request: Partial<OllamaGenerateRequest>): Promise<OllamaGenerateResponse> {
    const fullRequest: OllamaGenerateRequest = {
      model: this.defaultModel,
      ...request,
      prompt: request.prompt || '',
      stream: false, // We'll use non-streaming for simplicity
    };

    const response = await fetch(`${this.baseUrl}/api/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fullRequest),
    });

    if (!response.ok) {
      throw new Error(`Generation failed: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Chat with the model
   */
  async chat(request: Partial<OllamaChatRequest>): Promise<OllamaChatResponse> {
    const fullRequest: OllamaChatRequest = {
      model: this.defaultModel,
      messages: request.messages || [],
      stream: false,
      ...request,
    };

    const response = await fetch(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fullRequest),
    });

    if (!response.ok) {
      throw new Error(`Chat failed: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Set the default model
   */
  setModel(model: string): void {
    this.defaultModel = model;
  }

  /**
   * Get current default model
   */
  getModel(): string {
    return this.defaultModel;
  }

  /**
   * Set base URL for Ollama instance
   */
  setBaseUrl(url: string): void {
    this.baseUrl = url;
  }
}
