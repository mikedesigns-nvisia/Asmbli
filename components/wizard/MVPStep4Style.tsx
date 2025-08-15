
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Slider } from '../ui/slider';
import { Label } from '../ui/label';
import { CheckCircle, Volume2, MessageCircle, Zap, FileText, User, GraduationCap, Palette } from 'lucide-react';

interface MVPStep4StyleProps {
  selectedRole: string;
  style: {
    tone: string;
    responseLength: string;
    constraints: string[];
  };
  extractedConstraints: string[];
  onStyleChange: (style: { tone: string; responseLength: string; constraints: string[] }) => void;
}

const TONE_OPTIONS = {
  developer: [
    { id: 'technical', label: 'Technical & Precise', description: 'Clear, accurate, technical language', icon: '🔧' },
    { id: 'helpful', label: 'Helpful & Supportive', description: 'Encouraging and educational', icon: '🤝' },
    { id: 'efficient', label: 'Efficient & Direct', description: 'Straight to the point, minimal fluff', icon: '⚡' }
  ],
  creator: [
    { id: 'creative', label: 'Creative & Inspiring', description: 'Imaginative and motivational', icon: '🎨' },
    { id: 'professional', label: 'Professional & Polished', description: 'Clean, brand-appropriate tone', icon: '💼' },
    { id: 'friendly', label: 'Friendly & Conversational', description: 'Warm and approachable', icon: '😊' }
  ],
  researcher: [
    { id: 'academic', label: 'Academic & Formal', description: 'Scholarly, precise, citation-ready', icon: '🎓' },
    { id: 'analytical', label: 'Analytical & Objective', description: 'Data-driven and methodical', icon: '📊' },
    { id: 'collaborative', label: 'Collaborative & Inquisitive', description: 'Question-asking and exploratory', icon: '🤔' }
  ]
};

const RESPONSE_LENGTH_OPTIONS = [
  { id: 'concise', label: 'Concise', description: '1-2 sentences, get to the point', value: 25 },
  { id: 'balanced', label: 'Balanced', description: 'A paragraph, good detail', value: 50 },
  { id: 'detailed', label: 'Detailed', description: 'Multiple paragraphs, comprehensive', value: 75 },
  { id: 'comprehensive', label: 'Comprehensive', description: 'Thorough explanation with examples', value: 100 }
];

const ROLE_CONSTRAINTS = {
  developer: [
    'Always include code examples when relevant',
    'Explain the reasoning behind technical decisions',
    'Consider performance implications',
    'Include error handling suggestions',
    'Follow security best practices',
    'Mention testing considerations'
  ],
  creator: [
    'Maintain brand consistency in all outputs',
    'Include accessibility considerations',
    'Suggest visual hierarchy improvements',
    'Consider mobile responsiveness',
    'Include SEO considerations',
    'Maintain consistent design language'
  ],
  researcher: [
    'Always cite sources when making claims',
    'Include methodology considerations',
    'Consider sample size and validity',
    'Include limitations and assumptions',
    'Follow academic writing standards',
    'Include statistical significance when relevant'
  ]
};

export function MVPStep4Style({ selectedRole, style, extractedConstraints, onStyleChange }: MVPStep4StyleProps) {
  const toneOptions = TONE_OPTIONS[selectedRole as keyof typeof TONE_OPTIONS] || TONE_OPTIONS.developer;
  const roleConstraints = ROLE_CONSTRAINTS[selectedRole as keyof typeof ROLE_CONSTRAINTS] || ROLE_CONSTRAINTS.developer;
  
  const handleToneChange = (tone: string) => {
    onStyleChange({
      ...style,
      tone
    });
  };

  const handleResponseLengthChange = (responseLength: string) => {
    onStyleChange({
      ...style,
      responseLength
    });
  };

  const toggleConstraint = (constraint: string) => {
    const currentConstraints = style.constraints || [];
    const newConstraints = currentConstraints.includes(constraint)
      ? currentConstraints.filter(c => c !== constraint)
      : [...currentConstraints, constraint];
    
    onStyleChange({
      ...style,
      constraints: newConstraints
    });
  };

  const selectAllRecommended = () => {
    const recommended = roleConstraints.slice(0, 3); // Top 3 recommendations
    onStyleChange({
      ...style,
      constraints: recommended
    });
  };

  const clearConstraints = () => {
    onStyleChange({
      ...style,
      constraints: []
    });
  };

  const getRoleIcon = () => {
    switch (selectedRole) {
      case 'developer': return <User className="w-5 h-5" />;
      case 'creator': return <Palette className="w-5 h-5" />;
      case 'researcher': return <GraduationCap className="w-5 h-5" />;
      default: return <User className="w-5 h-5" />;
    }
  };

  const getSelectedResponseLength = () => {
    return RESPONSE_LENGTH_OPTIONS.find(option => option.id === style.responseLength) || RESPONSE_LENGTH_OPTIONS[1];
  };

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-semibold">How should your AI communicate?</h2>
        <p className="text-muted-foreground">
          Customize the personality and communication style to match your preferences.
        </p>
      </div>

      {/* Tone Selection */}
      <div className="space-y-4">
        <div className="flex items-center gap-2">
          <MessageCircle className="w-5 h-5 text-primary" />
          <h3 className="text-lg font-semibold">Communication Tone</h3>
          <Badge className="bg-primary/10 text-primary border-primary/30">
            For {selectedRole}s
          </Badge>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {toneOptions.map((option) => {
            const isSelected = style.tone === option.id;
            
            return (
              <Card
                key={option.id}
                className={`cursor-pointer transition-all duration-200 ${
                  isSelected 
                    ? 'border-primary bg-gradient-to-br from-primary/10 via-primary/5 to-transparent shadow-md ring-1 ring-primary/20' 
                    : 'hover:border-primary/30 hover:shadow-sm border-border'
                }`}
                onClick={() => handleToneChange(option.id)}
              >
                <CardHeader className="text-center pb-3">
                  <div className="text-3xl mb-2">{option.icon}</div>
                  <CardTitle className="text-base">{option.label}</CardTitle>
                  <CardDescription className="text-sm">
                    {option.description}
                  </CardDescription>
                </CardHeader>
                
                {isSelected && (
                  <CardContent className="pt-0">
                    <div className="flex items-center justify-center">
                      <CheckCircle className="w-5 h-5 text-primary" />
                    </div>
                  </CardContent>
                )}
              </Card>
            );
          })}
        </div>
      </div>

      {/* Response Length */}
      <div className="space-y-4">
        <div className="flex items-center gap-2">
          <Volume2 className="w-5 h-5 text-primary" />
          <h3 className="text-lg font-semibold">Response Length</h3>
        </div>
        
        <Card className="p-6">
          <div className="space-y-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-base font-medium">How detailed should responses be?</Label>
                <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
                  {getSelectedResponseLength().label}
                </Badge>
              </div>
              
              <div className="space-y-4">
                <Slider
                  value={[getSelectedResponseLength().value]}
                  onValueChange={(value) => {
                    const option = RESPONSE_LENGTH_OPTIONS.find(opt => 
                      Math.abs(opt.value - value[0]) < 15
                    ) || RESPONSE_LENGTH_OPTIONS[1];
                    handleResponseLengthChange(option.id);
                  }}
                  max={100}
                  min={0}
                  step={25}
                  className="w-full"
                />
                
                <div className="flex justify-between text-sm text-muted-foreground">
                  {RESPONSE_LENGTH_OPTIONS.map((option) => (
                    <div key={option.id} className="text-center">
                      <div className="font-medium">{option.label}</div>
                      <div className="text-xs">{option.description}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            
            <div className="p-4 bg-muted/30 rounded-lg">
              <p className="text-sm">
                <strong>Preview:</strong> {getSelectedResponseLength().description}
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* Constraints and Behaviors */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-primary" />
            <h3 className="text-lg font-semibold">Behavioral Constraints</h3>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={selectAllRecommended}>
              Select Recommended
            </Button>
            <Button variant="outline" size="sm" onClick={clearConstraints}>
              Clear All
            </Button>
          </div>
        </div>
        
        <p className="text-sm text-muted-foreground">
          These ensure your AI follows specific patterns and best practices for {selectedRole}s.
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {roleConstraints.map((constraint, index) => {
            const isSelected = (style.constraints || []).includes(constraint);
            const isRecommended = index < 3;
            
            return (
              <Card
                key={constraint}
                className={`cursor-pointer transition-all duration-200 ${
                  isSelected 
                    ? 'border-primary bg-primary/5' 
                    : 'hover:border-primary/30 border-border'
                }`}
                onClick={() => toggleConstraint(constraint)}
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center mt-0.5 transition-colors ${
                      isSelected 
                        ? 'border-primary bg-primary' 
                        : 'border-muted-foreground'
                    }`}>
                      {isSelected && (
                        <CheckCircle className="w-3 h-3 text-primary-foreground" />
                      )}
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-medium">{constraint}</p>
                        {isRecommended && (
                          <Badge className="bg-orange-500/10 text-orange-600 border-orange-500/30 text-xs">
                            Recommended
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Extracted Constraints from Files */}
      {extractedConstraints.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-success" />
            <h3 className="text-lg font-semibold">From Your Uploaded Files</h3>
            <Badge className="bg-success/10 text-success border-success/30">
              Auto-detected
            </Badge>
          </div>
          
          <Card className="border-success/30 bg-success/5">
            <CardContent className="p-4">
              <div className="space-y-2">
                <p className="text-sm font-medium text-success">
                  These constraints were automatically extracted from your uploaded files:
                </p>
                <div className="space-y-1">
                  {extractedConstraints.slice(0, 5).map((constraint, index) => (
                    <div key={index} className="flex items-center gap-2 text-sm">
                      <CheckCircle className="w-3 h-3 text-success flex-shrink-0" />
                      <span>{constraint}</span>
                    </div>
                  ))}
                  {extractedConstraints.length > 5 && (
                    <p className="text-sm text-muted-foreground">
                      + {extractedConstraints.length - 5} more constraints from your files
                    </p>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Selection Summary */}
      {(style.tone || style.responseLength || (style.constraints && style.constraints.length > 0)) && (
        <Card className="border-primary/30 bg-primary/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              {getRoleIcon()}
              Your AI Personality Summary
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {style.tone && (
              <div className="flex items-center gap-2">
                <MessageCircle className="w-4 h-4 text-primary" />
                <span className="text-sm">
                  <strong>Tone:</strong> {toneOptions.find(t => t.id === style.tone)?.label}
                </span>
              </div>
            )}
            
            {style.responseLength && (
              <div className="flex items-center gap-2">
                <Volume2 className="w-4 h-4 text-primary" />
                <span className="text-sm">
                  <strong>Response Length:</strong> {getSelectedResponseLength().label}
                </span>
              </div>
            )}
            
            {style.constraints && style.constraints.length > 0 && (
              <div className="flex items-start gap-2">
                <Zap className="w-4 h-4 text-primary mt-0.5" />
                <div className="text-sm">
                  <strong>Constraints:</strong> {style.constraints.length} behavioral rules
                </div>
              </div>
            )}
            
            {extractedConstraints.length > 0 && (
              <div className="flex items-start gap-2">
                <FileText className="w-4 h-4 text-success mt-0.5" />
                <div className="text-sm">
                  <strong>From Files:</strong> {extractedConstraints.length} auto-extracted requirements
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Help Text */}
      <div className="text-center space-y-2">
        <p className="text-sm text-muted-foreground">
          💡 These settings shape how your AI communicates. You can always adjust them later.
        </p>
        <p className="text-xs text-muted-foreground">
          Constraints from uploaded files are automatically applied and don't need to be selected.
        </p>
      </div>
    </div>
  );
}