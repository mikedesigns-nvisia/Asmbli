'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Search, Bot, Code, Palette, BarChart3, PenTool, Loader2, CheckCircle } from 'lucide-react'
import { agentLibrary, Agent, getAgentsByCategory, searchAgents } from '@/lib/agentLibrary'

const categoryIcons = {
  'Research': Search,
  'Development': Code,
  'Design': Palette,
  'Analytics': BarChart3,
  'Content': PenTool
}

interface AgentLibraryModalProps {
  isOpen: boolean
  onClose: () => void
  onSelectAgent: (agent: Agent) => void
  isLoading?: boolean
}

export function AgentLibraryModal({ isOpen, onClose, onSelectAgent, isLoading = false }: AgentLibraryModalProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  
  const categories = ['all', ...Array.from(new Set(agentLibrary.map(agent => agent.category)))]
  
  const filteredAgents = searchQuery 
    ? searchAgents(searchQuery)
    : selectedCategory === 'all' 
      ? agentLibrary 
      : getAgentsByCategory(selectedCategory)

  const handleSelectAgent = (agent: Agent) => {
    onSelectAgent(agent)
    onClose()
  }

  const getIconComponent = (iconName: string) => {
    const iconMap: { [key: string]: any } = {
      'Search': Search,
      'FileText': PenTool,
      'Database': BarChart3,
      'Github': Code,
      'Code': Code,
      'Figma': Palette
    }
    return iconMap[iconName] || Bot
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bot className="h-5 w-5" />
            Agent Library
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search agents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Categories */}
          <Tabs value={selectedCategory} onValueChange={setSelectedCategory}>
            <TabsList className="grid w-full grid-cols-6">
              <TabsTrigger value="all">All</TabsTrigger>
              {categories.slice(1).map(category => {
                const Icon = categoryIcons[category as keyof typeof categoryIcons] || Bot
                return (
                  <TabsTrigger key={category} value={category} className="flex items-center gap-2">
                    <Icon className="h-4 w-4" />
                    {category}
                  </TabsTrigger>
                )
              })}
            </TabsList>

            <TabsContent value={selectedCategory} className="mt-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {filteredAgents.map(agent => {
                  const CategoryIcon = categoryIcons[agent.category as keyof typeof categoryIcons] || Bot
                  return (
                    <Card key={agent.id} className="hover:shadow-lg transition-shadow cursor-pointer border-2 hover:border-primary/50">
                      <CardHeader className="pb-3">
                        <div className="flex items-start justify-between">
                          <div className="flex items-center gap-3">
                            <div className="p-2 rounded-lg bg-primary/10">
                              <CategoryIcon className="h-5 w-5 text-primary" />
                            </div>
                            <div>
                              <CardTitle className="text-lg">{agent.name}</CardTitle>
                              <Badge variant="secondary" className="text-xs">
                                {agent.category}
                              </Badge>
                            </div>
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent className="space-y-4">
                        <p className="text-sm text-muted-foreground line-clamp-2">
                          {agent.description}
                        </p>
                        
                        {/* Tags */}
                        <div className="flex flex-wrap gap-1">
                          {agent.tags.slice(0, 3).map(tag => (
                            <Badge key={tag} variant="outline" className="text-xs">
                              {tag}
                            </Badge>
                          ))}
                          {agent.tags.length > 3 && (
                            <Badge variant="outline" className="text-xs">
                              +{agent.tags.length - 3}
                            </Badge>
                          )}
                        </div>

                        {/* MCP Servers */}
                        <div>
                          <p className="text-xs font-medium text-muted-foreground mb-2">
                            MCP Servers ({agent.mcpServers.length})
                          </p>
                          <div className="flex gap-1 flex-wrap">
                            {agent.mcpServers.slice(0, 3).map(server => {
                              const ServerIcon = getIconComponent(server.icon)
                              return (
                                <div key={server.id} className="flex items-center gap-1 bg-muted rounded px-2 py-1">
                                  <ServerIcon className="h-3 w-3" />
                                  <span className="text-xs">{server.name}</span>
                                </div>
                              )
                            })}
                            {agent.mcpServers.length > 3 && (
                              <div className="flex items-center bg-muted rounded px-2 py-1">
                                <span className="text-xs">+{agent.mcpServers.length - 3}</span>
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Capabilities */}
                        <div>
                          <p className="text-xs font-medium text-muted-foreground mb-2">Key Capabilities</p>
                          <div className="text-xs text-muted-foreground">
                            {agent.capabilities.slice(0, 2).join(' • ')}
                            {agent.capabilities.length > 2 && ' • ...'}
                          </div>
                        </div>

                        <Button 
                          onClick={() => handleSelectAgent(agent)}
                          disabled={isLoading}
                          className="w-full"
                        >
                          {isLoading ? (
                            <>
                              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                              Loading...
                            </>
                          ) : (
                            <>
                              <CheckCircle className="h-4 w-4 mr-2" />
                              Load Agent
                            </>
                          )}
                        </Button>
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
              
              {filteredAgents.length === 0 && (
                <div className="text-center py-8 text-muted-foreground">
                  <Bot className="h-12 w-12 mx-auto mb-4 opacity-50" />
                  <p>No agents found matching your criteria</p>
                </div>
              )}
            </TabsContent>
          </Tabs>
        </div>
      </DialogContent>
    </Dialog>
  )
}