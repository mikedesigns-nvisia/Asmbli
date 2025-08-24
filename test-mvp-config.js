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

// Console output removed for production

try {
  const configs = generateMVPConfigurations(testMVPData);
  
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
  // Console output removed for production
  const lmConfig = JSON.parse(configs['lm-studio']);
  // Console output removed for production
  // Console output removed for production
  // Console output removed for production
  
} catch (error) {
  // Console output removed for production
  process.exit(1);
}

// Console output removed for production
