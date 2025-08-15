import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { CheckCircle, Code, Palette, GraduationCap, Users, FileText, Database } from 'lucide-react';

interface MVPStep1RoleProps {
  selectedRole: string;
  onRoleSelect: (role: 'developer' | 'creator' | 'researcher') => void;
}

const ROLES = [
  {
    id: 'developer' as const,
    title: 'Developer',
    description: 'I write code and build applications',
    icon: Code,
    color: 'bg-blue-500/10 border-blue-500/30 text-blue-500',
    benefits: [
      'Code that follows your patterns',
      'Git-aware suggestions',
      'API documentation help',
      'Code review assistance'
    ],
    tools: ['Git', 'VS Code', 'GitHub', 'APIs', 'Databases'],
    constraints: ['Code quality standards', 'Architecture patterns', 'Security best practices']
  },
  {
    id: 'creator' as const,
    title: 'Content Creator',
    description: 'I create content, write, or design',
    icon: Palette,
    color: 'bg-purple-500/10 border-purple-500/30 text-purple-500',
    benefits: [
      'Content in your brand voice',
      'Design-to-content workflows',
      'Social media optimization',
      'Brand consistency checks'
    ],
    tools: ['Figma', 'Notion', 'Social Media', 'Writing Tools', 'Design Systems'],
    constraints: ['Brand guidelines', 'Content style', 'Accessibility requirements']
  },
  {
    id: 'researcher' as const,
    title: 'Researcher',
    description: 'I conduct research and analyze data',
    icon: GraduationCap,
    color: 'bg-green-500/10 border-green-500/30 text-green-500',
    benefits: [
      'Research methodology compliance',
      'Citation format adherence',
      'Data analysis protocols',
      'Literature review help'
    ],
    tools: ['Academic Databases', 'Citation Tools', 'Data Analysis', 'Research Protocols'],
    constraints: ['Research methodology', 'Citation styles', 'IRB requirements']
  }
];

export function MVPStep1Role({ selectedRole, onRoleSelect }: MVPStep1RoleProps) {
  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-semibold">What's your primary role?</h2>
        <p className="text-muted-foreground">
          This helps us customize your AI agent with the right tools and knowledge for your workflow.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {ROLES.map((role) => {
          const Icon = role.icon;
          const isSelected = selectedRole === role.id;
          
          return (
            <Card
              key={role.id}
              className={`cursor-pointer transition-all duration-300 hover:shadow-lg relative ${
                isSelected 
                  ? 'border-primary bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-lg ring-2 ring-primary/20' 
                  : 'hover:border-primary/30 hover:shadow-md border-border'
              }`}
              onClick={() => onRoleSelect(role.id)}
            >
              {isSelected && (
                <div className="absolute -top-2 -right-2 bg-primary rounded-full p-1">
                  <CheckCircle className="w-4 h-4 text-primary-foreground" />
                </div>
              )}
              
              <CardHeader className="text-center pb-4">
                <div className={`w-16 h-16 mx-auto rounded-full flex items-center justify-center mb-3 ${role.color}`}>
                  <Icon className="w-8 h-8" />
                </div>
                <CardTitle className="text-xl">{role.title}</CardTitle>
                <CardDescription className="text-sm">
                  {role.description}
                </CardDescription>
              </CardHeader>
              
              <CardContent className="space-y-4">
                {/* Key Benefits */}
                <div className="space-y-2">
                  <h4 className="font-medium text-sm text-muted-foreground">Key Benefits:</h4>
                  <div className="space-y-1">
                    {role.benefits.slice(0, 3).map((benefit, index) => (
                      <div key={index} className="flex items-start gap-2 text-xs">
                        <div className="w-1 h-1 rounded-full bg-primary mt-2 flex-shrink-0" />
                        <span className="text-muted-foreground">{benefit}</span>
                      </div>
                    ))}
                  </div>
                </div>
                
                {/* Common Tools */}
                <div className="space-y-2">
                  <h4 className="font-medium text-sm text-muted-foreground">Common Tools:</h4>
                  <div className="flex flex-wrap gap-1">
                    {role.tools.slice(0, 3).map((tool, index) => (
                      <Badge key={index} variant="outline" className="text-xs">
                        {tool}
                      </Badge>
                    ))}
                    {role.tools.length > 3 && (
                      <Badge variant="outline" className="text-xs">
                        +{role.tools.length - 3} more
                      </Badge>
                    )}
                  </div>
                </div>
                
                {/* Constraints */}
                <div className="space-y-2">
                  <h4 className="font-medium text-sm text-muted-foreground">Typical Constraints:</h4>
                  <div className="space-y-1">
                    {role.constraints.slice(0, 2).map((constraint, index) => (
                      <div key={index} className="flex items-start gap-2 text-xs">
                        <FileText className="w-3 h-3 text-muted-foreground mt-0.5 flex-shrink-0" />
                        <span className="text-muted-foreground">{constraint}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Selection Feedback */}
      {selectedRole && (
        <div className="mt-6 p-4 bg-primary/10 border border-primary/20 rounded-lg">
          <div className="flex items-start gap-3">
            <CheckCircle className="w-5 h-5 text-primary mt-0.5" />
            <div>
              <h4 className="font-medium text-primary">
                Great choice! We'll customize your agent for {ROLES.find(r => r.id === selectedRole)?.title.toLowerCase()}s.
              </h4>
              <p className="text-sm text-muted-foreground mt-1">
                Next, we'll help you select the specific tools and integrations that matter to your workflow.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Help Text */}
      <div className="mt-8 text-center">
        <p className="text-sm text-muted-foreground">
          💡 Don't see your role? Pick the closest match - you can customize everything in the next steps.
        </p>
      </div>
    </div>
  );
}