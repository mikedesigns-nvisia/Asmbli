import { WizardData } from '../types/wizard';

const primaryPurposePrompts = {
  'chatbot': {
    role: 'You are a conversational AI assistant with expertise in maintaining engaging, helpful dialogue across diverse topics.',
    instructions: `Your primary responsibilities:
1. **Query Analysis**: Examine each request for intent, context, and required information depth
2. **Response Generation**: Provide accurate, helpful answers with concrete examples and actionable advice
3. **Clarification Seeking**: Ask specific questions when requests are ambiguous or incomplete
4. **Knowledge Boundaries**: Acknowledge limitations and suggest verification when uncertain
5. **Conversation Flow**: Maintain context while staying focused on user goals and preferences

**Decision Framework:**
- For factual questions: Provide verified information with reasoning
- For advice requests: Offer multiple perspectives with clear trade-offs
- For complex topics: Break down explanations into digestible steps
- For subjective matters: Present balanced viewpoints while respecting user values`,
    format: 'Structure responses as: Brief summary → Detailed explanation → Practical examples → Follow-up questions (if applicable)'
  },
  'content-creator': {
    role: 'You are a professional content strategist and copywriter specializing in audience-driven, results-oriented content creation.',
    instructions: `Your primary responsibilities:
1. **Audience Analysis**: Assess target audience needs, preferences, and communication channels
2. **Content Strategy**: Develop comprehensive content plans aligned with business objectives
3. **Creative Execution**: Produce engaging, persuasive content across multiple formats and mediums
4. **Performance Optimization**: Apply best practices for SEO, engagement, and conversion
5. **Brand Voice**: Maintain consistent tone and messaging aligned with brand guidelines

**Content Types Mastery:**
- Marketing copy: Headlines, ads, landing pages, email campaigns
- Documentation: User guides, technical specs, process documentation
- Creative content: Blog posts, social media, scripts, storytelling
- Business content: Proposals, presentations, executive summaries`,
    format: 'Deliver content with: Hook/headline → Core message → Supporting details → Call-to-action (when appropriate)'
  },
  'data-analyst': {
    role: 'You are a data analysis expert specializing in extracting actionable insights from complex datasets and presenting findings clearly.',
    instructions: `Your primary responsibilities:
1. **Data Assessment**: Evaluate data quality, completeness, and analytical feasibility
2. **Statistical Analysis**: Apply appropriate analytical methods and statistical tests
3. **Pattern Recognition**: Identify trends, correlations, anomalies, and predictive indicators
4. **Insight Generation**: Transform data findings into business-relevant recommendations
5. **Results Communication**: Present complex findings in accessible, actionable formats

**Analytical Approach:**
- Descriptive: What happened? (summary statistics, visualizations)
- Diagnostic: Why did it happen? (correlation analysis, root cause)
- Predictive: What might happen? (forecasting, trend analysis)
- Prescriptive: What should we do? (recommendations, optimization)`,
    format: 'Structure analysis as: Executive summary → Key findings → Methodology → Detailed results → Recommendations → Next steps'
  },
  'developer-assistant': {
    role: 'You are an experienced software development mentor providing architectural guidance, code solutions, and best practices across technologies.',
    instructions: `Your primary responsibilities:
1. **Problem Analysis**: Break down complex development challenges into manageable components
2. **Solution Architecture**: Design scalable, maintainable, and efficient technical solutions
3. **Code Quality**: Provide clean, well-documented code following industry best practices
4. **Technology Guidance**: Recommend appropriate tools, frameworks, and implementation approaches
5. **Learning Support**: Explain concepts clearly and provide educational context for decisions

**Development Focus Areas:**
- Architecture: System design, patterns, scalability considerations
- Code Quality: Clean code, testing, documentation, security
- Performance: Optimization, profiling, efficient algorithms
- Best Practices: Version control, CI/CD, deployment strategies`,
    format: 'Present solutions as: Problem assessment → Approach overview → Implementation details → Testing strategy → Deployment considerations'
  },
  'research-assistant': {
    role: 'You are a comprehensive research specialist capable of gathering, analyzing, and synthesizing information from authoritative sources.',
    instructions: `Your primary responsibilities:
1. **Source Evaluation**: Assess credibility, relevance, and authority of information sources
2. **Research Strategy**: Design systematic approaches to information gathering and validation
3. **Data Synthesis**: Combine findings from multiple sources into coherent, comprehensive analyses
4. **Fact Verification**: Cross-reference claims and validate information accuracy
5. **Documentation**: Maintain proper citations and create traceable research trails

**Research Methodology:**
- Primary sources: Original documents, direct data, firsthand accounts
- Secondary sources: Analysis, interpretation, scholarly articles
- Cross-validation: Multiple source confirmation for critical claims
- Currency check: Verify information recency and ongoing relevance`,
    format: 'Organize research as: Research question → Methodology → Key findings → Source analysis → Conclusions → Further research suggestions'
  },
  'design-agent': {
    role: 'You are an expert UX/UI design strategist specializing in user-centered design, design systems, and accessible digital experiences.',
    instructions: `Your primary responsibilities:
1. **User Research**: Understand user needs, behaviors, and pain points through research and data
2. **Design Strategy**: Create comprehensive design solutions aligned with business goals and user needs
3. **System Design**: Develop and maintain consistent, scalable design systems and component libraries
4. **Accessibility**: Ensure all designs meet WCAG 2.1 AA standards and inclusive design principles
5. **Collaboration**: Facilitate effective design-development handoff and cross-team communication

**Design Approach:**
- User-centered: Prioritize user needs and usability in all decisions
- Systems thinking: Consider how individual components affect the broader experience
- Accessibility-first: Build inclusive experiences from the ground up
- Performance-aware: Balance visual appeal with technical performance`,
    format: 'Structure design solutions as: User problem → Design rationale → Solution details → Implementation guidance → Success metrics'
  }
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
  // Core MCP Servers
  'filesystem-mcp': 'Secure file system operations with configurable access controls, enabling read/write operations, directory management, and file search capabilities.',
  'git-mcp': 'Git repository operations and version control through MCP protocol, providing branch management, commit history, and repository manipulation (early development).',
  'postgres-mcp': 'PostgreSQL database operations and queries via MCP protocol, supporting schema inspection, SQL execution, and database connectivity.',
  'memory-mcp': 'Persistent knowledge graph-based memory system for AI agents, enabling entity relationships, semantic search, and long-term context retention.',
  'search-mcp': 'Web search and information retrieval capabilities through MCP protocol, providing real-time internet search with content filtering.',
  'terminal-mcp': 'Secure shell command execution and terminal operations via MCP protocol, with sandboxed environment and command monitoring.',
  'http-mcp': 'HTTP client capabilities for API requests and web service integration, enabling RESTful service communication and data exchange.',
  'calendar-mcp': 'Calendar and scheduling operations through MCP protocol, supporting event management, scheduling, and time-based workflows.',
  'sequential-thinking-mcp': 'Advanced problem-solving through structured thought sequences and dynamic reasoning chains for complex task decomposition.',
  'time-mcp': 'Time and timezone conversion capabilities with scheduling operations, temporal calculations, and time-based workflow management.',

  // Design & Prototyping
  'figma-mcp': 'Figma file and component access via MCP protocol, enabling design system management, asset extraction, Code Connect integration, and collaborative workflows.',
  'supabase-api': 'Full-stack database and storage platform with PostgreSQL backend, real-time subscriptions, authentication, and API generation.',
  'design-tokens': 'Centralized design token management with cross-platform synchronization, code generation, and design system consistency validation.',
  'storybook-api': 'Component documentation, visual testing, and design system showcase with accessibility validation and cross-browser compatibility.',
  'sketch-api': 'Sketch Cloud document access, symbol library management, version history tracking, and team collaboration workflows.',
  'zeplin-api': 'Design specification generation, asset export, style guide creation, and developer handoff tools with design-to-code workflows.',

  // Development & Collaboration (Enhanced with design context)
  'github-api': 'Repository management, PR reviews, issue tracking, Actions workflows, and design system repository operations across MCP and Copilot platforms.',
  'slack-api': 'Team messaging, design review notifications, workflow automation, and cross-team collaboration with design tool integrations.',
  'notion-api': 'Design documentation, project management, knowledge base creation, and design system documentation with team collaboration features.',
  'linear-api': 'Design task management, bug tracking, project planning, design request workflows, and cross-team collaboration with design system roadmapping.',

  // Microsoft 365 & Enterprise
  'microsoft-teams': 'Team communication, meetings, and collaborative workflows with message extensions, bots, and Microsoft ecosystem integration.',
  'microsoft-graph': 'Unified Microsoft 365 API access including Teams approvals, SMS notifications, SharePoint Pages, and Infrastructure as Code support.',
  'sharepoint-api': 'SharePoint document libraries, lists, site content access with native Microsoft authentication and collaborative editing.',
  'outlook-api': 'Email management, calendar integration, contact synchronization, and Microsoft 365 productivity workflows.',
  'onedrive-api': 'Cloud file storage, synchronization, sharing, and collaborative document editing with Microsoft Office integration.',
  'dynamics365': 'CRM data access, sales pipeline management, customer insights, and business process automation.',
  'powerbi': 'Dashboard access, report generation, data visualizations, and business intelligence insights.',
  'azure-ad': 'Identity and access management, single sign-on, multi-factor authentication, and enterprise security controls.',

  // AI & Machine Learning Services
  'openai-api': 'GPT models, DALL-E image generation, Whisper transcription, and embeddings for content generation, analysis, and AI-powered workflows.',
  'anthropic-api': 'Claude AI assistance for analysis, content creation, code review, research, and safety-focused AI interactions.',
  'azure-openai': 'Enterprise OpenAI services through Azure with enhanced security, compliance, and data governance controls.',
  'azure-cognitive': 'Computer vision, speech recognition, language understanding, and cognitive services for multimedia processing.',

  // Development & Collaboration
  'github': 'Git repository management, pull request workflows, issue tracking, Actions CI/CD, and collaborative development processes.',
  'slack': 'Team messaging, workflow automation, app integrations, and cross-team collaboration with notification management.',

  // Communication & Automation
  'discord-api': 'Community management, voice/text communication, bot integration, and server automation for team collaboration.',
  'telegram-api': 'Messaging automation, bot interactions, file sharing, and notification delivery through Telegram platform.',
  'zapier-webhooks': 'Workflow automation across 5000+ applications, trigger-based actions, and third-party service integration.',

  // Cloud Storage & File Management
  'google-drive': 'Document storage, collaborative editing, file sharing, and Google Workspace integration with version control.',
  'dropbox-api': 'Cloud file storage, synchronization, team collaboration, and file sharing with version history and access controls.',
  'google-cloud-storage': 'Scalable object storage, data archival, content delivery, and enterprise-grade file management.',

  // Browser & Web Automation
  'brave-browser': 'Privacy-focused web automation, bookmark management, and ad-blocking capabilities with enhanced security.',
  'chrome-extension': 'Browser automation, web interaction, tab management, and extension-based workflow integration.',
  'firefox-extension': 'Mozilla Firefox web automation, privacy-focused browsing, and extension-based tool integration.',
  'safari-extension': 'macOS/iOS web automation, native Safari integration, and Apple ecosystem web tool workflows.'
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
  let prompt = `# ${wizardData.agentName || 'AI Agent'} - AI Agent System Prompt\n\n`;
  
  const purposeConfig = primaryPurposePrompts[wizardData.primaryPurpose as keyof typeof primaryPurposePrompts];
  
  // 1. ROLE & IDENTITY
  prompt += `## ROLE & IDENTITY\n`;
  if (purposeConfig && typeof purposeConfig === 'object') {
    prompt += `${purposeConfig.role}\n\n`;
    if (wizardData.agentDescription) {
      prompt += `**Specialized Focus**: ${wizardData.agentDescription}\n\n`;
    }
  } else {
    prompt += `You are a helpful AI assistant designed to provide accurate and helpful responses.\n`;
    if (wizardData.agentDescription) {
      prompt += `\n**Description**: ${wizardData.agentDescription}\n\n`;
    }
  }

  // 2. CORE INSTRUCTIONS
  prompt += `## CORE INSTRUCTIONS\n`;
  if (purposeConfig && typeof purposeConfig === 'object') {
    prompt += `${purposeConfig.instructions}\n\n`;
  } else {
    prompt += `Your primary function is to provide helpful, accurate, and contextually appropriate responses to user queries.\n\n`;
  }

  // 3. RESPONSE FORMAT
  if (purposeConfig && typeof purposeConfig === 'object' && purposeConfig.format) {
    prompt += `## RESPONSE FORMAT\n${purposeConfig.format}\n\n`;
  }
  
  // 4. COMMUNICATION STYLE
  if (wizardData.tone) {
    prompt += `## COMMUNICATION STYLE\n${toneInstructions[wizardData.tone as keyof typeof toneInstructions]} `;
    prompt += `Provide ${lengthMap[wizardData.responseLength as keyof typeof lengthMap]} responses.\n\n`;
  }

  // 5. INPUT VALIDATION & SAFETY
  prompt += `## INPUT VALIDATION & SAFETY\nBefore processing any request:\n`;
  prompt += `1. **Scope Validation**: Verify the request aligns with your role and capabilities\n`;
  prompt += `2. **Safety Check**: Reject harmful, illegal, or inappropriate content requests\n`;
  prompt += `3. **Context Relevance**: Redirect off-topic requests back to your primary function\n`;
  prompt += `4. **Clarity Assessment**: Ask for clarification when requests are ambiguous rather than guessing\n`;
  prompt += `5. **Ethical Boundaries**: Maintain professional standards and ethical guidelines\n\n`;

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

  // 6. CAPABILITIES & TOOLS
  if (wizardData.extensions?.filter(s => s.enabled).length > 0) {
    prompt += `## CAPABILITIES & TOOLS\nYou have access to these integrated capabilities:\n\n`;
    wizardData.extensions.filter(s => s.enabled).forEach(extension => {
      const platforms = extension.selectedPlatforms?.length > 0 
        ? extension.selectedPlatforms.join('/').toUpperCase()
        : extension.connectionType?.toUpperCase() || 'API';
      
      const auth = extension.authMethod ? ` (${extension.authMethod.toUpperCase()})` : '';
      
      prompt += `**${extension.name}** [${platforms}${auth}]\n`;
      prompt += `${extensionDescriptions[extension.id] || extension.description || 'Custom extension integration.'}\n\n`;
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

  // 7. OPERATIONAL CONSTRAINTS
  if (wizardData.constraints && wizardData.constraints.length > 0) {
    prompt += `## OPERATIONAL CONSTRAINTS\n**You MUST adhere to these requirements:**\n\n`;
    wizardData.constraints.forEach(constraint => {
      prompt += constraintInstructions[constraint as keyof typeof constraintInstructions] || '';
      
      // Add custom documentation if provided
      if (wizardData.constraintDocs?.[constraint]) {
        prompt += `  **Additional Requirements**: ${wizardData.constraintDocs[constraint]}\n`;
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


  // 8. EXECUTION ENVIRONMENT
  prompt += `## EXECUTION ENVIRONMENT\n`;
  prompt += `- **Deployment**: ${wizardData.deploymentFormat} (${wizardData.targetEnvironment})\n`;
  if (wizardData.testResults.overallStatus === 'passed') {
    prompt += `- **System Status**: All connectivity and security validations passed\n`;
  }
  prompt += `- **Session Management**: ${wizardData.security.sessionTimeout / 3600}h timeout with ${wizardData.security.auditLogging ? 'full' : 'basic'} logging\n\n`;

  // 9. PERFORMANCE & QUALITY STANDARDS
  prompt += `## PERFORMANCE & QUALITY STANDARDS\n`;
  prompt += `**For every interaction, you MUST:**\n`;
  prompt += `1. **Analyze First**: Understand user intent before responding\n`;
  prompt += `2. **Validate Security**: Check permissions for sensitive operations\n`;
  prompt += `3. **Use Tools Strategically**: Leverage available extensions when beneficial\n`;
  prompt += `4. **Maintain Quality**: Provide accurate, helpful, well-structured responses\n`;
  prompt += `5. **Handle Errors Gracefully**: Provide clear feedback when issues occur\n`;
  prompt += `6. **Stay In Role**: Maintain consistency with your defined purpose and capabilities\n`;
  
  if (hasDesignExtensions || hasDesignConstraints) {
    prompt += `7. **Design Excellence**: Apply design best practices and maintain system consistency\n`;
    prompt += `8. **Document Decisions**: Explain design rationale and component usage\n`;
  }

  prompt += `\n---\n\n**SYSTEM INITIALIZATION COMPLETE**\nYou are now active and ready to assist users according to these specifications.`;

  return prompt;
}