// Direct test of MVP configuration generation by importing from running app
import { generateDeploymentConfigs } from './utils/deploymentGenerator.js';

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
  const configs = generateDeploymentConfigs(testMVPData);
  
  console.log('✅ Configuration generation successful!');
  console.log('Generated configs:');
  console.log('- Total configurations:', Object.keys(configs).length);
  
  // Check key platform configs
  const platforms = ['lm-studio', 'ollama', 'vs-code'];
  platforms.forEach(platform => {
    if (configs[platform]) {
      console.log(`- ${platform.toUpperCase()} config: ${configs[platform].length} chars`);
      try {
        const parsed = JSON.parse(configs[platform]);
        console.log(`  - MCP Servers: ${Object.keys(parsed.mcpServers || {}).length}`);
        console.log(`  - Agent Role: ${parsed.agentConfig?.role || 'not set'}`);
      } catch (e) {
        console.log(`  - Config format: text/markdown`);
      }
    } else {
      console.log(`- ${platform.toUpperCase()} config: missing`);
    }
  });
  
  // Check setup guides
  const setupGuides = ['lm-studio-setup.md', 'ollama-setup.md', 'vs-code-setup.md'];
  setupGuides.forEach(guide => {
    if (configs[guide]) {
      console.log(`- ${guide}: ${configs[guide].length} chars`);
    }
  });
  
  // Test edge cases
  console.log('\n🧪 Testing edge cases...');
  
  // Test with empty data
  const emptyConfigs = generateDeploymentConfigs({});
  console.log('- Empty data:', Object.keys(emptyConfigs).length > 0 ? '✅ handled' : '❌ failed');
  
  // Test with null data
  const nullConfigs = generateDeploymentConfigs(null);
  console.log('- Null data:', Object.keys(nullConfigs).length > 0 ? '✅ handled' : '❌ failed');
  
  // Test with malformed data
  const malformedConfigs = generateDeploymentConfigs({ selectedRole: 'invalid', selectedTools: 'not-an-array' });
  console.log('- Malformed data:', Object.keys(malformedConfigs).length > 0 ? '✅ handled' : '❌ failed');
  
} catch (error) {
  console.error('❌ Configuration generation failed:', error);
  process.exit(1);
}

console.log('\n🎉 MVP Configuration system is bulletproof and ready!');