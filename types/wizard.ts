export interface SecurityConfig {
  authMethod: 'oauth' | 'apikey' | 'mtls' | null;
  permissions: string[];
  vaultIntegration: 'hashicorp' | 'aws' | '1password' | 'none';
  auditLogging: boolean;
  rateLimiting: boolean;
  sessionTimeout: number;
}

export interface Extension {
  id: string;
  name: string;
  description: string;
  category: string;
  provider: string;
  icon?: string; // Provider branded icon or Lucide icon name
  complexity: 'low' | 'medium' | 'high';
  enabled: boolean;
  connectionType: 'mcp' | 'api' | 'extension' | 'webhook';
  authMethod: string;
  pricing: 'free' | 'freemium' | 'paid';
  features: string[];
  capabilities: string[];
  requirements: string[];
  documentation: string;
  setupComplexity: number;
  configuration: Record<string, any>;
  supportedConnectionTypes?: string[]; // For multi-connection extensions like GitHub/Slack
  // Legacy fields for backward compatibility
  platforms?: {
    mcp?: {
      transport: 'stdio' | 'http' | 'streamable';
      authMethods: string[];
      capabilities: string[];
    };
    copilot?: {
      connectorType: string;
      authMethods: string[];
      permissions: string[];
      capabilities: string[];
    };
    powerPlatform?: {
      connectorType: string;
      authMethods: string[];
      capabilities: string[];
    };
    api?: {
      protocol: string;
      authMethods: string[];
      capabilities: string[];
    };
  };
  securityLevel?: 'low' | 'medium' | 'high';
  selectedPlatforms?: string[];
  config?: Record<string, any>;
}

export interface TestResults {
  connectionTests: Record<string, boolean>;
  latencyTests: Record<string, number>;
  securityValidation: boolean;
  overallStatus: 'passed' | 'failed' | 'pending';
}

export interface WizardData {
  // Step 1: Agent Profile
  agentName: string;
  agentDescription: string;
  primaryPurpose: string;
  targetEnvironment: 'development' | 'staging' | 'production';
  deploymentTargets: string[];
  
  // Step 2: Extensions & Integrations
  extensions: Extension[];
  
  // Step 3: Security & Access
  security: SecurityConfig;
  
  // Step 4: Behavior & Style
  tone: string | null;
  responseLength: number;
  constraints: string[];
  constraintDocs: Record<string, string>;
  
  // Step 5: Test & Validate
  testResults: TestResults;
  
  // Step 6: Deploy
  deploymentFormat: 'desktop' | 'docker' | 'kubernetes' | 'json';
}

export interface FlowNode {
  id: string;
  label: string;
  status: 'active' | 'pending' | 'error';
}