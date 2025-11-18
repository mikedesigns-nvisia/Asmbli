/**
 * Ollama API Types
 * Type definitions for Ollama API integration
 */

export interface OllamaGenerateRequest {
  model: string;
  prompt: string;
  system?: string;
  template?: string;
  context?: number[];
  stream?: boolean;
  raw?: boolean;
  format?: 'json';
  options?: {
    temperature?: number;
    top_p?: number;
    top_k?: number;
    num_predict?: number;
  };
}

export interface OllamaGenerateResponse {
  model: string;
  created_at: string;
  response: string;
  done: boolean;
  context?: number[];
  total_duration?: number;
  load_duration?: number;
  prompt_eval_count?: number;
  prompt_eval_duration?: number;
  eval_count?: number;
  eval_duration?: number;
}

export interface OllamaChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
  images?: string[];
}

export interface OllamaChatRequest {
  model: string;
  messages: OllamaChatMessage[];
  stream?: boolean;
  format?: 'json';
  options?: {
    temperature?: number;
    top_p?: number;
    top_k?: number;
    num_predict?: number;
  };
}

export interface OllamaChatResponse {
  model: string;
  created_at: string;
  message: OllamaChatMessage;
  done: boolean;
  total_duration?: number;
  load_duration?: number;
  prompt_eval_count?: number;
  prompt_eval_duration?: number;
  eval_count?: number;
  eval_duration?: number;
}

export interface OllamaModelInfo {
  name: string;
  modified_at: string;
  size: number;
  digest: string;
  details: {
    format: string;
    family: string;
    families: string[];
    parameter_size: string;
    quantization_level: string;
  };
}

export interface OllamaListResponse {
  models: OllamaModelInfo[];
}

export interface DesignAgentRequest {
  prompt: string;
  canvasContext?: {
    elements: any[];
    selectedElements: string[];
  };
  designTokens?: {
    colors?: Record<string, string>;
    spacing?: Record<string, number>;
    typography?: Record<string, any>;
    borderRadius?: Record<string, number>;
    shadows?: Record<string, any>;
  };
}

export interface DesignAgentResponse {
  suggestions: DesignSuggestion[];
  toolCalls?: ToolCall[];
  reasoning?: string;
}

export interface DesignSuggestion {
  type: 'layout' | 'color' | 'typography' | 'spacing' | 'component';
  description: string;
  confidence: number;
  actions?: string[];
}

export interface ToolCall {
  tool: string;
  parameters: Record<string, any>;
  rationale?: string;
}
