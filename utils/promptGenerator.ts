import { WizardData } from '../types/wizard';

const primaryPurposePrompts = {
  'chatbot': 'You are a sophisticated AI assistant designed for conversational interactions. Your core competency lies in understanding context, maintaining conversation flow, and providing helpful responses across various topics.',
  'content-creator': 'You are a professional content creator and copywriter. Your expertise encompasses creating engaging, persuasive, and well-structured content for various mediums including marketing, documentation, and creative writing.',
  'data-analyst': 'You are a data analysis expert specializing in extracting insights from complex information. You excel at pattern recognition, trend analysis, statistical interpretation, and presenting findings in clear, actionable formats.',
  'developer-assistant': 'You are an experienced software development mentor and coding assistant. You provide accurate code solutions, architectural guidance, best practices, and technical problem-solving across multiple programming languages and frameworks.',
  'research-assistant': 'You are a comprehensive research assistant capable of gathering, analyzing, and synthesizing information from multiple sources. You excel at fact-checking, citation management, and presenting research findings in structured formats.',
  'design-agent': 'You are an expert design agent specializing in user experience, visual design, and design systems. You excel at creating consistent, accessible, and user-centered design solutions while maintaining brand guidelines and component library standards.'
};

const toneInstructions = {
  professional: 'Maintain a professional, business-appropriate tone in all communications. Use formal language, focus on clarity and accuracy, and ensure responses meet enterprise standards.',
  friendly: 'Be warm, approachable, and conversational in your responses. Use a welcoming tone that makes users feel comfortable while maintaining helpful and informative dialogue.',
  technical: 'Provide precise, technical, and detailed responses. Use appropriate technical terminology, focus on accuracy and completeness, and include relevant technical context.',
  creative: 'Be creative, imaginative, and think outside conventional boundaries. Use engaging language, explore innovative solutions, and encourage creative problem-solving approaches.',
  analytical: 'Focus on logical reasoning, data-driven insights, and systematic analysis. Present information in structured formats with clear evidence and reasoning chains.'
};

const lengthMap = {
  1: 'very concise (under 100 words)',
  2: 'concise (100-200 words)', 
  3: 'balanced (200-400 words)',
  4: 'detailed (400-600 words)',
  5: 'comprehensive (600+ words)'
};

const extensionDescriptions: Record<string, string> = {
  // Design & Prototyping
  'figma-mcp': 'Figma file and component access via MCP protocol, enabling design system management, asset extraction, and collaborative design workflows.',
  'supabase-api': 'Full-stack database and storage for design data, user feedback, version control, and real-time collaboration with PostgreSQL backend.',
  'design-tokens': 'Centralized design token management with cross-platform synchronization, code generation, and design system consistency validation.',
  'storybook-api': 'Component documentation, visual testing, and design system showcase with accessibility validation and cross-browser compatibility.',
  'sketch-api': 'Sketch Cloud document access, symbol library management, version history tracking, and team collaboration workflows.',
  'zeplin-api': 'Design specification generation, asset export, style guide creation, and developer handoff tools with design-to-code workflows.',

  // Development & Collaboration (Enhanced with design context)
  'github-api': 'Repository management, PR reviews, issue tracking, Actions workflows, and design system repository operations across MCP and Copilot platforms.',
  'slack-api': 'Team messaging, design review notifications, workflow automation, and cross-team collaboration with design tool integrations.',
  'notion-api': 'Design documentation, project management, knowledge base creation, and design system documentation with team collaboration features.',
  'linear-api': 'Design task management, bug tracking, project planning, design request workflows, and cross-team collaboration with design system roadmapping.',

  // Traditional Extensions
  'sharepoint': 'Access documents, lists, libraries, and site content with native Microsoft authentication and permissions.',
  'teams': 'Message extensions, bots, workflows, and team collaboration tools integrated with Microsoft ecosystem.',
  'dynamics365': 'CRM data access, sales pipeline management, customer insights, and business process automation.',
  'powerbi': 'Dashboard access, report generation, data visualizations, and business intelligence insights.',
  'openai-api': 'GPT models, DALL-E image generation, Whisper transcription, and embeddings across multiple platforms for design content generation.',
  'anthropic-api': 'Claude AI assistance for design analysis, accessibility auditing, design system consistency checks, and documentation improvement.',
  'azure': 'Azure services integration with Active Directory, resource management, and cloud-native authentication.',
  'filesystem': 'Secure file system operations including design asset management, read, write, and directory operations with permission controls.',
  'web-search': 'Real-time internet search for design inspiration, trend analysis, and competitive research with content filtering.',
  'database': 'SQL database operations and vector similarity searches for design data, component metadata, and design system analytics.',
  'api-gateway': 'Secure external API integrations and third-party design service connections with authentication.',
  'computation': 'Mathematical computation, design calculations, and algorithmic processing capabilities for design optimization.',
  'monitoring': 'System monitoring, design performance tracking, and audit trail integration with design tool usage analytics.',
  'google-analytics': 'Design performance metrics, user behavior analysis, and design impact measurement for data-driven design decisions.',
  'mixpanel-api': 'Component interaction tracking, design experiment analysis, and user behavior funnels for design optimization.',
  'google-drive': 'Design asset management, collaborative document editing, version history, and design file synchronization.',
  'dropbox-api': 'Cloud storage for design assets, collaborative file access, version history, and design feedback collection workflows.'
};

const constraintInstructions = {
  citations: '- **Source Attribution**: Always cite sources and provide references when using external information, including MCP server data sources.\n',
  json: '- **Structured Output**: Return responses in valid JSON format when requested, ensuring proper schema validation and formatting.\n',
  token: '- **Response Optimization**: Keep responses under 500 tokens when possible to optimize for cost and latency while maintaining quality.\n',
  persona: '- **Consistency**: Maintain established character, voice, and behavioral patterns throughout multi-turn conversations.\n',
  safety: '- **Content Safety**: Apply comprehensive content filtering to avoid generating harmful, biased, or inappropriate content with audit logging.\n',
  branding: '- **Brand Alignment**: Follow organizational brand voice, terminology, and messaging guidelines consistently across all interactions.\n',
  compliance: '- **Regulatory Compliance**: Ensure all responses meet industry-specific regulatory requirements and data handling standards.\n',
  performance: '- **Performance Monitoring**: Track response times, accuracy metrics, and user satisfaction scores for continuous improvement.\n',
  
  // Design-specific constraints
  'design-system': '- **Design System Compliance**: Always reference and follow established design system guidelines, component libraries, and design patterns to ensure consistency.\n',
  'accessibility': '- **Accessibility Standards**: Apply WCAG 2.1 AA accessibility guidelines to all design decisions, ensuring inclusive and compliant design solutions.\n',
  'responsive-design': '- **Responsive Design**: Consider mobile-first design principles and ensure optimal experiences across all device sizes and breakpoints.\n',
  'brand-consistency': '- **Visual Brand Consistency**: Adhere strictly to brand colors, typography, visual identity guidelines, and maintain cohesive brand experience.\n',
  'figma-integration': '- **Figma File Standards**: Follow Figma naming conventions, layer organization, component structure, and file management best practices.\n',
  'design-tokens': '- **Design Tokens**: Use design tokens for all color, spacing, typography, and component decisions to ensure scalable and maintainable design systems.\n'
};

export function generatePrompt(wizardData: WizardData): string {
  let prompt = `# ${wizardData.agentName || 'AI Agent'} System Configuration\n\n`;
  
  if (wizardData.agentDescription) {
    prompt += `## Agent Description\n${wizardData.agentDescription}\n\n`;
  }

  prompt += `## Primary Function\n${primaryPurposePrompts[wizardData.primaryPurpose as keyof typeof primaryPurposePrompts] || 'You are a helpful AI assistant designed to provide accurate and helpful responses.'}\n\n`;
  
  if (wizardData.tone) {
    prompt += `## Communication Guidelines\n${toneInstructions[wizardData.tone as keyof typeof toneInstructions]} `;
    prompt += `Provide ${lengthMap[wizardData.responseLength as keyof typeof lengthMap]} responses.\n\n`;
  }

  // Check if this is a design-focused agent
  const hasDesignExtensions = wizardData.extensions?.some(ext => 
    ext.enabled && ['figma-mcp', 'storybook-api', 'design-tokens', 'sketch-api', 'zeplin-api', 'supabase-api'].includes(ext.id)
  );

  const hasDesignConstraints = wizardData.constraints?.some(constraint =>
    ['design-system', 'accessibility', 'responsive-design', 'brand-consistency', 'figma-integration', 'design-tokens'].includes(constraint)
  );

  // Add design-specific context if this is a design agent
  if (hasDesignExtensions || hasDesignConstraints) {
    prompt += `## Design Agent Specialization\n`;
    prompt += `You are a specialized design agent with expertise in:\n`;
    prompt += `- User experience and interface design principles\n`;
    prompt += `- Design system development and maintenance\n`;
    prompt += `- Component library management and documentation\n`;
    prompt += `- Accessibility compliance and inclusive design\n`;
    prompt += `- Brand guidelines and visual consistency\n`;
    prompt += `- Cross-platform design considerations\n`;
    prompt += `- Design tool integration and workflow optimization\n\n`;

    if (hasDesignExtensions) {
      prompt += `## Design Tool Integration\n`;
      prompt += `Your design capabilities are enhanced through direct integration with design tools and platforms. `;
      prompt += `Always leverage these integrations to:\n`;
      prompt += `- Sync with existing component libraries and design systems\n`;
      prompt += `- Maintain consistency with established design patterns\n`;
      prompt += `- Generate specifications and documentation automatically\n`;
      prompt += `- Collaborate effectively with design and development teams\n`;
      prompt += `- Track design performance and user feedback\n\n`;
    }
  }

  if (wizardData.extensions?.filter(s => s.enabled).length > 0) {
    prompt += `## Extensions & Integrations\nYou have access to the following extensions and their capabilities:\n\n`;
    wizardData.extensions.filter(s => s.enabled).forEach(extension => {
      prompt += `### ${extension.name || 'Unknown Extension'}\n`;
      prompt += `- **Category**: ${extension.category || 'General'}\n`;
      
      // Handle selectedPlatforms safely
      if (extension.selectedPlatforms && Array.isArray(extension.selectedPlatforms) && extension.selectedPlatforms.length > 0) {
        prompt += `- **Platforms**: ${extension.selectedPlatforms.join(', ').toUpperCase()}\n`;
      } else if (extension.connectionType) {
        prompt += `- **Connection Type**: ${extension.connectionType.toUpperCase()}\n`;
      } else {
        prompt += `- **Platforms**: API\n`;
      }
      
      // Handle complexity/security level safely
      if (extension.complexity) {
        prompt += `- **Complexity**: ${extension.complexity.toUpperCase()}\n`;
      } else if (extension.setupComplexity) {
        prompt += `- **Setup Complexity**: Level ${extension.setupComplexity}\n`;
      }

      // Add authentication method if available
      if (extension.authMethod) {
        prompt += `- **Authentication**: ${extension.authMethod.toUpperCase()}\n`;
      }

      // Add pricing information if available
      if (extension.pricing) {
        prompt += `- **Pricing**: ${extension.pricing.toUpperCase()}\n`;
      }

      prompt += `- **Description**: ${extensionDescriptions[extension.id] || extension.description || 'Custom extension integration.'}\n\n`;
    });
  }

  if (wizardData.security.authMethod) {
    prompt += `## Security Configuration\n`;
    prompt += `- **Authentication**: ${wizardData.security.authMethod.toUpperCase()}\n`;
    prompt += `- **Permissions**: ${wizardData.security.permissions.join(', ')}\n`;
    if (wizardData.security.vaultIntegration !== 'none') {
      prompt += `- **Secret Management**: ${wizardData.security.vaultIntegration}\n`;
    }
    if (wizardData.security.auditLogging) {
      prompt += `- **Audit Logging**: Enabled with full request/response tracking\n`;
    }
    prompt += `- **Session Management**: ${wizardData.security.sessionTimeout / 3600} hour timeout\n\n`;
  }

  if (wizardData.constraints && wizardData.constraints.length > 0) {
    prompt += `## Operational Constraints\n`;
    wizardData.constraints.forEach(constraint => {
      prompt += constraintInstructions[constraint as keyof typeof constraintInstructions] || '';
      
      // Add custom documentation if provided
      if (wizardData.constraintDocs?.[constraint]) {
        prompt += `  **Custom Requirements**: ${wizardData.constraintDocs[constraint]}\n`;
      }
    });
    prompt += '\n';
  }

  // Add design-specific operational guidelines if this is a design agent
  if (hasDesignExtensions || hasDesignConstraints) {
    prompt += `## Design-Specific Guidelines\n`;
    prompt += `When working on design tasks:\n`;
    prompt += `1. **Component First**: Always check existing component libraries before creating new components\n`;
    prompt += `2. **System Thinking**: Consider how design decisions impact the overall design system\n`;
    prompt += `3. **Accessibility**: Ensure all designs meet WCAG 2.1 AA standards\n`;
    prompt += `4. **Documentation**: Create clear usage guidelines and component documentation\n`;
    prompt += `5. **Collaboration**: Facilitate effective handoff between design and development teams\n`;
    prompt += `6. **Brand Consistency**: Maintain visual consistency with established brand guidelines\n`;
    prompt += `7. **User Research**: Consider user needs and behavior in all design decisions\n`;
    prompt += `8. **Performance**: Optimize designs for web performance and loading times\n\n`;
  }

  prompt += `## Execution Environment\n`;
  prompt += `- **Target Environment**: ${wizardData.targetEnvironment}\n`;
  prompt += `- **Deployment Model**: ${wizardData.deploymentFormat}\n`;
  if (wizardData.testResults.overallStatus === 'passed') {
    prompt += `- **System Status**: All connectivity and security tests passed\n`;
  }

  prompt += `\n## Operational Instructions\n`;
  prompt += `1. **Request Analysis**: Carefully analyze each user request for context, intent, and appropriate extension utilization\n`;
  prompt += `2. **Security Validation**: Verify user permissions and security constraints before processing sensitive operations\n`;
  prompt += `3. **Resource Utilization**: Use available extensions strategically to enhance response quality and accuracy\n`;
  prompt += `4. **Error Handling**: Implement graceful error handling with informative user feedback and audit logging\n`;
  prompt += `5. **Performance Monitoring**: Track and optimize response times while maintaining quality standards\n`;

  if (hasDesignExtensions || hasDesignConstraints) {
    prompt += `6. **Design Integration**: Leverage design tool integrations to maintain consistency and automate workflows\n`;
    prompt += `7. **Design Documentation**: Maintain comprehensive documentation for all design decisions and component usage\n`;
  }

  prompt += `\n**System Status**: Ready to assist users according to these specifications with full extension integration and security controls active.`;

  return prompt;
}