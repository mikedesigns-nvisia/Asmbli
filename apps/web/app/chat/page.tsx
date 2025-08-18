'use client'

import { useState, useEffect, useRef, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Bot, Send, Upload, Settings, User, Loader2, Menu, X, ChevronLeft, ChevronRight } from 'lucide-react'
import { MCPServersDisplay } from '@/components/MCPServersDisplay'

interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
}

interface Agent {
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
  const [agents, setAgents] = useState<Agent[]>([
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

  return (
    <div className="flex h-screen">
      {/* Navigation Header */}
      <header className="fixed top-0 left-0 right-0 z-50 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-3 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="lg:hidden"
            >
              <Menu className="h-4 w-4" />
            </Button>
            <Link href="/" className="text-xl font-bold italic">
              Asmbli
            </Link>
          </div>
          <nav className="flex gap-6 items-center">
            <Link href="/templates" className="hover:underline text-sm">
              Templates
            </Link>
            <Link href="/mcp-servers" className="hover:underline text-sm">
              Library
            </Link>
            <Link href="/dashboard" className="hover:underline text-sm">
              Dashboard
            </Link>
          </nav>
        </div>
      </header>

      {/* Sidebar */}
      <aside className={`${isSidebarOpen ? 'w-80' : 'w-0'} transition-all duration-300 overflow-hidden border-r bg-muted/50 mt-16 relative`}>
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
      <main className={`flex-1 flex flex-col mt-16 ${isSidebarOpen ? 'ml-0' : 'ml-0'}`}>
        {/* Chat Header */}
        <header className="border-b p-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-lg font-semibold">
                {agents.find(a => a.id === selectedAgent)?.name}
              </h1>
              <p className="text-sm text-muted-foreground">
                {agents.find(a => a.id === selectedAgent)?.description}
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
  )
}

export default function ChatPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <ChatInterface />
    </Suspense>
  )
}