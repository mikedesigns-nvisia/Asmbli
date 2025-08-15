import { useState, useMemo, useCallback, useEffect } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { Input } from '../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Checkbox } from '../ui/checkbox';
import { Separator } from '../ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { 
  ArrowRight, 
  ArrowLeft, 
  Search,
  Filter,
  Settings,
  X,
  Sparkles,
  Play,
  Pause,
  GitBranch,
  Globe,
  Layers,
  Brain,
  Server
} from 'lucide-react';

// Import the comprehensive extension library
import { extensionsLibrary, EXTENSION_CATEGORIES } from '../../data/extensions-library';

// Import extracted modules
import { Extension, ExtensionCategory, Step2ExtensionsProps, ViewMode, SortBy } from './step2/types';
import { 
  platformColors, 
  getIconForCategory, 
  quickTemplates, 
  filterOptions, 
  sortOptions, 
  platformOptions 
} from './step2/constants';
import { getRecommendations, filterExtensions, sortExtensions, applyTemplate } from './step2/helpers';
import { ExtensionCard } from './step2/ExtensionCard';

// Helper function to get category descriptions
const getCategoryDescription = (categoryName: string): string => {
  const descriptions: Record<string, string> = {
    'Design & Prototyping': 'Tools for design workflows, prototyping, and design system management',
    'Development & Code': 'Code repositories, version control, and development tools',
    'Communication & Collaboration': 'Team communication and collaboration platforms',
    'Documentation & Knowledge': 'Documentation systems and knowledge management',
    'Project Management': 'Project tracking and task management tools',
    'AI & Machine Learning': 'AI models and machine learning services',
    'Analytics & Data': 'Data analysis and business intelligence tools',
    'File & Asset Management': 'File storage and digital asset management',
    'Browser & Web Tools': 'Browser extensions and web automation tools',
    'Automation & Productivity': 'Workflow automation and productivity tools',
    'Email & Communication': 'Email and messaging services'
  };
  return descriptions[categoryName] || 'Extensions and integrations';
};

// Helper function to get extension badges
const getExtensionBadges = (extension: Extension): string[] => {
  const badges: string[] = [];
  
  // Add category-based badges
  if (extension.category.includes('Design')) badges.push('design');
  if (extension.category.includes('AI')) badges.push('ai-powered');
  if (extension.category.includes('Browser')) badges.push('browser');
  if (extension.category.includes('Automation')) badges.push('automation');
  if (extension.category.includes('Email') || extension.category.includes('Communication')) badges.push('email');
  
  // Add connection type badges
  if (extension.connectionType === 'mcp' || 
      extension.type === 'mcp-server' || 
      extension.id.includes('mcp') ||
      (extension.supportedConnectionTypes && extension.supportedConnectionTypes.includes('mcp'))) {
    badges.push('mcp');
  }
  
  // Add provider-based badges
  if (extension.provider.toLowerCase().includes('microsoft')) badges.push('microsoft');
  if (extension.provider.toLowerCase().includes('openai') || extension.id.includes('openai')) badges.push('openai');
  if (extension.provider.toLowerCase().includes('anthropic') || extension.id.includes('anthropic')) badges.push('anthropic');
  
  // Add pricing badges
  if (extension.pricing === 'free') badges.push('free');
  
  // Add special badges
  if (extension.authMethod === 'none' || extension.pricing === 'free') badges.push('privacy');
  if (extension.complexity === 'low' && extension.setupComplexity <= 2) badges.push('verified');
  if (extension.provider.toLowerCase().includes('google') || 
      extension.provider.toLowerCase().includes('microsoft') || 
      extension.provider.toLowerCase().includes('github') ||
      extension.provider.toLowerCase().includes('openai') ||
      extension.provider.toLowerCase().includes('anthropic')) badges.push('enterprise');
  
  return badges;
};

export const Step2Extensions = React.memo(function Step2Extensions({ data, onUpdate, onNext, onPrev }: Step2ExtensionsProps) {
  const [selectedExtensions, setSelectedExtensions] = useState<Extension[]>(() => {
    // Initialize with proper defaults for extensions that might not have all required fields
    return (data.extensions || []).map(ext => ({
      ...ext,
      enabled: ext.enabled ?? true,
      selectedPlatforms: ext.selectedPlatforms || [ext.connectionType || 'api'],
      status: ext.status || 'configuring',
      configProgress: ext.configProgress || 25
    }));
  });
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilters, setActiveFilters] = useState<string[]>([]);
  const [activePlatformFilter, setActivePlatformFilter] = useState<string>('all');
  const [activeCategoryFilter, setActiveCategoryFilter] = useState<string>('all');
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  const [globalAdvancedView, setGlobalAdvancedView] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [sortBy, setSortBy] = useState<SortBy>('popular');
  const [favoriteExtensions, setFavoriteExtensions] = useState<Set<string>>(new Set());
  const [deploymentTargets, setDeploymentTargets] = useState<string[]>(['claude-desktop']);
  const [visibleCount, setVisibleCount] = useState(12); // Start with 12 extensions

  // Sync with external wizard data changes (e.g., from templates)
  useEffect(() => {
    if (data.extensions) {
      const normalizedExtensions = data.extensions.map(ext => ({
        ...ext,
        enabled: ext.enabled ?? true,
        selectedPlatforms: ext.selectedPlatforms || [ext.connectionType || 'api'],
        status: ext.status || 'configuring',
        configProgress: ext.configProgress || 25
      }));
      setSelectedExtensions(normalizedExtensions);
    }
  }, [data.extensions]);

  // Use the imported comprehensive extension library
  const availableExtensions: Extension[] = extensionsLibrary || [];

  // Get unique categories for filter dropdown
  const categories = useMemo(() => {
    const uniqueCategories = Array.from(new Set(availableExtensions.map(ext => ext.category)));
    return uniqueCategories.map(categoryName => ({
      id: categoryName.toLowerCase().replace(/[^a-z0-9]/g, '-'),
      name: categoryName,
      description: getCategoryDescription(categoryName),
      icon: getIconForCategory(categoryName),
      extensions: availableExtensions.filter(ext => ext.category === categoryName)
    }));
  }, [availableExtensions]);

  const recommendations = getRecommendations(data.primaryPurpose, deploymentTargets);

  // Filter and search logic for grid display
  const filteredExtensions = useMemo(() => {
    let filtered = availableExtensions;

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(ext => 
        ext.name.toLowerCase().includes(query) ||
        ext.description.toLowerCase().includes(query) ||
        ext.category.toLowerCase().includes(query) ||
        ext.provider.toLowerCase().includes(query) ||
        ext.features?.some(feature => feature.toLowerCase().includes(query)) ||
        ext.capabilities?.some(cap => cap.toLowerCase().includes(query))
      );
    }

    // Apply platform filter
    if (activePlatformFilter !== 'all') {
      filtered = filtered.filter(ext => {
        // Check primary connection type
        if (ext.connectionType === activePlatformFilter) return true;
        // Check supported connection types for multi-connection extensions
        if (ext.supportedConnectionTypes && ext.supportedConnectionTypes.includes(activePlatformFilter)) return true;
        return false;
      });
    }

    // Apply category filter
    if (activeCategoryFilter !== 'all') {
      filtered = filtered.filter(ext => ext.category === activeCategoryFilter);
    }

    // Apply badge filters
    if (activeFilters.length > 0) {
      filtered = filtered.filter(ext => {
        const extBadges = getExtensionBadges(ext);
        
        // Special handling for certain filters
        if (activeFilters.includes('recommended')) {
          if (!recommendations.includes(ext.id)) return false;
        }
        if (activeFilters.includes('selected')) {
          if (!selectedExtensions.some(s => s.id === ext.id)) return false;
        }
        if (activeFilters.includes('popular')) {
          if (ext.setupComplexity > 3) return false;
        }
        
        // Check if extension has any of the selected badge filters
        const badgeFilters = activeFilters.filter(f => !['recommended', 'selected', 'popular'].includes(f));
        if (badgeFilters.length > 0) {
          if (!badgeFilters.some(filter => extBadges.includes(filter))) return false;
        }
        
        return true;
      });
    }

    // Apply sorting
    return sortExtensions([{ id: 'all', name: 'All', description: '', icon: Server, extensions: filtered }], sortBy)[0]?.extensions || [];
  }, [availableExtensions, searchQuery, activePlatformFilter, activeCategoryFilter, activeFilters, recommendations, selectedExtensions, sortBy]);

  const totalExtensionsCount = availableExtensions.length;
  const visibleExtensionsCount = filteredExtensions.length;
  
  // Pagination logic for performance
  const paginatedExtensions = useMemo(() => {
    return filteredExtensions.slice(0, visibleCount);
  }, [filteredExtensions, visibleCount]);
  
  const hasMoreExtensions = visibleCount < filteredExtensions.length;
  
  const loadMoreExtensions = useCallback(() => {
    setVisibleCount(prev => Math.min(prev + 12, filteredExtensions.length));
  }, [filteredExtensions.length]);

  // Extension management functions
  const isExtensionSelected = (extensionId: string) => {
    return selectedExtensions.some(s => s.id === extensionId);
  };

  const toggleExtension = (extensionId: string, platform?: string) => {
    console.log('toggleExtension called:', { extensionId, platform });
    const extensionTemplate = availableExtensions.find(s => s.id === extensionId);
    if (!extensionTemplate) {
      console.warn('Extension template not found:', extensionId);
      return;
    }

    const existingIndex = selectedExtensions.findIndex(s => s.id === extensionId);
    console.log('existingIndex:', existingIndex, 'current selections:', selectedExtensions.map(s => s.id));
    let newExtensions: Extension[];

    if (existingIndex >= 0) {
      if (platform) {
        // Toggle specific platform for existing extension
        const existing = selectedExtensions[existingIndex];
        const currentPlatforms = existing.selectedPlatforms || [];
        
        const updatedPlatforms = currentPlatforms.includes(platform)
          ? currentPlatforms.filter(p => p !== platform)
          : [...currentPlatforms, platform];

        if (updatedPlatforms.length === 0) {
          // Remove extension if no platforms selected
          newExtensions = selectedExtensions.filter(s => s.id !== extensionId);
        } else {
          // Update platforms
          newExtensions = selectedExtensions.map(s => 
            s.id === extensionId 
              ? { 
                  ...s, 
                  selectedPlatforms: updatedPlatforms,
                  // Update connection type to match the platform if single selection
                  connectionType: updatedPlatforms.length === 1 ? updatedPlatforms[0] as any : s.connectionType
                }
              : s
          );
        }
      } else {
        // Toggle entire extension (remove if selected, add if not)
        newExtensions = selectedExtensions.filter(s => s.id !== extensionId);
      }
    } else {
      // Add new extension
      let defaultPlatforms: string[];
      let defaultConnectionType = extensionTemplate.connectionType;
      
      if (platform) {
        // Specific platform requested
        defaultPlatforms = [platform];
        defaultConnectionType = platform as any;
      } else {
        // Use primary connection type, or first supported type for multi-connection extensions
        if (extensionTemplate.supportedConnectionTypes && extensionTemplate.supportedConnectionTypes.length > 0) {
          defaultPlatforms = [extensionTemplate.supportedConnectionTypes[0]];
          defaultConnectionType = extensionTemplate.supportedConnectionTypes[0] as any;
        } else {
          defaultPlatforms = [extensionTemplate.connectionType || 'api'];
        }
      }

      const newExtension: Extension = { 
        ...extensionTemplate, 
        enabled: true,
        selectedPlatforms: defaultPlatforms,
        connectionType: defaultConnectionType,
        status: 'configuring',
        configProgress: 25
      };

      newExtensions = [...selectedExtensions, newExtension];
    }

    console.log('Setting new extensions:', newExtensions.map(e => ({ id: e.id, platforms: e.selectedPlatforms })));
    setSelectedExtensions(newExtensions);
    onUpdate({ extensions: newExtensions });
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
    setActivePlatformFilter('all');
    setActiveCategoryFilter('all');
  };

  const toggleFavorite = (extensionId: string) => {
    setFavoriteExtensions(prev => {
      const newSet = new Set(prev);
      if (newSet.has(extensionId)) {
        newSet.delete(extensionId);
      } else {
        newSet.add(extensionId);
      }
      return newSet;
    });
  };

  // Template to badge mapping
  const getTemplateBadges = (template: string): string[] => {
    switch (template) {
      case 'recommended':
        return ['recommended', 'popular', 'ai-powered', 'mcp'];
      case 'development':
        return ['verified', 'enterprise', 'popular', 'mcp'];
      case 'design':
        return ['design', 'ai-powered', 'enterprise', 'mcp'];
      case 'browser-tools':
        return ['browser', 'privacy', 'free'];
      case 'productivity':
        return ['automation', 'email', 'enterprise'];
      case 'microsoft':
        return ['microsoft', 'enterprise', 'verified'];
      default:
        return [];
    }
  };

  const handleApplyTemplate = (template: string) => {
    // Toggle template selection - if same template is clicked, unselect it
    if (selectedTemplate === template) {
      // Clear selection and badges
      setSelectedExtensions([]);
      onUpdate({ extensions: [] });
      setSelectedTemplate('');
      setActiveFilters([]);
    } else {
      // Apply new template
      const newExtensions = applyTemplate(template, recommendations, deploymentTargets, availableExtensions);
      
      // Ensure proper initialization of extension fields
      const normalizedExtensions = newExtensions.map(ext => ({
        ...ext,
        enabled: true,
        selectedPlatforms: ext.selectedPlatforms || [ext.connectionType || 'api'],
        status: ext.status || 'configuring',
        configProgress: ext.configProgress || 25
      }));
      
      setSelectedExtensions(normalizedExtensions);
      onUpdate({ extensions: normalizedExtensions });
      setSelectedTemplate(template);
      
      // Auto-select relevant filter badges
      const templateBadges = getTemplateBadges(template);
      setActiveFilters(templateBadges);
    }
  };

  const getTemplateIcon = (iconName: string) => {
    switch (iconName) {
      case 'Sparkles': return Sparkles;
      case 'GitBranch': return GitBranch;
      case 'Layers': return Layers;
      case 'Globe': return Globe;
      case 'Server': return Server;
      case 'Brain': return Brain;
      default: return Sparkles;
    }
  };

  return (
    <div className="w-full space-y-8">
      {/* Header Section */}
      <div className="w-full space-y-4">
        <div className="w-full">
          <h2 className="mb-2">Extensions & Integrations</h2>
          <p className="text-muted-foreground">
            Connect your agent to external services through MCP servers, direct APIs, browser extensions, and webhook integrations. 
            Choose from comprehensive Microsoft 365, AI services, and development tools.
          </p>
        </div>

        {/* Quick Templates */}
        <div className="w-full grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {quickTemplates.map((template) => {
            const IconComponent = getTemplateIcon(template.icon);
            return (
              <Card
                key={template.id}
                className={`cursor-pointer transition-all duration-200 hover:border-primary/50 ${
                  selectedTemplate === template.id ? 'border-primary bg-primary/5' : ''
                }`}
                onClick={() => handleApplyTemplate(template.id)}
              >
                <CardContent className="p-3 text-center">
                  <div className="flex flex-col items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                      <IconComponent className="w-4 h-4 text-primary" />
                    </div>
                    <div>
                      <p className="text-xs mb-1">{template.name}</p>
                      <p className="text-xs text-muted-foreground line-clamp-1">{template.description}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Search and Filters */}
        <div className="w-full flex flex-col lg:flex-row gap-4">
          <div className="flex-1 w-full">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Search extensions by name, category, or capability..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 w-full"
              />
            </div>
          </div>
          
          <div className="flex gap-2">
            <Select value={activeCategoryFilter} onValueChange={setActiveCategoryFilter}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="All Categories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                {categories.map((category) => (
                  <SelectItem key={category.id} value={category.name}>
                    {category.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={activePlatformFilter} onValueChange={setActivePlatformFilter}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {platformOptions.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={sortBy} onValueChange={(value: SortBy) => setSortBy(value)}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {sortOptions.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setGlobalAdvancedView(!globalAdvancedView)}
              >
                {globalAdvancedView ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                {globalAdvancedView ? 'Simple' : 'Advanced'}
              </Button>
            </div>
          </div>
        </div>

        {/* Badge Filters */}
        <div className="flex flex-wrap gap-2">
          {filterOptions.map((filter) => (
            <Button
              key={filter.id}
              variant={activeFilters.includes(filter.id) ? "default" : "outline"}
              size="sm"
              onClick={() => toggleFilter(filter.id)}
              className="text-xs"
            >
              {filter.label}
              {activeFilters.includes(filter.id) && (
                <X className="w-3 h-3 ml-1" />
              )}
            </Button>
          ))}
          
          {(activeFilters.length > 0 || searchQuery || activePlatformFilter !== 'all' || activeCategoryFilter !== 'all') && (
            <Button
              variant="ghost"
              size="sm"
              onClick={clearAllFilters}
              className="text-xs text-muted-foreground"
            >
              Clear all
            </Button>
          )}
        </div>

        {/* Results Summary */}
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>
            Showing {visibleExtensionsCount} of {totalExtensionsCount} extensions
            {selectedExtensions.length > 0 && ` • ${selectedExtensions.length} selected`}
          </span>
        </div>
      </div>

      {/* Extensions Grid */}
      <div className="w-full">
        {filteredExtensions.length > 0 ? (
          <div className="space-y-6">
            <div className="extension-grid">
              {paginatedExtensions.map((extension) => {
                const isSelected = isExtensionSelected(extension.id);
                const isRecommended = recommendations.includes(extension.id);
                const isFavorited = favoriteExtensions.has(extension.id);
                const selectedExt = selectedExtensions.find(s => s.id === extension.id);
                
                return (
                  <ExtensionCard
                    key={extension.id}
                    extension={extension}
                    isSelected={isSelected}
                    isRecommended={isRecommended}
                    isFavorited={isFavorited}
                    selectedExt={selectedExt}
                    globalAdvancedView={globalAdvancedView}
                    onToggleExtension={toggleExtension}
                    onToggleFavorite={toggleFavorite}
                  />
                );
              })}
            </div>
            
            {/* Load More Button */}
            {hasMoreExtensions && (
              <div className="text-center">
                <Button
                  variant="outline"
                  onClick={loadMoreExtensions}
                  className="min-w-32"
                >
                  Load More ({filteredExtensions.length - visibleCount} remaining)
                </Button>
              </div>
            )}
          </div>
        ) : (
          <div className="text-center py-12">
            <Search className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="font-medium mb-2">No extensions found</h3>
            <p className="text-sm text-muted-foreground">
              Try adjusting your search terms or filters to find more extensions.
            </p>
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={onPrev}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Previous
        </Button>
        <Button onClick={onNext}>
          Next
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
});

// Export for lazy loading compatibility
export { Step2Extensions as default };