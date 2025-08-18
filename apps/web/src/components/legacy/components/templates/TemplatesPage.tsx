import { useState, useMemo, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { 
  Search, 
  Filter, 
  Plus, 
  Upload, 
  Download, 
  Sparkles,
  Grid3X3,
  List,
  ArrowLeft,
  Star,
  Crown,
  Zap,
  TrendingUp,
  Bell,
  Library,
  Users,
  Clock,
  Heart,
  Award,
  Gift,
  Rocket,
  BookOpen,
  GraduationCap,
  CheckCircle,
  Shield,
  Eye,
  Flame
} from 'lucide-react';
import { AgentTemplate, TemplateCategory } from '../../types/templates';
import { WizardData } from '../../types/wizard';
import { TemplateStorageAPI } from '../../utils/templateStorageAPI';
import { TemplateCard } from './TemplateCard';
import { SaveTemplateDialog } from './SaveTemplateDialog';
import { useAuth } from '../../contexts/AuthContext';

interface TemplatesPageProps {
  currentWizardData?: WizardData;
  onUseTemplate: (template: AgentTemplate) => void;
  onBackToWizard: () => void;
  onShowSaveDialog?: () => void;
  onShowTemplateReview?: (template: AgentTemplate) => void;
  onDeployTemplate?: (wizardData: WizardData) => void;
}

// Mock data for upcoming premium templates
const upcomingPremiumTemplates = [
  {
    id: 'up-1',
    name: 'Enterprise Code Auditor',
    description: 'Premium code review platform with enterprise security scanning and compliance automation.',
    category: 'Enterprise Security',
    estimatedRelease: '2024-02-15',
    previewImage: '/api/placeholder/300/200',
    features: ['Enterprise Security', 'Compliance Automation', 'Advanced Analytics', 'Professional Reports'],
    tier: 'Enterprise'
  },
  {
    id: 'up-2', 
    name: 'AI Knowledge Orchestrator',
    description: 'Premium knowledge management platform with enterprise AI capabilities and team collaboration.',
    category: 'Enterprise AI',
    estimatedRelease: '2024-02-28',
    previewImage: '/api/placeholder/300/200',
    features: ['Enterprise AI', 'Team Collaboration', 'Advanced Analytics', 'Custom Integrations'],
    tier: 'Power User'
  },
  {
    id: 'up-3',
    name: 'Brand Content Director',
    description: 'Premium content creation platform with brand management and multi-channel publishing.',
    category: 'Professional Marketing',
    estimatedRelease: '2024-03-10',
    previewImage: '/api/placeholder/300/200',
    features: ['Brand Management', 'Multi-channel Publishing', 'Performance Analytics', 'Team Workflows'],
    tier: 'Power User'
  }
];

const featuredCollections = [
  {
    id: 'community',
    title: 'Community Favorites',
    icon: TrendingUp,
    description: 'Most loved templates by the community',
    color: '#F59E0B'
  },
  {
    id: 'recent',
    title: 'Recently Added',
    icon: Sparkles,
    description: 'Latest contributions from developers',
    color: '#10B981'
  },
  {
    id: 'educational',
    title: 'Learning Resources',
    icon: GraduationCap,
    description: 'Great templates for learning and teaching',
    color: '#6366F1'
  }
];

export function TemplatesPage({
  currentWizardData,
  onUseTemplate,
  onBackToWizard,
  onShowTemplateReview
}: TemplatesPageProps) {
  const { user } = useAuth();
  const userRole = user?.role || 'beginner';
  
  const [templates, setTemplates] = useState<AgentTemplate[]>([]);
  const [categories, setCategories] = useState<TemplateCategory[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Load templates and categories
  useEffect(() => {
    const loadTemplates = async () => {
      setLoading(true);
      try {
        const [templatesData, categoriesData] = await Promise.all([
          TemplateStorageAPI.getTemplates(userRole, user?.id),
          TemplateStorageAPI.getCategories()
        ]);
        setTemplates(templatesData);
        setCategories(categoriesData);
      } catch (error) {
        console.error('Failed to load templates:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadTemplates();
  }, [userRole, user?.id]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [showSaveDialog, setShowSaveDialog] = useState(false);
  const [watchList, setWatchList] = useState<string[]>([]);
  const [notifyList, setNotifyList] = useState<string[]>([]);

  // Get all unique tags from templates
  const allTags = useMemo(() => {
    const tagSet = new Set<string>();
    templates.forEach(template => {
      template.tags.forEach(tag => tagSet.add(tag));
    });
    return Array.from(tagSet).sort();
  }, [templates]);

  // Filter templates based on search and filters
  const filteredTemplates = useMemo(() => {
    return TemplateStorageAPI.filterTemplates(templates, {
      category: selectedCategory === 'all' ? undefined : selectedCategory,
      tags: selectedTags.length > 0 ? selectedTags : undefined,
      searchQuery: searchQuery.trim() || undefined
    });
  }, [templates, selectedCategory, selectedTags, searchQuery]);

  // Group templates by category for the category view
  const templatesByCategory = useMemo(() => {
    const grouped = new Map<string, AgentTemplate[]>();
    
    categories.forEach(category => {
      grouped.set(category.id, []);
    });
    
    filteredTemplates.forEach(template => {
      const categoryTemplates = grouped.get(template.category) || [];
      categoryTemplates.push(template);
      grouped.set(template.category, categoryTemplates);
    });
    
    return grouped;
  }, [categories, filteredTemplates]);

  const handleUseTemplate = async (template: AgentTemplate) => {
    try {
      await TemplateStorageAPI.incrementUsageCount(template.id, user?.id);
      
      // Refresh templates to show updated usage count
      const updatedTemplates = await TemplateStorageAPI.getTemplates(userRole, user?.id);
      setTemplates(updatedTemplates);
      
      // Check if this is a pre-configured template
      if (template.isPreConfigured && onShowTemplateReview) {
        // Show review page for pre-configured templates
        onShowTemplateReview(template);
      } else {
        // Use normal wizard flow for regular templates
        onUseTemplate(template);
      }
    } catch (error) {
      console.error('Failed to use template:', error);
    }
  };

  const handleDeleteTemplate = async (id: string) => {
    if (confirm('Are you sure you want to remove this template from the library?')) {
      try {
        // Note: We need to add a delete method to TemplateStorageAPI
        // For now, just refresh the templates
        const updatedTemplates = await TemplateStorageAPI.getTemplates(userRole, user?.id);
        setTemplates(updatedTemplates);
      } catch (error) {
        console.error('Failed to delete template:', error);
      }
    }
  };

  const handleExportTemplate = async (id: string) => {
    try {
      const exportData = await TemplateStorageAPI.exportTemplate(id);
      if (exportData) {
        const template = await TemplateStorageAPI.getTemplate(id);
        const blob = new Blob([exportData], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${template?.name.replace(/[^a-z0-9]/gi, '_').toLowerCase()}_template.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    } catch (error) {
      console.error('Failed to export template:', error);
    }
  };

  const handleImportTemplate = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = async (e) => {
        const content = e.target?.result as string;
        try {
          const imported = await TemplateStorageAPI.importTemplate(content, user?.id);
          if (imported) {
            const updatedTemplates = await TemplateStorageAPI.getTemplates(userRole, user?.id);
            setTemplates(updatedTemplates);
          } else {
            alert('Failed to import template. Please check the file format.');
          }
        } catch (error) {
          console.error('Failed to import template:', error);
          alert('Failed to import template. Please check the file format.');
        }
      };
      reader.readAsText(file);
    }
  };

  const handleSaveCurrentTemplate = async (templateInfo: {
    name: string;
    description: string;
    category: string;
    tags: string[];
  }) => {
    if (currentWizardData) {
      try {
        await TemplateStorageAPI.saveTemplate(currentWizardData, templateInfo, user?.id);
        const updatedTemplates = await TemplateStorageAPI.getTemplates(userRole, user?.id);
        setTemplates(updatedTemplates);
        setShowSaveDialog(false);
      } catch (error) {
        console.error('Failed to save template:', error);
      }
    }
  };

  const toggleTag = (tag: string) => {
    setSelectedTags(prev => 
      prev.includes(tag) 
        ? prev.filter(t => t !== tag)
        : [...prev, tag]
    );
  };

  const toggleWatchList = (id: string) => {
    setWatchList(prev => 
      prev.includes(id) 
        ? prev.filter(item => item !== id)
        : [...prev, id]
    );
  };

  const toggleNotifyList = (id: string) => {
    setNotifyList(prev => 
      prev.includes(id) 
        ? prev.filter(item => item !== id)
        : [...prev, id]
    );
  };

  return (
    <div className="content-width mx-auto px-4 py-6 space-y-8">
      {/* Enhanced Header */}
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={onBackToWizard} className="flex items-center gap-2">
              <ArrowLeft className="w-4 h-4" />
              Back to Wizard
            </Button>
            <div>
              <h1 className="text-3xl font-bold flex items-center gap-3">
                <div className="relative">
                  <Library className="w-8 h-8 text-primary" />
                  <div className="absolute -top-1 -right-1 w-3 h-3 bg-primary rounded-full animate-pulse"></div>
                </div>
                {userRole === 'beginner' ? 'Template Library' : 'Premium Template Library'}
              </h1>
              <p className="text-muted-foreground">
                {userRole === 'beginner' 
                  ? 'Community AI agent templates and starter configurations'
                  : 'Premium pre-optimized AI agent templates for professional workflows'
                }
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <Badge variant="outline" className="flex items-center gap-1">
              <Users className="w-3 h-3" />
              {templates.length} Templates
            </Badge>
            <input
              type="file"
              accept=".json"
              onChange={handleImportTemplate}
              className="hidden"
              id="import-template"
            />
            <Button
              variant="outline"
              onClick={() => document.getElementById('import-template')?.click()}
            >
              <Upload className="w-4 h-4 mr-2" />
              Import
            </Button>
            
            {currentWizardData && (
              <Button onClick={() => setShowSaveDialog(true)}>
                <Plus className="w-4 h-4 mr-2" />
                Contribute Template
              </Button>
            )}
          </div>
        </div>

        {/* Featured Collections */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {featuredCollections.map((collection) => {
            const Icon = collection.icon;
            return (
              <Card key={collection.id} className="selection-card hover:scale-105 transition-transform cursor-pointer">
                <CardHeader className="pb-3">
                  <div className="flex items-center gap-3">
                    <div 
                      className="w-10 h-10 rounded-lg flex items-center justify-center"
                      style={{ backgroundColor: collection.color + '20' }}
                    >
                      <Icon className="w-5 h-5" style={{ color: collection.color }} />
                    </div>
                    <div>
                      <CardTitle className="text-base">{collection.title}</CardTitle>
                      <CardDescription className="text-sm">{collection.description}</CardDescription>
                    </div>
                  </div>
                </CardHeader>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Enhanced Filters and Search */}
      <div className="space-y-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search templates, categories, or features..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
          
          <Select value={selectedCategory} onValueChange={setSelectedCategory}>
            <SelectTrigger className="w-full sm:w-48">
              <SelectValue placeholder="All Categories" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              {categories.map(category => (
                <SelectItem key={category.id} value={category.id}>
                  <span className="flex items-center gap-2">
                    <span>{category.icon}</span>
                    {category.name}
                  </span>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          
          <div className="flex items-center gap-2">
            <Button
              variant={viewMode === 'grid' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setViewMode('grid')}
            >
              <Grid3X3 className="w-4 h-4" />
            </Button>
            <Button
              variant={viewMode === 'list' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setViewMode('list')}
            >
              <List className="w-4 h-4" />
            </Button>
          </div>
        </div>

        {/* Enhanced Tag Filter */}
        {allTags.length > 0 && (
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <Filter className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm font-medium">Filter by tags:</span>
              {selectedTags.length > 0 && (
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={() => setSelectedTags([])}
                  className="text-xs"
                >
                  Clear filters
                </Button>
              )}
            </div>
            <div className="flex flex-wrap gap-2">
              {allTags.map(tag => (
                <Badge
                  key={tag}
                  variant={selectedTags.includes(tag) ? 'default' : 'outline'}
                  className="cursor-pointer hover:bg-primary/80 transition-colors chip-hug"
                  onClick={() => toggleTag(tag)}
                >
                  {tag}
                </Badge>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Enhanced Templates Section */}
      <Tabs defaultValue="all" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="all">All Templates ({filteredTemplates.length})</TabsTrigger>
          {userRole === 'beginner' && (
            <TabsTrigger value="premium">Premium Preview</TabsTrigger>
          )}
          <TabsTrigger value="upcoming">Coming Soon</TabsTrigger>
          <TabsTrigger value="categories">By Category</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-6">
          {filteredTemplates.length === 0 ? (
            <div className="text-center py-12">
              <BookOpen className="w-16 h-16 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-xl font-medium mb-2">No templates found</h3>
              <p className="text-muted-foreground mb-6 max-w-md mx-auto">
                {templates.length === 0 
                  ? "Help us build the community library! Contribute your first template to get started and inspire others to share their work."
                  : "Try adjusting your search criteria or browse our featured collections above."
                }
              </p>
              {currentWizardData && (
                <Button onClick={() => setShowSaveDialog(true)} size="lg">
                  <Plus className="w-5 h-5 mr-2" />
                  Contribute the First Template
                </Button>
              )}
            </div>
          ) : (
            <>
              <div className={`grid gap-6 ${
                viewMode === 'grid' 
                  ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3' 
                  : 'grid-cols-1'
              }`}>
                {filteredTemplates.map(template => {
                  const category = categories.find(c => c.id === template.category);
                  return category ? (
                    <TemplateCard
                      key={template.id}
                      template={template}
                      category={category}
                      onUseTemplate={handleUseTemplate}
                      onDeleteTemplate={handleDeleteTemplate}
                      onExportTemplate={handleExportTemplate}
                    />
                  ) : null;
                })}
              </div>
              
              {/* Premium Upgrade CTA for Free Users */}
              {userRole === 'beginner' && (
                <Card className="selection-card bg-gradient-to-br from-primary/10 via-purple-500/5 to-blue-500/10 border-primary/20">
                  <CardHeader className="text-center">
                    <div className="flex items-center justify-center gap-3 mb-4">
                      <Crown className="w-8 h-8 text-primary" />
                      <Star className="w-6 h-6 text-yellow-500" />
                      <Zap className="w-6 h-6 text-primary" />
                    </div>
                    <CardTitle className="text-2xl mb-2">Unlock Premium Templates</CardTitle>
                    <CardDescription className="text-lg max-w-2xl mx-auto">
                      Access 50+ pre-optimized professional templates with enterprise integrations, 
                      advanced security, and expert-tuned configurations.
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-6">
                    {/* Premium Features Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div className="text-center space-y-2">
                        <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                          <Rocket className="w-6 h-6 text-primary" />
                        </div>
                        <h4 className="font-semibold">Expert-Optimized</h4>
                        <p className="text-sm text-muted-foreground">Templates fine-tuned by professionals</p>
                      </div>
                      <div className="text-center space-y-2">
                        <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                          <Shield className="w-6 h-6 text-primary" />
                        </div>
                        <h4 className="font-semibold">Enterprise Security</h4>
                        <p className="text-sm text-muted-foreground">Advanced auth & compliance built-in</p>
                      </div>
                      <div className="text-center space-y-2">
                        <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                          <Award className="w-6 h-6 text-primary" />
                        </div>
                        <h4 className="font-semibold">Priority Support</h4>
                        <p className="text-sm text-muted-foreground">24/7 expert assistance & guidance</p>
                      </div>
                    </div>
                    
                    {/* Sample Premium Templates */}
                    <div className="space-y-3">
                      <h4 className="font-semibold text-center">Featured Premium Templates</h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div className="flex items-center gap-3 p-3 bg-background/50 rounded-lg border">
                          <div className="text-2xl">🎨</div>
                          <div>
                            <p className="font-medium text-sm">UI Engineer</p>
                            <p className="text-xs text-muted-foreground">Design-to-code with Figma MCP</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-background/50 rounded-lg border">
                          <div className="text-2xl">🏗️</div>
                          <div>
                            <p className="font-medium text-sm">Full-Stack Architect</p>
                            <p className="text-xs text-muted-foreground">Complete application blueprints</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-background/50 rounded-lg border">
                          <div className="text-2xl">🔐</div>
                          <div>
                            <p className="font-medium text-sm">Security Analyst</p>
                            <p className="text-xs text-muted-foreground">Advanced threat detection</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-background/50 rounded-lg border">
                          <div className="text-2xl">☁️</div>
                          <div>
                            <p className="font-medium text-sm">DevOps Engineer</p>
                            <p className="text-xs text-muted-foreground">Multi-cloud deployments</p>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    {/* Pricing and CTA */}
                    <div className="text-center space-y-4">
                      <div className="space-y-1">
                        <div className="flex items-center justify-center gap-2">
                          <span className="text-3xl font-bold text-primary">$29</span>
                          <div className="text-left">
                            <div className="text-sm text-muted-foreground">/month</div>
                            <div className="text-xs text-muted-foreground">per agent</div>
                          </div>
                        </div>
                        <p className="text-sm text-muted-foreground">Save 40+ hours of configuration time</p>
                      </div>
                      
                      <div className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto">
                        <Button size="lg" className="flex-1">
                          <Crown className="w-4 h-4 mr-2" />
                          Upgrade to Premium
                        </Button>
                        <Button variant="outline" size="lg" className="flex-1">
                          <Eye className="w-4 h-4 mr-2" />
                          View Samples
                        </Button>
                      </div>
                      
                      <p className="text-xs text-muted-foreground">
                        7-day free trial • Cancel anytime • Used by 2,500+ professionals
                      </p>
                    </div>
                  </CardContent>
                </Card>
              )}
            </>
          )}
        </TabsContent>

        {/* Premium Preview Tab for Free Users */}
        {userRole === 'beginner' && (
          <TabsContent value="premium" className="space-y-6">
            {/* Premium Preview Header */}
            <div className="text-center space-y-4 py-8">
              <div className="flex items-center justify-center gap-3">
                <Crown className="w-8 h-8 text-primary" />
                <h2 className="text-3xl font-bold">Premium Templates</h2>
                <Star className="w-6 h-6 text-yellow-500" />
              </div>
              <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                Preview our premium collection of expert-optimized templates. 
                Upgrade to access the full library with deployment-ready configurations.
              </p>
            </div>

            {/* Premium Template Previews */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[
                {
                  id: 'figma-design-engineer-pro',
                  icon: '🎨',
                  name: 'UI Engineer',
                  description: 'Design-to-code specialist with enterprise Figma integration, component libraries, and automated workflows.',
                  category: 'Design & Development',
                  mcps: ['figma-mcp', 'file-manager-mcp', 'git-mcp', 'code-formatter-mcp'],
                  features: ['Figma API Integration', 'Component Library Sync', 'Design System Management', 'Auto Code Generation']
                },
                {
                  id: 'fullstack-architect-pro',
                  icon: '🏗️',
                  name: 'Full-Stack Architect',
                  description: 'Complete application architecture with database design, API development, and deployment automation.',
                  category: 'Development',
                  mcps: ['postgres-mcp', 'terminal-mcp', 'git-mcp', 'http-mcp'],
                  features: ['Database Design', 'API Architecture', 'Cloud Deployment', 'Security Implementation']
                },
                {
                  id: 'security-analyst-pro',
                  icon: '🔐',
                  name: 'Security Analyst',
                  description: 'Advanced security analysis with threat detection, compliance checking, and vulnerability management.',
                  category: 'Security & Compliance',
                  mcps: ['terminal-mcp', 'http-mcp', 'memory-mcp', 'search-mcp'],
                  features: ['Threat Detection', 'Compliance Audit', 'Vulnerability Scanning', 'Security Reports']
                },
                {
                  id: 'devops-engineer-pro',
                  icon: '☁️',
                  name: 'DevOps Engineer',
                  description: 'Multi-cloud deployment automation with monitoring, scaling, and infrastructure as code.',
                  category: 'Infrastructure',
                  mcps: ['terminal-mcp', 'git-mcp', 'http-mcp', 'calendar-mcp'],
                  features: ['Infrastructure as Code', 'Multi-Cloud Deploy', 'Auto Scaling', 'Monitoring Setup']
                },
                {
                  id: 'data-science-analyst-pro',
                  icon: '📊',
                  name: 'Data Science Analyst',
                  description: 'Advanced analytics with machine learning, data visualization, and automated reporting.',
                  category: 'Data & Analytics',
                  mcps: ['postgres-mcp', 'http-mcp', 'memory-mcp', 'search-mcp'],
                  features: ['ML Model Training', 'Data Visualization', 'Automated Reports', 'Predictive Analytics']
                },
                {
                  id: 'content-strategist-pro',
                  icon: '✍️',
                  name: 'Content Strategist',
                  description: 'Multi-channel content creation with SEO optimization, brand management, and performance tracking.',
                  category: 'Marketing & Content',
                  mcps: ['search-mcp', 'http-mcp', 'calendar-mcp', 'memory-mcp'],
                  features: ['SEO Optimization', 'Brand Management', 'Multi-Channel Publishing', 'Performance Analytics']
                }
              ].map((template) => (
                <Card key={template.id} className="selection-card relative overflow-hidden opacity-90 hover:opacity-100 transition-opacity">
                  {/* Premium Lock Overlay */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-purple-500/5 pointer-events-none z-10"></div>
                  <div className="absolute top-4 right-4 z-20">
                    <Badge className="bg-primary text-primary-foreground flex items-center gap-1">
                      <Crown className="w-3 h-3" />
                      Premium
                    </Badge>
                  </div>

                  <CardHeader className="pb-4 relative z-10">
                    <div className="text-center mb-4">
                      <div className="text-4xl mb-2">{template.icon}</div>
                      <CardTitle className="text-lg">{template.name}</CardTitle>
                      <CardDescription className="line-clamp-2">
                        {template.description}
                      </CardDescription>
                    </div>

                    <Badge variant="outline" className="chip-hug self-start">
                      {template.category}
                    </Badge>
                  </CardHeader>

                  <CardContent className="space-y-4 relative z-10">
                    {/* MCP Integrations */}
                    <div>
                      <h4 className="text-sm font-medium mb-2">Included MCPs:</h4>
                      <div className="flex flex-wrap gap-1">
                        {template.mcps.map((mcp) => (
                          <Badge key={mcp} variant="outline" className="text-xs">
                            {mcp}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    {/* Key Features */}
                    <div>
                      <h4 className="text-sm font-medium mb-2">Key Features:</h4>
                      <div className="space-y-1">
                        {template.features.slice(0, 3).map((feature, index) => (
                          <div key={index} className="flex items-center gap-2 text-xs text-muted-foreground">
                            <CheckCircle className="w-3 h-3 text-green-500" />
                            {feature}
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Upgrade CTA */}
                    <div className="space-y-2 pt-2 border-t">
                      <Button className="w-full" size="sm">
                        <Crown className="w-4 h-4 mr-2" />
                        Upgrade to Access
                      </Button>
                      <p className="text-center text-xs text-muted-foreground">
                        $29/mo • 7-day free trial
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            {/* Bottom CTA */}
            <Card className="selection-card bg-gradient-to-br from-primary/10 to-purple-500/10 border-primary/20">
              <CardContent className="text-center py-8">
                <Crown className="w-12 h-12 text-primary mx-auto mb-4" />
                <h3 className="text-2xl font-bold mb-2">Ready to unlock premium templates?</h3>
                <p className="text-muted-foreground mb-6 max-w-2xl mx-auto">
                  Join 2,500+ professionals using our expert-optimized templates. 
                  Save 40+ hours of configuration time and deploy production-ready agents instantly.
                </p>
                <div className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto">
                  <Button size="lg" className="flex-1">
                    <Rocket className="w-4 h-4 mr-2" />
                    Start Free Trial
                  </Button>
                  <Button variant="outline" size="lg" className="flex-1">
                    <Gift className="w-4 h-4 mr-2" />
                    View Pricing
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground mt-4">
                  7-day free trial • Cancel anytime • No setup fees
                </p>
              </CardContent>
            </Card>
          </TabsContent>
        )}

        {/* Consumer Deploy Tab */}
        <TabsContent value="consumer" className="space-y-6">
          {/* Consumer Deploy Header */}
          <div className="text-center space-y-4 py-8">
            <div className="flex items-center justify-center gap-3">
              <div className="text-4xl">🏠</div>
              <h2 className="text-3xl font-bold">Deploy to Your AI Setup</h2>
              <div className="text-4xl">🤖</div>
            </div>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Connect Asmbli capabilities to your existing AI tools - no complex deployments needed.
              Works with LM Studio, Ollama, ChatGPT, and Claude Desktop.
            </p>
          </div>

          {/* Consumer Platform Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                name: 'LM Studio',
                icon: '🎯',
                description: 'Local AI with enhanced MCP capabilities',
                difficulty: 'Easy',
                time: '5 minutes',
                popular: true
              },
              {
                name: 'Ollama',
                icon: '🐋', 
                description: 'Lightweight local deployment with bridge',
                difficulty: 'Medium',
                time: '10 minutes',
                popular: false
              },
              {
                name: 'ChatGPT',
                icon: '🤖',
                description: 'Enhance ChatGPT with custom tool APIs',
                difficulty: 'Medium', 
                time: '15 minutes',
                popular: true
              },
              {
                name: 'Claude Desktop',
                icon: '🖥️',
                description: 'Full native integration with Claude',
                difficulty: 'Easy',
                time: '5 minutes',
                popular: false
              }
            ].map((platform) => (
              <Card key={platform.name} className="selection-card cursor-pointer hover:shadow-lg transition-all duration-300">
                {platform.popular && (
                  <div className="absolute top-3 right-3">
                    <Badge className="bg-orange-500 text-white">
                      <Flame className="w-3 h-3 mr-1" />
                      Popular
                    </Badge>
                  </div>
                )}
                <CardHeader className="text-center pb-4">
                  <div className="text-4xl mb-2">{platform.icon}</div>
                  <CardTitle className="text-lg">{platform.name}</CardTitle>
                  <CardDescription className="text-sm">{platform.description}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex justify-between text-sm">
                    <span>Difficulty:</span>
                    <Badge variant={platform.difficulty === 'Easy' ? 'default' : 'secondary'} className="text-xs">
                      {platform.difficulty}
                    </Badge>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>Setup time:</span>
                    <span className="font-medium">{platform.time}</span>
                  </div>
                  <Button className="w-full" size="sm">
                    <Download className="w-4 h-4 mr-2" />
                    Download Installer
                  </Button>
                  <Button variant="outline" className="w-full" size="sm">
                    <BookOpen className="w-4 h-4 mr-2" />
                    View Guide
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Consumer Benefits */}
          <Card className="bg-gradient-to-br from-green-50 to-blue-50 border-green-200">
            <CardHeader className="text-center">
              <CardTitle className="flex items-center justify-center gap-2">
                <CheckCircle className="w-6 h-6 text-green-600" />
                Why Consumer Deployment?
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center space-y-2">
                  <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                    <Heart className="w-6 h-6 text-green-600" />
                  </div>
                  <h4 className="font-semibold">Use Your Favorite AI</h4>
                  <p className="text-sm text-muted-foreground">Keep using LM Studio, Ollama, or ChatGPT - just add superpowers</p>
                </div>
                <div className="text-center space-y-2">
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto">
                    <Shield className="w-6 h-6 text-blue-600" />
                  </div>
                  <h4 className="font-semibold">Local & Private</h4>
                  <p className="text-sm text-muted-foreground">MCP servers run on your machine - your data stays private</p>
                </div>
                <div className="text-center space-y-2">
                  <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
                    <Zap className="w-6 h-6 text-purple-600" />
                  </div>
                  <h4 className="font-semibold">5-Minute Setup</h4>
                  <p className="text-sm text-muted-foreground">One-click installers handle all the technical details</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="upcoming" className="space-y-6">
          {/* Coming Soon Header */}
          <div className="text-center space-y-4 py-8">
            <div className="flex items-center justify-center gap-3">
              <Rocket className="w-8 h-8 text-primary" />
              <h2 className="text-3xl font-bold">Premium Templates Coming Soon</h2>
            </div>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Advanced premium templates in development by our expert team. 
              Pre-optimized for professional workflows and enterprise needs.
            </p>
          </div>

          {/* Upcoming Premium Templates */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {upcomingPremiumTemplates.map((template) => (
              <Card key={template.id} className="selection-card relative overflow-hidden">
                {/* Coming Soon Badge */}
                <div className="absolute top-4 right-4 z-10">
                  <Badge className="bg-primary/90 text-primary-foreground">
                    <Clock className="w-3 h-3 mr-1" />
                    Coming Soon
                  </Badge>
                </div>

                <CardHeader className="pb-4">
                  <div className="aspect-video bg-gradient-to-br from-primary/20 to-purple-500/20 rounded-lg mb-4 flex items-center justify-center relative">
                    <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-transparent rounded-lg"></div>
                    <BookOpen className="w-12 h-12 text-primary/60" />
                  </div>

                  <div className="space-y-2">
                    <CardTitle className="text-lg">{template.name}</CardTitle>
                    <CardDescription className="line-clamp-2">
                      {template.description}
                    </CardDescription>
                  </div>

                  <div className="flex items-center justify-between mt-3">
                    <Badge variant="outline" className="chip-hug">
                      {template.category}
                    </Badge>
                    <Badge variant="outline" className={`chip-hug ${
                      template.tier === 'Enterprise' 
                        ? 'bg-purple-500/20 text-purple-400 border-purple-400/30' 
                        : 'bg-blue-500/20 text-blue-400 border-blue-400/30'
                    }`}>
                      {template.tier}
                    </Badge>
                  </div>
                </CardHeader>

                <CardContent className="space-y-4">
                  {/* Features List */}
                  <div>
                    <h4 className="text-sm font-medium mb-2">Planned Features:</h4>
                    <div className="space-y-1">
                      {template.features.slice(0, 3).map((feature, index) => (
                        <div key={index} className="flex items-center gap-2 text-sm text-muted-foreground">
                          <div className="w-1.5 h-1.5 bg-primary rounded-full"></div>
                          {feature}
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Expected Release */}
                  <div className="text-sm text-muted-foreground">
                    <strong>Expected Contribution:</strong> {new Date(template.estimatedRelease).toLocaleDateString('en-US', {
                      month: 'long',
                      day: 'numeric', 
                      year: 'numeric'
                    })}
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2">
                    <Button 
                      variant="outline" 
                      size="sm" 
                      onClick={() => toggleWatchList(template.id)}
                      className="flex-1"
                    >
                      <Heart className={`w-4 h-4 mr-2 ${watchList.includes(template.id) ? 'fill-current text-red-400' : ''}`} />
                      {watchList.includes(template.id) ? 'Watching' : 'Watch'}
                    </Button>
                    <Button 
                      size="sm" 
                      onClick={() => toggleNotifyList(template.id)}
                      className="flex-1"
                    >
                      <Bell className="w-4 h-4 mr-2" />
                      {notifyList.includes(template.id) ? 'Subscribed' : 'Notify Me'}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Premium Updates */}
          <Card className="selection-card bg-gradient-to-br from-primary/10 to-purple-500/10">
            <CardHeader className="text-center">
              <div className="flex items-center justify-center gap-2 mb-4">
                <Crown className="w-6 h-6 text-primary" />
                <CardTitle>Premium Updates</CardTitle>
              </div>
              <CardDescription>
                Get early access to new premium templates, exclusive features, and professional workflow updates.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-2 max-w-md mx-auto">
                <Input placeholder="Enter your email..." className="flex-1" />
                <Button>
                  <Bell className="w-4 h-4 mr-2" />
                  Get Updates
                </Button>
              </div>
              <p className="text-xs text-center text-muted-foreground">
                Join 2,500+ professionals using premium agent templates
              </p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="categories" className="space-y-8">
          {categories.map(category => {
            const categoryTemplates = templatesByCategory.get(category.id) || [];
            
            return (
              <div key={category.id} className="space-y-4">
                <div className="flex items-center gap-3">
                  <div 
                    className="w-10 h-10 rounded-lg flex items-center justify-center"
                    style={{ backgroundColor: category.color + '20' }}
                  >
                    <span style={{ color: category.color }}>{category.icon}</span>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold">{category.name}</h3>
                    <p className="text-sm text-muted-foreground">{category.description}</p>
                  </div>
                  <Badge variant="outline" className="ml-auto">
                    {categoryTemplates.length} templates
                  </Badge>
                </div>
                
                {categoryTemplates.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 pl-13">
                    {categoryTemplates.map(template => (
                      <TemplateCard
                        key={template.id}
                        template={template}
                        category={category}
                        onUseTemplate={handleUseTemplate}
                        onDeleteTemplate={handleDeleteTemplate}
                        onExportTemplate={handleExportTemplate}
                      />
                    ))}
                  </div>
                ) : (
                  <div className="pl-13 py-8 text-center">
                    <BookOpen className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
                    <p className="text-muted-foreground">
                      No templates in this category yet. Be the first to contribute one!
                    </p>
                  </div>
                )}
              </div>
            );
          })}
        </TabsContent>
      </Tabs>

      {/* Save Template Dialog */}
      {showSaveDialog && currentWizardData && (
        <SaveTemplateDialog
          isOpen={showSaveDialog}
          onClose={() => setShowSaveDialog(false)}
          onSave={handleSaveCurrentTemplate}
          categories={categories}
          existingTags={allTags}
        />
      )}
    </div>
  );
}