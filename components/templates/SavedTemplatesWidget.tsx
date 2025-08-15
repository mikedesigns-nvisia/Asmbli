import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../ui/tooltip';
import { 
  Play, 
  Clock, 
  TrendingUp, 
  ChevronRight,
  Sparkles
} from 'lucide-react';
import { AgentTemplate } from '../../types/templates';
import { TemplateStorage } from '../../utils/templateStorage';

interface SavedTemplatesWidgetProps {
  onUseTemplate: (template: AgentTemplate) => void;
  onViewAllTemplates: () => void;
}

export function SavedTemplatesWidget({
  onUseTemplate,
  onViewAllTemplates
}: SavedTemplatesWidgetProps) {
  const [recentTemplates, setRecentTemplates] = useState<AgentTemplate[]>([]);

  useEffect(() => {
    const templates = TemplateStorage.getTemplates();
    // Get the 3 most recently used or created templates
    const sortedTemplates = templates
      .sort((a, b) => {
        // Sort by usage count first, then by creation date
        if (a.usageCount !== b.usageCount) {
          return b.usageCount - a.usageCount;
        }
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      })
      .slice(0, 3);
    
    setRecentTemplates(sortedTemplates);
  }, []);

  if (recentTemplates.length === 0) {
    return null;
  }

  const handleUseTemplate = (template: AgentTemplate) => {
    TemplateStorage.incrementUsageCount(template.id);
    onUseTemplate(template);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <Card className="bg-gradient-to-br from-primary/5 to-transparent border-primary/20">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-primary" />
            </div>
            <div>
              <CardTitle className="text-sm">Quick Templates</CardTitle>
              <CardDescription className="text-xs">
                Your most used templates
              </CardDescription>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={onViewAllTemplates}
            className="text-xs hover:bg-primary/10 text-primary hover:text-primary"
          >
            View All
            <ChevronRight className="w-3 h-3 ml-1" />
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        {recentTemplates.map((template) => {
          const categories = TemplateStorage.getCategories();
          const category = categories.find(c => c.id === template.category);
          
          return (
            <div
              key={template.id}
              className="flex items-center gap-3 p-3 rounded-lg bg-background/60 hover:bg-background/80 transition-colors cursor-pointer group"
              onClick={() => handleUseTemplate(template)}
            >
              {category && (
                <div 
                  className="w-6 h-6 rounded flex items-center justify-center flex-shrink-0 text-xs"
                  style={{ 
                    backgroundColor: category.color + '20',
                    color: category.color 
                  }}
                >
                  {category.icon}
                </div>
              )}
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-sm font-medium truncate">
                    {template.name}
                  </span>
                  {template.usageCount > 0 && (
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger>
                          <Badge variant="secondary" className="chip-hug-tight text-xs">
                            {template.usageCount}
                          </Badge>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Used {template.usageCount} times</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  )}
                </div>
                
                <div className="flex items-center gap-3 text-xs text-muted-foreground">
                  <div className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    <span>{formatDate(template.createdAt)}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <TrendingUp className="w-3 h-3" />
                    <span>{template.wizardData.extensions?.length || 0} ext</span>
                  </div>
                </div>
              </div>
              
              <Button
                variant="ghost"
                size="sm"
                className="opacity-0 group-hover:opacity-100 transition-opacity p-1 h-auto w-auto"
                onClick={(e) => {
                  e.stopPropagation();
                  handleUseTemplate(template);
                }}
              >
                <Play className="w-3 h-3" />
              </Button>
            </div>
          );
        })}
      </CardContent>
    </Card>
  );
}