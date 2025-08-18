'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Search, Bot, Layers, ArrowRight } from 'lucide-react'

interface Template {
  id: string
  name: string
  description: string
  category: string
  author: string
  mcpStack: string[]
  tags: string[]
  isPublic: boolean
}

const categories = [
  'All',
  'Research',
  'Writing',
  'Development',
  'Data Analysis',
  'Customer Support',
  'Marketing',
  'Education',
  'Healthcare',
  'Finance'
]

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([])
  const [filteredTemplates, setFilteredTemplates] = useState<Template[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('All')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Mock data for now - will be replaced with API call
    const mockTemplates: Template[] = [
      {
        id: '1',
        name: 'Research Assistant',
        description: 'Academic research agent with citation management and fact-checking',
        category: 'Research',
        author: 'Asmbli Team',
        mcpStack: ['filesystem', 'brave-search', 'sqlite', 'fetch'],
        tags: ['academic', 'citations', 'fact-checking'],
        isPublic: true
      },
      {
        id: '2',
        name: 'Code Reviewer',
        description: 'Automated code review with best practices and security checks',
        category: 'Development',
        author: 'Asmbli Team',
        mcpStack: ['filesystem', 'git', 'github', 'sqlite'],
        tags: ['code-review', 'security', 'best-practices'],
        isPublic: true
      },
      {
        id: '3',
        name: 'Content Writer',
        description: 'SEO-optimized content generation with tone customization',
        category: 'Writing',
        author: 'Community',
        mcpStack: ['fetch', 'sqlite', 'filesystem'],
        tags: ['seo', 'content', 'marketing'],
        isPublic: true
      },
      {
        id: '4',
        name: 'Data Analyst',
        description: 'Statistical analysis and visualization for business insights',
        category: 'Data Analysis',
        author: 'Asmbli Team',
        mcpStack: ['sqlite', 'filesystem', 'fetch', 'postgres'],
        tags: ['statistics', 'visualization', 'insights'],
        isPublic: true
      },
      {
        id: '5',
        name: 'Customer Support Bot',
        description: 'Intelligent support agent with ticket management integration',
        category: 'Customer Support',
        author: 'Community',
        mcpStack: ['sqlite', 'fetch', 'filesystem'],
        tags: ['support', 'tickets', 'automation'],
        isPublic: true
      },
      {
        id: '6',
        name: 'Marketing Strategist',
        description: 'Campaign planning and performance analysis agent',
        category: 'Marketing',
        author: 'Asmbli Team',
        mcpStack: ['fetch', 'sqlite', 'brave-search', 'filesystem'],
        tags: ['campaigns', 'strategy', 'analytics'],
        isPublic: true
      }
    ]
    
    setTemplates(mockTemplates)
    setFilteredTemplates(mockTemplates)
    setLoading(false)
  }, [])

  useEffect(() => {
    let filtered = templates

    if (selectedCategory !== 'All') {
      filtered = filtered.filter(t => t.category === selectedCategory)
    }

    if (searchQuery) {
      filtered = filtered.filter(t => 
        t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        t.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        t.tags.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    }

    setFilteredTemplates(filtered)
  }, [searchQuery, selectedCategory, templates])

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="border-b">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold italic">
            Asmbli
          </Link>
          <nav className="flex gap-6 items-center">
            <Link href="/templates" className="font-semibold">
              Templates
            </Link>
            <Link href="/dashboard" className="hover:underline">
              Dashboard
            </Link>
            <Link href="/chat">
              <Button>Start Chat</Button>
            </Link>
          </nav>
        </div>
      </header>

      {/* Page Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Agent Templates</h1>
          <p className="text-lg text-muted-foreground">
            Start with a pre-built template and customize it to your needs
          </p>
        </div>

        {/* Filters */}
        <div className="flex gap-4 mb-8">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              placeholder="Search templates..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
          <Select value={selectedCategory} onValueChange={setSelectedCategory}>
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Category" />
            </SelectTrigger>
            <SelectContent>
              {categories.map(cat => (
                <SelectItem key={cat} value={cat}>{cat}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Templates Grid */}
        {loading ? (
          <div className="text-center py-12">Loading templates...</div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredTemplates.map(template => (
              <Card key={template.id} className="flex flex-col">
                <CardHeader>
                  <div className="flex justify-between items-start mb-2">
                    <Bot className="h-8 w-8 text-primary" />
                    <Badge variant="secondary">{template.category}</Badge>
                  </div>
                  <CardTitle>{template.name}</CardTitle>
                  <CardDescription>{template.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-wrap gap-2 mb-4">
                    {template.tags.map(tag => (
                      <Badge key={tag} variant="outline" className="text-xs">
                        {tag}
                      </Badge>
                    ))}
                  </div>
                  <div className="flex items-center justify-end text-sm text-muted-foreground">
                    <div 
                      className="flex items-center gap-1 cursor-help" 
                      title={`MCP Stack: ${template.mcpStack.join(', ')}`}
                    >
                      <Layers className="h-4 w-4" />
                      <span>MCP Stack</span>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="mt-auto">
                  <Link href={`/chat?template=${template.id}`} className="w-full">
                    <Button className="w-full">
                      Use Template
                      <ArrowRight className="ml-2 h-4 w-4" />
                    </Button>
                  </Link>
                </CardFooter>
              </Card>
            ))}
          </div>
        )}

        {filteredTemplates.length === 0 && !loading && (
          <div className="text-center py-12">
            <p className="text-muted-foreground">No templates found matching your criteria</p>
          </div>
        )}
      </main>
    </div>
  )
}