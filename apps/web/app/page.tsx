'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, Bot, Code, Zap, Users, Server, FileText, Key, Target, Shield, CheckCircle, Database, Search, Monitor, ExternalLink, Lock } from 'lucide-react'
import { 
  SiGithub, 
  SiFigma, 
  SiPostgresql,
  SiGit,
  SiBrave,
  SiMongodb,
  SiSlack,
  SiNotion,
  SiLinear,
  SiDiscord,
  SiAirtable,
  SiGooglesheets
} from 'react-icons/si'
import { Navigation } from '@/components/Navigation'
import { Footer } from '@/components/Footer'

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Navigation */}
      <Navigation />

      {/* Hero Section */}
      <section className="py-20 px-4 bg-gradient-to-br from-yellow-50/50 to-background">
        <div className="container mx-auto max-w-4xl text-center">
          <h1 className="text-5xl font-bold italic mb-6 font-display">
            AI Agents Made Easy
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            Build, customize, and deploy your own private AI agents with powerful tools and integrations. 
            Start with templates or create from scratch - your data and agentic experiences stay secure and under your control.
          </p>
          <div className="flex gap-4 justify-center">
            <Link href="/templates">
              <Button size="lg" className="bg-gradient-to-r from-amber-700 to-amber-800 hover:from-amber-800 hover:to-amber-900 text-white border-0">
                Browse Templates
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Link href="/chat">
              <Button size="lg" variant="outline" className="border-amber-700 hover:bg-amber-50 text-amber-900">
                View Demo
              </Button>
            </Link>
          </div>
          <div className="mt-6">
            <p className="text-sm text-muted-foreground italic">
              Desktop app with agent builder coming soon
            </p>
          </div>
          <div className="mt-12">
            <div className="max-w-6xl mx-auto px-4">
              <p className="text-sm md:text-base text-muted-foreground text-center mb-6">
                Desktop app beta - looking for testers to help improve the experience
              </p>
              <div className="rounded-xl border bg-card p-1 md:p-3 shadow-2xl hover:shadow-3xl transition-shadow duration-300">
                <img 
                  src="/flutter-desktop-preview.png" 
                  alt="Asmbli Desktop App - AI Agent Management Dashboard"
                  className="w-full rounded-lg hover:scale-[1.02] transition-transform duration-300"
                />
              </div>
              <div className="text-center mt-6">
                <p className="text-xs md:text-sm text-muted-foreground">
                  Cross-platform desktop app with full agent management capabilities
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 px-4 bg-yellow-50/30">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12 font-display">
            Everything You Need to Build AI Agents
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <Bot className="h-10 w-10 mb-2 text-yellow-600" />
                <CardTitle>Templates & Community</CardTitle>
                <CardDescription>
                  Pre-built agents for research, writing, and development. 
                  Fork and customize community configurations
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Code className="h-10 w-10 mb-2 text-yellow-600" />
                <CardTitle>MCP Integrations</CardTitle>
                <CardDescription>
                  Connect to Git, databases, and custom tools. 
                  10+ ready-to-use MCP servers available
                </CardDescription>
              </CardHeader>
            </Card>
            <Card>
              <CardHeader>
                <Zap className="h-10 w-10 mb-2 text-yellow-500" />
                <CardTitle>Instant Chat</CardTitle>
                <CardDescription>
                  Start chatting immediately with your AI agents.
                  No deployment needed
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* What You Bring Section */}
      <section className="py-20 px-4 bg-yellow-50/20">
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
            <Card className="border-2 hover:border-yellow-400/30 transition-colors bg-yellow-50/30">
              <CardHeader>
                <div className="w-12 h-12 bg-yellow-500/20 rounded-xl flex items-center justify-center mb-4">
                  <FileText className="h-6 w-6 text-yellow-600" />
                </div>
                <CardTitle className="text-xl font-display">Documents</CardTitle>
                <CardDescription className="text-base">
                  Your knowledge base and context materials
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Design systems</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Requirements docs</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Company knowledge</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Process documentation</span>
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* API Key */}
            <Card className="border-2 hover:border-yellow-400/30 transition-colors bg-yellow-50/30">
              <CardHeader>
                <div className="w-12 h-12 bg-yellow-500/20 rounded-xl flex items-center justify-center mb-4">
                  <Key className="h-6 w-6 text-yellow-600" />
                </div>
                <CardTitle className="text-xl font-display">An API Key</CardTitle>
                <CardDescription className="text-base">
                  Your preferred AI provider connection
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Anthropic (Claude)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">OpenAI (GPT)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Google (Gemini)</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-500 rounded-full"></div>
                    <span className="text-sm">Custom providers</span>
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* Use Case */}
            <Card className="border-2 hover:border-yellow-400/30 transition-colors bg-yellow-50/30">
              <CardHeader>
                <div className="w-12 h-12 bg-yellow-600/20 rounded-xl flex items-center justify-center mb-4">
                  <Target className="h-6 w-6 text-yellow-700" />
                </div>
                <CardTitle className="text-xl font-display">A Use Case</CardTitle>
                <CardDescription className="text-base">
                  What do you want/need/feel like doing?
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-3">
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-600 rounded-full"></div>
                    <span className="text-sm">Research & analysis</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-600 rounded-full"></div>
                    <span className="text-sm">Code & development</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-600 rounded-full"></div>
                    <span className="text-sm">Content creation</span>
                  </li>
                  <li className="flex items-center gap-3">
                    <div className="w-1.5 h-1.5 bg-yellow-600 rounded-full"></div>
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
              <Button size="lg" className="font-display bg-gradient-to-r from-amber-700 to-amber-800 hover:from-amber-800 hover:to-amber-900 text-white border-0">
                View Demo
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* What's an API Key Section */}
      <section className="py-20 px-4 bg-yellow-50/20">
        <div className="container mx-auto max-w-5xl">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4 font-display">
              What's an API Key and Why It's Important
            </h2>
            <p className="text-lg text-muted-foreground max-w-3xl mx-auto">
              An API key is your secure access credential that lets you use AI services while maintaining control over your data
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8 mb-12">
            {/* What is an API Key */}
            <Card className="border-2 border-yellow-300/30 bg-yellow-50/20">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-yellow-500/20 rounded-lg flex items-center justify-center">
                    <Key className="h-5 w-5 text-yellow-600" />
                  </div>
                  <CardTitle>What is an API Key?</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  Think of an API key as a secure password that identifies you to an AI service. It's like having your own personal access card that:
                </p>
                <ul className="space-y-2">
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm">Authenticates your requests to the AI provider</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm">Tracks your usage for billing purposes</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm">Ensures your conversations remain private to your account</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm">Allows you to set usage limits and control costs</span>
                  </li>
                </ul>
              </CardContent>
            </Card>

            {/* Why It's Important */}
            <Card className="border-2 border-yellow-300/30 bg-yellow-50/20">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-yellow-500/20 rounded-lg flex items-center justify-center">
                    <Shield className="h-5 w-5 text-yellow-600" />
                  </div>
                  <CardTitle>Why It's Important</CardTitle>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-muted-foreground">
                  Using your own API key with Asmbli provides crucial benefits:
                </p>
                <ul className="space-y-2">
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm"><strong>Direct relationship</strong> with the AI provider</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm"><strong>No middleman</strong> storing or processing your data</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm"><strong>Full control</strong> over usage limits and costs</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="h-4 w-4 text-green-500 mt-1 flex-shrink-0" />
                    <span className="text-sm"><strong>Provider-level security</strong> and data policies apply directly</span>
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>

          {/* Provider Data Safety Policies */}
          <Card className="border-2 border-yellow-300/30 bg-yellow-50/20">
            <CardHeader>
              <div className="flex items-center gap-3 mb-2">
                <div className="w-10 h-10 bg-yellow-500/20 rounded-lg flex items-center justify-center">
                  <Lock className="h-5 w-5 text-yellow-700" />
                </div>
                <CardTitle>Provider Data Safety Policies</CardTitle>
              </div>
              <CardDescription className="text-base">
                Major AI providers have strong data protection commitments when you use their API keys
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                {/* Anthropic */}
                <div className="space-y-2">
                  <h4 className="font-semibold flex items-center gap-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    Anthropic (Claude)
                  </h4>
                  <ul className="space-y-1 text-sm text-muted-foreground ml-4">
                    <li>• API inputs/outputs are <strong>NOT used</strong> for training models</li>
                    <li>• Data is <strong>automatically deleted</strong> within 30 days unless legally required</li>
                    <li>• <strong>Zero data retention</strong> option available for enterprise customers</li>
                    <li>• SOC 2 Type II certified with strict security controls</li>
                  </ul>
                </div>

                {/* OpenAI */}
                <div className="space-y-2">
                  <h4 className="font-semibold flex items-center gap-2">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    OpenAI (GPT)
                  </h4>
                  <ul className="space-y-1 text-sm text-muted-foreground ml-4">
                    <li>• API data is <strong>NOT used</strong> for training by default</li>
                    <li>• 30-day data retention for abuse monitoring (can opt-out)</li>
                    <li>• Enterprise agreements available with custom retention</li>
                    <li>• SOC 2 compliant with regular security audits</li>
                  </ul>
                </div>

                {/* Google */}
                <div className="space-y-2">
                  <h4 className="font-semibold flex items-center gap-2">
                    <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
                    Google (Gemini)
                  </h4>
                  <ul className="space-y-1 text-sm text-muted-foreground ml-4">
                    <li>• API data <strong>NOT used</strong> for model improvement</li>
                    <li>• Customizable data retention policies</li>
                    <li>• Cloud-level encryption and security standards</li>
                    <li>• ISO 27001, SOC 1/2/3 certified infrastructure</li>
                  </ul>
                </div>

                <div className="mt-6 p-4 bg-yellow-200/30 rounded-lg border border-yellow-300/30">
                  <p className="text-sm flex items-start gap-2">
                    <Shield className="h-4 w-4 text-yellow-700 mt-0.5 flex-shrink-0" />
                    <span>
                      <strong>Key Point:</strong> When you use your own API key with Asmbli, your data goes directly to your chosen provider. 
                      We never see, store, or process your conversations - ensuring maximum privacy and compliance with your provider's security policies.
                    </span>
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="text-center mt-8">
            <p className="text-muted-foreground mb-6">
              Ready to get started with your own API key?
            </p>
            <div className="flex gap-4 justify-center">
              <Link href="https://console.anthropic.com/api" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm" className="border-amber-700 hover:bg-amber-50 text-amber-900">
                  Get Anthropic API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
              <Link href="https://platform.openai.com/api-keys" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm" className="border-amber-700 hover:bg-amber-50 text-amber-900">
                  Get OpenAI API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
              <Link href="https://makersuite.google.com/app/apikey" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm" className="border-amber-700 hover:bg-amber-50 text-amber-900">
                  Get Google API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* MCP Servers Library Section */}
      <section className="py-20 px-4 bg-yellow-50/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <FileText className="h-5 w-5 text-blue-500" />
                  <CardTitle className="text-sm">Filesystem</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  File operations, directory traversal, search & monitoring
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiGit className="h-5 w-5 text-orange-500" />
                  <CardTitle className="text-sm">Git</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Repository cloning, branch management, commit operations
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiGithub className="h-5 w-5 text-gray-800" />
                  <CardTitle className="text-sm">GitHub</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Issues, pull requests, code review, actions integration
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiPostgresql className="h-5 w-5 text-blue-600" />
                  <CardTitle className="text-sm">PostgreSQL</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  SQL execution, schema introspection, performance analysis
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Database className="h-5 w-5 text-purple-500" />
                  <CardTitle className="text-sm">Memory</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Knowledge storage, semantic search, context management
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiBrave className="h-5 w-5 text-orange-600" />
                  <CardTitle className="text-sm">Brave Search</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Real-time web search, ranking, domain-specific queries
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Server className="h-5 w-5 text-green-500" />
                  <CardTitle className="text-sm">HTTP/Fetch</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  API requests, authentication, response parsing
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiFigma className="h-5 w-5 text-purple-600" />
                  <CardTitle className="text-sm">Figma</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Design files, components, design systems integration
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <Monitor className="h-5 w-5 text-blue-700" />
                  <CardTitle className="text-sm">VSCode</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Code editing, extensions, workspace control
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiSlack className="h-5 w-5 text-purple-700" />
                  <CardTitle className="text-sm">Slack</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Team communication, channels, message automation
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiNotion className="h-5 w-5 text-black" />
                  <CardTitle className="text-sm">Notion</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Knowledge bases, documents, database operations
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/20 border-yellow-200/30">
              <CardHeader className="pb-3">
                <div className="flex items-center gap-2">
                  <SiLinear className="h-5 w-5 text-blue-800" />
                  <CardTitle className="text-sm">Linear</CardTitle>
                </div>
                <CardDescription className="text-xs">
                  Issue tracking, project management, team workflows
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
          <div className="text-center mt-8">
            <Link href="/mcp-servers">
              <Button variant="outline" className="border-amber-700 hover:bg-amber-50 text-amber-900">
                View All MCP Servers
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Privacy Section */}
      <section className="py-20 px-4 bg-yellow-50/20">
        <div className="container mx-auto max-w-3xl text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <Shield className="h-6 w-6 text-yellow-600" />
            <h2 className="text-2xl font-bold font-display">
              Your Privacy, Protected
            </h2>
          </div>
          <p className="text-lg text-muted-foreground mb-6">
            We don't store your chats or user data. Your conversations with AI agents remain entirely on your device. 
            We only collect basic profile registration information needed to provide you access to the platform.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-yellow-600" />
              <span>No chat history stored</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-yellow-600" />
              <span>No user data collection</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-yellow-600" />
              <span>Profile info only</span>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <Footer />
    </div>
  )
}