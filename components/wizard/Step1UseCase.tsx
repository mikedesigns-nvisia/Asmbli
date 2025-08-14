import React from 'react';
import { MessageSquare, PenTool, BarChart3, Code, ArrowRight } from 'lucide-react';
import { Button } from '../ui/button';

interface Step1Props {
  selectedUseCase: string | null;
  onSelect: (value: string) => void;
  onNext: () => void;
}

const useCases = [
  {
    id: 'chatbot',
    title: 'Conversational AI',
    description: 'Interactive chatbots and virtual assistants',
    icon: <MessageSquare className="w-8 h-8" />,
    features: ['Multi-turn conversations', 'Context awareness', 'Natural responses'],
    gradient: 'from-blue-500/10 to-cyan-500/10'
  },
  {
    id: 'content',
    title: 'Content Generator',
    description: 'Create articles, emails, and marketing copy',
    icon: <PenTool className="w-8 h-8" />,
    features: ['SEO optimization', 'Brand voice', 'Multiple formats'],
    gradient: 'from-purple-500/10 to-pink-500/10'
  },
  {
    id: 'analyzer',
    title: 'Data Analyzer',
    description: 'Extract insights and analyze information',
    icon: <BarChart3 className="w-8 h-8" />,
    features: ['Pattern detection', 'Trend analysis', 'Report generation'],
    gradient: 'from-green-500/10 to-emerald-500/10'
  },
  {
    id: 'coder',
    title: 'Code Assistant',
    description: 'Programming help and code generation',
    icon: <Code className="w-8 h-8" />,
    features: ['Code review', 'Bug fixing', 'Documentation'],
    gradient: 'from-orange-500/10 to-red-500/10'
  }
];

export function Step1UseCase({ selectedUseCase, onSelect, onNext }: Step1Props) {
  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-foreground mb-4">
            What are you building?
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Choose your AI's primary purpose to get the most optimized prompt structure and recommendations.
          </p>
        </div>

        {/* Use case grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
          {useCases.map((useCase) => (
            <div
              key={useCase.id}
              className={`
                selection-card cursor-pointer group relative overflow-hidden
                ${selectedUseCase === useCase.id ? 'selected border-primary' : 'border-border'}
              `}
              onClick={() => onSelect(useCase.id)}
            >
              <div className={`absolute inset-0 bg-gradient-to-br ${useCase.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-300`} />
              
              <div className="relative p-6">
                <div className="flex items-start space-x-4">
                  <div className={`
                    p-3 rounded-xl transition-colors duration-200
                    ${selectedUseCase === useCase.id 
                      ? 'bg-primary text-primary-foreground' 
                      : 'bg-muted text-muted-foreground group-hover:bg-primary group-hover:text-primary-foreground'}
                  `}>
                    {useCase.icon}
                  </div>
                  
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold text-foreground mb-2">
                      {useCase.title}
                    </h3>
                    <p className="text-muted-foreground mb-4">
                      {useCase.description}
                    </p>
                    
                    <ul className="space-y-2">
                      {useCase.features.map((feature, index) => (
                        <li key={index} className="flex items-center text-sm text-muted-foreground">
                          <div className="w-1.5 h-1.5 bg-primary rounded-full mr-3 flex-shrink-0" />
                          {feature}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
                
                {selectedUseCase === useCase.id && (
                  <div className="absolute top-4 right-4 w-6 h-6 bg-primary rounded-full flex items-center justify-center animate-fadeIn">
                    <div className="w-2 h-2 bg-primary-foreground rounded-full" />
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Additional options */}
        <div className="backdrop-blur-xl p-6 rounded-xl mb-8" style={{
          background: 'rgba(24, 24, 27, 0.8)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}>
          <h4 className="text-lg font-semibold text-foreground mb-4">
            Need something custom?
          </h4>
          <p className="text-muted-foreground mb-4">
            These templates provide optimized starting points, but you can customize everything in the following steps.
          </p>
          <div className="flex items-center space-x-4">
            <Button variant="outline" size="sm">
              Import Template
            </Button>
            <Button variant="ghost" size="sm">
              Start from Scratch
            </Button>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex items-center justify-between">
          <div className="text-sm text-muted-foreground">
            Step 1 of 5
          </div>
          
          <Button 
            onClick={onNext}
            disabled={!selectedUseCase}
            className="shadow-lg"
            style={{
              boxShadow: selectedUseCase ? '0 4px 12px rgba(99, 102, 241, 0.3)' : 'none'
            }}
          >
            Continue
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    </div>
  );
}