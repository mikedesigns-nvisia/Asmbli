import { useState, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Progress } from '../ui/progress';
import { Alert, AlertDescription } from '../ui/alert';
import { Upload, FileText, FileCode, CheckCircle, X, AlertCircle, Brain, Sparkles, File } from 'lucide-react';

interface UploadedFile {
  id: string;
  name: string;
  size: number;
  type: string;
  status: 'uploading' | 'complete' | 'error';
  progress?: number;
  error?: string;
  extractedConstraints?: string[];
}

interface MVPStep3UploadProps {
  extractedConstraints: string[];
  selectedRole?: string;
  onFilesChange: (files: File[], constraints: string[]) => void;
}

const SUPPORTED_FILE_TYPES = ['.pdf', '.md', '.txt', '.docx', '.json', '.js', '.ts', '.yml', '.yaml', '.eslintrc'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_FILES = 5;


// Role-specific requirement types
const ROLE_REQUIREMENT_TYPES = {
  developer: [
    {
      id: 'code-standards',
      name: 'Code Quality Standards',
      description: 'Coding standards, style guides, linting rules',
      fileTypes: ['.eslintrc', '.prettierrc', '.js', '.ts', '.json'],
      examples: ['ESLint config', 'TypeScript standards', 'Code review guidelines']
    },
    {
      id: 'architecture',
      name: 'Architecture Patterns',
      description: 'System design patterns, architectural decisions',
      fileTypes: ['.md', '.txt', '.pdf'],
      examples: ['System architecture docs', 'Design patterns guide', 'Technical specifications']
    },
    {
      id: 'security',
      name: 'Security Best Practices',
      description: 'Security policies, vulnerability guidelines',
      fileTypes: ['.md', '.pdf', '.txt'],
      examples: ['Security policy', 'OWASP guidelines', 'Vulnerability checklist']
    }
  ],
  creator: [
    {
      id: 'brand-guidelines',
      name: 'Brand Guidelines',
      description: 'Brand style guide, visual identity, tone of voice',
      fileTypes: ['.pdf', '.docx', '.md'],
      examples: ['Brand style guide', 'Logo usage guidelines', 'Color palette specs']
    },
    {
      id: 'content-style',
      name: 'Content Style',
      description: 'Writing style, editorial guidelines, content standards',
      fileTypes: ['.pdf', '.docx', '.md', '.txt'],
      examples: ['Writing style guide', 'Editorial standards', 'Content templates']
    },
    {
      id: 'accessibility',
      name: 'Accessibility Requirements',
      description: 'WCAG compliance, inclusive design standards',
      fileTypes: ['.pdf', '.md', '.txt'],
      examples: ['WCAG compliance guide', 'Accessibility checklist', 'Screen reader guidelines']
    }
  ],
  researcher: [
    {
      id: 'methodology',
      name: 'Research Methodology',
      description: 'Research protocols, methodology standards',
      fileTypes: ['.pdf', '.docx', '.md'],
      examples: ['Research protocol', 'Methodology guidelines', 'Study design standards']
    },
    {
      id: 'citation-styles',
      name: 'Citation Styles',
      description: 'Citation formats, bibliography standards',
      fileTypes: ['.pdf', '.txt', '.md'],
      examples: ['APA style guide', 'Citation format rules', 'Bibliography standards']
    },
    {
      id: 'irb-requirements',
      name: 'IRB Requirements',
      description: 'Institutional review board policies, ethics guidelines',
      fileTypes: ['.pdf', '.docx', '.txt'],
      examples: ['IRB policies', 'Ethics guidelines', 'Human subjects protocols']
    }
  ]
};

export function MVPStep3Upload({ extractedConstraints, selectedRole, onFilesChange }: MVPStep3UploadProps) {
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [dragActive, setDragActive] = useState(false);
  const [allExtractedConstraints, setAllExtractedConstraints] = useState<string[]>(extractedConstraints);
  const [selectedRequirementTypes, setSelectedRequirementTypes] = useState<string[]>([]);
  
  // Get role-specific requirement types
  const roleRequirements = selectedRole ? ROLE_REQUIREMENT_TYPES[selectedRole as keyof typeof ROLE_REQUIREMENT_TYPES] || [] : [];


  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  const validateFile = (file: File): string | null => {
    const extension = '.' + file.name.split('.').pop()?.toLowerCase();
    if (!SUPPORTED_FILE_TYPES.some(type => extension === type || file.name.toLowerCase().includes(type.replace('.', '')))) {
      return `File type ${extension} not supported. Supported: ${SUPPORTED_FILE_TYPES.join(', ')}`;
    }
    if (file.size > MAX_FILE_SIZE) {
      return `File size exceeds 10MB limit`;
    }
    return null;
  };

  const extractConstraintsFromFile = (file: File): string[] => {
    const fileName = file.name.toLowerCase();
    const extension = '.' + fileName.split('.').pop();
    
    // Mock constraint extraction based on file type and name
    if (fileName.includes('eslint') || fileName.includes('prettier')) {
      return [
        "Use consistent code formatting and linting rules",
        "Enforce specific JavaScript/TypeScript style guidelines"
      ];
    } else if (fileName.includes('brand') || fileName.includes('style')) {
      return [
        "Maintain consistent brand voice and tone",
        "Follow established design system guidelines"
      ];
    } else if (fileName.includes('api') || extension === '.json') {
      return [
        "Follow API response format specifications",
        "Use consistent data structure patterns"
      ];
    } else if (fileName.includes('research') || fileName.includes('methodology')) {
      return [
        "Adhere to established research methodology", 
        "Maintain academic writing standards"
      ];
    } else if (extension === '.pdf' || extension === '.md') {
      return [
        "Follow document formatting standards",
        "Maintain professional writing tone"
      ];
    }
    
    return ["Extract and follow patterns from uploaded documentation"];
  };

  const simulateUpload = async (file: UploadedFile): Promise<void> => {
    return new Promise((resolve) => {
      let progress = 0;
      const interval = setInterval(() => {
        progress += Math.random() * 30;
        if (progress >= 100) {
          progress = 100;
          clearInterval(interval);
          
          // Extract constraints when upload completes
          const originalFile = new File([''], file.name);
          const constraints = extractConstraintsFromFile(originalFile);
          
          setFiles(prev => prev.map(f => 
            f.id === file.id 
              ? { ...f, status: 'complete', progress: 100, extractedConstraints: constraints }
              : f
          ));
          
          // Update parent component with new constraints
          const newConstraints = [...allExtractedConstraints, ...constraints];
          setAllExtractedConstraints(newConstraints);
          
          // Convert UploadedFile back to File for parent component
          const fileList = files.filter(f => f.status === 'complete').map(f => new File([''], f.name));
          onFilesChange(fileList, newConstraints);
          
          resolve();
        } else {
          setFiles(prev => prev.map(f => 
            f.id === file.id 
              ? { ...f, progress }
              : f
          ));
        }
      }, 150);
    });
  };

  const handleFiles = useCallback(async (fileList: FileList) => {
    const newFiles: UploadedFile[] = [];
    
    for (let i = 0; i < fileList.length && files.length + newFiles.length < MAX_FILES; i++) {
      const file = fileList[i];
      const error = validateFile(file);
      
      const uploadedFile: UploadedFile = {
        id: `${Date.now()}-${i}`,
        name: file.name,
        size: file.size,
        type: file.type,
        status: error ? 'error' : 'uploading',
        progress: 0,
        error: error || undefined
      };
      
      newFiles.push(uploadedFile);
    }
    
    const updatedFiles = [...files, ...newFiles];
    setFiles(updatedFiles);
    
    // Simulate upload for valid files
    for (const file of newFiles) {
      if (file.status === 'uploading') {
        try {
          await simulateUpload(file);
        } catch (error) {
          setFiles(prev => prev.map(f => 
            f.id === file.id 
              ? { ...f, status: 'error', error: 'Upload failed' }
              : f
          ));
        }
      }
    }
  }, [files, allExtractedConstraints, onFilesChange]);

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  const handleDragIn = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.dataTransfer.items && e.dataTransfer.items.length > 0) {
      setDragActive(true);
    }
  }, []);

  const handleDragOut = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFiles(e.dataTransfer.files);
    }
  }, [handleFiles]);

  const removeFile = (id: string) => {
    const fileToRemove = files.find(f => f.id === id);
    const updatedFiles = files.filter(f => f.id !== id);
    setFiles(updatedFiles);
    
    // Remove constraints from this file
    if (fileToRemove?.extractedConstraints) {
      const remainingConstraints = allExtractedConstraints.filter(constraint => 
        !fileToRemove.extractedConstraints!.includes(constraint)
      );
      setAllExtractedConstraints(remainingConstraints);
      
      // Update parent
      const fileList = updatedFiles.filter(f => f.status === 'complete').map(f => new File([''], f.name));
      onFilesChange(fileList, remainingConstraints);
    }
  };

  const getFileIcon = (file: UploadedFile) => {
    const ext = file.name.split('.').pop()?.toLowerCase() || '';
    const codeExts = ['json', 'js', 'ts', 'yml', 'yaml'];
    
    if (codeExts.includes(ext || '') || file.name.includes('eslint')) {
      return <FileCode className="w-4 h-4" />;
    }
    return <FileText className="w-4 h-4" />;
  };

  const completedFiles = files.filter(f => f.status === 'complete');
  const totalExtractedConstraints = completedFiles.reduce((total, file) => 
    total + (file.extractedConstraints?.length || 0), 0
  );

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <p className="text-muted-foreground">
          Upload documents, config files, or specifications so your AI agent knows your exact requirements.
        </p>
        <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30">
          Optional but Powerful
        </Badge>
      </div>

      {/* Role-Specific Requirements Selector */}
      {selectedRole && roleRequirements.length > 0 && (
        <Card className="p-6 bg-gradient-to-r from-primary/5 to-secondary/5 border-primary/20">
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-primary" />
              <h3 className="text-lg font-medium">What type of requirements do you have?</h3>
            </div>
            <p className="text-sm text-muted-foreground">
              Select the types of requirements you want to upload. This helps us better understand and extract the right information.
            </p>
            
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
              {roleRequirements.map((reqType) => {
                const isSelected = selectedRequirementTypes.includes(reqType.id);
                return (
                  <div
                    key={reqType.id}
                    className={`p-4 border rounded-lg cursor-pointer transition-all ${
                      isSelected 
                        ? 'border-primary bg-primary/10 shadow-md' 
                        : 'border-muted hover:border-primary/50 hover:bg-muted/50'
                    }`}
                    onClick={() => {
                      setSelectedRequirementTypes(prev => 
                        isSelected 
                          ? prev.filter(id => id !== reqType.id)
                          : [...prev, reqType.id]
                      );
                    }}
                  >
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <h4 className="font-medium text-sm">{reqType.name}</h4>
                        {isSelected && <CheckCircle className="w-4 h-4 text-primary" />}
                      </div>
                      <p className="text-xs text-muted-foreground">{reqType.description}</p>
                      <div className="flex flex-wrap gap-1">
                        {reqType.fileTypes.slice(0, 3).map(type => (
                          <Badge key={type} variant="outline" className="text-xs py-0">
                            {type}
                          </Badge>
                        ))}
                        {reqType.fileTypes.length > 3 && (
                          <Badge variant="outline" className="text-xs py-0">
                            +{reqType.fileTypes.length - 3}
                          </Badge>
                        )}
                      </div>
                      <div className="text-xs text-muted-foreground">
                        <strong>Examples:</strong> {reqType.examples.slice(0, 2).join(', ')}
                        {reqType.examples.length > 2 && '...'}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </Card>
      )}

      {/* Upload Area */}
      <Card 
        className={`border-2 border-dashed transition-all duration-300 cursor-pointer ${
          dragActive 
            ? 'border-primary bg-primary/5 shadow-lg scale-[1.02]' 
            : 'border-muted-foreground/30 hover:border-primary/50'
        }`}
        onDragEnter={handleDragIn}
        onDragLeave={handleDragOut}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => document.getElementById('file-upload')?.click()}
      >
        <CardContent className="py-12">
          <div className="text-center space-y-4">
            <div className={`w-16 h-16 mx-auto rounded-full flex items-center justify-center transition-colors ${
              dragActive ? 'bg-primary/20' : 'bg-muted/50'
            }`}>
              <Upload className={`w-8 h-8 ${
                dragActive ? 'text-primary' : 'text-muted-foreground'
              }`} />
            </div>
            
            <div className="space-y-2">
              <h3 className="text-lg font-semibold">
                {dragActive ? 'Drop files here' : 'Drag & drop your requirements'}
              </h3>
              
              {/* Show selected requirement types */}
              {selectedRequirementTypes.length > 0 && (
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">
                    Perfect for: <strong>{selectedRequirementTypes.map(id => 
                      roleRequirements.find(req => req.id === id)?.name
                    ).join(', ')}</strong>
                  </p>
                  <div className="flex flex-wrap gap-1 justify-center">
                    {selectedRequirementTypes.flatMap(id => {
                      const reqType = roleRequirements.find(req => req.id === id);
                      return reqType?.fileTypes.slice(0, 2).map(type => (
                        <Badge key={`${id}-${type}`} variant="outline" className="text-xs">
                          {type}
                        </Badge>
                      )) || [];
                    })}
                  </div>
                </div>
              )}
              <p className="text-muted-foreground">
                or{' '}
                <label className="text-primary hover:underline cursor-pointer">
                  browse your files
                  <input
                    id="file-upload"
                    type="file"
                    multiple
                    accept={SUPPORTED_FILE_TYPES.join(',')}
                    onChange={(e) => e.target.files && handleFiles(e.target.files)}
                    className="hidden"
                  />
                </label>
              </p>
            </div>
            
            <div className="space-y-2 text-sm text-muted-foreground">
              <p>Supported: {SUPPORTED_FILE_TYPES.slice(0, 5).join(', ')}, and more</p>
              <p>Maximum: {MAX_FILES} files, 10MB each</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* File List */}
      {files.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Upload className="w-4 h-4" />
              Files ({files.length}/{MAX_FILES})
            </CardTitle>
            {completedFiles.length > 0 && (
              <CardDescription>
                <Brain className="w-4 h-4 inline mr-1" />
                {totalExtractedConstraints} requirements extracted
              </CardDescription>
            )}
          </CardHeader>
          <CardContent className="space-y-3">
            {files.map((file) => (
              <div key={file.id} className="flex items-center gap-3 p-3 bg-muted/30 rounded-lg">
                <div className="flex-shrink-0">
                  {getFileIcon(file)}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <p className="text-sm font-medium truncate">{file.name}</p>
                    <div className="flex items-center gap-2">
                      {file.status === 'complete' && (
                        <CheckCircle className="w-4 h-4 text-success" />
                      )}
                      {file.status === 'error' && (
                        <AlertCircle className="w-4 h-4 text-destructive" />
                      )}
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => removeFile(file.id)}
                        className="h-6 w-6 p-0 hover:bg-destructive/10 hover:text-destructive"
                      >
                        <X className="w-3 h-3" />
                      </Button>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between text-xs text-muted-foreground mb-2">
                    <span>{formatFileSize(file.size)}</span>
                    <Badge 
                      variant={
                        file.status === 'complete' ? 'default' :
                        file.status === 'error' ? 'destructive' : 'secondary'
                      }
                      className="text-xs"
                    >
                      {file.status === 'uploading' ? 'Processing...' : 
                       file.status === 'complete' ? 'Complete' : 'Error'}
                    </Badge>
                  </div>
                  
                  {file.status === 'uploading' && (
                    <div className="space-y-1">
                      <Progress value={file.progress || 0} className="h-1" />
                      <p className="text-xs text-muted-foreground">Analyzing file and extracting requirements...</p>
                    </div>
                  )}
                  
                  {file.status === 'complete' && file.extractedConstraints && (
                    <div className="mt-2 space-y-1">
                      <p className="text-xs font-medium text-success flex items-center gap-1">
                        <Sparkles className="w-3 h-3" />
                        {file.extractedConstraints.length} requirements found
                      </p>
                      <div className="text-xs text-muted-foreground">
                        {file.extractedConstraints.slice(0, 2).map((constraint, index) => (
                          <div key={index} className="truncate">• {constraint}</div>
                        ))}
                        {file.extractedConstraints.length > 2 && (
                          <div>+ {file.extractedConstraints.length - 2} more</div>
                        )}
                      </div>
                    </div>
                  )}
                  
                  {file.status === 'error' && file.error && (
                    <Alert className="mt-2">
                      <AlertCircle className="h-4 w-4" />
                      <AlertDescription className="text-xs">
                        {file.error}
                      </AlertDescription>
                    </Alert>
                  )}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Extracted Constraints Summary */}
      {completedFiles.length > 0 && totalExtractedConstraints > 0 && (
        <Card className="border-success/30 bg-success/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-success" />
              All Extracted Requirements ({totalExtractedConstraints})
            </CardTitle>
            <CardDescription>
              Your AI agent will follow these patterns and constraints automatically.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-40 overflow-y-auto">
              {completedFiles.flatMap(file => file.extractedConstraints || []).slice(0, 8).map((constraint, index) => (
                <div key={index} className="flex items-start gap-2 p-2 bg-background rounded text-sm">
                  <CheckCircle className="w-4 h-4 text-success mt-0.5 flex-shrink-0" />
                  <span>{constraint}</span>
                </div>
              ))}
              {totalExtractedConstraints > 8 && (
                <p className="text-sm text-muted-foreground text-center">
                  + {totalExtractedConstraints - 8} more requirements
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Example Files Helper */}
      {files.length === 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="border-muted/50">
            <CardHeader className="pb-3">
              <CardTitle className="flex items-center gap-2 text-base">
                <FileText className="w-5 h-5 text-muted-foreground" />
                Documents
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="text-sm space-y-1">
                <div className="text-muted-foreground">• Style guides (.pdf, .md)</div>
                <div className="text-muted-foreground">• Brand guidelines (.docx)</div>
                <div className="text-muted-foreground">• Research protocols (.pdf)</div>
              </div>
            </CardContent>
          </Card>
          
          <Card className="border-muted/50">
            <CardHeader className="pb-3">
              <CardTitle className="flex items-center gap-2 text-base">
                <FileCode className="w-5 h-5 text-muted-foreground" />
                Config Files
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="text-sm space-y-1">
                <div className="text-muted-foreground">• .eslintrc.json</div>
                <div className="text-muted-foreground">• tsconfig.json</div>
                <div className="text-muted-foreground">• API schemas (.json)</div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Help Text */}
      <div className="text-center space-y-2">
        <p className="text-sm text-muted-foreground">
          💡 Upload your coding standards, brand guidelines, or research protocols for best results.
        </p>
        <p className="text-xs text-muted-foreground">
          Files are processed locally and securely to extract patterns and requirements.
        </p>
      </div>
    </div>
  );
}