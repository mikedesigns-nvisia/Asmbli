import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Button } from '../ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../ui/tooltip';
import { 
  Play, 
  Download, 
  Trash2, 
  Calendar, 
  TrendingUp, 
  Star,
  User,
  Heart,
  Share2,
  Zap,
  Shield,
  CheckCircle,
  Flame,
  BookOpen,
  Users,
  GitFork
} from 'lucide-react';
import { AgentTemplate, TemplateCategory } from '../../types/templates';

interface TemplateCardProps {
  template: AgentTemplate;
  category: TemplateCategory;
  onUseTemplate: (template: AgentTemplate) => void;
  onDeleteTemplate: (id: string) => void;
  onExportTemplate: (id: string) => void;
}

export function TemplateCard({
  template,
  category,
  onUseTemplate,
  onDeleteTemplate,
  onExportTemplate
}: TemplateCardProps) {
  const [isLiked, setIsLiked] = useState(false);
  const [likes] = useState(Math.floor(Math.random() * 100) + 10);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const getComplexityLevel = () => {
    const extensionCount = template.wizardData.extensions?.length || 0;
    const constraintCount = template.wizardData.constraints?.length || 0;
    const hasAdvancedSecurity = template.wizardData.security.vaultIntegration !== 'none';
    
    const complexity = extensionCount + constraintCount + (hasAdvancedSecurity ? 2 : 0);
    
    if (complexity <= 2) return { level: 'Beginner', color: 'bg-green-500/20 text-green-400 border-green-400/30', icon: CheckCircle };
    if (complexity <= 5) return { level: 'Intermediate', color: 'bg-yellow-500/20 text-yellow-400 border-yellow-400/30', icon: Zap };
    return { level: 'Advanced', color: 'bg-red-500/20 text-red-400 border-red-400/30', icon: Shield };
  };

  const getPopularityBadge = () => {
    if (template.usageCount >= 50) return { text: 'Popular', icon: Flame, color: 'bg-red-500/20 text-red-400' };
    if (template.usageCount >= 20) return { text: 'Trending', icon: TrendingUp, color: 'bg-orange-500/20 text-orange-400' };
    if (template.usageCount >= 10) return { text: 'Rising', icon: Star, color: 'bg-yellow-500/20 text-yellow-400' };
    return null;
  };

  const complexity = getComplexityLevel();
  const popularityBadge = getPopularityBadge();
  const ComplexityIcon = complexity.icon;

  const handleLike = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsLiked(!isLiked);
  };

  const handleShare = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (navigator.share) {
      navigator.share({
        title: template.name,
        text: template.description,
        url: window.location.href
      });
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(`${template.name}: ${template.description}`);
    }
  };

  return (
    <Card className="selection-card group hover:shadow-xl transition-all duration-500 relative overflow-hidden">
      {/* Popularity Badge */}
      {popularityBadge && (
        <div className="absolute top-3 left-3 z-10">
          <Badge className={`${popularityBadge.color} border flex items-center gap-1`}>
            <popularityBadge.icon className="w-3 h-3" />
            {popularityBadge.text}
          </Badge>
        </div>
      )}

      {/* Premium/Open Source Badge */}
      <div className="absolute top-3 right-3 z-10">
        {template.isPreConfigured ? (
          <Badge variant="outline" className="bg-purple-500/20 text-purple-400 border-purple-400/30">
            <Star className="w-3 h-3 mr-1" />
            Premium
          </Badge>
        ) : (
          <Badge variant="outline" className="bg-green-500/20 text-green-400 border-green-400/30">
            <BookOpen className="w-3 h-3 mr-1" />
            Open Source
          </Badge>
        )}
      </div>

      <CardHeader className="pb-4 pt-12">
        {/* Category Badge and Actions */}
        <div className="flex items-start justify-between mb-3">
          <Badge 
            variant="outline" 
            className="chip-hug flex items-center gap-1"
            style={{ 
              borderColor: category.color + '40',
              backgroundColor: category.color + '20',
              color: category.color 
            }}
          >
            <span className="text-sm">{category.icon}</span>
            {category.name}
          </Badge>
          
          <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={handleLike}
                    className="h-8 w-8 p-0"
                  >
                    <Heart className={`w-4 h-4 ${isLiked ? 'fill-current text-red-400' : ''}`} />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>Like template</TooltipContent>
              </Tooltip>
            </TooltipProvider>

            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={handleShare}
                    className="h-8 w-8 p-0"
                  >
                    <Share2 className="w-4 h-4" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>Share template</TooltipContent>
              </Tooltip>
            </TooltipProvider>
            
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      onExportTemplate(template.id);
                    }}
                    className="h-8 w-8 p-0"
                  >
                    <Download className="w-4 h-4" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>Download template</TooltipContent>
              </Tooltip>
            </TooltipProvider>
            
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteTemplate(template.id);
                    }}
                    className="h-8 w-8 p-0 hover:bg-destructive/20 hover:text-destructive"
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>Remove from library</TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </div>
        </div>

        {/* Template Title and Description */}
        <div className="space-y-2">
          <CardTitle className="text-lg line-clamp-2 leading-tight">
            {template.name}
          </CardTitle>
          <CardDescription className="text-sm line-clamp-3 leading-relaxed">
            {template.description}
          </CardDescription>
        </div>

        {/* Enhanced Stats */}
        <div className="flex items-center gap-4 text-xs text-muted-foreground pt-2">
          <div className="flex items-center gap-1">
            <Users className="w-3 h-3" />
            <span>{template.usageCount} uses</span>
          </div>
          <div className="flex items-center gap-1">
            <Heart className="w-3 h-3" />
            <span>{likes + (isLiked ? 1 : 0)} likes</span>
          </div>
          <div className="flex items-center gap-1">
            <GitFork className="w-3 h-3" />
            <span>{Math.floor(template.usageCount * 0.3)} forks</span>
          </div>
        </div>

        {/* Tags */}
        {template.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-3">
            {template.tags.slice(0, 2).map((tag) => (
              <Badge key={tag} variant="secondary" className="chip-hug text-xs">
                {tag}
              </Badge>
            ))}
            {template.tags.length > 2 && (
              <TooltipProvider>
                <Tooltip>
                  <TooltipTrigger>
                    <Badge variant="outline" className="chip-hug text-xs">
                      +{template.tags.length - 2}
                    </Badge>
                  </TooltipTrigger>
                  <TooltipContent>
                    <div className="text-xs max-w-48">
                      <p className="font-medium mb-1">Additional tags:</p>
                      <p>{template.tags.slice(2).join(', ')}</p>
                    </div>
                  </TooltipContent>
                </Tooltip>
              </TooltipProvider>
            )}
          </div>
        )}
      </CardHeader>

      <CardContent className="pt-0 space-y-4">
        {/* Enhanced Configuration Summary */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Skill Level</span>
            <Badge variant="outline" className={`chip-hug text-xs ${complexity.color} flex items-center gap-1`}>
              <ComplexityIcon className="w-3 h-3" />
              {complexity.level}
            </Badge>
          </div>
          
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="space-y-1">
              <div className="text-muted-foreground">Extensions</div>
              <div className="font-medium">{template.wizardData.extensions?.length || 0}</div>
            </div>
            <div className="space-y-1">
              <div className="text-muted-foreground">Constraints</div>
              <div className="font-medium">{template.wizardData.constraints?.length || 0}</div>
            </div>
          </div>

          {/* Security Level */}
          {template.wizardData.security.vaultIntegration !== 'none' && (
            <div className="flex items-center gap-2 text-xs">
              <Shield className="w-3 h-3 text-blue-400" />
              <span className="text-blue-400">Enterprise Security Included</span>
            </div>
          )}
        </div>

        {/* Timeline */}
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <div className="flex items-center gap-2">
            <Calendar className="w-3 h-3" />
            <span>Added {formatDate(template.createdAt)}</span>
          </div>
          {template.author && (
            <div className="flex items-center gap-2">
              <User className="w-3 h-3" />
              <span>by {template.author}</span>
            </div>
          )}
        </div>

        {/* Enhanced Use Template Button */}
        <div className="space-y-2">
          <Button
            className="w-full bg-primary hover:bg-primary/90 transition-all duration-300 group-hover:shadow-lg"
            onClick={() => onUseTemplate(template)}
          >
            <Play className="w-4 h-4 mr-2" />
            Use This Template
          </Button>
          
          <p className="text-center text-xs text-muted-foreground">
            {template.isPreConfigured 
              ? 'Premium template • Pre-optimized workflows' 
              : 'Free and open source • Ready to customize'
            }
          </p>
        </div>
      </CardContent>

      {/* Subtle background pattern for featured templates */}
      {popularityBadge && (
        <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-purple-500/5 pointer-events-none"></div>
      )}
    </Card>
  );
}