'use client'

import { useState, useRef } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { 
  ArrowLeft, 
  Upload, 
  FileText, 
  File, 
  Image, 
  Code, 
  Database,
  Link as LinkIcon,
  X, 
  CheckCircle,
  AlertCircle,
  Loader2,
  FolderOpen,
  Globe,
  Download
} from 'lucide-react'
import { Navigation } from '@/components/Navigation'

interface UploadedFile {
  id: string
  name: string
  size: number
  type: string
  status: 'uploading' | 'processing' | 'completed' | 'error'
  progress: number
  url?: string
}

export default function UploadPage() {
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([])
  const [isDragging, setIsDragging] = useState(false)
  const [webUrl, setWebUrl] = useState('')
  const [isProcessingUrl, setIsProcessingUrl] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileUpload = (files: FileList | null) => {
    if (!files) return

    const newFiles: UploadedFile[] = Array.from(files).map(file => ({
      id: Math.random().toString(36).substr(2, 9),
      name: file.name,
      size: file.size,
      type: file.type,
      status: 'uploading',
      progress: 0
    }))

    setUploadedFiles(prev => [...prev, ...newFiles])

    // Simulate upload process
    newFiles.forEach(file => {
      simulateUpload(file.id)
    })
  }

  const simulateUpload = (fileId: string) => {
    const interval = setInterval(() => {
      setUploadedFiles(prev => prev.map(file => {
        if (file.id === fileId) {
          const newProgress = file.progress + Math.random() * 20
          if (newProgress >= 100) {
            clearInterval(interval)
            return {
              ...file,
              progress: 100,
              status: 'processing'
            }
          }
          return { ...file, progress: newProgress }
        }
        return file
      }))
    }, 500)

    // Simulate processing completion
    setTimeout(() => {
      setUploadedFiles(prev => prev.map(file => {
        if (file.id === fileId) {
          return {
            ...file,
            status: Math.random() > 0.1 ? 'completed' : 'error'
          }
        }
        return file
      }))
    }, 3000 + Math.random() * 2000)
  }

  const handleUrlSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!webUrl) return

    setIsProcessingUrl(true)
    
    // Simulate URL processing
    const urlFile: UploadedFile = {
      id: Math.random().toString(36).substr(2, 9),
      name: new URL(webUrl).hostname,
      size: 0,
      type: 'url',
      status: 'processing',
      progress: 100,
      url: webUrl
    }

    setUploadedFiles(prev => [...prev, urlFile])
    
    setTimeout(() => {
      setUploadedFiles(prev => prev.map(file => {
        if (file.id === urlFile.id) {
          return {
            ...file,
            status: Math.random() > 0.2 ? 'completed' : 'error'
          }
        }
        return file
      }))
      setIsProcessingUrl(false)
      setWebUrl('')
    }, 2000)
  }

  const removeFile = (fileId: string) => {
    setUploadedFiles(prev => prev.filter(file => file.id !== fileId))
  }

  const getFileIcon = (type: string) => {
    if (type === 'url') return Globe
    if (type.startsWith('image/')) return Image
    if (type.includes('pdf') || type.includes('document')) return FileText
    if (type.includes('text') || type.includes('code')) return Code
    return File
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'text-green-600'
      case 'error':
        return 'text-red-600'
      case 'processing':
      case 'uploading':
        return 'text-blue-600'
      default:
        return 'text-muted-foreground'
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return 'N/A'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return (
    <div className="min-h-screen bg-background">
      <Navigation showBackButton backHref="/chat" backLabel="Back to Chat" />

      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="space-y-8">
          <div>
            <h1 className="text-3xl font-bold">Upload Documents</h1>
            <p className="text-muted-foreground mt-2">
              Add documents, websites, and data sources for your AI agents to reference
            </p>
          </div>

          <Tabs defaultValue="upload" className="space-y-6">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="upload">File Upload</TabsTrigger>
              <TabsTrigger value="web">Web Content</TabsTrigger>
              <TabsTrigger value="integrations">Integrations</TabsTrigger>
            </TabsList>

            <TabsContent value="upload" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Upload className="h-5 w-5" />
                    Upload Files
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div
                    className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
                      isDragging ? 'border-primary bg-primary/5' : 'border-muted-foreground/25'
                    }`}
                    onDragOver={(e) => {
                      e.preventDefault()
                      setIsDragging(true)
                    }}
                    onDragLeave={() => setIsDragging(false)}
                    onDrop={(e) => {
                      e.preventDefault()
                      setIsDragging(false)
                      handleFileUpload(e.dataTransfer.files)
                    }}
                  >
                    <FolderOpen className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                    <h3 className="text-lg font-semibold mb-2">Drop files here or click to browse</h3>
                    <p className="text-muted-foreground mb-4">
                      Supports PDF, Word docs, text files, images, and more
                    </p>
                    <Button onClick={() => fileInputRef.current?.click()}>
                      <Upload className="h-4 w-4 mr-2" />
                      Choose Files
                    </Button>
                    <input
                      ref={fileInputRef}
                      type="file"
                      multiple
                      className="hidden"
                      onChange={(e) => handleFileUpload(e.target.files)}
                      accept=".pdf,.doc,.docx,.txt,.md,.csv,.json,.png,.jpg,.jpeg,.gif"
                    />
                  </div>

                  <div className="mt-4 text-sm text-muted-foreground">
                    <p className="mb-2">Supported formats:</p>
                    <div className="flex flex-wrap gap-2">
                      <Badge variant="secondary">PDF</Badge>
                      <Badge variant="secondary">Word</Badge>
                      <Badge variant="secondary">Text</Badge>
                      <Badge variant="secondary">Markdown</Badge>
                      <Badge variant="secondary">CSV</Badge>
                      <Badge variant="secondary">JSON</Badge>
                      <Badge variant="secondary">Images</Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="web" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Globe className="h-5 w-5" />
                    Web Content
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <form onSubmit={handleUrlSubmit} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="webUrl">Website URL</Label>
                      <Input
                        id="webUrl"
                        type="url"
                        placeholder="https://example.com"
                        value={webUrl}
                        onChange={(e) => setWebUrl(e.target.value)}
                      />
                      <p className="text-sm text-muted-foreground">
                        Enter a URL to extract and index its content
                      </p>
                    </div>
                    <Button type="submit" disabled={!webUrl || isProcessingUrl}>
                      {isProcessingUrl ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          Processing...
                        </>
                      ) : (
                        <>
                          <Download className="h-4 w-4 mr-2" />
                          Extract Content
                        </>
                      )}
                    </Button>
                  </form>

                  <div className="space-y-2">
                    <Label>Bulk URL Import</Label>
                    <Textarea
                      placeholder="Paste multiple URLs (one per line)"
                      rows={4}
                    />
                    <Button variant="outline" size="sm">
                      Import URLs
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="integrations" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Database className="h-5 w-5" />
                    Data Integrations
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Card>
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
                            <Database className="h-5 w-5 text-blue-500" />
                          </div>
                          <div>
                            <h4 className="font-semibold">Google Drive</h4>
                            <p className="text-sm text-muted-foreground">Sync documents and folders</p>
                          </div>
                        </div>
                        <Button variant="outline" size="sm" className="w-full mt-3">
                          Connect
                        </Button>
                      </CardContent>
                    </Card>

                    <Card>
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center">
                            <FileText className="h-5 w-5 text-purple-500" />
                          </div>
                          <div>
                            <h4 className="font-semibold">Notion</h4>
                            <p className="text-sm text-muted-foreground">Import pages and databases</p>
                          </div>
                        </div>
                        <Button variant="outline" size="sm" className="w-full mt-3">
                          Connect
                        </Button>
                      </CardContent>
                    </Card>

                    <Card>
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-orange-500/20 rounded-lg flex items-center justify-center">
                            <Code className="h-5 w-5 text-orange-500" />
                          </div>
                          <div>
                            <h4 className="font-semibold">GitHub</h4>
                            <p className="text-sm text-muted-foreground">Repository documentation</p>
                          </div>
                        </div>
                        <Button variant="outline" size="sm" className="w-full mt-3">
                          Connect
                        </Button>
                      </CardContent>
                    </Card>

                    <Card>
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
                            <LinkIcon className="h-5 w-5 text-green-500" />
                          </div>
                          <div>
                            <h4 className="font-semibold">Confluence</h4>
                            <p className="text-sm text-muted-foreground">Wiki and documentation</p>
                          </div>
                        </div>
                        <Button variant="outline" size="sm" className="w-full mt-3">
                          Connect
                        </Button>
                      </CardContent>
                    </Card>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          {/* Uploaded Files List */}
          {uploadedFiles.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Uploaded Files ({uploadedFiles.length})</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {uploadedFiles.map((file) => {
                    const Icon = getFileIcon(file.type)
                    return (
                      <div key={file.id} className="flex items-center gap-3 p-3 border rounded-lg">
                        <Icon className="h-8 w-8 text-muted-foreground flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <h4 className="font-medium truncate">{file.name}</h4>
                            {file.status === 'completed' && (
                              <CheckCircle className="h-4 w-4 text-green-600 flex-shrink-0" />
                            )}
                            {file.status === 'error' && (
                              <AlertCircle className="h-4 w-4 text-red-600 flex-shrink-0" />
                            )}
                            {(file.status === 'uploading' || file.status === 'processing') && (
                              <Loader2 className="h-4 w-4 animate-spin text-blue-600 flex-shrink-0" />
                            )}
                          </div>
                          <div className="flex items-center gap-4 text-sm text-muted-foreground">
                            <span>{formatFileSize(file.size)}</span>
                            <span className={getStatusColor(file.status)}>
                              {file.status === 'uploading' && `Uploading ${Math.round(file.progress)}%`}
                              {file.status === 'processing' && 'Processing...'}
                              {file.status === 'completed' && 'Ready'}
                              {file.status === 'error' && 'Failed'}
                            </span>
                          </div>
                          {file.status === 'uploading' && (
                            <Progress value={file.progress} className="mt-2" />
                          )}
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeFile(file.id)}
                          className="flex-shrink-0"
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    )
                  })}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}