
import { Shield, FileText, Database, User, Clock, Tag, ArrowRight, ArrowLeft } from 'lucide-react';
import { Button } from '../ui/button';
import { Checkbox } from '../ui/checkbox';

interface Step4Props {
  selectedConstraints: string[];
  onToggle: (value: string) => void;
  onNext: () => void;
  onPrev: () => void;
}

const constraints = [
  {
    id: 'citations',
    title: 'Source Citations',
    description: 'Always reference information sources and provide links when available',
    icon: <FileText className="w-6 h-6" />,
    impact: 'Increases response length by ~20-30 tokens',
    category: 'Quality'
  },
  {
    id: 'json',
    title: 'Structured Output',
    description: 'Return responses in JSON format for easy parsing and integration',
    icon: <Database className="w-6 h-6" />,
    impact: 'Adds formatting overhead but improves data structure',
    category: 'Format'
  },
  {
    id: 'token',
    title: 'Token Limits',
    description: 'Keep responses under 500 tokens to manage costs and latency',
    icon: <Clock className="w-6 h-6" />,
    impact: 'May require response truncation for complex queries',
    category: 'Performance'
  },
  {
    id: 'persona',
    title: 'Consistent Persona',
    description: 'Maintain character and voice throughout multi-turn conversations',
    icon: <User className="w-6 h-6" />,
    impact: 'Requires conversation context storage',
    category: 'Behavior'
  },
  {
    id: 'safety',
    title: 'Content Safety',
    description: 'Filter harmful, biased, or inappropriate content automatically',
    icon: <Shield className="w-6 h-6" />,
    impact: 'May refuse certain legitimate requests',
    category: 'Safety'
  },
  {
    id: 'branding',
    title: 'Brand Guidelines',
    description: 'Follow specific brand voice, terminology, and messaging guidelines',
    icon: <Tag className="w-6 h-6" />,
    impact: 'Requires brand guideline documentation',
    category: 'Branding'
  }
];

const categories = ['Quality', 'Format', 'Performance', 'Behavior', 'Safety', 'Branding'];

export function Step4Constraints({ selectedConstraints, onToggle, onNext, onPrev }: Step4Props) {
  const getConstraintsByCategory = (category: string) => 
    constraints.filter(c => c.category === category);

  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-foreground mb-4">
            Any special requirements?
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Add constraints and guidelines to ensure your AI behaves exactly as needed for your use case.
          </p>
        </div>

        {/* Constraints by Category */}
        <div className="space-y-8 mb-12">
          {categories.map((category) => {
            const categoryConstraints = getConstraintsByCategory(category);
            if (categoryConstraints.length === 0) return null;

            return (
              <div key={category} className="space-y-4">
                <h3 className="text-lg font-semibold text-foreground flex items-center">
                  <div className="w-2 h-2 bg-primary rounded-full mr-3"></div>
                  {category}
                </h3>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {categoryConstraints.map((constraint) => {
                    const isSelected = selectedConstraints.includes(constraint.id);
                    
                    return (
                      <div
                        key={constraint.id}
                        className={`
                          backdrop-blur-xl p-6 rounded-xl cursor-pointer transition-all duration-200 hover:border-primary/50
                          ${isSelected ? 'border-primary bg-primary/5' : 'border-border'}
                        `}
                        style={{
                          background: isSelected ? 'rgba(99, 102, 241, 0.05)' : 'rgba(24, 24, 27, 0.8)',
                          border: isSelected ? '1px solid rgba(99, 102, 241, 0.5)' : '1px solid rgba(255, 255, 255, 0.1)',
                          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
                        }}
                        onClick={() => onToggle(constraint.id)}
                      >
                        <div className="flex items-start space-x-4">
                          <Checkbox
                            checked={isSelected}
                            onChange={() => onToggle(constraint.id)}
                            className="mt-1"
                          />
                          
                          <div className={`
                            p-2 rounded-lg flex-shrink-0
                            ${isSelected ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground'}
                          `}>
                            {constraint.icon}
                          </div>
                          
                          <div className="min-w-0 flex-1">
                            <h4 className="font-semibold text-foreground mb-2">
                              {constraint.title}
                            </h4>
                            <p className="text-sm text-muted-foreground mb-3">
                              {constraint.description}
                            </p>
                            <div className="text-xs text-muted-foreground bg-muted/50 px-2 py-1 rounded">
                              Impact: {constraint.impact}
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        {/* Selected constraints summary */}
        {selectedConstraints.length > 0 && (
          <div className="backdrop-blur-xl p-6 rounded-xl mb-8 animate-fadeIn" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <h4 className="text-lg font-semibold text-foreground mb-4">
              Selected Constraints ({selectedConstraints.length})
            </h4>
            <div className="flex flex-wrap gap-2">
              {selectedConstraints.map((constraintId) => {
                const constraint = constraints.find(c => c.id === constraintId);
                if (!constraint) return null;
                
                return (
                  <div
                    key={constraintId}
                    className="flex items-center space-x-2 bg-primary/10 text-primary px-3 py-1.5 rounded-lg text-sm"
                  >
                    <div className="w-4 h-4">
                      {React.cloneElement(constraint.icon, { className: 'w-4 h-4' })}
                    </div>
                    <span>{constraint.title}</span>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Enterprise options */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h4 className="text-lg font-semibold text-foreground mb-4">
            Enterprise Features
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-success/20 text-success rounded-full flex items-center justify-center mx-auto mb-2">
                <Shield className="w-4 h-4" />
              </div>
              <div className="text-sm font-medium text-foreground">Audit Logging</div>
              <div className="text-xs text-muted-foreground mt-1">Track all interactions</div>
            </div>
            <div className="text-center p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-warning/20 text-warning rounded-full flex items-center justify-center mx-auto mb-2">
                <User className="w-4 h-4" />
              </div>
              <div className="text-sm font-medium text-foreground">Role-based Access</div>
              <div className="text-xs text-muted-foreground mt-1">Control permissions</div>
            </div>
            <div className="text-center p-4 bg-muted/30 rounded-lg">
              <div className="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center mx-auto mb-2">
                <Database className="w-4 h-4" />
              </div>
              <div className="text-sm font-medium text-foreground">Data Encryption</div>
              <div className="text-xs text-muted-foreground mt-1">End-to-end security</div>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex items-center justify-between">
          <Button onClick={onPrev} variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          
          <div className="text-sm text-muted-foreground">
            Step 4 of 5 • {selectedConstraints.length} constraint(s) selected
          </div>
          
          <Button onClick={onNext} className="shadow-lg" style={{
            boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)'
          }}>
            Generate Prompt
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    </div>
  );
}