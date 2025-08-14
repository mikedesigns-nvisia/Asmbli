import { 
  Server, 
  Brain, 
  GitBranch, 
  Layers, 
  MessageSquare, 
  Target, 
  Cloud, 
  Users, 
  Database, 
  Globe, 
  FileText, 
  Zap, 
  Monitor, 
  Shield,
  Figma,
  PenTool,
  Code2,
  BookOpen,
  Calendar,
  BarChart3,
  FolderOpen,
  Palette,
  ChromeIcon,
  Mail,
  Settings,
  Workflow
} from 'lucide-react';

export const platformColors = {
  mcp: { bg: 'bg-purple-500/10', text: 'text-purple-400', border: 'border-purple-500/30' },
  copilot: { bg: 'bg-blue-500/10', text: 'text-blue-400', border: 'border-blue-500/30' },
  powerPlatform: { bg: 'bg-orange-500/10', text: 'text-orange-400', border: 'border-orange-500/30' },
  api: { bg: 'bg-green-500/10', text: 'text-green-400', border: 'border-green-500/30' },
  extension: { bg: 'bg-cyan-500/10', text: 'text-cyan-400', border: 'border-cyan-500/30' },
  webhook: { bg: 'bg-yellow-500/10', text: 'text-yellow-400', border: 'border-yellow-500/30' },
  'bot-token': { bg: 'bg-pink-500/10', text: 'text-pink-400', border: 'border-pink-500/30' }
};

export const getIconForCategory = (iconName: string | React.ComponentType<{ className?: string }>): React.ComponentType<{ className?: string }> => {
  // If it's already a component, return it
  if (typeof iconName === 'function') {
    return iconName;
  }

  // Handle category names
  switch (iconName) {
    case 'Design & Prototyping':
      return Figma;
    case 'Development & Code':
      return Code2;
    case 'Communication & Collaboration':
      return MessageSquare;
    case 'Documentation & Knowledge':
      return BookOpen;
    case 'Project Management':
      return Calendar;
    case 'AI & Machine Learning':
      return Brain;
    case 'Analytics & Data':
      return BarChart3;
    case 'File & Asset Management':
      return FolderOpen;
    case 'Browser & Web Tools':
      return Globe;
    case 'Automation & Productivity':
      return Zap;
    case 'Email & Communication':
      return Mail;
    
    // Handle icon names
    case 'Server': return Server;
    case 'Brain': return Brain;
    case 'GitBranch': return GitBranch;
    case 'Layers': return Layers;
    case 'MessageSquare': return MessageSquare;
    case 'Target': return Target;
    case 'Cloud': return Cloud;
    case 'Users': return Users;
    case 'Database': return Database;
    case 'Globe': return Globe;
    case 'FileText': return FileText;
    case 'Zap': return Zap;
    case 'Monitor': return Monitor;
    case 'Shield': return Shield;
    case 'Figma': return Figma;
    case 'PenTool': return PenTool;
    case 'Code2': return Code2;
    case 'BookOpen': return BookOpen;
    case 'Calendar': return Calendar;
    case 'BarChart3': return BarChart3;
    case 'FolderOpen': return FolderOpen;
    case 'Palette': return Palette;
    case 'Mail': return Mail;
    case 'Settings': return Settings;
    case 'Workflow': return Workflow;
    default: return Server;
  }
};

export const getCategoryIcon = (category: string): React.ComponentType<{ className?: string }> => {
  switch (category) {
    case 'mcp-core': return Server;
    case 'openai': return Brain;
    case 'development': return GitBranch;
    case 'microsoft': return Layers;
    case 'communication': return MessageSquare;
    case 'productivity': return Target;
    case 'cloud': return Cloud;
    case 'crm': return Users;
    case 'design': return Figma;
    default: return Server;
  }
};

export const quickTemplates = [
  { id: 'recommended', name: 'Recommended', description: 'Based on your agent purpose', icon: 'Sparkles' },
  { id: 'development', name: 'Development', description: 'Code, Git, Files', icon: 'GitBranch' },
  { id: 'design', name: 'Design Agent', description: 'Figma, Storybook, Tokens', icon: 'Palette' },
  { id: 'browser-tools', name: 'Browser Tools', description: 'Brave, Chrome, Web scraping', icon: 'Globe' },
  { id: 'productivity', name: 'Productivity', description: 'Zapier, Email, Automation', icon: 'Zap' },
  { id: 'microsoft', name: 'Microsoft 365', description: 'Teams, SharePoint, Office', icon: 'Layers' }
];

export const filterOptions = [
  { id: 'recommended', label: 'Recommended' },
  { id: 'selected', label: 'Selected' },
  { id: 'verified', label: 'Verified' },
  { id: 'mcp', label: 'MCP Servers' },
  { id: 'microsoft', label: 'Microsoft' },
  { id: 'openai', label: 'OpenAI' },
  { id: 'anthropic', label: 'Anthropic' },
  { id: 'popular', label: 'Popular' },
  { id: 'enterprise', label: 'Enterprise' },
  { id: 'ai-powered', label: 'AI-Powered' },
  { id: 'browser', label: 'Browser Tools' },
  { id: 'automation', label: 'Automation' },
  { id: 'email', label: 'Email & Messaging' },
  { id: 'design', label: 'Design Tools' },
  { id: 'free', label: 'Free' },
  { id: 'privacy', label: 'Privacy-Focused' }
];

export const sortOptions = [
  { value: 'popular', label: 'Most Popular' },
  { value: 'recent', label: 'Recently Updated' },
  { value: 'alphabetical', label: 'Alphabetical' },
  { value: 'security', label: 'Security Level' }
];

export const platformOptions = [
  { value: 'all', label: 'All Platforms' },
  { value: 'mcp', label: 'MCP' },
  { value: 'copilot', label: 'Copilot Studio' },
  { value: 'powerPlatform', label: 'Power Platform' },
  { value: 'api', label: 'Direct API' },
  { value: 'extension', label: 'Browser Extension' },
  { value: 'webhook', label: 'Webhook' },
  { value: 'bot-token', label: 'Bot Token' }
];