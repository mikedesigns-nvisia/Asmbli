import { useState, useEffect } from 'react';
import { 
  X, 
  ArrowRight, 
  Zap, 
  Crown,
  Star,
  CheckCircle,
  Code,
  Palette,
  BarChart3,
  MessageSquare
} from 'lucide-react';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';

interface TemplatesPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onViewAll: () => void;
  onGetStarted: () => void;
}

export function TemplatesPreviewModal({ isOpen, onClose, onViewAll, onGetStarted }: TemplatesPreviewModalProps) {
  const [selectedCategory, setSelectedCategory] = useState('all');

  // Sample template data for preview
  const sampleTemplates = [
    {
      id: '1',
      name: 'Code Review Assistant',
      description: 'AI-powered code analysis and review suggestions with best practice recommendations.',
      category: 'Development',
      icon: Code,
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/10',
      tags: ['Code Review', 'Development', 'Quality Assurance'],
      featured: true
    },
    {
      id: '2', 
      name: 'UI/UX Design Reviewer',
      description: 'Analyze designs for accessibility, usability, and design system compliance.',
      category: 'Design',
      icon: Palette,
      color: 'text-primary',
      bgColor: 'bg-primary/10',
      tags: ['Design', 'UI/UX', 'Accessibility'],
      featured: false
    },
    {
      id: '3',
      name: 'Data Analyst Agent',
      description: 'Transform raw data into actionable insights with automated reporting.',
      category: 'Analytics',
      icon: BarChart3,
      color: 'text-green-500',
      bgColor: 'bg-green-500/10',
      tags: ['Data', 'Analytics', 'Reporting'],
      featured: true
    },
    {
      id: '4',
      name: 'Customer Support Bot',
      description: 'Intelligent customer service with context-aware responses and escalation.',
      category: 'Support',
      icon: MessageSquare,
      color: 'text-orange-500',
      bgColor: 'bg-orange-500/10',
      tags: ['Support', 'Customer Service', 'Chat'],
      featured: false
    }
  ];

  const categories = [
    { id: 'all', name: 'All Templates', count: sampleTemplates.length },
    { id: 'Development', name: 'Development', count: 1 },
    { id: 'Design', name: 'Design', count: 1 },
    { id: 'Analytics', name: 'Analytics', count: 1 },
    { id: 'Support', name: 'Support', count: 1 }
  ];

  const filteredTemplates = selectedCategory === 'all' 
    ? sampleTemplates 
    : sampleTemplates.filter(t => t.category === selectedCategory);

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }
    
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className="relative w-full max-w-4xl mx-4 max-h-[90vh] bg-background rounded-xl shadow-2xl border overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b bg-gradient-to-r from-background to-muted/30">
          <div>
            <h2 className="text-2xl font-bold">Template Library Preview</h2>
            <p className="text-muted-foreground mt-1">
              Get a taste of our pre-built AI agent templates
            </p>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose}>
            <X className="w-5 h-5" />
          </Button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6 overflow-y-auto max-h-[calc(90vh-200px)]">
          {/* Categories */}
          <div className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <Button
                key={category.id}
                variant={selectedCategory === category.id ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedCategory(category.id)}
                className="text-sm"
              >
                {category.name} ({category.count})
              </Button>
            ))}
          </div>

          {/* Templates Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredTemplates.map((template) => {
              const Icon = template.icon;
              return (
                <Card key={template.id} className="hover:shadow-md transition-shadow">
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div className="flex items-start space-x-3">
                        <div className={`p-2 rounded-lg ${template.bgColor}`}>
                          <Icon className={`w-5 h-5 ${template.color}`} />
                        </div>
                        <div>
                          <CardTitle className="text-base flex items-center gap-2">
                            {template.name}
                            {template.featured && (
                              <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                            )}
                          </CardTitle>
                          <Badge variant="outline" className="mt-1 text-xs">
                            {template.category}
                          </Badge>
                        </div>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    <CardDescription className="text-sm">
                      {template.description}
                    </CardDescription>
                    
                    <div className="flex flex-wrap gap-1">
                      {template.tags.slice(0, 3).map((tag) => (
                        <Badge key={tag} variant="secondary" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>

                    <div className="flex items-center justify-between pt-2">
                      <div className="flex items-center text-xs text-muted-foreground">
                        <CheckCircle className="w-3 h-3 mr-1 text-green-500" />
                        Ready to deploy
                      </div>
                      <Button size="sm" variant="outline">
                        Preview
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {/* Premium Preview */}
          <Card className="bg-gradient-to-r from-primary/5 to-primary/10 border-primary/20">
            <CardContent className="p-6">
              <div className="flex items-center justify-center space-x-3 mb-4">
                <Crown className="w-6 h-6 text-primary" />
                <h3 className="text-lg font-semibold">Premium Templates</h3>
                <Badge className="bg-primary">Coming Soon</Badge>
              </div>
              <p className="text-center text-muted-foreground mb-4">
                Advanced templates with enterprise features, custom integrations, and priority support.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                {[
                  'Enterprise Security Agent',
                  'Advanced Analytics Suite', 
                  'Custom Integration Builder'
                ].map((name, index) => (
                  <div key={index} className="text-center p-3 bg-background/50 rounded-lg border">
                    <div className="text-sm font-medium">{name}</div>
                    <div className="text-xs text-muted-foreground mt-1">Premium</div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Footer */}
        <div className="p-6 border-t bg-muted/30 flex flex-col sm:flex-row items-center justify-between space-y-3 sm:space-y-0">
          <div className="text-sm text-muted-foreground">
            {filteredTemplates.length} templates available • More being added weekly
          </div>
          <div className="flex space-x-3">
            <Button variant="outline" onClick={onViewAll}>
              <Zap className="w-4 h-4 mr-2" />
              Browse All Templates
            </Button>
            <Button onClick={onGetStarted}>
              Get Started
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}