
import { Briefcase, Heart, Wrench, Palette, ArrowRight, ArrowLeft } from 'lucide-react';
import { Button } from '../ui/button';
import { Slider } from '../ui/slider';

interface Step3Props {
  selectedTone: string | null;
  responseLength: number;
  onToneSelect: (value: string) => void;
  onLengthChange: (value: number[]) => void;
  onNext: () => void;
  onPrev: () => void;
}

const tones = [
  {
    id: 'professional',
    title: 'Professional',
    description: 'Formal, business-appropriate communication',
    icon: <Briefcase className="w-8 h-8" />,
    example: 'I can assist you with that request. Let me provide a comprehensive analysis...',
    color: 'from-slate-500 to-slate-600'
  },
  {
    id: 'friendly',
    title: 'Friendly',
    description: 'Warm, conversational, and approachable',
    icon: <Heart className="w-8 h-8" />,
    example: 'Hey there! I\'d be happy to help you with that. Let me break it down...',
    color: 'from-pink-500 to-pink-600'
  },
  {
    id: 'technical',
    title: 'Technical',
    description: 'Precise, detailed, and methodical',
    icon: <Wrench className="w-8 h-8" />,
    example: 'Executing analysis protocol. Parameters: validated. Output format: JSON...',
    color: 'from-blue-500 to-blue-600'
  },
  {
    id: 'creative',
    title: 'Creative',
    description: 'Playful, imaginative, and inspiring',
    icon: <Palette className="w-8 h-8" />,
    example: 'Ooh, interesting challenge! Let me paint you a picture of possibilities...',
    color: 'from-purple-500 to-purple-600'
  }
];

const lengthLabels = {
  1: 'Very Concise',
  2: 'Concise',
  3: 'Balanced',
  4: 'Detailed',
  5: 'Very Detailed'
};

export function Step3Communication({ 
  selectedTone, 
  responseLength, 
  onToneSelect, 
  onLengthChange, 
  onNext, 
  onPrev 
}: Step3Props) {
  return (
    <div className="p-8 animate-fadeIn">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-foreground mb-4">
            How should it communicate?
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Define your AI's personality and communication style to match your brand and audience.
          </p>
        </div>

        {/* Tone Selection */}
        <div className="mb-12">
          <h3 className="text-xl font-semibold text-foreground mb-6">Communication Tone</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {tones.map((tone) => {
              const isSelected = selectedTone === tone.id;
              
              return (
                <div
                  key={tone.id}
                  className={`
                    selection-card cursor-pointer group relative overflow-hidden
                    ${isSelected ? 'selected border-primary' : 'border-border'}
                  `}
                  onClick={() => onToneSelect(tone.id)}
                >
                  <div className="relative p-6">
                    <div className="flex items-start space-x-4 mb-4">
                      <div className={`
                        p-3 rounded-xl transition-all duration-200
                        ${isSelected 
                          ? `bg-gradient-to-br ${tone.color} text-white` 
                          : 'bg-muted text-muted-foreground group-hover:bg-primary group-hover:text-primary-foreground'}
                      `}>
                        {tone.icon}
                      </div>
                      
                      <div className="flex-1">
                        <h4 className="text-lg font-semibold text-foreground mb-2">
                          {tone.title}
                        </h4>
                        <p className="text-muted-foreground">
                          {tone.description}
                        </p>
                      </div>
                      
                      {isSelected && (
                        <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center animate-fadeIn">
                          <div className="w-2 h-2 bg-primary-foreground rounded-full" />
                        </div>
                      )}
                    </div>
                    
                    <div className="backdrop-blur-xl p-4 rounded-lg" style={{
                      background: 'rgba(24, 24, 27, 0.8)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                      boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
                    }}>
                      <div className="text-xs text-muted-foreground mb-2">Example response:</div>
                      <p className="text-sm text-foreground italic">"{tone.example}"</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Response Length */}
        <div className="mb-12">
          <h3 className="text-xl font-semibold text-foreground mb-6">Response Length</h3>
          <div className="backdrop-blur-xl p-8 rounded-xl" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="flex items-center justify-between mb-6">
              <span className="text-sm text-muted-foreground">Concise</span>
              <span className="text-lg font-semibold text-primary">
                {lengthLabels[responseLength as keyof typeof lengthLabels]}
              </span>
              <span className="text-sm text-muted-foreground">Detailed</span>
            </div>
            
            <Slider
              value={[responseLength]}
              onValueChange={onLengthChange}
              max={5}
              min={1}
              step={1}
              className="mb-6"
            />
            
            <div className="grid grid-cols-5 gap-2 text-xs text-muted-foreground">
              {Object.entries(lengthLabels).map(([value, label]) => (
                <div 
                  key={value}
                  className={`text-center ${responseLength === parseInt(value) ? 'text-primary font-medium' : ''}`}
                >
                  {label}
                </div>
              ))}
            </div>
            
            <div className="mt-6 p-4 bg-muted/50 rounded-lg">
              <div className="text-xs text-muted-foreground mb-2">
                Impact on responses:
              </div>
              <div className="text-sm text-foreground">
                {responseLength <= 2 && "Responses will be brief and to-the-point, focusing on essential information only."}
                {responseLength === 3 && "Responses will provide adequate detail while remaining focused and readable."}
                {responseLength >= 4 && "Responses will be comprehensive with examples, context, and thorough explanations."}
              </div>
            </div>
          </div>
        </div>

        {/* Preview */}
        {selectedTone && (
          <div className="backdrop-blur-xl p-6 rounded-xl mb-8 animate-fadeIn" style={{
            background: 'rgba(24, 24, 27, 0.8)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <h4 className="text-lg font-semibold text-foreground mb-4">
              Communication Preview
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div className="text-sm font-medium text-foreground mb-2">Selected Style</div>
                <div className="flex items-center space-x-3">
                  <div className={`w-8 h-8 rounded-lg bg-gradient-to-br ${tones.find(t => t.id === selectedTone)?.color} flex items-center justify-center text-white`}>
                    {React.cloneElement(tones.find(t => t.id === selectedTone)!.icon, { className: 'w-4 h-4' })}
                  </div>
                  <div>
                    <div className="font-medium text-foreground">{tones.find(t => t.id === selectedTone)?.title}</div>
                    <div className="text-sm text-muted-foreground">{lengthLabels[responseLength as keyof typeof lengthLabels]}</div>
                  </div>
                </div>
              </div>
              <div>
                <div className="text-sm font-medium text-foreground mb-2">Token Estimate</div>
                <div className="text-2xl font-bold text-primary">
                  {responseLength <= 2 ? '50-150' : responseLength === 3 ? '150-300' : '300-500'}
                </div>
                <div className="text-xs text-muted-foreground">tokens per response</div>
              </div>
            </div>
          </div>
        )}

        {/* Navigation */}
        <div className="flex items-center justify-between">
          <Button onClick={onPrev} variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          
          <div className="text-sm text-muted-foreground">
            Step 3 of 5
          </div>
          
          <Button 
            onClick={onNext}
            disabled={!selectedTone}
            className="shadow-lg"
            style={{
              boxShadow: selectedTone ? '0 4px 12px rgba(99, 102, 241, 0.3)' : 'none'
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