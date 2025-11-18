/**
 * Design Agent
 * AI-powered design assistant using Ollama for intelligent canvas manipulation
 */

import { OllamaClient } from './ollama-client';
import { DesignTokenClient } from '../tokens/design-token-client';
import type {
  DesignAgentRequest,
  DesignAgentResponse,
  OllamaChatMessage,
} from '../types/ollama';
import type { DesignTokens } from '../types/design-tokens';

export class DesignAgent {
  private ollama: OllamaClient;
  private tokenClient: DesignTokenClient;
  private conversationHistory: OllamaChatMessage[] = [];
  private systemPrompt: string;
  private designTokens: DesignTokens | null = null;

  constructor(ollamaClient: OllamaClient, tokenClient: DesignTokenClient) {
    this.ollama = ollamaClient;
    this.tokenClient = tokenClient;
    this.systemPrompt = this.buildSystemPrompt();
    this.loadDesignTokens();
  }

  /**
   * Load design tokens from Flutter app
   */
  private async loadDesignTokens(): Promise<void> {
    try {
      this.designTokens = await this.tokenClient.fetchTokens();
      console.log('Design tokens loaded successfully');
    } catch (error) {
      console.error('Failed to load design tokens:', error);
      this.designTokens = null;
    }
  }

  private buildSystemPrompt(): string {
    return `You are an expert UI/UX design assistant integrated into PenPOT, a design tool.

Your role is to:
1. Analyze design requests and canvas state
2. Suggest design improvements (layout, colors, typography, spacing)
3. Generate tool calls to manipulate canvas elements
4. Provide design rationale and best practices
5. Use brand design tokens for consistent styling

Available MCP Tools:
- CREATE: createRectangle, createEllipse, createText, createFrame, clearCanvas
- UPDATE: updateElement
- QUERY: queryElements, getCanvasState, getElementDetails
- TRANSFORM: rotateElement, scaleElement, flipHorizontal, flipVertical
- DELETE: deleteElement
- DUPLICATE: duplicateElement
- GROUP: groupElements, ungroupElements
- REORDER: bringToFront, sendToBack, bringForward, sendBackward
- HISTORY: undo, redo
- LAYOUT: alignElements, distributeElements, setConstraints
- COMPONENT: createComponent, detachComponent, createComponentInstance
- EXPORT: exportElement, exportPage, exportSelection

Design Token Guidelines:
- ALWAYS use brand colors from design tokens when available
- ALWAYS use spacing tokens for consistent layout
- ALWAYS use typography tokens for text elements
- ALWAYS use border radius tokens for rounded corners
- Use shadow tokens for depth and elevation
- Never hardcode values that exist in design tokens

When responding:
1. Analyze the user's request and canvas context
2. Check available design tokens and prioritize their use
3. Provide design suggestions with confidence scores
4. Generate specific tool calls to implement suggestions
5. Reference design tokens in your rationale
6. Explain your design reasoning

Respond in JSON format:
{
  "suggestions": [
    {
      "type": "layout" | "color" | "typography" | "spacing" | "component",
      "description": "Description of suggestion",
      "confidence": 0.0-1.0,
      "actions": ["action1", "action2"],
      "tokensUsed": ["colors.primary", "spacing.lg"]
    }
  ],
  "toolCalls": [
    {
      "tool": "toolName",
      "parameters": {},
      "rationale": "Why this tool call"
    }
  ],
  "reasoning": "Overall design rationale"
}`;
  }

  /**
   * Process a design request with AI assistance
   */
  async processRequest(request: DesignAgentRequest): Promise<DesignAgentResponse> {
    // Build user message with context
    const userMessage = this.buildUserMessage(request);

    // Add to conversation history
    this.conversationHistory.push({
      role: 'user',
      content: userMessage,
    });

    try {
      // Get AI response
      const response = await this.ollama.chat({
        messages: [
          { role: 'system', content: this.systemPrompt },
          ...this.conversationHistory,
        ],
        options: {
          temperature: 0.7,
          top_p: 0.9,
        },
        format: 'json',
      });

      // Add assistant response to history
      this.conversationHistory.push(response.message);

      // Parse and return design response
      const designResponse = this.parseDesignResponse(response.message.content);
      return designResponse;
    } catch (error) {
      console.error('Design agent error:', error);
      return {
        suggestions: [],
        reasoning: `Error processing request: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }

  private buildUserMessage(request: DesignAgentRequest): string {
    let message = `User Request: ${request.prompt}\n\n`;

    if (request.canvasContext) {
      message += `Canvas Context:\n`;
      message += `- Total elements: ${request.canvasContext.elements.length}\n`;
      message += `- Selected elements: ${request.canvasContext.selectedElements.length}\n`;

      if (request.canvasContext.elements.length > 0) {
        message += `\nElements:\n`;
        request.canvasContext.elements.forEach((el, i) => {
          message += `  ${i + 1}. ${el.type} at (${el.x}, ${el.y}) - ${el.width}x${el.height}\n`;
        });
      }
    }

    // Include design tokens in user message
    const tokens = request.designTokens || this.designTokens;
    if (tokens) {
      message += `\nBrand Design Tokens Available:\n`;

      if (tokens.colors) {
        message += `\nColors:\n`;
        Object.entries(tokens.colors).forEach(([key, value]) => {
          message += `  - ${key}: ${value}\n`;
        });
      }

      if (tokens.spacing) {
        message += `\nSpacing (px):\n`;
        Object.entries(tokens.spacing).forEach(([key, value]) => {
          message += `  - ${key}: ${value}px\n`;
        });
      }

      if (tokens.typography) {
        message += `\nTypography:\n`;
        Object.entries(tokens.typography).forEach(([key, value]) => {
          if (typeof value === 'object' && 'fontFamily' in value) {
            message += `  - ${key}: ${value.fontFamily} ${value.fontSize}px, weight ${value.fontWeight}\n`;
          }
        });
      }

      if (tokens.borderRadius) {
        message += `\nBorder Radius (px):\n`;
        Object.entries(tokens.borderRadius).forEach(([key, value]) => {
          message += `  - ${key}: ${value}px\n`;
        });
      }
    }

    return message;
  }

  private parseDesignResponse(content: string): DesignAgentResponse {
    try {
      const parsed = JSON.parse(content);
      return {
        suggestions: parsed.suggestions || [],
        toolCalls: parsed.toolCalls || [],
        reasoning: parsed.reasoning || '',
      };
    } catch (error) {
      // If JSON parsing fails, return a basic response
      return {
        suggestions: [],
        reasoning: content,
      };
    }
  }

  /**
   * Get simple design suggestion without full processing
   */
  async getSuggestion(prompt: string): Promise<string> {
    try {
      const response = await this.ollama.generate({
        prompt: `As a UI/UX design expert, provide a brief design suggestion for: ${prompt}`,
        system: 'You are a helpful UI/UX design assistant. Provide concise, actionable design advice.',
        options: {
          temperature: 0.7,
          num_predict: 200,
        },
      });

      return response.response;
    } catch (error) {
      return `Error getting suggestion: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Clear conversation history
   */
  clearHistory(): void {
    this.conversationHistory = [];
  }

  /**
   * Get conversation history
   */
  getHistory(): OllamaChatMessage[] {
    return [...this.conversationHistory];
  }

  /**
   * Check if Ollama is available
   */
  async isAvailable(): Promise<boolean> {
    return this.ollama.isAvailable();
  }

  /**
   * Refresh design tokens from Flutter app
   */
  async refreshDesignTokens(): Promise<void> {
    await this.loadDesignTokens();
  }

  /**
   * Get current design tokens
   */
  getDesignTokens(): DesignTokens | null {
    return this.designTokens;
  }

  /**
   * Get token value by path (e.g., 'colors.primary')
   */
  getTokenValue(tokenPath: string): any {
    return this.tokenClient.getTokenValue(tokenPath, this.designTokens || undefined);
  }

  /**
   * Apply design token to create element parameters
   */
  applyTokenToParameters(parameters: any, tokenMappings: Record<string, string>): any {
    const updatedParams = { ...parameters };

    for (const [paramKey, tokenPath] of Object.entries(tokenMappings)) {
      const tokenValue = this.getTokenValue(tokenPath);
      if (tokenValue !== undefined) {
        updatedParams[paramKey] = tokenValue;
      }
    }

    return updatedParams;
  }
}
