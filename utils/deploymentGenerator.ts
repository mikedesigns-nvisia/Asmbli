import { WizardData } from '../types/wizard';
import { generateChatMCPConfigs } from './chatmcpGenerator';

// Type for MVP wizard data
interface MVPWizardData {
  selectedRole?: string;
  role?: string;
  selectedTools?: string[];
  tools?: string[];
  extractedConstraints?: string[];
  style?: any;
  deployment?: any;
}

/**
 * Main deployment configuration generator - now exclusively targets ChatMCP
 * 
 * This function generates ChatMCP-compatible packages with:
 * - mcp.json configuration
 * - Installation scripts for all platforms
 * - Environment setup guides
 * - Complete documentation
 */
export function generateDeploymentConfigs(wizardData: WizardData | MVPWizardData, promptOutput?: string): Record<string, string> {
  console.log('🚀 AgentEngine Deployment - ChatMCP Only');
  console.log('Generating ChatMCP configuration packages...');
  
  // Use the new ChatMCP-focused generator for all deployments
  return generateChatMCPConfigs(wizardData);
}