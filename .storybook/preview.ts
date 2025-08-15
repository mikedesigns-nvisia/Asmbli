import type { Preview } from '@storybook/react';
import '../styles/design-tokens.css';
import '../index.css';

const preview: Preview = {
  parameters: {
    actions: { argTypesRegex: '^on[A-Z].*' },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/,
      },
    },
    docs: {
      toc: true,
    },
    viewport: {
      viewports: {
        mobile: {
          name: 'Mobile',
          styles: {
            width: '375px',
            height: '667px',
          },
        },
        tablet: {
          name: 'Tablet',
          styles: {
            width: '768px',
            height: '1024px',
          },
        },
        desktop: {
          name: 'Desktop',
          styles: {
            width: '1440px',
            height: '900px',
          },
        },
      },
    },
    a11y: {
      config: {},
      options: {
        checks: { 'color-contrast': { options: { noScroll: true } } },
        restoreScroll: true,
      },
    },
  },
  tags: ['autodocs'],
  globalTypes: {
    designTokens: {
      name: 'Design Tokens',
      description: 'Toggle design token visualization',
      defaultValue: 'off',
      toolbar: {
        icon: 'component',
        items: [
          { value: 'off', title: 'Hide tokens' },
          { value: 'spacing', title: 'Show spacing' },
          { value: 'colors', title: 'Show colors' },
          { value: 'typography', title: 'Show typography' },
        ],
      },
    },
  },
};

export default preview;