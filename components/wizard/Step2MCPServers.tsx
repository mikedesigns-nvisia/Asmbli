import { useState, useMemo } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { Input } from '../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Checkbox } from '../ui/checkbox';
import { Separator } from '../ui/separator';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '../ui/collapsible';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../ui/tooltip';
import { 
  ArrowRight, 
  ArrowLeft, 
  Database, 
  Globe, 
  FileText, 
  Zap, 
  Monitor, 
  Shield, 
  CheckCircle, 
  AlertTriangle,
  Search,
  Filter,
  Settings,
  ChevronDown,
  ChevronUp,
  X,
  Link,
  Sparkles,
  Eye,
  EyeOff,
  TestTube,
  Play,
  Pause,
  CircleCheck,
  CircleX,
  Circle,
  Network,
  BarChart3,
  Code,
  Lock,
  Cloud,
  Workflow,
  Star,
  Info,
  Clock,
  TrendingUp,
  Users,
  Activity,
  GitBranch,
  MessageSquare,
  Brain,
  Laptop,
  Server,
  Cpu,
  HardDrive,
  Mail
} from 'lucide-react';

interface MCPServer {
  id: string;
  name: string;
  description: string;
  category: string;
  transport: 'stdio' | 'http' | 'streamable';
  securityLevel: 'low' | 'medium' | 'high';
  enabled: boolean;
  status: 'connected' | 'configuring' | 'error' | 'not-configured';
  configProgress: number;
  dependencies: string[];
  isRequired: boolean;
  config: Record<string, any>;
  usageStats?: {
    memory: string;
    requests: string;
    connections: string;
  };
  recommendationReason?: string;
  recommendationStrength: 'strongly-recommended' | 'suggested' | 'optional';
  badges?: string[];
  brandColor?: string;
  verified: boolean;
  lastUpdated: string;
  authMethods: string[];
  capabilities: string[];
  isOfficial: boolean;
  rating?: number;
  setupTime: string;
}

interface ServerCategory {
  id: string;
  name: string;
  description: string;
  icon: React.ComponentType;
  servers: MCPServer[];
}

interface Step2MCPServersProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function Step2MCPServers({ data, onUpdate, onNext, onPrev }: Step2MCPServersProps) {
  const [selectedServers, setSelectedServers] = useState<MCPServer[]>(data.mcpServers || []);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilters, setActiveFilters] = useState<string[]>([]);
  const [viewMode, setViewMode] = useState<'grid' | 'list' | 'compact'>('grid');
  const [globalAdvancedView, setGlobalAdvancedView] = useState(false);
  const [advancedViewCards, setAdvancedViewCards] = useState<Set<string>>(new Set());
  const [collapsedCategories, setCollapsedCategories] = useState<Set<string>>(new Set());
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [configPanelServer, setConfigPanelServer] = useState<string | null>(null);
  const [sortBy, setSortBy] = useState<'popular' | 'recent' | 'alphabetical' | 'security'>('popular');
  const [favoriteServers, setFavoriteServers] = useState<Set<string>>(new Set());

  // Comprehensive server library with real brands
  const availableServers: MCPServer[] = [
    // Development & Version Control
    {
      id: 'github',
      name: 'GitHub MCP Server',
      description: 'Repository management, PR reviews, issue tracking, Actions workflows',
      category: 'development',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Required for Development Assistant profiles',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~12MB', requests: '150 req/min', connections: '2.1M active' },
      badges: ['VERIFIED', 'POPULAR'],
      brandColor: '#24292f',
      verified: true,
      lastUpdated: '2 days ago',
      authMethods: ['OAuth 2.0', 'Personal Access Token'],
      capabilities: ['Code review', 'CI/CD triggers', 'Issue automation', 'Repository management'],
      isOfficial: true,
      rating: 4.8,
      setupTime: '2 minutes',
      config: {
        'GITHUB_TOKEN': '',
        'WEBHOOK_SECRET': '',
        'DEFAULT_BRANCH': 'main',
        'AUTO_MERGE': 'false'
      }
    },
    {
      id: 'gitlab',
      name: 'GitLab MCP Server',
      description: 'Complete DevOps platform integration with built-in CI/CD',
      category: 'development',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Comprehensive DevOps workflow management',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~15MB', requests: '120 req/min', connections: '890K active' },
      badges: ['VERIFIED'],
      brandColor: '#FC6D26',
      verified: true,
      lastUpdated: '5 days ago',
      authMethods: ['Personal Access Token', 'OAuth 2.0'],
      capabilities: ['Merge requests', 'Pipeline control', 'Container registry', 'Issue tracking'],
      isOfficial: true,
      rating: 4.6,
      setupTime: '3 minutes',
      config: {}
    },
    {
      id: 'vercel',
      name: 'Vercel MCP Server',
      description: 'Deploy and manage Next.js applications, edge functions',
      category: 'development',
      transport: 'http',
      securityLevel: 'medium',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Streamlined deployment and hosting',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~8MB', requests: '200 req/min', connections: '1.3M active' },
      badges: ['POPULAR', 'VERIFIED'],
      brandColor: '#000000',
      verified: true,
      lastUpdated: '1 day ago',
      authMethods: ['API Tokens'],
      capabilities: ['Instant deployments', 'Preview URLs', 'Analytics', 'Edge functions'],
      isOfficial: true,
      rating: 4.7,
      setupTime: '1 minute',
      config: {}
    },

    // Cloud Infrastructure
    {
      id: 'aws',
      name: 'AWS MCP Server',
      description: 'Complete AWS service integration - EC2, S3, Lambda, RDS',
      category: 'cloud',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Industry-leading cloud infrastructure',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~25MB', requests: '500 req/min', connections: '3.4M active' },
      badges: ['ENTERPRISE', 'VERIFIED'],
      brandColor: '#FF9900',
      verified: true,
      lastUpdated: '3 days ago',
      authMethods: ['IAM Roles', 'Access Keys'],
      capabilities: ['Resource management', 'CloudFormation', 'Cost optimization', 'Auto-scaling'],
      isOfficial: true,
      rating: 4.5,
      setupTime: '5 minutes',
      config: {}
    },
    {
      id: 'gcp',
      name: 'Google Cloud MCP Server',
      description: 'GCP services - Compute Engine, BigQuery, Cloud Run, Vertex AI',
      category: 'cloud',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Advanced AI and analytics capabilities',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~22MB', requests: '450 req/min', connections: '2.1M active' },
      badges: ['AI-POWERED', 'VERIFIED'],
      brandColor: '#4285F4',
      verified: true,
      lastUpdated: '4 days ago',
      authMethods: ['Service Accounts', 'OAuth 2.0'],
      capabilities: ['Resource provisioning', 'Data analytics', 'ML workflows', 'Serverless computing'],
      isOfficial: true,
      rating: 4.4,
      setupTime: '4 minutes',
      config: {}
    },
    {
      id: 'azure',
      name: 'Microsoft Azure MCP Server',
      description: 'Azure services integration with Active Directory support',
      category: 'cloud',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Enterprise identity and hybrid cloud',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~28MB', requests: '380 req/min', connections: '2.8M active' },
      badges: ['ENTERPRISE', 'VERIFIED'],
      brandColor: '#0078D4',
      verified: true,
      lastUpdated: '2 days ago',
      authMethods: ['Service Principals', 'Managed Identity'],
      capabilities: ['Resource management', 'Azure DevOps', 'Cosmos DB', 'Active Directory'],
      isOfficial: true,
      rating: 4.3,
      setupTime: '6 minutes',
      config: {}
    },

    // Communication & Collaboration
    {
      id: 'slack',
      name: 'Slack MCP Server',
      description: 'Team messaging, channel management, workflow automation',
      category: 'communication',
      transport: 'http',
      securityLevel: 'medium',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Essential team communication hub',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~10MB', requests: '300 req/min', connections: '4.2M active' },
      badges: ['MOST POPULAR', 'VERIFIED'],
      brandColor: '#4A154B',
      verified: true,
      lastUpdated: '1 day ago',
      authMethods: ['OAuth 2.0', 'Bot Tokens'],
      capabilities: ['Message posting', 'User lookup', 'App interactions', 'Workflow automation'],
      isOfficial: true,
      rating: 4.9,
      setupTime: '2 minutes',
      config: {}
    },
    {
      id: 'teams',
      name: 'Microsoft Teams MCP Server',
      description: 'Team collaboration with Office 365 integration',
      category: 'communication',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Integrated with Microsoft ecosystem',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~14MB', requests: '250 req/min', connections: '3.1M active' },
      badges: ['ENTERPRISE', 'VERIFIED'],
      brandColor: '#6264A7',
      verified: true,
      lastUpdated: '3 days ago',
      authMethods: ['Azure AD', 'Graph API'],
      capabilities: ['Channel operations', 'Meeting scheduling', 'File sharing', 'Office integration'],
      isOfficial: true,
      rating: 4.2,
      setupTime: '4 minutes',
      config: {}
    },

    // AI & Machine Learning
    {
      id: 'openai',
      name: 'OpenAI MCP Server',
      description: 'GPT models, DALL-E, Whisper, and embeddings access',
      category: 'ai',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Leading AI model capabilities',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~18MB', requests: '800 req/min', connections: '5.7M active' },
      badges: ['AI ESSENTIAL', 'VERIFIED'],
      brandColor: '#412991',
      verified: true,
      lastUpdated: '1 day ago',
      authMethods: ['API Keys'],
      capabilities: ['Text generation', 'Image creation', 'Audio transcription', 'Embeddings'],
      isOfficial: true,
      rating: 4.8,
      setupTime: '1 minute',
      config: {}
    },
    {
      id: 'anthropic',
      name: 'Anthropic Claude MCP Server',
      description: 'Claude model API integration with constitutional AI',
      category: 'ai',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Safe and helpful AI assistant',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~16MB', requests: '600 req/min', connections: '3.2M active' },
      badges: ['RECOMMENDED', 'VERIFIED'],
      brandColor: '#D97706',
      verified: true,
      lastUpdated: '2 days ago',
      authMethods: ['API Keys'],
      capabilities: ['Conversational AI', 'Code generation', 'Analysis', 'Reasoning'],
      isOfficial: true,
      rating: 4.7,
      setupTime: '1 minute',
      config: {}
    },

    // Database & Analytics
    {
      id: 'postgresql',
      name: 'PostgreSQL MCP Server',
      description: 'Advanced SQL queries, schema management, real-time replication',
      category: 'database',
      transport: 'stdio',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Robust relational database',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~30MB', requests: '400 req/min', connections: '2.5M active' },
      badges: ['VERIFIED'],
      brandColor: '#336791',
      verified: true,
      lastUpdated: '1 week ago',
      authMethods: ['SSL/TLS Connections'],
      capabilities: ['Query optimization', 'Backup management', 'Extensions', 'Replication'],
      isOfficial: true,
      rating: 4.6,
      setupTime: '5 minutes',
      config: {}
    },

    // Productivity & Project Management
    {
      id: 'notion',
      name: 'Notion MCP Server',
      description: 'Workspace management, database operations, content creation',
      category: 'productivity',
      transport: 'http',
      securityLevel: 'medium',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'All-in-one workspace solution',
      recommendationStrength: 'suggested',
      usageStats: { memory: '~12MB', requests: '180 req/min', connections: '2.3M active' },
      badges: ['TRENDING', 'VERIFIED'],
      brandColor: '#000000',
      verified: true,
      lastUpdated: '2 days ago',
      authMethods: ['Integration Tokens'],
      capabilities: ['Page creation', 'Database queries', 'Block manipulation', 'Content sync'],
      isOfficial: true,
      rating: 4.5,
      setupTime: '3 minutes',
      config: {}
    },

    // Security & Compliance
    {
      id: 'vault',
      name: 'HashiCorp Vault MCP Server',
      description: 'Secrets management, encryption, identity-based access',
      category: 'security',
      transport: 'http',
      securityLevel: 'high',
      enabled: false,
      status: 'not-configured',
      configProgress: 0,
      dependencies: [],
      isRequired: false,
      recommendationReason: 'Enterprise secrets management',
      recommendationStrength: 'strongly-recommended',
      usageStats: { memory: '~20MB', requests: '100 req/min', connections: '920K active' },
      badges: ['SECURITY ESSENTIAL', 'VERIFIED'],
      brandColor: '#1DAEFF',
      verified: true,
      lastUpdated: '4 days ago',
      authMethods: ['Token', 'AppRole'],
      capabilities: ['Secret storage', 'Dynamic credentials', 'Encryption as a service', 'PKI'],
      isOfficial: true,
      rating: 4.4,
      setupTime: '8 minutes',
      config: {}
    }
  ];

  // Category definitions with real brand focus
  const categories: ServerCategory[] = [
    {
      id: 'development',
      name: 'Development & Version Control',
      description: 'GitHub, GitLab, Vercel - Code repositories and deployment platforms',
      icon: GitBranch,
      servers: availableServers.filter(s => s.category === 'development')
    },
    {
      id: 'cloud',
      name: 'Cloud Infrastructure',
      description: 'AWS, Google Cloud, Azure - Enterprise cloud platforms',
      icon: Cloud,
      servers: availableServers.filter(s => s.category === 'cloud')
    },
    {
      id: 'communication',
      name: 'Communication & Collaboration',
      description: 'Slack, Teams, Discord - Team messaging and collaboration',
      icon: MessageSquare,
      servers: availableServers.filter(s => s.category === 'communication')
    },
    {
      id: 'ai',
      name: 'AI & Machine Learning',
      description: 'OpenAI, Anthropic, Hugging Face - AI model integrations',
      icon: Brain,
      servers: availableServers.filter(s => s.category === 'ai')
    },
    {
      id: 'database',
      name: 'Database & Analytics',
      description: 'PostgreSQL, MongoDB, Snowflake - Data storage and analytics',
      icon: Database,
      servers: availableServers.filter(s => s.category === 'database')
    },
    {
      id: 'productivity',
      name: 'Productivity & Project Management',
      description: 'Notion, Jira, Linear - Project management and productivity tools',
      icon: Laptop,
      servers: availableServers.filter(s => s.category === 'productivity')
    },
    {
      id: 'security',
      name: 'Security & Compliance',
      description: 'HashiCorp Vault, Okta, Snyk - Security and identity management',
      icon: Shield,
      servers: availableServers.filter(s => s.category === 'security')
    }
  ];

  const securityColors = {
    low: 'text-success border-success/30 bg-success/10',
    medium: 'text-warning border-warning/30 bg-warning/10',
    high: 'text-destructive border-destructive/30 bg-destructive/10'
  };

  const statusColors = {
    connected: 'text-success',
    configuring: 'text-warning',
    error: 'text-destructive',
    'not-configured': 'text-muted-foreground'
  };

  const recommendationColors = {
    'strongly-recommended': 'text-success border-success/30 bg-success/10',
    'suggested': 'text-warning border-warning/30 bg-warning/10',
    'optional': 'text-muted-foreground border-muted/30 bg-muted/10'
  };

  // Get recommendations based on agent purpose
  const getRecommendations = () => {
    const purpose = data.primaryPurpose;
    const recommendations: string[] = [];

    switch (purpose) {
      case 'chatbot':
        recommendations.push('slack', 'openai', 'postgresql');
        break;
      case 'content-creator':
        recommendations.push('notion', 'openai', 'github');
        break;
      case 'data-analyst':
        recommendations.push('postgresql', 'aws', 'openai');
        break;
      case 'developer-assistant':
        recommendations.push('github', 'vercel', 'openai', 'slack');
        break;
      case 'research-assistant':
        recommendations.push('openai', 'anthropic', 'notion', 'postgresql');
        break;
    }

    return recommendations;
  };

  const recommendations = getRecommendations();

  // Server management functions
  const isServerSelected = (serverId: string) => {
    return selectedServers.some(s => s.id === serverId);
  };

  // Filter and search logic
  const filteredCategories = useMemo(() => {
    let filtered = categories.map(category => ({
      ...category,
      servers: category.servers.filter(server => {
        // Search filter
        const matchesSearch = searchQuery === '' || 
          server.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          server.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
          server.capabilities.some(cap => cap.toLowerCase().includes(searchQuery.toLowerCase()));

        // Active filters
        const matchesFilters = activeFilters.length === 0 || activeFilters.some(filter => {
          switch (filter) {
            case 'recommended':
              return recommendations.includes(server.id);
            case 'selected':
              return isServerSelected(server.id);
            case 'verified':
              return server.verified;
            case 'popular':
              return server.badges?.includes('POPULAR') || server.badges?.includes('MOST POPULAR');
            case 'enterprise':
              return server.badges?.includes('ENTERPRISE');
            case 'ai-powered':
              return server.badges?.includes('AI-POWERED') || server.badges?.includes('AI ESSENTIAL');
            case 'low':
            case 'medium':
            case 'high':
              return server.securityLevel === filter;
            case 'stdio':
            case 'http':
            case 'streamable':
              return server.transport === filter;
            default:
              return true;
          }
        });

        return matchesSearch && matchesFilters;
      })
    })).filter(category => category.servers.length > 0);

    // Sort servers within categories
    filtered.forEach(category => {
      category.servers.sort((a, b) => {
        switch (sortBy) {
          case 'popular':
            const aConnections = parseInt(a.usageStats?.connections?.replace(/[^0-9.]/g, '') || '0');
            const bConnections = parseInt(b.usageStats?.connections?.replace(/[^0-9.]/g, '') || '0');
            return bConnections - aConnections;
          case 'recent':
            return new Date(b.lastUpdated).getTime() - new Date(a.lastUpdated).getTime();
          case 'alphabetical':
            return a.name.localeCompare(b.name);
          case 'security':
            const securityOrder = { high: 3, medium: 2, low: 1 };
            return securityOrder[b.securityLevel] - securityOrder[a.securityLevel];
          default:
            return 0;
        }
      });
    });

    return filtered;
  }, [searchQuery, activeFilters, recommendations, selectedServers, sortBy]);

  const totalServersCount = availableServers.length;
  const visibleServersCount = filteredCategories.reduce((acc, cat) => acc + cat.servers.length, 0);

  const toggleServer = (serverId: string) => {
    const serverTemplate = availableServers.find(s => s.id === serverId);
    if (!serverTemplate) return;

    const existingIndex = selectedServers.findIndex(s => s.id === serverId);
    let newServers: MCPServer[];

    if (existingIndex >= 0) {
      newServers = selectedServers.filter(s => s.id !== serverId);
    } else {
      newServers = [...selectedServers, { 
        ...serverTemplate, 
        enabled: true,
        status: 'configuring',
        configProgress: 25
      }];
    }

    setSelectedServers(newServers);
    onUpdate({ mcpServers: newServers });
  };

  const toggleFilter = (filter: string) => {
    setActiveFilters(prev => 
      prev.includes(filter) 
        ? prev.filter(f => f !== filter)
        : [...prev, filter]
    );
  };

  const clearAllFilters = () => {
    setActiveFilters([]);
    setSearchQuery('');
  };

  const toggleCategoryCollapse = (categoryId: string) => {
    setCollapsedCategories(prev => {
      const newSet = new Set(prev);
      if (newSet.has(categoryId)) {
        newSet.delete(categoryId);
      } else {
        newSet.add(categoryId);
      }
      return newSet;
    });
  };

  const toggleFavorite = (serverId: string) => {
    setFavoriteServers(prev => {
      const newSet = new Set(prev);
      if (newSet.has(serverId)) {
        newSet.delete(serverId);
      } else {
        newSet.add(serverId);
      }
      return newSet;
    });
  };

  const applyTemplate = (template: string) => {
    let templateServers: string[] = [];
    
    switch (template) {
      case 'development':
        templateServers = ['github', 'vercel', 'slack'];
        break;
      case 'enterprise':
        templateServers = ['aws', 'vault', 'teams', 'postgresql'];
        break;
      case 'minimal':
        templateServers = ['github', 'openai'];
        break;
      case 'recommended':
        templateServers = recommendations;
        break;
    }

    const newServers = availableServers
      .filter(s => templateServers.includes(s.id))
      .map(s => ({ ...s, enabled: true, status: 'configuring' as const, configProgress: 50 }));

    setSelectedServers(newServers);
    onUpdate({ mcpServers: newServers });
    setSelectedTemplate(template);
  };

  const getSelectedCountForCategory = (categoryId: string) => {
    const categoryServers = categories.find(c => c.id === categoryId)?.servers || [];
    const selectedCount = categoryServers.filter(s => isServerSelected(s.id)).length;
    return `${selectedCount}/${categoryServers.length}`;
  };

  const StatusIcon = ({ status }: { status: string }) => {
    switch (status) {
      case 'connected': return <CircleCheck className="w-3 h-3 text-success" />;
      case 'configuring': return <Circle className="w-3 h-3 text-warning animate-pulse" />;
      case 'error': return <CircleX className="w-3 h-3 text-destructive" />;
      default: return <Circle className="w-3 h-3 text-muted-foreground" />;
    }
  };

  const ServerCard = ({ server }: { server: MCPServer }) => {
    const isSelected = isServerSelected(server.id);
    const isFavorite = favoriteServers.has(server.id);
    const isRecommended = recommendations.includes(server.id);

    return (
      <Card 
        className={`selection-card relative group transition-all duration-300 ${
          isSelected ? 'selected border-primary shadow-lg shadow-primary/20' : ''
        } ${viewMode === 'compact' ? 'p-3' : 'p-4'}`}
        style={{ 
          borderColor: server.brandColor ? `${server.brandColor}20` : undefined,
          backgroundColor: isSelected ? `${server.brandColor || '#6366F1'}08` : undefined
        }}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2">
              <div 
                className="w-3 h-3 rounded-full flex-shrink-0"
                style={{ backgroundColor: server.brandColor || '#6366F1' }}
              />
              <h4 className="font-semibold text-sm truncate">{server.name}</h4>
              {server.verified && (
                <Badge variant="outline" className="text-xs bg-success/10 border-success/30 text-success">
                  <CheckCircle className="w-3 h-3 mr-1" />
                  Verified
                </Badge>
              )}
            </div>

            <p className="text-xs text-muted-foreground line-clamp-2 mb-3">
              {server.description}
            </p>

            {/* Badges */}
            <div className="flex flex-wrap gap-1 mb-3">
              {server.badges?.map(badge => (
                <Badge 
                  key={badge} 
                  variant="secondary" 
                  className="text-xs px-1.5 py-0.5"
                  style={{ 
                    backgroundColor: badge.includes('POPULAR') ? '#10B98120' : 
                                   badge.includes('ENTERPRISE') ? '#6366F120' : 
                                   badge.includes('AI') ? '#F59E0B20' : undefined,
                    color: badge.includes('POPULAR') ? '#10B981' : 
                           badge.includes('ENTERPRISE') ? '#6366F1' : 
                           badge.includes('AI') ? '#F59E0B' : undefined
                  }}
                >
                  {badge}
                </Badge>
              ))}
              {isRecommended && (
                <Badge variant="outline" className="text-xs animate-pulse bg-primary/10 border-primary/30 text-primary">
                  <Sparkles className="w-3 h-3 mr-1" />
                  Recommended
                </Badge>
              )}
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground mb-3">
              <div className="flex items-center gap-1">
                <Users className="w-3 h-3" />
                {server.usageStats?.connections}
              </div>
              <div className="flex items-center gap-1">
                <Activity className="w-3 h-3" />
                {server.usageStats?.requests}
              </div>
              <div className="flex items-center gap-1">
                <HardDrive className="w-3 h-3" />
                {server.usageStats?.memory}
              </div>
              <div className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {server.setupTime}
              </div>
            </div>

            {globalAdvancedView && (
              <div className="space-y-2 pt-2 border-t border-border/30">
                <div className="text-xs">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Security:</span>
                    <Badge 
                      variant="outline" 
                      className={`text-xs ${securityColors[server.securityLevel]}`}
                    >
                      {server.securityLevel.toUpperCase()}
                    </Badge>
                  </div>
                  <div className="flex justify-between mt-1">
                    <span className="text-muted-foreground">Transport:</span>
                    <span className="font-medium">{server.transport.toUpperCase()}</span>
                  </div>
                  <div className="flex justify-between mt-1">
                    <span className="text-muted-foreground">Rating:</span>
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 fill-warning text-warning" />
                      <span className="font-medium">{server.rating}</span>
                    </div>
                  </div>
                </div>
                
                <div className="text-xs">
                  <span className="text-muted-foreground">Auth Methods:</span>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {server.authMethods.map(method => (
                      <Badge key={method} variant="outline" className="text-xs">
                        {method}
                      </Badge>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Action buttons */}
          <div className="flex flex-col gap-2 flex-shrink-0">
            <Button
              size="sm"
              variant={isSelected ? "default" : "outline"}
              onClick={() => toggleServer(server.id)}
              className="w-8 h-8 p-0"
            >
              {isSelected ? <CheckCircle className="w-4 h-4" /> : <Circle className="w-4 h-4" />}
            </Button>
            
            <Button
              size="sm"
              variant="ghost"
              onClick={() => toggleFavorite(server.id)}
              className={`w-8 h-8 p-0 ${isFavorite ? 'text-warning' : 'text-muted-foreground'}`}
            >
              <Star className={`w-4 h-4 ${isFavorite ? 'fill-current' : ''}`} />
            </Button>

            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    size="sm"
                    variant="ghost"
                    className="w-8 h-8 p-0 text-muted-foreground"
                  >
                    <Info className="w-4 h-4" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent side="left" className="max-w-sm">
                  <div className="space-y-2">
                    <div className="font-medium">{server.name}</div>
                    <div className="text-xs">{server.description}</div>
                    <div className="text-xs">
                      <div>Capabilities:</div>
                      <ul className="list-disc list-inside mt-1 space-y-0.5">
                        {server.capabilities.slice(0, 3).map(cap => (
                          <li key={cap}>{cap}</li>
                        ))}
                      </ul>
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Updated {server.lastUpdated} • By {server.isOfficial ? 'Official Team' : 'Community'}
                    </div>
                  </div>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </div>
        </div>
      </Card>
    );
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          MCP Server Library
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Connect to enterprise-grade Model Context Protocol servers from leading technology companies.
          Build powerful integrations with authentic APIs and services.
        </p>
      </div>

      {/* Connection Stats Dashboard */}
      <Card className="selection-card">
        <CardContent className="pt-6">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-primary">{totalServersCount}</div>
              <div className="text-sm text-muted-foreground">Available Servers</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-success">{selectedServers.length}</div>
              <div className="text-sm text-muted-foreground">Your Connected</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-warning">3 min</div>
              <div className="text-sm text-muted-foreground">Avg Setup Time</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-accent-foreground">Slack</div>
              <div className="text-sm text-muted-foreground">Most Popular</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Setup Templates */}
      <Card className="selection-card">
        <CardHeader className="pb-4">
          <CardTitle className="flex items-center gap-2">
            <Workflow className="w-5 h-5 text-primary" />
            Quick Setup Templates
          </CardTitle>
          <CardDescription>
            Start with pre-configured server bundles for common use cases
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 gap-4">
            {[
              { id: 'recommended', name: 'Recommended for You', desc: 'Based on your agent profile', servers: recommendations.length },
              { id: 'development', name: 'Development Stack', desc: 'GitHub + Vercel + Slack', servers: 3 },
              { id: 'enterprise', name: 'Enterprise Security', desc: 'AWS + Vault + Teams', servers: 4 },
              { id: 'minimal', name: 'Minimal Setup', desc: 'GitHub + OpenAI only', servers: 2 }
            ].map(template => (
              <Button
                key={template.id}
                variant={selectedTemplate === template.id ? "default" : "outline"}
                className="h-auto min-h-[100px] p-4 flex flex-col items-start justify-start text-left relative overflow-hidden"
                onClick={() => applyTemplate(template.id)}
              >
                <div className="flex flex-col items-start justify-between h-full w-full overflow-hidden">
                  <span className="font-medium text-sm leading-snug w-full flex-shrink-0 mb-2 break-words hyphens-auto overflow-hidden">
                    {template.name}
                  </span>
                  <span className="text-xs text-muted-foreground leading-relaxed w-full flex-1 flex items-end break-words hyphens-auto overflow-hidden">
                    <span className="w-full">{template.desc}</span>
                  </span>
                  <Badge variant="secondary" className="mt-2 text-xs">
                    {template.servers} servers
                  </Badge>
                </div>
              </Button>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Search and Filter Controls */}
      <Card className="selection-card">
        <CardContent className="pt-6">
          <div className="space-y-6">
            {/* Search and Sort */}
            <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
              <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center w-full sm:flex-1">
                <div className="relative w-full max-w-md">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="Search servers, companies, or capabilities..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10 bg-input-background"
                  />
                </div>
                <div className="flex items-center gap-2">
                  <Select value={sortBy} onValueChange={(value: any) => setSortBy(value)}>
                    <SelectTrigger className="w-40">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="popular">Most Popular</SelectItem>
                      <SelectItem value="recent">Recently Updated</SelectItem>
                      <SelectItem value="alphabetical">Alphabetical</SelectItem>
                      <SelectItem value="security">Security Level</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <Button
                  variant={viewMode === 'grid' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setViewMode('grid')}
                >
                  Grid
                </Button>
                <Button
                  variant={viewMode === 'list' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setViewMode('list')}
                >
                  List
                </Button>
                <Button
                  variant={viewMode === 'compact' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setViewMode('compact')}
                >
                  Compact
                </Button>
              </div>
            </div>

            {/* Filter Chips */}
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Filter className="w-4 h-4 text-muted-foreground" />
                <span className="text-sm font-medium">Filters</span>
                {activeFilters.length > 0 && (
                  <Badge variant="secondary">{activeFilters.length} active</Badge>
                )}
              </div>
              
              <div className="flex flex-wrap gap-2">
                {[
                  { id: 'recommended', label: 'Recommended', icon: Sparkles },
                  { id: 'selected', label: 'Selected', icon: CheckCircle },
                  { id: 'verified', label: 'Verified', icon: CheckCircle },
                  { id: 'popular', label: 'Popular', icon: TrendingUp },
                  { id: 'enterprise', label: 'Enterprise', icon: Shield },
                  { id: 'ai-powered', label: 'AI-Powered', icon: Brain },
                  { id: 'high', label: 'High Security', icon: Lock },
                  { id: 'http', label: 'HTTP/API', icon: Globe },
                ].map(filter => {
                  const Icon = filter.icon;
                  const isActive = activeFilters.includes(filter.id);
                  return (
                    <Button
                      key={filter.id}
                      variant={isActive ? "default" : "outline"}
                      size="sm"
                      onClick={() => toggleFilter(filter.id)}
                      className={`h-8 ${isActive ? 'bg-primary text-primary-foreground' : ''}`}
                    >
                      <Icon className="w-3 h-3 mr-1" />
                      {filter.label}
                      {isActive && <X className="w-3 h-3 ml-1" />}
                    </Button>
                  );
                })}
                {(activeFilters.length > 0 || searchQuery) && (
                  <Button variant="ghost" size="sm" onClick={clearAllFilters}>
                    Clear all
                  </Button>
                )}
              </div>
            </div>

            {/* Advanced View Toggle */}
            <div className="flex items-center justify-between pt-2 border-t border-border/30">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium">Detail Level:</span>
                <Button
                  variant={globalAdvancedView ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setGlobalAdvancedView(!globalAdvancedView)}
                  className="h-7"
                >
                  {globalAdvancedView ? (
                    <>
                      <Settings className="w-3 h-3 mr-1" />
                      Advanced
                    </>
                  ) : (
                    <>
                      <Eye className="w-3 h-3 mr-1" />
                      Simple
                    </>
                  )}
                </Button>
              </div>
              
              <div className="text-sm text-muted-foreground">
                Showing {visibleServersCount} of {totalServersCount} servers
                {selectedServers.length > 0 && ` • ${selectedServers.length} selected`}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Server Categories */}
      <div className="space-y-6">
        {filteredCategories.map(category => {
          const CategoryIcon = category.icon;
          const isCollapsed = collapsedCategories.has(category.id);
          const selectedCount = getSelectedCountForCategory(category.id);

          return (
            <Card key={category.id} className="selection-card">
              <Collapsible open={!isCollapsed} onOpenChange={() => toggleCategoryCollapse(category.id)}>
                <CollapsibleTrigger asChild>
                  <CardHeader className="cursor-pointer hover:bg-muted/20 transition-colors">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <CategoryIcon className="w-6 h-6 text-primary" />
                        <div>
                          <CardTitle className="text-lg">{category.name}</CardTitle>
                          <CardDescription>{category.description}</CardDescription>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <Badge variant="secondary">{selectedCount}</Badge>
                        <Badge variant="outline">{category.servers.length} available</Badge>
                        {isCollapsed ? (
                          <ChevronDown className="w-4 h-4" />
                        ) : (
                          <ChevronUp className="w-4 h-4" />
                        )}
                      </div>
                    </div>
                  </CardHeader>
                </CollapsibleTrigger>

                <CollapsibleContent>
                  <CardContent className="pt-0">
                    <div className={`grid gap-4 ${
                      viewMode === 'grid' ? 'grid-cols-1 lg:grid-cols-2' :
                      viewMode === 'list' ? 'grid-cols-1' :
                      'grid-cols-1 md:grid-cols-2 lg:grid-cols-3'
                    }`}>
                      {category.servers.map(server => (
                        <ServerCard key={server.id} server={server} />
                      ))}
                    </div>
                  </CardContent>
                </CollapsibleContent>
              </Collapsible>
            </Card>
          );
        })}
      </div>

      {/* Navigation */}
      <div className="flex justify-between pt-8">
        <Button variant="outline" onClick={onPrev} className="flex items-center gap-2">
          <ArrowLeft className="w-4 h-4" />
          Previous
        </Button>
        <Button 
          onClick={onNext} 
          className="flex items-center gap-2"
          disabled={selectedServers.length === 0}
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </Button>
      </div>
    </div>
  );
}