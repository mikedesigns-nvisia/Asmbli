# Agent Engine

A React TypeScript application for configuring and deploying AI agents with advanced features like MCP server integration, security controls, and deployment management.

## Features

- **Agent Configuration Wizard**: Step-by-step agent setup with profile, extensions, security, and behavior configuration
- **Template System**: Save and reuse agent configurations as templates
- **Security Management**: Authentication, permissions, vault integration, and audit logging
- **Deployment Options**: Support for multiple deployment targets including Claude Desktop
- **Extension Library**: Browse and integrate various MCP tools and extensions
- **Real-time Preview**: Live code preview and flow diagram visualization

## Development

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Setup

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000) in your browser

### Build for Production

```bash
npm run build
```

### Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## Deployment

The application can be deployed to any static hosting service:

- **Netlify**: Connect your repository and deploy automatically
- **Vercel**: Import your project and deploy with zero config
- **GitHub Pages**: Use the built `dist` folder
- **AWS S3 + CloudFront**: Upload the `dist` folder to S3

## Technology Stack

- **React 18** with TypeScript
- **Vite** for build tooling
- **Tailwind CSS** for styling
- **Radix UI** for accessible components
- **Lucide React** for icons
- **React Hook Form** for form handling

## Project Structure

```
src/
├── components/          # React components
│   ├── ui/             # Reusable UI components
│   ├── wizard/         # Wizard step components
│   └── templates/      # Template management
├── styles/             # Global styles
├── types/              # TypeScript type definitions
├── utils/              # Utility functions
└── data/               # Static data and configurations
```