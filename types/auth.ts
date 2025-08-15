export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  createdAt: Date;
  lastLoginAt?: Date;
  subscription?: Subscription;
}

export type UserRole = 'beginner' | 'power_user' | 'enterprise' | 'beta';

export interface Subscription {
  plan: UserRole;
  status: 'active' | 'inactive' | 'trial' | 'expired';
  startDate: Date;
  endDate?: Date;
  features: string[];
}

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface SignupCredentials extends LoginCredentials {
  name: string;
  role?: UserRole;
}

export interface RoleFeatures {
  role: UserRole;
  displayName: string;
  description: string;
  price: string;
  features: {
    maxAgents: number;
    securityCustomization: boolean;
    advancedExtensions: boolean;
    customDeployment: boolean;
    prioritySupport: boolean;
    analyticsAndLogging: boolean;
    teamCollaboration: boolean;
    apiAccess: boolean;
    customDomains: boolean;
    ssoIntegration: boolean;
    complianceCertifications: boolean;
  };
  restrictions: {
    hiddenSteps: string[];
    disabledFeatures: string[];
    preConfiguredSettings: Record<string, any>;
  };
}

export const ROLE_CONFIGURATIONS: Record<UserRole, RoleFeatures> = {
  beta: {
    role: 'beta',
    displayName: 'Beta Tester',
    description: 'Try our simplified MVP wizard experience',
    price: 'Free Beta',
    features: {
      maxAgents: 5,
      securityCustomization: false,
      advancedExtensions: false,
      customDeployment: false,
      prioritySupport: false,
      analyticsAndLogging: false,
      teamCollaboration: false,
      apiAccess: false,
      customDomains: false,
      ssoIntegration: false,
      complianceCertifications: false,
    },
    restrictions: {
      hiddenSteps: ['all-enterprise-steps'],
      disabledFeatures: ['enterprise-wizard'],
      preConfiguredSettings: {
        useMVPWizard: true,
        deploymentTargets: ['lm-studio', 'ollama', 'vs-code'],
        targetEnvironment: 'development'
      }
    }
  },
  beginner: {
    role: 'beginner',
    displayName: 'Beginner',
    description: 'Perfect for getting started with AI agents',
    price: 'Free',
    features: {
      maxAgents: 3,
      securityCustomization: false,
      advancedExtensions: false,
      customDeployment: false,
      prioritySupport: false,
      analyticsAndLogging: false,
      teamCollaboration: false,
      apiAccess: false,
      customDomains: false,
      ssoIntegration: false,
      complianceCertifications: false,
    },
    restrictions: {
      hiddenSteps: ['security-advanced', 'enterprise-features'],
      disabledFeatures: [
        'kubernetes-deployment',
        'custom-auth-methods',
        'advanced-security',
        'team-management',
        'api-keys',
        'custom-domains',
        'compliance-settings',
        'custom-builder'
      ],
      preConfiguredSettings: {
        security: {
          authMethod: 'none',
          permissions: ['read'],
          vaultIntegration: 'none',
          auditLogging: false,
          rateLimiting: true,
          sessionTimeout: 3600
        },
        deploymentTargets: ['claude-desktop', 'lm-studio'],
        targetEnvironment: 'development'
      }
    }
  },
  power_user: {
    role: 'power_user',
    displayName: 'Power User',
    description: 'Advanced features for experienced developers',
    price: '$29/month',
    features: {
      maxAgents: 25,
      securityCustomization: true,
      advancedExtensions: true,
      customDeployment: true,
      prioritySupport: true,
      analyticsAndLogging: true,
      teamCollaboration: false,
      apiAccess: true,
      customDomains: false,
      ssoIntegration: false,
      complianceCertifications: false,
    },
    restrictions: {
      hiddenSteps: ['enterprise-features'],
      disabledFeatures: [
        'team-management',
        'sso-integration',
        'compliance-certifications',
        'dedicated-support'
      ],
      preConfiguredSettings: {}
    }
  },
  enterprise: {
    role: 'enterprise',
    displayName: 'Enterprise',
    description: 'Full-featured solution for organizations',
    price: '$199/month',
    features: {
      maxAgents: -1, // Unlimited
      securityCustomization: true,
      advancedExtensions: true,
      customDeployment: true,
      prioritySupport: true,
      analyticsAndLogging: true,
      teamCollaboration: true,
      apiAccess: true,
      customDomains: true,
      ssoIntegration: true,
      complianceCertifications: true,
    },
    restrictions: {
      hiddenSteps: [],
      disabledFeatures: [],
      preConfiguredSettings: {}
    }
  }
};