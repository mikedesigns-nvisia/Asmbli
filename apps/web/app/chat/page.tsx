'use client'

import { useState, useEffect, useRef, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Bot, Send, Upload, Settings, User, Loader2, Menu, X, ChevronLeft, ChevronRight, Library, Sparkles } from 'lucide-react'
import { MCPServersDisplay } from '@/components/MCPServersDisplay'
import { AgentLibraryModal } from '@/components/AgentLibraryModal'
import { Agent, agentLibrary } from '@/lib/agentLibrary'
import { Navigation } from '@/components/Navigation'
import { Footer } from '@/components/Footer'

interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
}

interface BasicAgent {
  id: string
  name: string
  description: string
}

function ChatInterface() {
  const searchParams = useSearchParams()
  const templateId = searchParams.get('template')
  
  const [messages, setMessages] = useState<Message[]>([])
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [selectedAgent, setSelectedAgent] = useState<string>('default')
  const [isSidebarOpen, setIsSidebarOpen] = useState(true)
  const [showAgentLibrary, setShowAgentLibrary] = useState(false)
  const [isLoadingAgent, setIsLoadingAgent] = useState(false)
  const [currentAgent, setCurrentAgent] = useState<Agent | null>(null)
  const [agents, setAgents] = useState<BasicAgent[]>([
    { id: 'default', name: 'General Assistant', description: 'A helpful AI assistant' },
    { id: 'research', name: 'Research Assistant', description: 'Specialized in research and citations' },
    { id: 'code', name: 'Code Assistant', description: 'Helps with programming tasks' }
  ])
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (templateId) {
      // Load template configuration
      console.log('Loading template:', templateId)
    }
  }, [templateId])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading) return

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputValue('')
    setIsLoading(true)

    // Simulate AI response
    setTimeout(() => {
      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: `I'm a mock response to: "${userMessage.content}". In production, this would connect to your configured AI model via API.`,
        timestamp: new Date()
      }
      setMessages(prev => [...prev, assistantMessage])
      setIsLoading(false)
    }, 1000)
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSendMessage()
    }
  }

  const handleLoadAgent = async (agent: Agent) => {
    setIsLoadingAgent(true)
    
    // Simulate loading time
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    // Load the agent
    setCurrentAgent(agent)
    setSelectedAgent(agent.id)
    
    // Add agent to the agents list if not already there
    setAgents(prev => {
      const exists = prev.find(a => a.id === agent.id)
      if (!exists) {
        return [...prev, {
          id: agent.id,
          name: agent.name,
          description: agent.description
        }]
      }
      return prev
    })
    
    // Add welcome message from the agent
    const welcomeMessage: Message = {
      id: Date.now().toString(),
      role: 'assistant',
      content: `Hello! I'm ${agent.name}. ${agent.description}\n\nI'm equipped with the following capabilities:\n${agent.capabilities.map(cap => `• ${cap}`).join('\n')}\n\nHow can I help you today?`,
      timestamp: new Date()
    }
    
    setMessages([welcomeMessage])
    setIsLoadingAgent(false)
  }

  const getCurrentAgentDisplay = () => {
    if (currentAgent && selectedAgent === currentAgent.id) {
      return {
        name: currentAgent.name,
        description: currentAgent.description
      }
    }
    return agents.find(a => a.id === selectedAgent) || agents[0]
  }

  return (
    <>
      {/* Navigation Header */}
      <Navigation />
      
      <div className="flex h-[calc(100vh-64px)]">
        {/* Sidebar */}
        <aside className={`${isSidebarOpen ? 'w-80' : 'w-0'} transition-all duration-300 overflow-hidden border-r bg-muted/50 relative`}>
        <div className="p-4 h-full flex flex-col">
          {/* Sidebar Toggle */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold">Agent Control</h2>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="h-8 w-8 p-0"
            >
              {isSidebarOpen ? <ChevronLeft className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
            </Button>
          </div>
          
          <div className="space-y-6 flex-1 overflow-y-auto">
            <div>
              <label className="text-sm font-medium mb-2 block">Select Agent</label>
              <Select value={selectedAgent} onValueChange={setSelectedAgent}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {agents.map(agent => (
                    <SelectItem key={agent.id} value={agent.id}>
                      {agent.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Agent Library Button */}
            <Button 
              onClick={() => setShowAgentLibrary(true)} 
              variant="outline" 
              className="w-full justify-start mb-4"
            >
              <Library className="mr-2 h-4 w-4" />
              Browse Agent Library
            </Button>

            {/* Current Agent Info */}
            {currentAgent && selectedAgent === currentAgent.id && (
              <Card className="mb-4 border-primary/20 bg-primary/5">
                <CardHeader className="pb-3">
                  <div className="flex items-center gap-2">
                    <Sparkles className="h-4 w-4 text-primary" />
                    <CardTitle className="text-sm">Loaded Agent</CardTitle>
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div>
                    <p className="text-sm font-medium">{currentAgent.name}</p>
                    <p className="text-xs text-muted-foreground">{currentAgent.category}</p>
                  </div>
                  <div className="flex flex-wrap gap-1">
                    {currentAgent.tags.slice(0, 3).map(tag => (
                      <Badge key={tag} variant="secondary" className="text-xs">
                        {tag}
                      </Badge>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* MCP Servers Display */}
            <MCPServersDisplay selectedAgentId={selectedAgent} />

            <div className="space-y-2">
              <Link href="/upload">
                <Button variant="outline" className="w-full justify-start">
                  <Upload className="mr-2 h-4 w-4" />
                  Upload Documents
                </Button>
              </Link>
              <Link href="/settings">
                <Button variant="outline" className="w-full justify-start">
                  <Settings className="mr-2 h-4 w-4" />
                  API Settings
                </Button>
              </Link>
            </div>

            <div className="mt-auto pt-8">
              <Link href="/templates">
                <Button variant="ghost" className="w-full">
                  Browse Templates
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </aside>

      {/* Sidebar Toggle Button (when closed) */}
      {!isSidebarOpen && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setIsSidebarOpen(true)}
          className="fixed left-2 top-20 z-40 h-8 w-8 p-0 border bg-background"
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
      )}

        {/* Main Chat Area */}
        <main className="flex-1 flex flex-col">
        {/* Chat Header */}
        <header className="border-b p-4">
          <div className="flex items-center justify-center">
            <div className="text-center">
              <h1 className="text-lg font-semibold flex items-center justify-center gap-2 font-display">
                {currentAgent && selectedAgent === currentAgent.id && (
                  <Sparkles className="h-4 w-4 text-primary" />
                )}
                {getCurrentAgentDisplay().name}
              </h1>
              <p className="text-sm text-muted-foreground">
                {getCurrentAgentDisplay().description}
              </p>
            </div>
          </div>
        </header>

        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto p-4">
          {messages.length === 0 ? (
            <div className="flex items-center justify-center h-full">
              <Card className="p-8 text-center max-w-md">
                <Bot className="h-12 w-12 mx-auto mb-4 text-primary" />
                <h2 className="text-xl font-semibold mb-2">Start a Conversation</h2>
                <p className="text-muted-foreground">
                  Select an agent and send a message to begin. You can upload documents
                  for context or configure API settings in the sidebar.
                </p>
              </Card>
            </div>
          ) : (
            <div className="space-y-4 max-w-3xl mx-auto">
              {messages.map(message => (
                <div
                  key={message.id}
                  className={`flex gap-3 ${
                    message.role === 'assistant' ? '' : 'justify-end'
                  }`}
                >
                  {message.role === 'assistant' && (
                    <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                      <Bot className="h-5 w-5 text-primary-foreground" />
                    </div>
                  )}
                  <Card className={`p-4 max-w-[80%] ${
                    message.role === 'user' ? 'bg-primary text-primary-foreground' : ''
                  }`}>
                    <p className="whitespace-pre-wrap">{message.content}</p>
                    <p className="text-xs mt-2 opacity-70">
                      {message.timestamp.toLocaleTimeString()}
                    </p>
                  </Card>
                  {message.role === 'user' && (
                    <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                      <User className="h-5 w-5" />
                    </div>
                  )}
                </div>
              ))}
              {isLoading && (
                <div className="flex gap-3">
                  <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                    <Bot className="h-5 w-5 text-primary-foreground" />
                  </div>
                  <Card className="p-4">
                    <Loader2 className="h-4 w-4 animate-spin" />
                  </Card>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="border-t p-4">
          <div className="flex gap-2 max-w-3xl mx-auto">
            <Textarea
              placeholder="Type your message..."
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={handleKeyPress}
              className="resize-none"
              rows={3}
            />
            <Button 
              onClick={handleSendMessage} 
              disabled={!inputValue.trim() || isLoading}
              size="icon"
              className="h-auto"
            >
              <Send className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </main>
      </div>

      {/* Agent Library Modal */}
      <AgentLibraryModal
        isOpen={showAgentLibrary}
        onClose={() => setShowAgentLibrary(false)}
        onSelectAgent={handleLoadAgent}
        isLoading={isLoadingAgent}
      />
    </>
  )
}

export default function ChatPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ChatInterface />
    </Suspense>
  )
}