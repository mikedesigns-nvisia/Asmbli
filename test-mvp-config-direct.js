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

// Console output removed for production

try {
  const configs = generateDeploymentConfigs(testMVPData);
  
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
  // Check key platform configs
  const platforms = ['lm-studio', 'ollama', 'vs-code'];
  platforms.forEach(platform => {
    if (configs[platform]) {
      // Console output removed for production
      try {
        const parsed = JSON.parse(configs[platform]);
        // Console output removed for production
        // Console output removed for production
      } catch (e) {
        // Console output removed for production
      }
    } else {
      // Console output removed for production
    }
  });
  
  // Check setup guides
  const setupGuides = ['lm-studio-setup.md', 'ollama-setup.md', 'vs-code-setup.md'];
  setupGuides.forEach(guide => {
    if (configs[guide]) {
      // Console output removed for production
    }
  });
  
  // Test edge cases
  // Console output removed for production
  
  // Test with empty data
  const emptyConfigs = generateDeploymentConfigs({});
  // Console output removed for production
  
  // Test with null data
  const nullConfigs = generateDeploymentConfigs(null);
  // Console output removed for production
  
  // Test with malformed data
  const malformedConfigs = generateDeploymentConfigs({ selectedRole: 'invalid', selectedTools: 'not-an-array' });
  // Console output removed for production
  
} catch (error) {
  // Console output removed for production
  process.exit(1);
}

// Console output removed for production
