'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, Bot, Code, Zap, Users, Server, Figma, FileText, Key, Target } from 'lucide-react'
import { Navigation } from '@/components/Navigation'
import { Footer } from '@/components/Footer'

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Navigation */}
      <Navigation />

      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-4xl text-center">
          <h1 className="text-5xl font-bold italic mb-6 font-display">
            AI Agents Made - Easy
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            Build, customize, and deploy your own private AI agents with powerful tools and integrations. 
            Start with templates or create from scratch - your data and agentic experiences stay secure and under your control.
          </p>
          <div className="flex gap-4 justify-center">
            <Link href="/templates">
              <Button size="lg">
                Browse Templates
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Link href="/chat">
              <Button size="lg" variant="outline">
                View Demo
              </Button>
            </Link>
          </div>
          <div className="mt-6">
            <p className="text-sm text-muted-foreground italic">
              Desktop app with agent builder coming soon
            </p>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 px-4 bg-muted/50">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12 font-display">
            Everything You Need to Build AI Agents
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <Bot className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Template & Community Library</CardTitle>
                <CardDescription>
                  Start with pre-built agent templates for research, writing, and development. 
                  Discover and share configurations with the community - fork and customize to your needs
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Code className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>MCP Integration & Servers</CardTitle>
                <CardDescription>
                  Connect to filesystem, Git, GitHub, databases, and custom tools via Model Context Protocol. 
                  Browse 10+ ready-to-use MCP servers with seamless integrations
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Zap className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Instant Chat</CardTitle>
                <CardDescription>
                  Start chatting with your configured AI agents immediately.
                  No deployment needed - just instant conversation
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* What You Bring Section */}
      <section className="py-20 px-4 bg-gradient-to-br from-muted/30 to-background">
        <div className="container mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4 font-display">
              What You Bring
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Everything you need to get started building your custom AI agent
            </p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {/* Documents */}
            <Card className="border-2 hover:border-primary/30 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-blue-500/10 rounded-xl flex items-center justify-center mb-4">
                  <FileText className="h-6 w-6 text-blue-500" />
                </div>
                <CardTitle className="text-xl font-display">Documents</CardTitle>
                <CardDescription className="text-base">
                  Your knowledge base and context materials
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                    <span className="text-sm">Design systems</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                    <span className="text-sm">Requirements docs</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                    <span className="text-sm">Company knowledge</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                    <span className="text-sm">Process documentation</span>
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* API Key */}
            <Card className="border-2 hover:border-primary/30 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-green-500/10 rounded-xl flex items-center justify-center mb-4">
                  <Key className="h-6 w-6 text-green-500" />
                </div>
                <CardTitle className="text-xl font-display">An API Key</CardTitle>
                <CardDescription className="text-base">
                  Your preferred AI provider connection
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
                    <span className="text-sm">Anthropic (Claude)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
                    <span className="text-sm">OpenAI (GPT)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
                    <span className="text-sm">Google (Gemini)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
                    <span className="text-sm">Custom providers</span>
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* Use Case */}
            <Card className="border-2 hover:border-primary/30 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-purple-500/10 rounded-xl flex items-center justify-center mb-4">
                  <Target className="h-6 w-6 text-purple-500" />
                </div>
                <CardTitle className="text-xl font-display">A Use Case</CardTitle>
                <CardDescription className="text-base">
                  What do you want/need/feel like doing?
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span className="text-sm">Research & analysis</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span className="text-sm">Code & development</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span className="text-sm">Content creation</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-purple-500 rounded-full"></div>
                    <span className="text-sm">Process automation</span>
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>
          
          <div className="text-center mt-12">
            <p className="text-muted-foreground mb-6">
              That's it! Bring these three things and you're ready to build.
            </p>
            <Link href="/chat">
              <Button size="lg" className="font-display">
                View Demo
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* MCP Servers Library Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4">
              MCP Servers Library
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Connect your agents to powerful tools and services with our curated collection of Model Context Protocol servers
            </p>
          </div>
          <div className="grid md:grid-cols-3 lg:grid-cols-4 gap-4">
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-blue-500" />
                  <CardTitle className="text-sm">Filesystem</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  File operations, directory traversal, search & monitoring
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-orange-500" />
                  <CardTitle className="text-sm">Git</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Repository cloning, branch management, commit operations
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-gray-800" />
                  <CardTitle className="text-sm">GitHub</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Issues, pull requests, code review, actions integration
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-blue-600" />
                  <CardTitle className="text-sm">PostgreSQL</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  SQL execution, schema introspection, performance analysis
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-purple-500" />
                  <CardTitle className="text-sm">Memory</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Knowledge storage, semantic search, context management
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-orange-600" />
                  <CardTitle className="text-sm">Brave Search</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Real-time web search, ranking, domain-specific queries
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Code className="h-5 w-5 text-green-500" />
                  <CardTitle className="text-sm">HTTP/Fetch</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  API requests, authentication, response parsing
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Figma className="h-5 w-5 text-purple-600" />
                  <CardTitle className="text-sm">Figma</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Design files, components, design systems integration
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
          <div className="text-center mt-8">
            <Link href="/mcp-servers">
              <Button variant="outline">
                View All MCP Servers
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold mb-6">
            Ready to Build Your First Agent?
          </h2>
          <p className="text-lg text-muted-foreground mb-8">
            Join thousands of developers building AI agents with Asmbli.
            Start with a template or create from scratch.
          </p>
          <Link href="/templates">
            <Button size="lg">
              Get Started Free
              <ArrowRight className="ml-2 h-4 w-4" />
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <Footer />
    </div>
  )
}