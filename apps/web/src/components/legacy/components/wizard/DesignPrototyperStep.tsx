import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { DesignUpload } from '../ui/design-upload';
import { CheckCircle, Palette, Upload, ArrowRight, Sparkles, Figma, Image, FileText } from 'lucide-react';
import { AgentTemplate } from '../../types/agent-templates';

interface UploadedFile {
  id: string;
  name: string;
  size: number;
  type: string;
  status: 'uploading' | 'complete' | 'error';
  progress?: number;
  error?: string;
}

interface DesignPrototyperStepProps {
  template: AgentTemplate;
  onNext: () => void;
  onBack: () => void;
  onUpdate: (files: UploadedFile[]) => void;
}

export function DesignPrototyperStep({ template, onNext, onBack, onUpdate }: DesignPrototyperStepProps) {
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([]);
  const [currentStep, setCurrentStep] = useState<'intro' | 'upload' | 'complete'>('intro');

  const uploadConfig = template.config.specialFeatures?.uploadSupport;

  const handleFilesChange = (files: UploadedFile[]) => {
    setUploadedFiles(files);
    onUpdate(files);
  };

  const completedFiles = uploadedFiles.filter(f => f.status === 'complete');
  const hasFiles = completedFiles.length > 0;

  const handleContinue = () => {
    if (currentStep === 'intro') {
      setCurrentStep('upload');
    } else if (currentStep === 'upload') {
      setCurrentStep('complete');
    } else {
      onNext();
    }
  };

  const designCapabilities = [
    {
      icon: <Figma className="w-5 h-5" />,
      title: 'Figma Integration',
      description: 'Connect to your Figma workspace and sync designs automatically'
    },
    {
      icon: <Palette className="w-5 h-5" />,
      title: 'Design Systems',
      description: 'Generate and maintain consistent design tokens and components'
    },
    {
      icon: <Sparkles className="w-5 h-5" />,
      title: 'AI Prototyping',
      description: 'Convert sketches and ideas into interactive prototypes instantly'
    },
    {
      icon: <Image className="w-5 h-5" />,
      title: 'Visual Analysis',
      description: 'Analyze uploaded designs and provide improvement suggestions'
    }
  ];

  if (currentStep === 'intro') {
    return (
      <div className="space-y-8 animate-fadeIn">
        <div className="text-center">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Palette className="w-4 h-4" />
            Design Prototyper Setup
          </div>
          <h2 className="text-3xl font-bold text-foreground mb-4">
            Welcome to Your Design Assistant
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Your AI-powered design companion is ready to help with UI/UX design, prototyping, and design system management.
          </p>
        </div>

        {/* Template Overview */}
        <Card className="border-primary/20 bg-primary/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-3">
              <div className="text-2xl">{template.icon}</div>
              <div>
                <div className="text-xl">{template.name}</div>
                <Badge className="bg-primary text-white mt-1">Pre-configured Template</Badge>
              </div>
            </CardTitle>
            <CardDescription className="text-base mt-2">
              {template.description}
            </CardDescription>
          </CardHeader>
        </Card>

        {/* Capabilities Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {designCapabilities.map((capability, index) => (
            <Card key={index} className="hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center flex-shrink-0">
                    {capability.icon}
                  </div>
                  <div>
                    <h3 className="font-semibold mb-2">{capability.title}</h3>
                    <p className="text-sm text-muted-foreground">{capability.description}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Pre-configured MCPs */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-primary" />
              Pre-installed Tools & Integrations
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {template.config.requiredMcps.map((mcp, index) => (
                <div key={index} className="flex items-center gap-3 p-3 bg-primary/5 rounded-lg border border-primary/20">
                  <CheckCircle className="w-4 h-4 text-primary dark:text-green-400" />
                  <span className="font-medium text-foreground">
                    {mcp.replace('-mcp', '').replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </span>
                  <Badge variant="outline" className="ml-auto text-xs border-primary/30 text-primary">
                    Installed
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Next Steps */}
        <div className="flex justify-between pt-6">
          <Button variant="outline" onClick={onBack}>
            Back to Templates
          </Button>
          <Button onClick={handleContinue} className="bg-primary hover:bg-primary/90 text-white">
            Set Up Design Files
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      </div>
    );
  }

  if (currentStep === 'upload') {
    return (
      <div className="space-y-8 animate-fadeIn">
        <div className="text-center">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Upload className="w-4 h-4" />
            Upload Design Files
          </div>
          <h2 className="text-3xl font-bold text-foreground mb-4">
            Upload Your Design Assets
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Add your design files, inspiration images, brand guidelines, and documentation to get started.
          </p>
        </div>

        {/* Upload Instructions */}
        <Card className="border-primary/20 bg-primary/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="w-5 h-5" />
              What to Upload
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div className="space-y-2">
                <h5 className="font-medium">Design Files</h5>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• Figma files (.fig)</li>
                  <li>• Sketch files (.sketch)</li>
                  <li>• Adobe XD files</li>
                  <li>• PSD files</li>
                </ul>
              </div>
              <div className="space-y-2">
                <h5 className="font-medium">Inspiration & Assets</h5>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• Design inspiration (PNG, JPG)</li>
                  <li>• UI mockups</li>
                  <li>• Icon sets (SVG)</li>
                  <li>• Brand assets</li>
                </ul>
              </div>
              <div className="space-y-2">
                <h5 className="font-medium">Documentation</h5>
                <ul className="space-y-1 text-muted-foreground">
                  <li>• Brand guidelines (PDF)</li>
                  <li>• Design requirements</li>
                  <li>• Style guides</li>
                  <li>• User research</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Upload Component */}
        {uploadConfig && (
          <DesignUpload
            allowedTypes={uploadConfig.allowedTypes}
            maxFileSize={uploadConfig.maxFileSize}
            maxFiles={10}
            onFilesChange={handleFilesChange}
            description={uploadConfig.description}
          />
        )}

        {/* Continue Button */}
        <div className="flex justify-between pt-6">
          <Button variant="outline" onClick={() => setCurrentStep('intro')}>
            Back
          </Button>
          <Button 
            onClick={handleContinue} 
            className="bg-primary hover:bg-primary/90 text-white"
            disabled={!hasFiles}
          >
            {hasFiles ? 'Continue Setup' : 'Upload files to continue'}
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>

        {/* Optional note */}
        <Card className="border-border bg-muted/30">
          <CardContent className="p-4 text-center">
            <p className="text-sm text-muted-foreground">
              <strong>Note:</strong> You can skip this step and add files later. Your design assistant will be ready to help with or without uploaded files.
            </p>
            <Button 
              variant="ghost" 
              size="sm" 
              onClick={() => setCurrentStep('complete')}
              className="mt-2"
            >
              Skip for now
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Complete step
  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center">
        <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-6">
          <CheckCircle className="w-8 h-8 text-primary" />
        </div>
        <h2 className="text-3xl font-bold text-foreground mb-4">
          Design Assistant Ready!
        </h2>
        <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
          Your AI design prototyper is configured and ready to help with your creative projects.
        </p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Palette className="w-5 h-5" />
              Configuration Summary
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Template:</span>
              <span className="font-medium">{template.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Deployment:</span>
              <span className="font-medium">Local (Claude Desktop)</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Security:</span>
              <span className="font-medium">Local Only</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Files Uploaded:</span>
              <span className="font-medium">{completedFiles.length} files</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-primary" />
              Ready to Use
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-primary" />
                <span className="text-sm">Figma MCP configured</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-primary" />
                <span className="text-sm">File manager ready</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-primary" />
                <span className="text-sm">Upload support enabled</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-primary" />
                <span className="text-sm">Security configured</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Final Actions */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={() => setCurrentStep('upload')}>
          Back to Files
        </Button>
        <Button onClick={onNext} className="bg-primary hover:bg-primary/90 text-white">
          Complete Setup
          <CheckCircle className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}