// Core Agent Types
export interface Agent {
  id: string
  name: string
  description: string
  config: AgentConfig
  templateId?: string
  userId: string
  createdAt: Date
  updatedAt: Date
}

export interface AgentConfig {
  role: string
  instructions: string
  tools: MCPServer[]
  model?: string
  temperature?: number
  maxTokens?: number
  security: SecurityConfig
  constraints: string[]
  style: StyleConfig
}

export interface StyleConfig {
  tone: 'professional' | 'casual' | 'friendly' | 'technical' | null
  responseLength: number
  format: 'paragraph' | 'bullet' | 'structured'
}

export interface SecurityConfig {
  authMethod: string | null
  permissions: string[]
  vaultIntegration: 'none' | 'local' | 'cloud'
  auditLogging: boolean
  rateLimiting: boolean
  sessionTimeout: number
}

// Template Types
export interface Template {
  id: string
  name: string
  description: string
  category: TemplateCategory
  config: AgentConfig
  isPublic: boolean
  author: string
  usageCount: number
  rating: number
  tags: string[]
  createdAt: Date
  updatedAt: Date
}

export type TemplateCategory = 
  | 'Research'
  | 'Writing' 
  | 'Development'
  | 'Data Analysis'
  | 'Customer Support'
  | 'Marketing'
  | 'Education'
  | 'Healthcare'
  | 'Finance'
  | 'General'

// Chat Types
export interface ChatSession {
  id: string
  agentId: string
  userId: string
  messages: Message[]
  context: DocumentContext[]
  startedAt: Date
  updatedAt: Date
}

export interface Message {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp: Date
  metadata?: MessageMetadata
}

export interface MessageMetadata {
  tokens?: number
  model?: string
  cost?: number
  latency?: number
}

export interface DocumentContext {
  id: string
  filename: string
  content: string
  type: 'text' | 'pdf' | 'image' | 'code'
  uploadedAt: Date
}

// MCP Server Types
export interface MCPServer {
  id: string
  name: string
  type: MCPServerType
  config: Record<string, any>
  requiredAuth?: AuthRequirement[]
  enabled: boolean
  version?: string
  supportedPlatforms?: PlatformType[]
  command?: string
  featured?: boolean
}

export type MCPServerType = 
  | 'filesystem'
  | 'git'
  | 'github'
  | 'figma'
  | 'database'
  | 'web'
  | 'api'
  | 'custom'

export type PlatformType = 'web' | 'desktop'

export interface AuthRequirement {
  type: 'api_key' | 'oauth' | 'basic_auth' | 'bearer_token'
  name: string
  required: boolean
  description?: string
}

// User Types
export interface User {
  id: string
  email: string
  name: string
  role: 'user' | 'admin'
  plan: 'free' | 'pro' | 'enterprise'
  settings: UserSettings
  createdAt: Date
  updatedAt: Date
}

export interface UserSettings {
  theme: 'light' | 'dark' | 'system'
  defaultModel: string
  apiKeys: APIKey[]
  notifications: NotificationSettings
}

export interface APIKey {
  provider: string
  keyId: string
  configured: boolean
  createdAt: Date
}

export interface NotificationSettings {
  email: boolean
  inApp: boolean
  chatUpdates: boolean
}

// API Response Types
export interface APIResponse<T> {
  data: T
  success: boolean
  error?: string
  timestamp: Date
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  hasMore: boolean
}

// Deployment Types
export interface DeploymentConfig {
  platform: DeploymentPlatform
  target: string
  config: Record<string, any>
  status: DeploymentStatus
}

export type DeploymentPlatform = 
  | 'claude-desktop'
  | 'vscode'
  | 'web'
  | 'api'
  | 'custom'

export type DeploymentStatus = 
  | 'pending'
  | 'deploying'
  | 'deployed'
  | 'failed'
  | 'stopped'

// Error Types
export interface APIError {
  code: string
  message: string
  details?: Record<string, any>
}

// Extension Types (from legacy system)
export interface Extension {
  id: string
  name: string
  description: string
  category: string
  provider: string
  config: Record<string, any>
  requiredFields: string[]
  optional: boolean
}

// Wizard Types (for desktop app)
export interface WizardData {
  agentName: string
  agentDescription: string
  primaryPurpose: string
  targetEnvironment: 'development' | 'production' | 'testing'
  deploymentTargets: string[]
  extensions: Extension[]
  security: SecurityConfig
  tone: string | null
  responseLength: number
  constraints: string[]
  constraintDocs: Record<string, any>
  testResults: TestResults
  deploymentFormat: string
}

export interface TestResults {
  connectionTests: Record<string, boolean>
  latencyTests: Record<string, number>
  securityValidation: boolean
  overallStatus: 'passed' | 'failed' | 'pending'
}