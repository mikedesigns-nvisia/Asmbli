import React, { useState, useCallback } from 'react';
import { Button } from './button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './card';
import { Badge } from './badge';
import { Progress } from './progress';
import { Alert, AlertDescription } from './alert';
import { Upload, X, File, Image, CheckCircle, AlertCircle, Palette } from 'lucide-react';

interface UploadedFile {
  id: string;
  name: string;
  size: number;
  type: string;
  url?: string;
  status: 'uploading' | 'complete' | 'error';
  progress?: number;
  error?: string;
}

interface DesignUploadProps {
  allowedTypes: string[];
  maxFileSize: string;
  maxFiles?: number;
  onFilesChange: (files: UploadedFile[]) => void;
  description?: string;
  className?: string;
}

export function DesignUpload({
  allowedTypes,
  maxFileSize,
  maxFiles = 10,
  onFilesChange,
  description,
  className = ''
}: DesignUploadProps) {
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [dragActive, setDragActive] = useState(false);

  const maxSizeBytes = parseSize(maxFileSize);

  function parseSize(sizeStr: string): number {
    const units = { KB: 1024, MB: 1024 * 1024, GB: 1024 * 1024 * 1024 };
    const match = sizeStr.match(/^(\d+)(KB|MB|GB)$/i);
    if (!match) return 50 * 1024 * 1024; // Default 50MB
    const [, size, unit] = match;
    return parseInt(size) * units[unit.toUpperCase() as keyof typeof units];
  }

  function formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  const validateFile = (file: File): string | null => {
    const extension = '.' + file.name.split('.').pop()?.toLowerCase();
    if (!allowedTypes.includes(extension)) {
      return `File type ${extension} not allowed. Allowed types: ${allowedTypes.join(', ')}`;
    }
    if (file.size > maxSizeBytes) {
      return `File size exceeds ${maxFileSize} limit`;
    }
    return null;
  };

  const simulateUpload = (file: UploadedFile): Promise<void> => {
    return new Promise((resolve) => {
      let progress = 0;
      const interval = setInterval(() => {
        progress += Math.random() * 20;
        if (progress >= 100) {
          progress = 100;
          clearInterval(interval);
          setFiles(prev => prev.map(f => 
            f.id === file.id 
              ? { ...f, status: 'complete', progress: 100 }
              : f
          ));
          resolve();
        } else {
          setFiles(prev => prev.map(f => 
            f.id === file.id 
              ? { ...f, progress }
              : f
          ));
        }
      }, 200);
    });
  };

  const handleFiles = useCallback(async (fileList: FileList) => {
    const newFiles: UploadedFile[] = [];
    
    for (let i = 0; i < fileList.length && files.length + newFiles.length < maxFiles; i++) {
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
    onFilesChange(updatedFiles);
    
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
  }, [files, maxFiles, onFilesChange]);

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
    const updatedFiles = files.filter(f => f.id !== id);
    setFiles(updatedFiles);
    onFilesChange(updatedFiles);
  };

  const getFileIcon = (file: UploadedFile) => {
    const ext = file.name.split('.').pop()?.toLowerCase();
    const imageExts = ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp'];
    const designExts = ['fig', 'sketch', 'xd', 'psd'];
    
    if (imageExts.includes(ext || '')) {
      return <Image className="w-4 h-4" />;
    } else if (designExts.includes(ext || '')) {
      return <Palette className="w-4 h-4" />;
    }
    return <File className="w-4 h-4" />;
  };

  return (
    <div className={`space-y-4 ${className}`}>
      {/* Upload Area */}
      <Card 
        className={`border-2 border-dashed transition-colors cursor-pointer ${
          dragActive 
            ? 'border-primary bg-primary/5' 
            : 'border-muted-foreground/25 hover:border-primary/50'
        }`}
        onDragEnter={handleDragIn}
        onDragLeave={handleDragOut}
        onDragOver={handleDrag}
        onDrop={handleDrop}
        onClick={() => document.getElementById('file-upload')?.click()}
      >
        <CardContent className="p-8 text-center">
          <Upload className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
          <CardTitle className="text-lg mb-2">
            Drop design files here or click to browse
          </CardTitle>
          <CardDescription className="mb-4">
            {description || `Upload your design files, inspiration, and documentation`}
          </CardDescription>
          <div className="space-y-2 text-sm text-muted-foreground">
            <p>Supported formats: {allowedTypes.join(', ')}</p>
            <p>Maximum file size: {maxFileSize}</p>
            <p>Maximum files: {maxFiles}</p>
          </div>
          <Button variant="outline" className="mt-4">
            Choose Files
          </Button>
          <input
            id="file-upload"
            type="file"
            multiple
            accept={allowedTypes.join(',')}
            onChange={(e) => e.target.files && handleFiles(e.target.files)}
            className="hidden"
          />
        </CardContent>
      </Card>

      {/* Upload Progress and File List */}
      {files.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Upload className="w-4 h-4" />
              Uploaded Files ({files.length}/{maxFiles})
            </CardTitle>
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
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      )}
                      {file.status === 'error' && (
                        <AlertCircle className="w-4 h-4 text-red-500" />
                      )}
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => removeFile(file.id)}
                        className="h-6 w-6 p-0"
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
                      {file.status === 'uploading' ? 'Uploading...' : 
                       file.status === 'complete' ? 'Complete' : 'Error'}
                    </Badge>
                  </div>
                  
                  {file.status === 'uploading' && (
                    <Progress value={file.progress || 0} className="h-1" />
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
    </div>
  );
}