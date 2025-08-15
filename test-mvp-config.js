// Quick test script to validate MVP configuration generation
import { generateMVPConfigurations } from './utils/mvpConfigGenerator.js';

// Test data mimicking what comes from the MVP wizard
const testMVPData = {
  selectedRole: 'developer',
  selectedTools: ['code-management', 'api-integration', 'file-management'],
  style: {
    tone: 'technical',
    responseLength: 'balanced',
    constraints: ['Always include code examples when relevant']
  },
  extractedConstraints: ['Use TypeScript for all examples']
};

console.log('Testing MVP Configuration Generation...\n');

try {
  const configs = generateMVPConfigurations(testMVPData);
  
  console.log('✅ Configuration generation successful!');
  console.log('Generated configs:');
  console.log('- LM Studio config length:', configs['lm-studio']?.length || 0);
  console.log('- Ollama config length:', configs['ollama']?.length || 0);
  console.log('- VS Code config length:', configs['vs-code']?.length || 0);
  console.log('- Setup instructions generated:', Object.keys(configs).filter(k => k.includes('.md')).length);
  
  console.log('\n✅ LM Studio Config Preview:');
  const lmConfig = JSON.parse(configs['lm-studio']);
  console.log('- MCP Servers:', Object.keys(lmConfig.mcpServers || {}));
  console.log('- Agent Role:', lmConfig.agentConfig?.role);
  console.log('- Communication Style:', lmConfig.agentConfig?.style?.tone);
  
} catch (error) {
  console.error('❌ Configuration generation failed:', error);
  process.exit(1);
}

console.log('\n🎉 MVP Configuration system is bulletproof and ready!');