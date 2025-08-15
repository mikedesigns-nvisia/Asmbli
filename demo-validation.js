import { validateComponentTokenUsage, checkHardcodedValues, getDesignTokensByCategory } from './src/utils/design-token-validator.js';
import fs from 'fs';

console.log('🎯 AgentEngine Design System Testing Demo\n');

// Test 1: Validate the test component with violations
console.log('1. Testing component with hardcoded values:');
const badComponent = fs.readFileSync('test-component.tsx', 'utf-8');
const badResult = validateComponentTokenUsage(badComponent);

console.log(`   ❌ Validation result: ${badResult.isValid ? 'PASSED' : 'FAILED'}`);
console.log(`   📊 Found ${badResult.errors.length} errors:`);
badResult.errors.forEach((error, i) => {
  console.log(`      ${i + 1}. ${error}`);
});

// Test 2: Check individual CSS values
console.log('\n2. Testing individual CSS values:');
const testCases = [
  'padding: 16px',
  'color: #3b82f6',
  'border-radius: 8px',
  'padding: var(--space-4)', // Should pass
];

testCases.forEach(css => {
  const result = checkHardcodedValues(css);
  const status = result.length === 0 ? '✅ PASS' : '❌ FAIL';
  console.log(`   ${status} "${css}"`);
  if (result.length > 0) {
    console.log(`        → ${result[0]}`);
  }
});

// Test 3: Show available design tokens
console.log('\n3. Available design tokens:');
const tokens = getDesignTokensByCategory();
Object.entries(tokens).forEach(([category, subcategories]) => {
  console.log(`   📁 ${category.toUpperCase()}:`);
  Object.entries(subcategories).forEach(([subcat, tokenList]) => {
    console.log(`      ${subcat}: ${tokenList.slice(0, 3).join(', ')}...`);
  });
});

console.log('\n🚀 Design system testing is working! Ready to validate new components.');