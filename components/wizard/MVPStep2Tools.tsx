import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { CheckCircle, Search, Plus, GitBranch, Figma, Database, Globe, FileText, MessageSquare, Calendar, Folder, Code, Palette, GraduationCap } from 'lucide-react';

interface MVPStep2ToolsProps {
  selectedRole: string;
  selectedTools: string[];
  onToolsChange: (tools: string[]) => void;
}

const TOOL_CATEGORIES = {
  development: {
    title: 'Development',
    icon: Code,
    tools: [
      { id: 'git', name: 'Git', description: 'Version control and repository management', icon: GitBranch, popular: true },
      { id: 'github', name: 'GitHub', description: 'Code hosting and collaboration', icon: GitBranch, popular: true },
      { id: 'filesystem', name: 'File System', description: 'Local file operations', icon: Folder, popular: true },
      { id: 'postgres', name: 'PostgreSQL', description: 'Database operations', icon: Database },
      { id: 'web-search', name: 'Web Search', description: 'Research and documentation lookup', icon: Globe },
      { id: 'memory', name: 'Memory', description: 'Remember project context and preferences', icon: FileText, popular: true },
    ]
  },
  design: {
    title: 'Design & Content',
    icon: Palette,
    tools: [
      { id: 'figma', name: 'Figma', description: 'Design files and component access', icon: Figma, popular: true },
      { id: 'web-fetch', name: 'Web Research', description: 'Fetch content from URLs', icon: Globe, popular: true },
      { id: 'memory', name: 'Memory', description: 'Remember brand guidelines and preferences', icon: FileText, popular: true },
      { id: 'filesystem', name: 'File System', description: 'Access local design assets', icon: Folder },
      { id: 'notion', name: 'Notion', description: 'Content management and notes', icon: FileText },
    ]
  },
  research: {
    title: 'Research & Analysis',
    icon: GraduationCap,
    tools: [
      { id: 'web-search', name: 'Web Search', description: 'Academic and research search', icon: Globe, popular: true },
      { id: 'web-fetch', name: 'Web Research', description: 'Extract content from research sources', icon: Globe, popular: true },
      { id: 'filesystem', name: 'File System', description: 'Access research documents and data', icon: Folder, popular: true },
      { id: 'memory', name: 'Memory', description: 'Remember methodology and research context', icon: FileText, popular: true },
      { id: 'postgres', name: 'Database', description: 'Research data analysis', icon: Database },
    ]
  }
};

const ROLE_TOOL_MAPPING = {
  developer: ['git', 'github', 'filesystem', 'memory'],
  creator: ['figma', 'web-fetch', 'memory', 'filesystem'],
  researcher: ['web-search', 'web-fetch', 'filesystem', 'memory']
};

export function MVPStep2Tools({ selectedRole, selectedTools, onToolsChange }: MVPStep2ToolsProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [showAllCategories, setShowAllCategories] = useState(false);

  // Auto-select recommended tools based on role
  useEffect(() => {
    if (selectedRole && selectedTools.length === 0) {
      const recommendedTools = ROLE_TOOL_MAPPING[selectedRole as keyof typeof ROLE_TOOL_MAPPING] || [];
      onToolsChange(recommendedTools);
    }
  }, [selectedRole, selectedTools.length, onToolsChange]);

  const toggleTool = (toolId: string) => {
    if (selectedTools.includes(toolId)) {
      onToolsChange(selectedTools.filter(t => t !== toolId));
    } else {
      onToolsChange([...selectedTools, toolId]);
    }
  };

  const selectAllRecommended = () => {
    const recommendedTools = ROLE_TOOL_MAPPING[selectedRole as keyof typeof ROLE_TOOL_MAPPING] || [];
    onToolsChange(recommendedTools);
  };

  const clearAll = () => {
    onToolsChange([]);
  };

  // Get primary category based on role
  const getPrimaryCategory = () => {
    switch (selectedRole) {
      case 'developer': return 'development';
      case 'creator': return 'design';
      case 'researcher': return 'research';
      default: return 'development';
    }
  };

  const primaryCategory = getPrimaryCategory();
  const otherCategories = Object.entries(TOOL_CATEGORIES).filter(([key]) => key !== primaryCategory);

  // Filter tools based on search
  const filterTools = (tools: typeof TOOL_CATEGORIES.development.tools) => {
    if (!searchTerm) return tools;
    return tools.filter(tool => 
      tool.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tool.description.toLowerCase().includes(searchTerm.toLowerCase())
    );
  };

  const renderToolCard = (tool: any) => {
    const isSelected = selectedTools.includes(tool.id);
    const Icon = tool.icon;
    
    return (
      <Card
        key={tool.id}
        className={`cursor-pointer transition-all duration-200 hover:shadow-md relative ${
          isSelected 
            ? 'border-primary bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-md ring-1 ring-primary/20' 
            : 'hover:border-primary/30 border-border'
        }`}
        onClick={() => toggleTool(tool.id)}
      >
        {isSelected && (
          <div className="absolute -top-2 -right-2 bg-primary rounded-full p-1">
            <CheckCircle className="w-4 h-4 text-primary-foreground" />
          </div>
        )}
        
        {tool.popular && !isSelected && (
          <div className="absolute -top-2 -right-2">
            <Badge className="bg-orange-500 text-white text-xs px-2 py-0.5">
              Popular
            </Badge>
          </div>
        )}
        
        <CardHeader className="pb-3">
          <div className="flex items-start gap-3">
            <div className={`p-2 rounded-lg ${
              isSelected ? 'bg-primary/20' : 'bg-muted/50'
            } transition-colors`}>
              <Icon className={`w-5 h-5 ${
                isSelected ? 'text-primary' : 'text-muted-foreground'
              }`} />
            </div>
            <div className="flex-1 min-w-0">
              <CardTitle className="text-base">{tool.name}</CardTitle>
              <CardDescription className="text-sm leading-relaxed">
                {tool.description}
              </CardDescription>
            </div>
          </div>
        </CardHeader>
      </Card>
    );
  };

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-semibold">What tools do you use?</h2>
        <p className="text-muted-foreground">
          Select the tools and services your AI agent should integrate with. We've pre-selected the most popular ones for {selectedRole}s.
        </p>
      </div>

      {/* Search and Controls */}
      <div className="flex flex-col sm:flex-row gap-4 items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
          <Input
            placeholder="Search tools..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={selectAllRecommended}>
            Select Recommended
          </Button>
          <Button variant="outline" size="sm" onClick={clearAll}>
            Clear All
          </Button>
        </div>
      </div>

      {/* Selected Tools Summary */}
      {selectedTools.length > 0 && (
        <div className="p-4 bg-primary/5 border border-primary/20 rounded-lg">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircle className="w-4 h-4 text-primary" />
            <span className="font-medium text-primary">
              {selectedTools.length} tool{selectedTools.length !== 1 ? 's' : ''} selected
            </span>
          </div>
          <div className="flex flex-wrap gap-2">
            {selectedTools.map(toolId => {
              const allTools = Object.values(TOOL_CATEGORIES).flatMap(cat => cat.tools);
              const tool = allTools.find(t => t.id === toolId);
              return tool ? (
                <Badge key={toolId} variant="outline" className="bg-background">
                  {tool.name}
                </Badge>
              ) : null;
            })}
          </div>
        </div>
      )}

      {/* Primary Category (Based on Role) */}
      <div>
        <div className="flex items-center gap-3 mb-4">
          {React.createElement(TOOL_CATEGORIES[primaryCategory as keyof typeof TOOL_CATEGORIES].icon, { 
            className: "w-5 h-5 text-primary" 
          })}
          <h3 className="text-lg font-semibold">
            {TOOL_CATEGORIES[primaryCategory as keyof typeof TOOL_CATEGORIES].title}
          </h3>
          <Badge className="bg-primary/10 text-primary border-primary/30">
            Recommended for you
          </Badge>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filterTools(TOOL_CATEGORIES[primaryCategory as keyof typeof TOOL_CATEGORIES].tools).map(renderToolCard)}
        </div>
      </div>

      {/* Other Categories */}
      {(showAllCategories || searchTerm) && otherCategories.map(([categoryKey, category]) => {
        const filteredTools = filterTools(category.tools);
        if (searchTerm && filteredTools.length === 0) return null;
        
        return (
          <div key={categoryKey}>
            <div className="flex items-center gap-3 mb-4">
              {React.createElement(category.icon, { className: "w-5 h-5 text-muted-foreground" })}
              <h3 className="text-lg font-semibold">{category.title}</h3>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredTools.map(renderToolCard)}
            </div>
          </div>
        );
      })}

      {/* Show More/Less Button */}
      {!searchTerm && (
        <div className="text-center">
          <Button
            variant="outline"
            onClick={() => setShowAllCategories(!showAllCategories)}
            className="flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            {showAllCategories ? 'Show Less' : 'Show More Tools'}
          </Button>
        </div>
      )}

      {/* Help Text */}
      <div className="mt-8 text-center space-y-2">
        <p className="text-sm text-muted-foreground">
          💡 Don't worry if you're not sure - you can always change these later.
        </p>
        <p className="text-xs text-muted-foreground">
          Each tool will be configured as an MCP server that your AI agent can use.
        </p>
      </div>
    </div>
  );
}