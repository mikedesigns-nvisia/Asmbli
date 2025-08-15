/**
 * ESLint Plugin for Design Token Enforcement
 * Prevents hardcoded values and enforces design token usage
 */

const DESIGN_TOKEN_MAPPINGS = {
  // Spacing
  '2px': 'var(--space-0-5)',
  '4px': 'var(--space-1)',
  '8px': 'var(--space-2)',
  '12px': 'var(--space-3)',
  '16px': 'var(--space-4)',
  '24px': 'var(--space-6)',
  '32px': 'var(--space-8)',
  '48px': 'var(--space-12)',
  
  // Border radius
  '4px': 'var(--radius-base)',
  '6px': 'var(--radius-md)',
  '8px': 'var(--radius-lg)',
  '12px': 'var(--radius-xl)',
  
  // Font sizes
  '12px': 'var(--text-xs)',
  '14px': 'var(--text-sm)',
  '16px': 'var(--text-base)',
  '18px': 'var(--text-lg)',
  '20px': 'var(--text-xl)',
};

module.exports = {
  rules: {
    'no-hardcoded-values': {
      meta: {
        type: 'suggestion',
        docs: {
          description: 'Enforce design token usage instead of hardcoded values',
          category: 'Best Practices',
          recommended: true,
        },
        fixable: 'code',
        schema: [
          {
            type: 'object',
            properties: {
              allowedValues: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of allowed hardcoded values',
              },
              checkColors: {
                type: 'boolean',
                description: 'Check for hardcoded color values',
                default: true,
              },
              checkSpacing: {
                type: 'boolean',
                description: 'Check for hardcoded spacing values',
                default: true,
              },
            },
            additionalProperties: false,
          },
        ],
        messages: {
          hardcodedValue: 'Hardcoded value "{{value}}" found. Use design token "{{suggestion}}" instead.',
          hardcodedColor: 'Hardcoded color "{{value}}" found. Use a design token instead.',
          hardcodedSpacing: 'Hardcoded spacing "{{value}}" found. Use design token "{{suggestion}}" instead.',
        },
      },
      create(context) {
        const options = context.options[0] || {};
        const allowedValues = new Set(options.allowedValues || []);
        const checkColors = options.checkColors !== false;
        const checkSpacing = options.checkSpacing !== false;

        function checkStringValue(node, value) {
          // Skip if in allowedValues
          if (allowedValues.has(value)) return;

          // Check for hardcoded spacing values
          if (checkSpacing) {
            const spacingMatch = value.match(/\b(\d+(?:\.\d+)?)(px|rem|em)\b/g);
            if (spacingMatch) {
              spacingMatch.forEach(match => {
                const suggestion = DESIGN_TOKEN_MAPPINGS[match];
                if (suggestion) {
                  context.report({
                    node,
                    messageId: 'hardcodedSpacing',
                    data: { value: match, suggestion },
                    fix(fixer) {
                      return fixer.replaceText(node, `"${value.replace(match, suggestion)}"`);
                    },
                  });
                }
              });
            }
          }

          // Check for hardcoded colors
          if (checkColors) {
            const colorPatterns = [
              /#[0-9a-fA-F]{3,8}\b/g,  // Hex colors
              /rgba?\([^)]+\)/g,        // RGB/RGBA
              /hsla?\([^)]+\)/g,        // HSL/HSLA
            ];

            colorPatterns.forEach(pattern => {
              const matches = value.match(pattern);
              if (matches) {
                matches.forEach(match => {
                  context.report({
                    node,
                    messageId: 'hardcodedColor',
                    data: { value: match },
                  });
                });
              }
            });
          }
        }

        function checkObjectExpression(node) {
          node.properties.forEach(prop => {
            if (prop.type === 'Property' && prop.value.type === 'Literal' && typeof prop.value.value === 'string') {
              checkStringValue(prop.value, prop.value.value);
            }
          });
        }

        return {
          // Check JSX style props
          JSXExpressionContainer(node) {
            if (node.expression && node.expression.type === 'ObjectExpression') {
              checkObjectExpression(node.expression);
            }
          },
          
          // Check object expressions in style props
          Property(node) {
            if (
              node.key &&
              ((node.key.type === 'Identifier' && node.key.name === 'style') ||
               (node.key.type === 'Literal' && node.key.value === 'style'))
            ) {
              if (node.value.type === 'ObjectExpression') {
                checkObjectExpression(node.value);
              }
            }
          },

          // Check template literals that might contain CSS
          TemplateLiteral(node) {
            const value = node.quasis.map(q => q.value.cooked).join('');
            if (value.includes('px') || value.includes('rem') || value.includes('#')) {
              checkStringValue(node, value);
            }
          },
        };
      },
    },

    'prefer-design-tokens': {
      meta: {
        type: 'suggestion',
        docs: {
          description: 'Prefer design token utility classes over arbitrary values',
          category: 'Best Practices',
          recommended: true,
        },
        schema: [],
        messages: {
          preferToken: 'Prefer design token utility classes over arbitrary Tailwind values in "{{className}}".',
        },
      },
      create(context) {
        return {
          Literal(node) {
            if (typeof node.value === 'string') {
              // Check for Tailwind arbitrary values that could use design tokens
              const arbitraryValuePattern = /\[[\d.]+(?:px|rem|em)\]/g;
              const matches = node.value.match(arbitraryValuePattern);
              
              if (matches) {
                context.report({
                  node,
                  messageId: 'preferToken',
                  data: { className: node.value },
                });
              }
            }
          },
        };
      },
    },
  },

  configs: {
    recommended: {
      plugins: ['design-tokens'],
      rules: {
        'design-tokens/no-hardcoded-values': 'warn',
        'design-tokens/prefer-design-tokens': 'warn',
      },
    },
  },
};