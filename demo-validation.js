import { validateComponentTokenUsage, checkHardcodedValues, getDesignTokensByCategory } from './src/utils/design-token-validator.js';
import fs from 'fs';

// Console output removed for production

// Test 1: Validate the test component with violations
// Console output removed for production
const badComponent = fs.readFileSync('test-component.tsx', 'utf-8');
const badResult = validateComponentTokenUsage(badComponent);

// Console output removed for production
// Console output removed for production
badResult.errors.forEach((error, i) => {
  // Console output removed for production
});

// Test 2: Check individual CSS values
// Console output removed for production
const testCases = [
  'padding: 16px',
  'color: #3b82f6',
  'border-radius: 8px',
  'padding: var(--space-4)', // Should pass
];

testCases.forEach(css => {
  const result = checkHardcodedValues(css);
  const status = result.length === 0 ? '✅ PASS' : '❌ FAIL';
  // Console output removed for production
  if (result.length > 0) {
    // Console output removed for production
  }
});

// Test 3: Show available design tokens
// Console output removed for production
const tokens = getDesignTokensByCategory();
Object.entries(tokens).forEach(([category, subcategories]) => {
  // Console output removed for production
  Object.entries(subcategories).forEach(([subcat, tokenList]) => {
    // Console output removed for production
  });
});

// Console output removed for production
