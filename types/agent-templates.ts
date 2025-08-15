export interface AgentTemplate {
  id: string;
  name: string;
  description: string;
  category: 'design' | 'content' | 'analysis' | 'code' | 'research' | 'conversation';
  icon: string;
  targetRole: 'beginner' | 'power_user' | 'enterprise';
  isPreConfigured: boolean;
  
  // Pre-configured settings
  config: {
    // Agent Profile
    agentName: string;
    agentDescription: string;
    primaryPurpose: string;
    
    // Extensions/MCPs
    requiredMcps: string[];
    optionalMcps: string[];
    
    // Security (restricted for free users)
    securitySettings: {
      authMethod: 'none' | 'basic' | 'oauth' | 'enterprise';
      permissions: string[];
      localOnly: boolean;
    };
    
    // Deployment
    recommendedDeployment: string[];
    
    // Specialized features
    specialFeatures: {
      uploadSupport?: {
        enabled: boolean;
        allowedTypes: string[];
        maxFileSize: string;
        description: string;
      };
      designTools?: {
        figmaIntegration: boolean;
        prototyping: boolean;
        designSystems: boolean;
      };
    };
  };
  
  // User questionnaire triggers
  triggers: {
    primaryPurpose?: string[];
    technicalLevel?: string[];
    expectedUsers?: string[];
    customFields?: Record<string, string[]>;
  };
}

// Pro agent templates for power users
export const POWER_USER_AGENT_TEMPLATES: AgentTemplate[] = [
  {
    id: 'figma-design-engineer-pro',
    name: 'UI Engineer',
    description: 'Premium design-to-code specialist with enterprise Figma integration. Pre-optimized workflows for professional design teams and agencies.',
    category: 'design',
    icon: '🎯',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'UI Engineer',
      agentDescription: 'I bridge design and development by extracting assets from Figma, generating component code, maintaining design systems, and ensuring pixel-perfect implementations.',
      primaryPurpose: 'designer',
      requiredMcps: ['figma-mcp', 'file-manager-mcp', 'git-mcp', 'code-formatter-mcp'],
      optionalMcps: ['design-tokens-mcp', 'storybook-mcp', 'tailwind-mcp', 'chromatic-mcp'],
      securitySettings: {
        authMethod: 'oauth',
        permissions: ['read', 'write', 'execute'],
        localOnly: false
      },
      recommendedDeployment: ['claude-desktop', 'vscode-extension', 'api-server'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.fig', '.sketch', '.svg', '.png', '.jpg', '.json', '.ts', '.tsx', '.css'],
          maxFileSize: '200MB',
          description: 'Upload Figma files, design tokens, component specs, and style guides'
        },
        designTools: {
          figmaIntegration: true,
          prototyping: true,
          designSystems: true
        }
      }
    },
    triggers: {
      primaryPurpose: ['designer', 'coder'],
      technicalLevel: ['advanced'],
      expectedUsers: ['team', 'company'],
      customFields: {
        designTools: ['figma', 'sketch', 'adobe-xd'],
        codeFramework: ['react', 'vue', 'angular']
      }
    }
  },
  {
    id: 'fullstack-architect-pro',
    name: 'Full-Stack Architect',
    description: 'Premium full-stack development suite with enterprise tooling. Pre-configured for complex architectures, automated deployments, and professional workflows.',
    category: 'code',
    icon: '🏗️',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'Full-Stack Architect',
      agentDescription: 'I design and implement complex software architectures, manage deployments, optimize performance, and maintain enterprise-grade codebases with best practices.',
      primaryPurpose: 'coder',
      requiredMcps: ['git-mcp', 'docker-mcp', 'kubernetes-mcp', 'aws-mcp', 'database-mcp'],
      optionalMcps: ['terraform-mcp', 'monitoring-mcp', 'security-scan-mcp', 'load-test-mcp'],
      securitySettings: {
        authMethod: 'oauth',
        permissions: ['read', 'write', 'execute', 'deploy'],
        localOnly: false
      },
      recommendedDeployment: ['api-server', 'cloud-deployment'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.js', '.ts', '.py', '.java', '.go', '.rs', '.yaml', '.json', '.sql', '.tf'],
          maxFileSize: '500MB',
          description: 'Upload codebases, configuration files, deployment specs, and documentation'
        }
      }
    },
    triggers: {
      primaryPurpose: ['coder'],
      technicalLevel: ['advanced'],
      expectedUsers: ['team', 'company'],
      customFields: {
        deploymentType: ['cloud', 'enterprise', 'microservices'],
        techStack: ['node', 'python', 'java', 'go', 'rust']
      }
    }
  },
  {
    id: 'data-science-analyst-pro',
    name: 'Data Science Analyst',
    description: 'Premium data science platform with enterprise ML/AI capabilities. Pre-optimized for professional data teams and advanced analytics workflows.',
    category: 'analysis',
    icon: '🧬',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'Data Science Analyst',
      agentDescription: 'I perform advanced data analysis, build machine learning models, conduct statistical tests, and create comprehensive data visualizations and reports.',
      primaryPurpose: 'analyzer',
      requiredMcps: ['python-mcp', 'jupyter-mcp', 'pandas-mcp', 'visualization-mcp'],
      optionalMcps: ['tensorflow-mcp', 'pytorch-mcp', 'scikit-learn-mcp', 'sql-mcp', 'r-mcp'],
      securitySettings: {
        authMethod: 'oauth',
        permissions: ['read', 'write', 'execute'],
        localOnly: false
      },
      recommendedDeployment: ['jupyter-server', 'cloud-notebook'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.csv', '.xlsx', '.json', '.parquet', '.h5', '.pkl', '.ipynb', '.py', '.r'],
          maxFileSize: '1GB',
          description: 'Upload large datasets, trained models, notebooks, and analysis scripts'
        }
      }
    },
    triggers: {
      primaryPurpose: ['analyzer', 'researcher'],
      technicalLevel: ['advanced'],
      expectedUsers: ['team', 'company'],
      customFields: {
        analysisType: ['machine-learning', 'statistics', 'big-data'],
        dataSource: ['databases', 'apis', 'files', 'streams']
      }
    }
  },
  {
    id: 'devops-engineer-pro',
    name: 'DevOps Engineer',
    description: 'Premium DevOps automation suite with enterprise infrastructure tools. Pre-configured for professional deployment pipelines and cloud management.',
    category: 'code',
    icon: '⚙️',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'DevOps Engineer',
      agentDescription: 'I automate deployments, manage infrastructure as code, implement monitoring solutions, and ensure secure, scalable, reliable systems.',
      primaryPurpose: 'coder',
      requiredMcps: ['docker-mcp', 'kubernetes-mcp', 'terraform-mcp', 'aws-mcp', 'monitoring-mcp'],
      optionalMcps: ['azure-mcp', 'gcp-mcp', 'ansible-mcp', 'jenkins-mcp', 'prometheus-mcp'],
      securitySettings: {
        authMethod: 'oauth',
        permissions: ['read', 'write', 'execute', 'deploy', 'admin'],
        localOnly: false
      },
      recommendedDeployment: ['api-server', 'cloud-deployment'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.yaml', '.yml', '.tf', '.json', '.sh', '.ps1', '.dockerfile', '.helm'],
          maxFileSize: '100MB',
          description: 'Upload infrastructure configs, deployment scripts, and automation templates'
        }
      }
    },
    triggers: {
      primaryPurpose: ['coder'],
      technicalLevel: ['advanced'],
      expectedUsers: ['team', 'company'],
      customFields: {
        cloudProvider: ['aws', 'azure', 'gcp', 'hybrid'],
        infrastructure: ['containers', 'serverless', 'traditional']
      }
    }
  },
  {
    id: 'security-analyst-pro',
    name: 'Security Analyst',
    description: 'Premium cybersecurity platform with enterprise threat detection. Pre-configured for professional security teams and compliance requirements.',
    category: 'analysis',
    icon: '🔒',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'Security Analyst',
      agentDescription: 'I conduct security assessments, analyze threats, implement security controls, and ensure compliance with security standards and regulations.',
      primaryPurpose: 'analyzer',
      requiredMcps: ['security-scan-mcp', 'vulnerability-mcp', 'compliance-mcp', 'log-analysis-mcp'],
      optionalMcps: ['penetration-test-mcp', 'threat-intel-mcp', 'siem-mcp', 'crypto-mcp'],
      securitySettings: {
        authMethod: 'enterprise',
        permissions: ['read', 'analyze', 'audit'],
        localOnly: true
      },
      recommendedDeployment: ['secure-server', 'air-gapped'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.log', '.pcap', '.json', '.xml', '.csv', '.txt', '.yaml'],
          maxFileSize: '2GB',
          description: 'Upload security logs, network captures, configuration files, and audit reports'
        }
      }
    },
    triggers: {
      primaryPurpose: ['analyzer'],
      technicalLevel: ['advanced'],
      expectedUsers: ['company'],
      customFields: {
        securityFocus: ['vulnerability-assessment', 'compliance', 'incident-response'],
        industryType: ['financial', 'healthcare', 'government', 'enterprise']
      }
    }
  },
  {
    id: 'content-strategist-pro',
    name: 'Content Strategist',
    description: 'Premium content marketing platform with enterprise analytics. Pre-optimized for professional marketing teams and data-driven campaigns.',
    category: 'content',
    icon: '📈',
    targetRole: 'power_user',
    isPreConfigured: true,
    config: {
      agentName: 'Content Strategist',
      agentDescription: 'I develop data-driven content strategies, create multi-channel campaigns, analyze performance metrics, and optimize content for maximum engagement and conversion.',
      primaryPurpose: 'content',
      requiredMcps: ['analytics-mcp', 'seo-tools-mcp', 'social-media-mcp', 'content-management-mcp'],
      optionalMcps: ['email-marketing-mcp', 'ad-platforms-mcp', 'crm-mcp', 'ab-testing-mcp'],
      securitySettings: {
        authMethod: 'oauth',
        permissions: ['read', 'write', 'publish'],
        localOnly: false
      },
      recommendedDeployment: ['api-server', 'cloud-service'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.txt', '.md', '.docx', '.pdf', '.csv', '.xlsx', '.json', '.html'],
          maxFileSize: '200MB',
          description: 'Upload content assets, brand guidelines, analytics reports, and campaign data'
        }
      }
    },
    triggers: {
      primaryPurpose: ['content'],
      technicalLevel: ['advanced'],
      expectedUsers: ['team', 'company'],
      customFields: {
        contentType: ['blog', 'social', 'email', 'video', 'multi-channel'],
        marketingGoals: ['awareness', 'conversion', 'retention', 'engagement']
      }
    }
  }
];

// Pre-configured agent templates for consumers
export const BEGINNER_AGENT_TEMPLATES: AgentTemplate[] = [
  {
    id: 'design-prototyper-free',
    name: 'Design Assistant',
    description: 'Your personal design helper that creates mockups, suggests improvements, and manages design files. Works with Figma and other design tools.',
    category: 'design',
    icon: '🎨',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Design Assistant',
      agentDescription: 'I help you create beautiful designs, organize your design files, and turn your ideas into visual mockups quickly and easily.',
      primaryPurpose: 'designer',
      requiredMcps: ['figma-mcp', 'file-manager-mcp'],
      optionalMcps: ['image-generator-mcp', 'color-palette-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read', 'write'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.sketch', '.fig', '.png', '.jpg', '.svg', '.pdf'],
          maxFileSize: '50MB',
          description: 'Upload design files, inspiration images, and documentation'
        },
        designTools: {
          figmaIntegration: true,
          prototyping: true,
          designSystems: true
        }
      }
    },
    triggers: {
      primaryPurpose: ['designer'],
      technicalLevel: ['beginner', 'intermediate'],
      expectedUsers: ['personal', 'team']
    }
  },
  {
    id: 'content-writer-free',
    name: 'Writing Assistant',
    description: 'Your personal writer that creates blog posts, social media content, and emails in your style and tone.',
    category: 'content',
    icon: '✍️',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Writing Assistant',
      agentDescription: 'I help you write engaging content for any platform, maintaining your unique voice and style while saving you hours of work.',
      primaryPurpose: 'content',
      requiredMcps: ['web-search-mcp', 'file-manager-mcp'],
      optionalMcps: ['seo-tools-mcp', 'grammar-check-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read', 'write'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.txt', '.md', '.docx', '.pdf'],
          maxFileSize: '25MB',
          description: 'Upload brand guidelines, existing content, and reference materials'
        }
      }
    },
    triggers: {
      primaryPurpose: ['content'],
      technicalLevel: ['beginner', 'intermediate']
    }
  },
  {
    id: 'research-assistant-free',
    name: 'Research Helper',
    description: 'Your smart researcher that finds information, reads documents, and creates summaries for you.',
    category: 'research',
    icon: '🔍',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Research Helper',
      agentDescription: 'I gather information from multiple sources, read through documents for you, and create clear summaries of what you need to know.',
      primaryPurpose: 'researcher',
      requiredMcps: ['web-search-mcp', 'pdf-reader-mcp', 'file-manager-mcp'],
      optionalMcps: ['citation-manager-mcp', 'academic-search-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.pdf', '.txt', '.docx', '.csv', '.xlsx'],
          maxFileSize: '100MB',
          description: 'Upload research papers, documents, and datasets for analysis'
        }
      }
    },
    triggers: {
      primaryPurpose: ['researcher'],
      technicalLevel: ['beginner', 'intermediate', 'advanced']
    }
  },
  {
    id: 'chatbot-free',
    name: 'Customer Support Bot',
    description: 'A friendly assistant that answers customer questions, provides support, and handles common inquiries 24/7.',
    category: 'conversation',
    icon: '💬',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Support Assistant',
      agentDescription: 'I help your customers get answers quickly, provide friendly support around the clock, and know when to connect them with a human agent.',
      primaryPurpose: 'chatbot',
      requiredMcps: ['knowledge-base-mcp'],
      optionalMcps: ['sentiment-analysis-mcp', 'translation-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.txt', '.csv', '.json', '.pdf'],
          maxFileSize: '25MB',
          description: 'Upload knowledge base files, FAQs, and training data'
        }
      }
    },
    triggers: {
      primaryPurpose: ['chatbot'],
      expectedUsers: ['personal', 'team', 'company']
    }
  },
  {
    id: 'code-helper-free',
    name: 'Coding Helper',
    description: 'Your programming buddy that helps fix bugs, explains code, and writes documentation.',
    category: 'code',
    icon: '💻',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Coding Helper',
      agentDescription: 'I help you understand code, fix bugs, write better programs, and explain complex concepts in simple terms.',
      primaryPurpose: 'coder',
      requiredMcps: ['file-manager-mcp', 'git-mcp'],
      optionalMcps: ['code-formatter-mcp', 'test-generator-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read', 'write'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.js', '.ts', '.py', '.java', '.cpp', '.html', '.css', '.json', '.md'],
          maxFileSize: '50MB',
          description: 'Upload source code files and project documentation'
        }
      }
    },
    triggers: {
      primaryPurpose: ['coder'],
      technicalLevel: ['beginner', 'intermediate', 'advanced']
    }
  },
  {
    id: 'data-analyzer-free',
    name: 'Data Analysis Helper',
    description: 'Your data expert that turns spreadsheets and data into insights, charts, and reports.',
    category: 'analysis',
    icon: '📊',
    targetRole: 'beginner',
    isPreConfigured: true,
    config: {
      agentName: 'Your Data Analyst',
      agentDescription: 'I analyze your data, find important patterns, create easy-to-understand charts, and explain what the numbers mean for your business.',
      primaryPurpose: 'analyzer',
      requiredMcps: ['csv-reader-mcp', 'chart-generator-mcp'],
      optionalMcps: ['statistics-mcp', 'excel-mcp'],
      securitySettings: {
        authMethod: 'none',
        permissions: ['read'],
        localOnly: true
      },
      recommendedDeployment: ['claude-desktop', 'lm-studio'],
      specialFeatures: {
        uploadSupport: {
          enabled: true,
          allowedTypes: ['.csv', '.xlsx', '.json', '.sql', '.txt'],
          maxFileSize: '100MB',
          description: 'Upload datasets, spreadsheets, and data files for analysis'
        }
      }
    },
    triggers: {
      primaryPurpose: ['analyzer'],
      expectedUsers: ['personal', 'team', 'company']
    }
  }
];

// Combined template collections
export function getAllTemplates(userRole: 'beginner' | 'power_user' | 'enterprise' = 'beginner'): AgentTemplate[] {
  switch (userRole) {
    case 'power_user':
      return [...POWER_USER_AGENT_TEMPLATES, ...BEGINNER_AGENT_TEMPLATES];
    case 'enterprise':
      return [...POWER_USER_AGENT_TEMPLATES, ...BEGINNER_AGENT_TEMPLATES];
    default:
      return BEGINNER_AGENT_TEMPLATES;
  }
}

// Template matching algorithm
export function findMatchingTemplate(
  questionnaire: Record<string, string>,
  userRole: 'beginner' | 'power_user' | 'enterprise' = 'beginner'
): AgentTemplate | null {
  const availableTemplates = getAllTemplates(userRole);
  
  for (const template of availableTemplates) {
    let score = 0;
    let totalChecks = 0;

    // Check primary purpose match
    if (template.triggers.primaryPurpose?.includes(questionnaire.primaryPurpose)) {
      score += 10;
    }
    totalChecks += 10;

    // Check technical level match
    if (template.triggers.technicalLevel?.includes(questionnaire.technicalLevel)) {
      score += 5;
    }
    totalChecks += 5;

    // Check expected users match
    if (template.triggers.expectedUsers?.includes(questionnaire.expectedUsers)) {
      score += 3;
    }
    totalChecks += 3;

    // Custom field matches
    if (template.triggers.customFields) {
      for (const [field, values] of Object.entries(template.triggers.customFields)) {
        if (values.includes(questionnaire[field])) {
          score += 2;
        }
        totalChecks += 2;
      }
    }

    // Bonus for matching target role exactly
    if (template.targetRole === userRole) {
      score += 5;
      totalChecks += 5;
    }

    // If score is above 70%, it's a good match
    if (score / totalChecks >= 0.7) {
      return template;
    }
  }

  // Default fallback based on user role
  if (userRole === 'power_user') {
    return POWER_USER_AGENT_TEMPLATES.find(t => t.id === 'figma-design-engineer-pro') || 
           BEGINNER_AGENT_TEMPLATES.find(t => t.id === 'chatbot-free') || null;
  }
  
  return BEGINNER_AGENT_TEMPLATES.find(t => t.id === 'chatbot-free') || null;
}