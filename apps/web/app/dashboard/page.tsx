'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Bot, MessageSquare, Key, Activity, Plus, Settings, Trash2, Edit } from 'lucide-react'

interface SavedAgent {
  id: string
  name: string
  description: string
  lastUsed: Date
  messageCount: number
}

interface Conversation {
  id: string
  agentName: string
  lastMessage: string
  timestamp: Date
}

export default function DashboardPage() {
  const [savedAgents, setSavedAgents] = useState<SavedAgent[]>([])
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [apiKeys, setApiKeys] = useState<{ provider: string; configured: boolean }[]>([])

  useEffect(() => {
    // Mock data - will be replaced with API calls
    setSavedAgents([
      {
        id: '1',
        name: 'Research Assistant',
        description: 'Academic research with citations',
        lastUsed: new Date('2024-01-15'),
        messageCount: 45
      },
      {
        id: '2',
        name: 'Code Reviewer',
        description: 'Automated code review and suggestions',
        lastUsed: new Date('2024-01-14'),
        messageCount: 128
      },
      {
        id: '3',
        name: 'Content Writer',
        description: 'SEO-optimized blog posts',
        lastUsed: new Date('2024-01-13'),
        messageCount: 67
      }
    ])

    setConversations([
      {
        id: '1',
        agentName: 'Research Assistant',
        lastMessage: 'Found 5 relevant papers on quantum computing',
        timestamp: new Date('2024-01-15T10:30:00')
      },
      {
        id: '2',
        agentName: 'Code Reviewer',
        lastMessage: 'Identified 3 potential security issues',
        timestamp: new Date('2024-01-14T15:45:00')
      }
    ])

    setApiKeys([
      { provider: 'OpenAI', configured: true },
      { provider: 'Anthropic', configured: false },
      { provider: 'Google', configured: false }
    ])
  }, [])

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="border-b">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold">
            Asmbli
          </Link>
          <nav className="flex gap-6 items-center">
            <Link href="/templates" className="hover:underline">
              Templates
            </Link>
            <Link href="/dashboard" className="font-semibold">
              Dashboard
            </Link>
            <Link href="/chat">
              <Button>Start Chat</Button>
            </Link>
          </nav>
        </div>
      </header>

      {/* Dashboard Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-2">Dashboard</h1>
          <p className="text-muted-foreground">Manage your agents, conversations, and settings</p>
        </div>

        {/* Stats Cards */}
        <div className="grid md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Agents</CardTitle>
              <Bot className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{savedAgents.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Conversations</CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{conversations.length}</div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">API Keys</CardTitle>
              <Key className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {apiKeys.filter(k => k.configured).length}/{apiKeys.length}
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Usage</CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {savedAgents.reduce((sum, agent) => sum + agent.messageCount, 0)}
              </div>
              <p className="text-xs text-muted-foreground">Total messages</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Tabs */}
        <Tabs defaultValue="agents" className="space-y-4">
          <TabsList>
            <TabsTrigger value="agents">Saved Agents</TabsTrigger>
            <TabsTrigger value="conversations">Recent Conversations</TabsTrigger>
            <TabsTrigger value="settings">Settings</TabsTrigger>
          </TabsList>

          <TabsContent value="agents" className="space-y-4">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-semibold">Your Agents</h2>
              <Link href="/templates">
                <Button>
                  <Plus className="mr-2 h-4 w-4" />
                  Create New Agent
                </Button>
              </Link>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {savedAgents.map(agent => (
                <Card key={agent.id}>
                  <CardHeader>
                    <CardTitle className="flex justify-between items-start">
                      {agent.name}
                      <div className="flex gap-2">
                        <Button size="icon" variant="ghost">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button size="icon" variant="ghost">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </CardTitle>
                    <CardDescription>{agent.description}</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-sm text-muted-foreground space-y-1">
                      <p>Last used: {agent.lastUsed.toLocaleDateString()}</p>
                      <p>Messages: {agent.messageCount}</p>
                    </div>
                    <Link href={`/chat?agent=${agent.id}`}>
                      <Button className="w-full mt-4">Open Chat</Button>
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="conversations" className="space-y-4">
            <h2 className="text-2xl font-semibold mb-4">Recent Conversations</h2>
            <div className="space-y-2">
              {conversations.map(conv => (
                <Card key={conv.id}>
                  <CardHeader>
                    <div className="flex justify-between items-start">
                      <div>
                        <CardTitle className="text-base">{conv.agentName}</CardTitle>
                        <CardDescription>{conv.lastMessage}</CardDescription>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        {conv.timestamp.toLocaleString()}
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <Link href={`/chat?conversation=${conv.id}`}>
                      <Button variant="outline" className="w-full">Continue Conversation</Button>
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="settings" className="space-y-4">
            <h2 className="text-2xl font-semibold mb-4">API Settings</h2>
            <div className="space-y-4">
              {apiKeys.map(key => (
                <Card key={key.provider}>
                  <CardHeader>
                    <CardTitle className="flex justify-between items-center">
                      {key.provider}
                      {key.configured ? (
                        <span className="text-sm text-green-600">Configured</span>
                      ) : (
                        <span className="text-sm text-muted-foreground">Not configured</span>
                      )}
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <Button variant={key.configured ? "outline" : "default"}>
                      <Settings className="mr-2 h-4 w-4" />
                      {key.configured ? 'Update' : 'Configure'} API Key
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}