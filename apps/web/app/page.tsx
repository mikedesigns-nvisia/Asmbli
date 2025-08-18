import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, Bot, Code, Zap, Users, Server, Figma } from 'lucide-react'

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Navigation */}
      <header className="border-b">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold italic">
            Asmbli
          </Link>
          <nav className="flex gap-6 items-center">
            <Link href="/templates" className="hover:underline">
              Templates
            </Link>
            <Link href="/mcp-servers" className="hover:underline">
              Library
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

      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-4xl text-center">
          <h1 className="text-5xl font-bold italic mb-6">
            AI Agents Made Easy
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
                Quick Start Chat
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 px-4 bg-muted/50">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">
            Everything You Need to Build AI Agents
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <Bot className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Template Library</CardTitle>
                <CardDescription>
                  Start with pre-built agent templates for research, writing,
                  development, and more
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Code className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>MCP Integration</CardTitle>
                <CardDescription>
                  Connect to filesystem, Git, GitHub, databases, and custom tools
                  via Model Context Protocol. MCP Gateway support coming soon
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
            <Card>
              <CardHeader>
                <Users className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Community Templates</CardTitle>
                <CardDescription>
                  Discover and share agent configurations with the community.
                  Fork and customize to your needs
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Server className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>MCP Servers Library</CardTitle>
                <CardDescription>
                  Browse 10+ ready-to-use MCP servers: filesystem, Git, GitHub, 
                  databases, search, memory, and more integrations
                </CardDescription>
              </CardHeader>
            </Card>
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
      <footer className="border-t mt-auto">
        <div className="container mx-auto px-4 py-8">
          <div className="flex justify-between items-center">
            <p className="text-sm text-muted-foreground">
              © 2025 Asmbli. All rights reserved.
            </p>
            <div className="flex gap-6">
              <Link href="/docs" className="text-sm hover:underline">
                Documentation
              </Link>
              <Link href="/support" className="text-sm hover:underline">
                Support
              </Link>
              <Link href="/privacy" className="text-sm hover:underline">
                Privacy
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}