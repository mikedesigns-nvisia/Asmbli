import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { 
  Users, 
  Crown, 
  ArrowRight,
  Zap,
  BookOpen,
  Play,
  Shield
} from 'lucide-react';

interface TemplatesPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSignUp: () => void;
}

// Sample template data for preview
const sampleTemplates = {
  community: [
    {
      id: 'basic-chatbot',
      name: 'Basic Chatbot',
      description: 'Simple conversational AI for customer support and general queries',
      category: 'Communication',
      icon: '💬',
      tags: ['beginner', 'customer-support', 'chat'],
      author: 'DevCommunity',
      isOpenSource: true,
      extensions: 3,
      constraints: 1
    },
    {
      id: 'code-reviewer',
      name: 'Code Reviewer',
      description: 'Automated code review and suggestions for better coding practices',
      category: 'Development',
      icon: '🔍',
      tags: ['code-review', 'development', 'automation'],
      author: 'CodeMasters',
      isOpenSource: true,
      extensions: 5,
      constraints: 2
    },
    {
      id: 'content-writer',
      name: 'Content Writer',
      description: 'AI-powered content creation for blogs, social media, and marketing',
      category: 'Content',
      icon: '✍️',
      tags: ['content', 'writing', 'marketing'],
      author: 'ContentCreators',
      isOpenSource: true,
      extensions: 4,
      constraints: 1
    }
  ],
  premium: [
    {
      id: 'figma-design-engineer-pro',
      name: 'UI Engineer',
      description: 'Premium design-to-code specialist with enterprise Figma integration and automated workflows',
      category: 'Design & Development',
      icon: '🎨',
      tags: ['figma', 'design-system', 'enterprise'],
      isPremium: true,
      price: '$29/mo',
      features: ['Figma API Integration', 'Component Library Sync', 'Auto Code Generation', 'Design System Management']
    },
    {
      id: 'fullstack-architect-pro',
      name: 'Full-Stack Architect',
      description: 'Complete application architecture with database design, API development, and deployment automation',
      category: 'Development',
      icon: '🏗️',
      tags: ['fullstack', 'architecture', 'enterprise'],
      isPremium: true,
      price: '$29/mo',
      features: ['Database Design', 'API Architecture', 'Cloud Deployment', 'Security Implementation']
    },
    {
      id: 'security-analyst-pro',
      name: 'Security Analyst',
      description: 'Advanced security analysis with threat detection, compliance checking, and vulnerability management',
      category: 'Security & Compliance',
      icon: '🔐',
      tags: ['security', 'compliance', 'enterprise'],
      isPremium: true,
      price: '$29/mo',
      features: ['Threat Detection', 'Compliance Audit', 'Vulnerability Scanning', 'Security Reports']
    }
  ]
};

export function TemplatesPreviewModal({ isOpen, onClose, onSignUp }: TemplatesPreviewModalProps) {
  const [activeTab, setActiveTab] = useState('community');

  const renderTemplateCard = (template: any, isPremium = false) => (
    <Card key={template.id} className="selection-card relative overflow-hidden">
      {/* Premium/Open Source Badge */}
      <div className="absolute top-3 right-3 z-10">
        {isPremium ? (
          <Badge className="bg-purple-500 text-white flex items-center gap-1">
            <Crown className="w-3 h-3" />
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
        <div className="flex items-start justify-between mb-3">
          <Badge variant="outline" className="chip-hug flex items-center gap-1">
            <span className="text-sm">{template.icon}</span>
            {template.category}
          </Badge>
        </div>

        <div className="space-y-2">
          <CardTitle className="text-lg line-clamp-2 leading-tight">
            {template.name}
          </CardTitle>
          <CardDescription className="text-sm line-clamp-3 leading-relaxed">
            {template.description}
          </CardDescription>
        </div>


        {/* Tags */}
        <div className="flex flex-wrap gap-1 mt-3">
          {template.tags.slice(0, 2).map((tag: string) => (
            <Badge key={tag} variant="secondary" className="chip-hug text-xs">
              {tag}
            </Badge>
          ))}
          {template.tags.length > 2 && (
            <Badge variant="outline" className="chip-hug text-xs">
              +{template.tags.length - 2}
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="pt-0 space-y-4">
        {/* Premium Features */}
        {isPremium && template.features && (
          <div>
            <h4 className="text-sm font-medium mb-2">Key Features:</h4>
            <div className="space-y-1">
              {template.features.slice(0, 3).map((feature: string, index: number) => (
                <div key={index} className="flex items-center gap-2 text-xs text-muted-foreground">
                  <div className="w-1.5 h-1.5 bg-primary rounded-full"></div>
                  {feature}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Configuration Summary for Community */}
        {!isPremium && (
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="space-y-1">
              <div className="text-muted-foreground">Extensions</div>
              <div className="font-medium">{template.extensions}</div>
            </div>
            <div className="space-y-1">
              <div className="text-muted-foreground">Constraints</div>
              <div className="font-medium">{template.constraints}</div>
            </div>
          </div>
        )}

        {/* Action Button */}
        <div className="space-y-2">
          <Button 
            className="w-full" 
            size="sm"
            onClick={onSignUp}
          >
            {isPremium ? (
              <>
                <Crown className="w-4 h-4 mr-2" />
                Sign Up for Premium
              </>
            ) : (
              <>
                <Play className="w-4 h-4 mr-2" />
                Sign Up to Use
              </>
            )}
          </Button>
          
          {isPremium && (
            <p className="text-center text-xs text-muted-foreground">
              {template.price} • 7-day free trial
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="!max-w-5xl !w-full max-h-[90vh] overflow-y-auto p-8 sm:!max-w-5xl">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle className="text-2xl flex items-center gap-3">
                <div className="relative">
                  <BookOpen className="w-7 h-7 text-primary" />
                  <div className="absolute -top-1 -right-1 w-3 h-3 bg-primary rounded-full animate-pulse"></div>
                </div>
                Template Library Preview
              </DialogTitle>
              <DialogDescription className="text-base mt-2">
                Explore our collection of AI agent templates. Sign up to access the full library and deploy your own agents.
              </DialogDescription>
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6 mt-6">

          {/* Template Tabs */}
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="community" className="flex items-center gap-2">
                <Users className="w-4 h-4" />
                Community Templates
              </TabsTrigger>
              <TabsTrigger value="premium" className="flex items-center gap-2">
                <Crown className="w-4 h-4" />
                Premium Templates
              </TabsTrigger>
            </TabsList>

            <TabsContent value="community" className="space-y-4 mt-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold">Community Templates</h3>
                  <p className="text-sm text-muted-foreground">Free, open-source templates contributed by the community</p>
                </div>
                <Badge variant="outline" className="flex items-center gap-1">
                  <BookOpen className="w-3 h-3" />
                  Free & Open Source
                </Badge>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
                {sampleTemplates.community.map(template => 
                  renderTemplateCard(template, false)
                )}
              </div>
            </TabsContent>

            <TabsContent value="premium" className="space-y-4 mt-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold">Premium Templates</h3>
                  <p className="text-sm text-muted-foreground">Expert-optimized templates with enterprise features and priority support</p>
                </div>
                <Badge className="bg-purple-500 text-white flex items-center gap-1">
                  <Crown className="w-3 h-3" />
                  Premium Only
                </Badge>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
                {sampleTemplates.premium.map(template => 
                  renderTemplateCard(template, true)
                )}
              </div>

              {/* Premium Benefits */}
              <Card className="bg-gradient-to-br from-purple-500/5 to-blue-500/5 border-purple-200/30 backdrop-blur-sm">
                <CardContent className="p-4">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="text-center space-y-2">
                      <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
                        <Zap className="w-5 h-5 text-purple-600" />
                      </div>
                      <h4 className="font-semibold text-sm">Expert-Optimized</h4>
                      <p className="text-xs text-muted-foreground">Pre-configured by professionals</p>
                    </div>
                    <div className="text-center space-y-2">
                      <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
                        <Shield className="w-5 h-5 text-purple-600" />
                      </div>
                      <h4 className="font-semibold text-sm">Enterprise Security</h4>
                      <p className="text-xs text-muted-foreground">Advanced auth & compliance</p>
                    </div>
                    <div className="text-center space-y-2">
                      <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
                        <Users className="w-5 h-5 text-purple-600" />
                      </div>
                      <h4 className="font-semibold text-sm">Priority Support</h4>
                      <p className="text-xs text-muted-foreground">24/7 expert assistance</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          {/* Bottom CTA */}
          <div className="border-t pt-6">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-semibold">Ready to build your AI agent?</h4>
                <p className="text-sm text-muted-foreground">Join developers using asmbli</p>
              </div>
              <div className="flex items-center gap-3">
                <Button variant="outline" onClick={onClose}>
                  Maybe Later
                </Button>
                <Button onClick={onSignUp} className="flex items-center gap-2">
                  <ArrowRight className="w-4 h-4" />
                  Sign Up Free
                </Button>
              </div>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}