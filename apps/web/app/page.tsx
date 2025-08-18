import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, Bot, Code, Zap, Shield, Cloud, Users } from 'lucide-react'

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
            Making Agents Easy
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            Professional-grade AI agent configuration platform. Choose from templates,
            customize with your tools, and instantly use in chat.
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
                <Shield className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Enterprise Security</CardTitle>
                <CardDescription>
                  Built-in authentication, rate limiting, audit logging, and
                  secure API key management
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Cloud className="h-10 w-10 mb-2 text-primary" />
                <CardTitle>Cloud Sync</CardTitle>
                <CardDescription>
                  Save your agents to the cloud and access them from anywhere.
                  Share with your team or the community
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
              © 2024 Asmbli. All rights reserved.
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