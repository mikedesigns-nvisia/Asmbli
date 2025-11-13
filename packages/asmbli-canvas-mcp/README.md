# Asmbli Canvas MCP Server

A Model Context Protocol (MCP) server that provides a visual design canvas with design system support, enabling AI agents to create, manipulate, and export UI designs programmatically.

## Features

- **Visual Canvas Engine**: Create and manipulate UI elements on a canvas
- **Design System Support**: Built-in Material 3 design system with token support
- **Natural Language Rendering**: Convert descriptions into UI designs
- **Multi-Format Export**: Generate Flutter, React, HTML, and SwiftUI code
- **Real-time Manipulation**: Modify, align, and organize elements
- **Undo/Redo Support**: Full history management
- **Component Library**: Pre-built components with variants

## Installation

```bash
npm install @asmbli/canvas-mcp
```

## Usage

### As an MCP Server

```bash
npx @asmbli/canvas-mcp
```

### In Asmbli

The Canvas MCP is pre-installed in Asmbli and available to all agents automatically.

## Available Tools

### create_element
Create a new UI element on the canvas.

```json
{
  "tool": "create_element",
  "arguments": {
    "type": "button",
    "x": 100,
    "y": 200,
    "width": 200,
    "height": 48,
    "text": "Click Me",
    "component": "button",
    "variant": "filled"
  }
}
```

### render_design
Generate a complete UI design from natural language.

```json
{
  "tool": "render_design",
  "arguments": {
    "description": "Create a modern login screen with email and password fields",
    "designSystemId": "material3",
    "style": "material3"
  }
}
```

### export_code
Export the canvas to production-ready code.

```json
{
  "tool": "export_code",
  "arguments": {
    "format": "flutter",
    "includeTokens": true,
    "componentize": true
  }
}
```

### modify_element
Update properties of existing elements.

```json
{
  "tool": "modify_element",
  "arguments": {
    "elementId": "element-123",
    "updates": {
      "x": 150,
      "text": "Updated Text",
      "style": {
        "backgroundColor": "#6750A4"
      }
    }
  }
}
```

### align_elements
Align multiple elements together.

```json
{
  "tool": "align_elements",
  "arguments": {
    "alignment": "center",
    "elementIds": ["element-1", "element-2", "element-3"]
  }
}
```

### load_design_system
Load a design system from available systems.

```json
{
  "tool": "load_design_system",
  "arguments": {
    "designSystemId": "material3",
    "merge": false
  }
}
```

## Design Systems

Design systems can be loaded from:
1. Built-in systems (Material 3 included)
2. Context documents (any `.design.json` file)
3. Custom JSON files

### Design System Format

```json
{
  "id": "my-design-system",
  "name": "My Design System",
  "version": "1.0.0",
  "tokens": {
    "colors": {
      "primary": "#6750A4",
      "surface": "#FFFFFF"
    },
    "typography": {
      "headlineLarge": {
        "fontSize": 32,
        "lineHeight": 40,
        "fontWeight": 400
      }
    },
    "spacing": {
      "sm": 8,
      "md": 16,
      "lg": 24
    }
  },
  "components": {
    "button": {
      "type": "button",
      "defaultVariant": "filled",
      "variants": {
        "filled": {
          "name": "Filled Button",
          "props": {
            "backgroundColor": "{{tokens.colors.primary}}",
            "color": "{{tokens.colors.onPrimary}}"
          }
        }
      }
    }
  }
}
```

## Element Types

- `container`: Layout container with optional styling
- `text`: Text element with typography options
- `button`: Interactive button with variants
- `input`: Text input field
- `image`: Image placeholder
- `card`: Card container with elevation
- `list`: List container
- `grid`: Grid layout container

## Export Formats

### Flutter
- Generates stateless widgets
- Includes design tokens as classes
- Supports Material 3 components
- Proper positioning with Stack/Positioned

### React
- Styled-components integration
- Functional components
- Design token hooks
- Responsive support

### HTML/CSS
- Semantic HTML structure
- Modern CSS with custom properties
- Responsive design
- Accessibility attributes

### SwiftUI
- Native SwiftUI views
- Design token integration
- Proper view modifiers
- Color extensions

## Integration with Asmbli

The Canvas MCP integrates seamlessly with Asmbli's:
- **Context Library**: Load design systems from uploaded documents
- **Local Models**: Use Ollama for design suggestions
- **Agent Collaboration**: Multiple agents can work on the same canvas
- **Human-in-the-Loop**: Approval workflows for design changes

## Examples

### Creating a Login Form

```typescript
// Agent conversation
User: "Create a login form with modern design"
Agent: *calls render_design tool*
Canvas: *generates login UI with Material 3 components*
Agent: "I've created a modern login form. Would you like to export it as Flutter code?"
User: "Yes, and make the button purple"
Agent: *calls modify_element to update button color*
Agent: *calls export_code with Flutter format*
```

### Loading Custom Design System

```typescript
// Upload company-brand.design.json to Context
// Agent can then use it
Agent: *calls load_design_system with "company-brand"*
Canvas: *updates all elements to use company colors and tokens*
```

## Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run in development
npm run dev

# Run tests
npm test
```

## License

MIT