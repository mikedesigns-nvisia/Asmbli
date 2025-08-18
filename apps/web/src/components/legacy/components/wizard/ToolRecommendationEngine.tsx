import React, { useState, useEffect, useMemo } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Progress } from '../ui/progress';
import { 
  Lightbulb, 
  Plus, 
  X, 
  Star, 
  TrendingUp, 
  Users, 
  Zap,
  CheckCircle,
  ExternalLink,
  Info
} from 'lucide-react';
import { toast } from 'sonner';

interface Tool {
  id: string;
  name: string;
  category: string;
  description: string;
  icon?: string;
  popularity: number;
  difficulty: 'easy' | 'medium' | 'hard';
  tags: string[];
  dependencies?: string[];
  documentation?: string;
  useCase: string;
}

interface ToolRecommendation {
  tool: Tool;
  score: number;
  reasons: string[];
  category: 'essential' | 'recommended' | 'suggested';
  isNew?: boolean;
}

interface RecommendationEngineProps {
  selectedRole: string;
  selectedTools: string[];
  extractedConstraints: string[];
  onToolsChange: (tools: string[]) => void;
  className?: string;
}

const TOOL_CATALOG: Tool[] = [
  // Development Tools
  {
    id: 'git',
    name: 'Git',
    category: 'development',
    description: 'Version control and collaboration',
    popularity: 95,
    difficulty: 'medium',
    tags: ['version-control', 'collaboration', 'essential'],
    useCase: 'Track code changes and collaborate with team members'
  },
  {
    id: 'github',
    name: 'GitHub',
    category: 'development',
    description: 'Code hosting and project management',
    popularity: 90,
    difficulty: 'easy',
    tags: ['hosting', 'collaboration', 'ci/cd'],
    dependencies: ['git'],
    useCase: 'Host repositories and manage development workflow'
  },
  {
    id: 'vscode',
    name: 'VS Code',
    category: 'development',
    description: 'Code editor with AI assistance',
    popularity: 85,
    difficulty: 'easy',
    tags: ['editor', 'debugging', 'extensions'],
    useCase: 'Write and debug code with intelligent assistance'
  },
  {
    id: 'docker',
    name: 'Docker',
    category: 'development',
    description: 'Containerization and deployment',
    popularity: 70,
    difficulty: 'medium',
    tags: ['containers', 'deployment', 'devops'],
    useCase: 'Package applications for consistent deployment'
  },
  {
    id: 'npm',
    name: 'NPM',
    category: 'development',
    description: 'Node.js package management',
    popularity: 80,
    difficulty: 'easy',
    tags: ['packages', 'dependencies', 'javascript'],
    useCase: 'Manage JavaScript packages and dependencies'
  },

  // Design Tools
  {
    id: 'figma',
    name: 'Figma',
    category: 'design',
    description: 'Collaborative design and prototyping',
    popularity: 85,
    difficulty: 'easy',
    tags: ['design', 'prototyping', 'collaboration'],
    useCase: 'Create and collaborate on UI/UX designs'
  },
  {
    id: 'sketch',
    name: 'Sketch',
    category: 'design',
    description: 'Vector graphics and UI design',
    popularity: 60,
    difficulty: 'medium',
    tags: ['design', 'ui', 'vector'],
    useCase: 'Design user interfaces and graphics'
  },
  {
    id: 'adobe-cc',
    name: 'Adobe Creative Cloud',
    category: 'design',
    description: 'Complete creative suite',
    popularity: 75,
    difficulty: 'hard',
    tags: ['design', 'creative', 'professional'],
    useCase: 'Professional design and creative work'
  },

  // Productivity Tools
  {
    id: 'notion',
    name: 'Notion',
    category: 'productivity',
    description: 'All-in-one workspace for notes and docs',
    popularity: 80,
    difficulty: 'easy',
    tags: ['notes', 'documentation', 'collaboration'],
    useCase: 'Organize documents, notes, and project information'
  },
  {
    id: 'obsidian',
    name: 'Obsidian',
    category: 'productivity',
    description: 'Knowledge management and note-taking',
    popularity: 65,
    difficulty: 'medium',
    tags: ['notes', 'knowledge', 'linking'],
    useCase: 'Build interconnected knowledge bases'
  },
  {
    id: 'airtable',
    name: 'Airtable',
    category: 'productivity',
    description: 'Spreadsheet-database hybrid',
    popularity: 70,
    difficulty: 'easy',
    tags: ['database', 'spreadsheet', 'collaboration'],
    useCase: 'Organize data and manage projects'
  },

  // Communication Tools
  {
    id: 'slack',
    name: 'Slack',
    category: 'communication',
    description: 'Team communication and collaboration',
    popularity: 85,
    difficulty: 'easy',
    tags: ['chat', 'collaboration', 'team'],
    useCase: 'Communicate with team members and manage discussions'
  },
  {
    id: 'discord',
    name: 'Discord',
    category: 'communication',
    description: 'Voice and text communication',
    popularity: 75,
    difficulty: 'easy',
    tags: ['chat', 'voice', 'community'],
    useCase: 'Real-time communication and community building'
  },
  {
    id: 'zoom',
    name: 'Zoom',
    category: 'communication',
    description: 'Video conferencing and meetings',
    popularity: 90,
    difficulty: 'easy',
    tags: ['video', 'meetings', 'collaboration'],
    useCase: 'Host virtual meetings and presentations'
  },

  // Research Tools
  {
    id: 'scholar',
    name: 'Google Scholar',
    category: 'research',
    description: 'Academic research and citations',
    popularity: 70,
    difficulty: 'easy',
    tags: ['research', 'academic', 'citations'],
    useCase: 'Find academic papers and research sources'
  },
  {
    id: 'zotero',
    name: 'Zotero',
    category: 'research',
    description: 'Reference management and research organization',
    popularity: 60,
    difficulty: 'medium',
    tags: ['references', 'research', 'citations'],
    useCase: 'Manage research references and citations'
  },
  {
    id: 'arxiv',
    name: 'arXiv',
    category: 'research',
    description: 'Scientific paper repository',
    popularity: 55,
    difficulty: 'easy',
    tags: ['papers', 'science', 'preprints'],
    useCase: 'Access latest scientific research and preprints'
  }
];

const ROLE_TOOL_MAPPING = {
  developer: [
    'git', 'github', 'vscode', 'npm', 'docker', 'slack', 'notion'
  ],
  creator: [
    'figma', 'adobe-cc', 'notion', 'slack', 'discord', 'github'
  ],
  researcher: [
    'scholar', 'zotero', 'arxiv', 'notion', 'obsidian', 'slack'
  ]
};

const TOOL_SYNERGIES = {
  'git': ['github', 'vscode'],
  'github': ['git', 'vscode', 'docker'],
  'figma': ['notion', 'slack'],
  'notion': ['slack', 'obsidian'],
  'scholar': ['zotero', 'arxiv'],
  'slack': ['zoom', 'github', 'notion']
};

export function ToolRecommendationEngine({ 
  selectedRole, 
  selectedTools, 
  extractedConstraints,
  onToolsChange, 
  className = '' 
}: RecommendationEngineProps) {
  const [dismissedRecommendations, setDismissedRecommendations] = useState<string[]>([]);
  const [acceptedRecommendations, setAcceptedRecommendations] = useState<string[]>([]);
  const [showAllSuggestions, setShowAllSuggestions] = useState(false);

  useEffect(() => {
    // Load dismissed recommendations from localStorage
    const dismissed = JSON.parse(localStorage.getItem('dismissed_recommendations') || '[]');
    setDismissedRecommendations(dismissed);
    
    const accepted = JSON.parse(localStorage.getItem('accepted_recommendations') || '[]');
    setAcceptedRecommendations(accepted);
  }, []);

  const recommendations = useMemo(() => {
    const recs: ToolRecommendation[] = [];
    
    // Get base recommendations for role
    const roleTools = ROLE_TOOL_MAPPING[selectedRole as keyof typeof ROLE_TOOL_MAPPING] || [];
    
    // Score each tool
    TOOL_CATALOG.forEach(tool => {
      if (selectedTools.includes(tool.id) || dismissedRecommendations.includes(tool.id)) {
        return; // Skip already selected or dismissed tools
      }

      let score = 0;
      const reasons: string[] = [];

      // Role-based scoring
      if (roleTools.includes(tool.id)) {
        score += 50;
        reasons.push(`Essential for ${selectedRole}s`);
      }

      // Popularity scoring
      score += tool.popularity * 0.3;
      if (tool.popularity > 80) {
        reasons.push('Highly popular among users');
      }

      // Synergy scoring
      const synergies = TOOL_SYNERGIES[tool.id] || [];
      const synergyCount = synergies.filter(synergyTool => selectedTools.includes(synergyTool)).length;
      if (synergyCount > 0) {
        score += synergyCount * 20;
        reasons.push(`Works well with ${synergies.filter(s => selectedTools.includes(s)).join(', ')}`);
      }

      // Constraint-based scoring
      extractedConstraints.forEach(constraint => {
        tool.tags.forEach(tag => {
          if (constraint.toLowerCase().includes(tag.toLowerCase())) {
            score += 15;
            reasons.push('Matches your project requirements');
          }
        });
      });

      // Difficulty penalty for beginners
      if (tool.difficulty === 'hard') {
        score -= 10;
      }

      // Category bonus for diversity
      const selectedCategories = selectedTools.map(toolId => 
        TOOL_CATALOG.find(t => t.id === toolId)?.category
      ).filter(Boolean);
      
      if (!selectedCategories.includes(tool.category)) {
        score += 10;
        reasons.push('Adds functionality in a new area');
      }

      if (score > 20) { // Threshold for recommendations
        let category: 'essential' | 'recommended' | 'suggested' = 'suggested';
        
        if (score > 70) category = 'essential';
        else if (score > 50) category = 'recommended';

        recs.push({
          tool,
          score,
          reasons: reasons.slice(0, 3), // Limit to 3 reasons
          category,
          isNew: !acceptedRecommendations.includes(tool.id)
        });
      }
    });

    // Sort by score and limit results
    return recs
      .sort((a, b) => b.score - a.score)
      .slice(0, showAllSuggestions ? 10 : 6);
  }, [selectedRole, selectedTools, extractedConstraints, dismissedRecommendations, acceptedRecommendations, showAllSuggestions]);

  const addTool = (toolId: string) => {
    const newTools = [...selectedTools, toolId];
    onToolsChange(newTools);
    
    // Track acceptance
    const newAccepted = [...acceptedRecommendations, toolId];
    setAcceptedRecommendations(newAccepted);
    localStorage.setItem('accepted_recommendations', JSON.stringify(newAccepted));
    
    toast.success(`Added ${TOOL_CATALOG.find(t => t.id === toolId)?.name} to your tools!`);
  };

  const dismissRecommendation = (toolId: string) => {
    const newDismissed = [...dismissedRecommendations, toolId];
    setDismissedRecommendations(newDismissed);
    localStorage.setItem('dismissed_recommendations', JSON.stringify(newDismissed));
    
    toast.info('Recommendation dismissed');
  };

  const getCategoryIcon = (category: 'essential' | 'recommended' | 'suggested') => {
    switch (category) {
      case 'essential':
        return <Star className="w-4 h-4 text-yellow-500" />;
      case 'recommended':
        return <TrendingUp className="w-4 h-4 text-primary" />;
      case 'suggested':
        return <Lightbulb className="w-4 h-4 text-primary" />;
    }
  };

  const getCategoryLabel = (category: 'essential' | 'recommended' | 'suggested') => {
    switch (category) {
      case 'essential':
        return 'Essential';
      case 'recommended':
        return 'Recommended';
      case 'suggested':
        return 'Suggested';
    }
  };

  const getAcceptanceRate = () => {
    const totalShown = acceptedRecommendations.length + dismissedRecommendations.length;
    if (totalShown === 0) return 0;
    return Math.round((acceptedRecommendations.length / totalShown) * 100);
  };

  if (recommendations.length === 0) {
    return null;
  }

  return (
    <Card className={`${className} border-primary/20 bg-primary/5`}>
      <CardHeader className="pb-4">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-lg">
            <Lightbulb className="w-5 h-5 text-primary" />
            Smart Recommendations
          </CardTitle>
          <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
            {recommendations.length} suggestions
          </Badge>
        </div>
        <CardDescription>
          Based on your role and current tools, here are some recommendations to enhance your workflow.
        </CardDescription>
        
        {/* Acceptance Rate */}
        {(acceptedRecommendations.length > 0 || dismissedRecommendations.length > 0) && (
          <div className="mt-3 p-3 bg-muted/50 rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium">Recommendation Accuracy</span>
              <span className="text-sm text-muted-foreground">{getAcceptanceRate()}%</span>
            </div>
            <Progress value={getAcceptanceRate()} className="h-2" />
            <p className="text-xs text-muted-foreground mt-1">
              Based on {acceptedRecommendations.length} accepted out of {acceptedRecommendations.length + dismissedRecommendations.length} shown
            </p>
          </div>
        )}
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Recommendation Groups */}
        {['essential', 'recommended', 'suggested'].map(category => {
          const categoryRecs = recommendations.filter(r => r.category === category);
          if (categoryRecs.length === 0) return null;

          return (
            <div key={category} className="space-y-3">
              <div className="flex items-center gap-2">
                {getCategoryIcon(category as any)}
                <h4 className="font-medium text-sm">{getCategoryLabel(category as any)}</h4>
                <Badge variant="secondary" className="text-xs">
                  {categoryRecs.length}
                </Badge>
              </div>

              <div className="grid gap-3">
                {categoryRecs.map(({ tool, score, reasons, isNew }) => (
                  <Card 
                    key={tool.id} 
                    className="p-4 hover:shadow-md transition-shadow border-l-4 border-l-blue-500"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h5 className="font-medium text-sm">{tool.name}</h5>
                          {isNew && (
                            <Badge variant="secondary" className="text-xs bg-primary/10 text-primary">
                              New
                            </Badge>
                          )}
                          <Badge variant="outline" className="text-xs">
                            {tool.category}
                          </Badge>
                          <div className="flex items-center gap-1">
                            <Users className="w-3 h-3 text-muted-foreground" />
                            <span className="text-xs text-muted-foreground">{tool.popularity}%</span>
                          </div>
                        </div>
                        
                        <p className="text-xs text-muted-foreground mb-2">
                          {tool.description}
                        </p>
                        
                        <div className="space-y-1">
                          <p className="text-xs font-medium text-primary">
                            <Zap className="w-3 h-3 inline mr-1" />
                            {tool.useCase}
                          </p>
                          
                          {reasons.length > 0 && (
                            <div className="space-y-1">
                              {reasons.map((reason, idx) => (
                                <div key={idx} className="flex items-center gap-1 text-xs text-muted-foreground">
                                  <CheckCircle className="w-3 h-3 text-primary" />
                                  {reason}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>

                        {tool.dependencies && tool.dependencies.length > 0 && (
                          <div className="mt-2">
                            <p className="text-xs text-muted-foreground">
                              <Info className="w-3 h-3 inline mr-1" />
                              Works with: {tool.dependencies.map(dep => 
                                TOOL_CATALOG.find(t => t.id === dep)?.name
                              ).join(', ')}
                            </p>
                          </div>
                        )}
                      </div>

                      <div className="flex gap-2 ml-4">
                        <Button
                          size="sm"
                          onClick={() => addTool(tool.id)}
                          className="flex items-center gap-1"
                        >
                          <Plus className="w-3 h-3" />
                          Add
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => dismissRecommendation(tool.id)}
                          className="flex items-center gap-1 text-muted-foreground hover:text-foreground"
                        >
                          <X className="w-3 h-3" />
                        </Button>
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          );
        })}

        {/* Show More Button */}
        {!showAllSuggestions && recommendations.length >= 6 && (
          <Button
            variant="outline"
            onClick={() => setShowAllSuggestions(true)}
            className="w-full flex items-center gap-2"
          >
            <Lightbulb className="w-4 h-4" />
            Show More Suggestions
          </Button>
        )}

        {/* Reset Dismissed */}
        {dismissedRecommendations.length > 0 && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setDismissedRecommendations([]);
              localStorage.removeItem('dismissed_recommendations');
              toast.info('Cleared dismissed recommendations');
            }}
            className="w-full text-xs text-muted-foreground"
          >
            Reset dismissed recommendations ({dismissedRecommendations.length})
          </Button>
        )}
      </CardContent>
    </Card>
  );
}