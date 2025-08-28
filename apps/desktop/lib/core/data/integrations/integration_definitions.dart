import 'package:flutter/material.dart';
import 'package:agent_engine_core/agent_engine_core.dart';

/// Continue.dev AI code assistant integration
const continueDev = IntegrationDefinition(
  id: 'continue-dev',
  name: 'Continue.dev',
  description: 'Open-source AI code assistant for IDEs with chat, autocomplete, and inline editing',
  icon: Icons.code,
  category: IntegrationCategory.devops,
  difficulty: 'Easy',
  tags: ['continue', 'ai', 'code-assistant', 'vscode', 'development'],
  brandColor: Color(0xFF0066CC),
  command: 'uvx',
  args: ['@modelcontextprotocol/server-continue-dev'],
  configFields: [
    IntegrationField(
      id: 'apiProvider',
      label: 'AI Provider',
      description: 'Choose your AI model provider',
      required: true,
      fieldType: IntegrationFieldType.select,
      options: {
        'options': ['openai', 'claude', 'ollama', 'local'],
        'labels': ['OpenAI', 'Anthropic Claude', 'Ollama (Local)', 'Local Model'],
      },
      defaultValue: 'ollama',
    ),
    IntegrationField(
      id: 'apiKey',
      label: 'API Key',
      description: 'API key for your chosen provider (not needed for local models)',
      fieldType: IntegrationFieldType.apiToken,
    ),
    IntegrationField(
      id: 'modelName',
      label: 'Model Name',
      description: 'Specific model to use (e.g., gpt-4, claude-3, llama3)',
      fieldType: IntegrationFieldType.text,
      placeholder: 'llama3',
    ),
    IntegrationField(
      id: 'contextLength',
      label: 'Context Length',
      description: 'Maximum context length for the model',
      fieldType: IntegrationFieldType.number,
      defaultValue: 4096,
    ),
  ],
  capabilities: [
    'AI-powered code completion',
    'Inline code editing and refactoring', 
    'Codebase-aware chat assistant',
    'Documentation generation',
    'Code explanation and analysis',
    'Multi-language support'
  ],
  prerequisites: ['VS Code or compatible IDE'],
  documentationUrl: 'https://docs.continue.dev/',
  isPopular: true,
  isRecommended: true,
  isAvailable: true,
);