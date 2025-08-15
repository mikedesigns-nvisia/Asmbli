
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../ui/card';
import { Badge } from '../../ui/badge';
import { Button } from '../../ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../../ui/tooltip';
import { 
  CheckCircle, 
  Star, 
  Clock, 
  TrendingUp,
  Shield,
  Zap,
  Globe,
  Lock
} from 'lucide-react';
import { Extension } from './types';
import { platformColors, getIconForCategory } from './constants';

interface ExtensionCardProps {
  extension: Extension;
  isSelected: boolean;
  isRecommended: boolean;
  isFavorited: boolean;
  selectedExt?: Extension;
  globalAdvancedView: boolean;
  onToggleExtension: (extensionId: string, platform?: string) => void;
  onToggleFavorite: (extensionId: string) => void;
}

export function ExtensionCard({
  extension,
  isSelected,
  isRecommended,
  isFavorited,
  selectedExt,
  globalAdvancedView,
  onToggleExtension,
  onToggleFavorite
}: ExtensionCardProps) {
  // Use provider-specific icon if available, otherwise use category icon
  const IconComponent = extension.icon 
    ? getIconForCategory(extension.icon)
    : getIconForCategory(extension.category);

  // Map complexity to security level colors
  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'low': return 'text-green-400';
      case 'medium': return 'text-yellow-400';
      case 'high': return 'text-red-400';
      default: return 'text-gray-400';
    }
  };

  // Map pricing to badge color
  const getPricingColor = (pricing: string) => {
    switch (pricing) {
      case 'free': return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'freemium': return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      case 'paid': return 'bg-orange-500/20 text-orange-400 border-orange-500/30';
      default: return 'bg-gray-500/20 text-gray-400 border-gray-500/30';
    }
  };

  // Create platform badges based on connectionType and supportedConnectionTypes
  const createPlatformBadges = () => {
    const badges = [];
    
    // If extension supports multiple connection types, show all options
    if (extension.supportedConnectionTypes && extension.supportedConnectionTypes.length > 1) {
      extension.supportedConnectionTypes.forEach(connectionType => {
        const connectionColors = platformColors[connectionType as keyof typeof platformColors] || 
                               platformColors.api;
        badges.push({
          name: connectionType.toUpperCase(),
          type: connectionType,
          colors: connectionColors,
          isActive: selectedExt?.selectedPlatforms?.includes(connectionType)
        });
      });
    } else {
      // Single connection type
      const connectionType = extension.connectionType;
      if (connectionType) {
        const connectionColors = platformColors[connectionType as keyof typeof platformColors] || 
                               platformColors.api;
        badges.push({
          name: connectionType.toUpperCase(),
          type: connectionType,
          colors: connectionColors,
          isActive: selectedExt?.selectedPlatforms?.includes(connectionType)
        });
      }
    }

    return badges;
  };

  const platformBadges = createPlatformBadges();

  return (
    <Card 
      className={`selection-card transition-all duration-300 hover:-translate-y-1 cursor-pointer relative 
        overflow-hidden w-full extension-card
        ${
          isSelected 
            ? 'selected ring-2 ring-primary/70 bg-gradient-to-br from-primary/10 to-primary/5 shadow-lg shadow-primary/20' 
            : 'hover:ring-1 hover:ring-primary/30'
        } ${
          isRecommended && !isSelected 
            ? 'ring-1 ring-yellow-500/40 bg-gradient-to-br from-yellow-500/8 to-transparent' 
            : ''
        }`}
      onClick={() => onToggleExtension(extension.id)}
    >
      {/* Selection indicator */}
      {isSelected && (
        <div className="absolute top-2 right-2 w-6 h-6 bg-primary rounded-full flex items-center justify-center z-10">
          <CheckCircle className="w-4 h-4 text-primary-foreground" />
        </div>
      )}
      
      {/* Recommended indicator */}
      {isRecommended && !isSelected && (
        <div className="absolute top-2 right-2 w-6 h-6 bg-yellow-500/20 rounded-full flex items-center justify-center z-10">
          <Star className="w-4 h-4 text-yellow-400 fill-current" />
        </div>
      )}

      {/* Favorite indicator */}
      {isFavorited && (
        <div className="absolute top-2 left-2 w-6 h-6 bg-red-500/20 rounded-full flex items-center justify-center z-10">
          <Star className="w-4 h-4 text-red-400 fill-current" />
        </div>
      )}

      <CardHeader className="pb-3">
        {/* Header Row with Icon, Title, and Actions */}
        <div className="flex flex-col items-center gap-3 mb-3">
          {/* Icon */}
          <div 
            className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-primary/10"
          >
            <IconComponent className="w-5 h-5 text-primary" />
          </div>
          
          {/* Content Area */}
          <div className="flex flex-col items-center gap-2 w-full">
            {/* Title Row with Icons */}
            <div className="flex items-center justify-center gap-2">
              <CardTitle className="text-sm text-center safe-truncate">
                {extension.name}
              </CardTitle>
              
              {/* Status Icons */}
              <div className="flex items-center gap-1 flex-shrink-0">
                {extension.pricing === 'free' && (
                  <CheckCircle className="w-4 h-4 text-green-400" />
                )}
                {isRecommended && (
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger>
                        <Star className="w-4 h-4 text-yellow-400 fill-current" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Recommended for your use case</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                )}
              </div>
            </div>
            
            {/* Badges Row */}
            <div className="flex flex-wrap items-center justify-center gap-1 badge-container">
              <Badge 
                variant="outline" 
                className={`chip-hug text-xs whitespace-nowrap ${getPricingColor(extension.pricing)}`}
              >
                {extension.pricing}
              </Badge>
              <Badge variant="secondary" className="chip-hug text-xs whitespace-nowrap">
                {extension.provider}
              </Badge>
              {extension.category === 'Design & Prototyping' && (
                <Badge variant="outline" className="chip-hug text-xs whitespace-nowrap bg-indigo-500/20 text-indigo-400 border-indigo-500/30">
                  Design
                </Badge>
              )}
            </div>
          </div>
        </div>
        
        {/* Description */}
        <div className="mb-3 px-2">
          <CardDescription className="text-xs line-clamp-2 leading-relaxed text-muted-foreground text-center">
            {extension.description}
          </CardDescription>
        </div>

        {/* Platform Support */}
        <div className="flex items-center justify-center">
          <TooltipProvider>
            <div className="flex flex-wrap items-center justify-center gap-1">
              {platformBadges.map((badge, index) => {
                return (
                  <Tooltip key={index}>
                    <TooltipTrigger asChild>
                      <Badge 
                        variant="outline"
                        className={`chip-hug text-xs cursor-pointer hover:scale-105 transition-transform duration-200 
                          whitespace-nowrap
                          ${badge.colors?.bg} ${badge.colors?.text} ${badge.colors?.border} 
                          ${badge.isActive ? 'ring-2 ring-current shadow-md' : 'hover:shadow-sm'}`}
                        onClick={(e) => {
                          e.stopPropagation();
                          onToggleExtension(extension.id, badge.type);
                        }}
                      >
                        {badge.name}
                      </Badge>
                    </TooltipTrigger>
                    <TooltipContent>
                      <div className="text-xs max-w-64">
                        <p className="mb-2 font-medium text-foreground">
                          Click to {badge.isActive ? 'deactivate' : 'activate'} {badge.name} connection
                        </p>
                        <div className="space-y-1 text-muted-foreground">
                          <p><span className="text-muted-foreground">Auth:</span> {extension.authMethod}</p>
                          <p><span className="text-muted-foreground">Type:</span> {extension.connectionType}</p>
                          {extension.features && extension.features.length > 0 && (
                            <p><span className="text-muted-foreground">Features:</span> {extension.features.slice(0, 2).join(', ')}</p>
                          )}
                        </div>
                      </div>
                    </TooltipContent>
                  </Tooltip>
                );
              })}
            </div>
          </TooltipProvider>
        </div>
      </CardHeader>

      <CardContent className="pt-0">
        {/* Stats Row */}
        <div className="flex items-center justify-around text-xs text-muted-foreground mb-3">
          <div className="flex items-center gap-1">
            <Clock className="w-3 h-3" />
            <span>Setup: {extension.setupComplexity}/5</span>
          </div>
          
          <div className="flex items-center gap-1">
            <TrendingUp className="w-3 h-3" />
            <span>{extension.features?.length || 0} features</span>
          </div>
          
          <div className="flex items-center gap-1">
            <Shield className={`w-3 h-3 ${getComplexityColor(extension.complexity)}`} />
            <span className={getComplexityColor(extension.complexity)}>
              {extension.complexity}
            </span>
          </div>
        </div>

        {/* Advanced View Details */}
        {globalAdvancedView && (
          <div className="mt-3 pt-3 border-t border-border/50">
            <div className="space-y-2 text-xs">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Complexity:</span>
                <Badge 
                  variant={extension.complexity === 'low' ? 'default' : 
                          extension.complexity === 'medium' ? 'secondary' : 'outline'}
                  className="chip-hug text-xs"
                >
                  {extension.complexity.toUpperCase()}
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Provider:</span>
                <span className="text-xs">{extension.provider}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Auth Method:</span>
                <span className="text-xs">{extension.authMethod}</span>
              </div>
              {extension.capabilities && extension.capabilities.length > 0 && (
                <div className="mt-2">
                  <span className="text-muted-foreground">Capabilities:</span>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {extension.capabilities.slice(0, 3).map((capability, idx) => (
                      <Badge key={idx} variant="outline" className="chip-hug-tight text-xs">
                        {capability}
                      </Badge>
                    ))}
                    {extension.capabilities.length > 3 && (
                      <Badge variant="outline" className="chip-hug-tight text-xs">
                        +{extension.capabilities.length - 3}
                      </Badge>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Configuration Progress for Selected Extensions */}
        {isSelected && selectedExt && (
          <div className="mt-3 pt-3 border-t border-primary/20">
            <div className="flex items-center justify-between text-xs mb-2">
              <span className="text-primary font-medium">Configuration Progress</span>
              <span className="text-primary font-medium">{selectedExt.configProgress || 25}%</span>
            </div>
            <div className="w-full bg-primary/20 rounded-full h-2">
              <div 
                className="bg-gradient-to-r from-primary to-primary/80 h-2 rounded-full transition-all duration-500 ease-out" 
                style={{ width: `${selectedExt.configProgress || 25}%` }}
              />
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground mt-1">
              <span>Status: {selectedExt.status || 'configuring'}</span>
              <span>{selectedExt.selectedPlatforms?.length || 0} platform{(selectedExt.selectedPlatforms?.length || 0) !== 1 ? 's' : ''}</span>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center gap-2 mt-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={(e) => {
              e.stopPropagation();
              onToggleFavorite(extension.id);
            }}
            className="flex items-center gap-1 text-xs"
          >
            <Star className={`w-3 h-3 ${isFavorited ? 'text-red-400 fill-current' : 'text-muted-foreground'}`} />
            {isFavorited ? 'Favorited' : 'Favorite'}
          </Button>
          
          {extension.documentation && (
            <Button
              variant="ghost"
              size="sm"
              onClick={(e) => {
                e.stopPropagation();
                try {
                  // Ensure the URL is absolute for external links
                  const url = extension.documentation.startsWith('http') 
                    ? extension.documentation 
                    : `https://${extension.documentation}`;
                  
                  const newWindow = window.open(url, '_blank', 'noopener,noreferrer');
                  if (!newWindow) {
                    // Fallback if popup blocked
                    window.location.href = url;
                  }
                } catch (error) {
                  console.error('Failed to open documentation:', error);
                  // Fallback to direct navigation
                  window.location.href = extension.documentation;
                }
              }}
              className="flex items-center gap-1 text-xs"
              title={`Open documentation for ${extension.name}`}
              aria-label={`View external documentation for ${extension.name}`}
            >
              <Globe className="w-3 h-3" />
              Docs
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}