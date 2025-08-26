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
      <section className="py-20 px-4 bg-gradient-to-br from-yellow-50/20 to-background">
        <div className="container mx-auto max-w-4xl text-center">
          {/* Hero Screenshot First */}
          <div className="mb-12">
            <div className="max-w-5xl mx-auto px-4">
              <div className="rounded-xl border bg-card p-1 md:p-3 shadow-2xl hover:shadow-3xl transition-shadow duration-300">
                <img 
                  src="/hero-app-screenshot.png" 
                  alt="Asmbli - Professional AI Agent Platform with Your Tools and MCP Integration"
                  className="w-full h-auto rounded-lg hover:scale-[1.02] transition-transform duration-300 object-contain max-h-[500px] md:max-h-[600px] lg:max-h-[700px]"
                />
              </div>
            </div>
          </div>

          {/* Hero Text */}
          <h1 className="text-5xl font-bold italic mb-6 font-display">
            Build and integrate custom AI agents into your workflow
          </h1>
          <p className="text-xl text-muted-foreground mb-8 max-w-3xl mx-auto">
            The only AI agent platform where integrations configure themselves automatically. 
            Connect your tools, deploy specialized agents, stay in control.
          </p>

          {/* Key Capabilities */}
          <div className="grid md:grid-cols-3 gap-6 mb-12 max-w-4xl mx-auto">
            <div className="text-center">
              <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <Zap className="h-6 w-6 text-amber-600" />
              </div>
              <h3 className="font-semibold mb-2">🎯 Your Tools</h3>
              <p className="text-sm text-muted-foreground">
                Immediately access your tools through MCP Servers. Set up your tool workflows naturally in the app.
              </p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <Bot className="h-6 w-6 text-amber-600" />
              </div>
              <h3 className="font-semibold mb-2">🚀 20+ Templates</h3>
              <p className="text-sm text-muted-foreground">
                Blockchain developer, UX designer, DevOps engineer, and more. Professional agents ready in seconds.
              </p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
                <Shield className="h-6 w-6 text-amber-600" />
              </div>
              <h3 className="font-semibold mb-2">🔒 Private & Secure</h3>
              <p className="text-sm text-muted-foreground">
                Your API key, your data, your agents. Everything runs locally with enterprise-grade security.
              </p>
            </div>
          </div>

          <div className="flex gap-4 justify-center">
            <Link href="#beta-signup">
              <Button size="lg" className="bg-amber-400 hover:bg-amber-500 text-amber-950">
                Get Early Access
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Link href="/templates">
              <Button size="lg" variant="outline">
                View Templates
              </Button>
            </Link>
          </div>
          
          {/* Status Bar */}
          <div className="mt-8 flex items-center justify-center gap-6 text-sm text-muted-foreground">
            <span className="flex items-center">
              <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
              Windows Available Now
            </span>
            <span className="flex items-center">
              <span className="w-2 h-2 bg-amber-400 rounded-full mr-2"></span>
              macOS Coming Soon
            </span>
            <span className="flex items-center">
              <Shield className="w-3 h-3 mr-1" />
              100% Private
            </span>
          </div>
        </div>
      </section>

      {/* Why Asmbli Section */}
      <section className="py-20 px-4 bg-yellow-50/10">
        <div className="container mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4 font-display">
              Why Asmbli?
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              The professional AI agent platform that actually works in your environment
            </p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl mx-auto">
            <Card className="text-center border-2 hover:border-amber-200 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Zap className="h-6 w-6 text-green-600" />
                </div>
                <CardTitle className="text-lg">Zero Setup</CardTitle>
                <CardDescription>
                  Auto-detects your tools. No configuration files, no YAML, no complex setup.
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="text-center border-2 hover:border-amber-200 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Code className="h-6 w-6 text-blue-600" />
                </div>
                <CardTitle className="text-lg">Real Integration</CardTitle>
                <CardDescription>
                  Connect to actual tools: Git repos, databases, Figma, Slack. Not just chat.
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="text-center border-2 hover:border-amber-200 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Bot className="h-6 w-6 text-purple-600" />
                </div>
                <CardTitle className="text-lg">Professional Agents</CardTitle>
                <CardDescription>
                  Specialized for real work: blockchain dev, UX design, DevOps, research.
                </CardDescription>
              </CardHeader>
            </Card>
            <Card className="text-center border-2 hover:border-amber-200 transition-colors">
              <CardHeader>
                <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
                  <Shield className="h-6 w-6 text-amber-600" />
                </div>
                <CardTitle className="text-lg">Your Control</CardTitle>
                <CardDescription>
                  Your API keys, your data, your agents. Nothing leaves your machine.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* Get Started Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-4xl text-center">
          <h2 className="text-3xl font-bold mb-6 font-display">
            Get Started in 3 Steps
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-amber-800">1</span>
              </div>
              <h3 className="font-semibold mb-2">Download Asmbli</h3>
              <p className="text-sm text-muted-foreground">
                Get the desktop app and sign in with beta access
              </p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-amber-800">2</span>
              </div>
              <h3 className="font-semibold mb-2">Add Your API Key</h3>
              <p className="text-sm text-muted-foreground">
                Connect Claude, GPT, or Gemini. Your key, your data, your control.
              </p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-2xl font-bold text-amber-800">3</span>
              </div>
              <h3 className="font-semibold mb-2">Pick an Agent & Chat</h3>
              <p className="text-sm text-muted-foreground">
                Choose a template or create custom. Auto-detection handles the rest.
              </p>
            </div>
          </div>
          
          <div className="mt-12">
            <Link href="#beta-signup">
              <Button size="lg" className="bg-amber-400 hover:bg-amber-500 text-amber-950">
                Start Building Agents
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* What's an API Key Section */}
      <section className="py-20 px-4 bg-yellow-50/10">
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
            <Card className="border-2 border-yellow-300/20 bg-yellow-50/10">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-yellow-500/10 rounded-lg flex items-center justify-center">
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
            <Card className="border-2 border-yellow-300/20 bg-yellow-50/10">
              <CardHeader>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-yellow-500/10 rounded-lg flex items-center justify-center">
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

                <div className="mt-6 p-4 bg-yellow-200/20 rounded-lg border border-yellow-300/20">
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
                <Button variant="outline" size="sm">
                  Get Anthropic API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
              <Link href="https://platform.openai.com/api-keys" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm">
                  Get OpenAI API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
              <Link href="https://makersuite.google.com/app/apikey" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="sm">
                  Get Google API Key
                  <ExternalLink className="ml-2 h-3 w-3" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* MCP Servers Library Section */}
      <section className="py-20 px-4 bg-yellow-50/10">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
            <Card className="hover:shadow-lg transition-shadow bg-yellow-50/10 border-yellow-200/20">
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
              <Button variant="outline">
                View All MCP Servers
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Beta Signup Section */}
      <section id="beta-signup" className="py-20 px-4 bg-gradient-to-br from-amber-50/30 to-yellow-50/30">
        <div className="container mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold mb-6 font-display">
            Join the Beta
          </h2>
          <p className="text-lg text-muted-foreground mb-8">
            Get early access to Asmbli's professional AI agent platform. 
            Beta users receive priority support and exclusive features.
          </p>
          
          <div className="bg-white rounded-xl shadow-lg p-8 border">
            <form className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <input
                    type="text"
                    placeholder="First Name"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-amber-400 focus:border-transparent"
                    required
                  />
                </div>
                <div>
                  <input
                    type="text"
                    placeholder="Last Name"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-amber-400 focus:border-transparent"
                    required
                  />
                </div>
              </div>
              <div>
                <input
                  type="email"
                  placeholder="Email Address"
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-amber-400 focus:border-transparent"
                  required
                />
              </div>
              <div>
                <textarea
                  placeholder="What would you like to use AI agents for? (Optional)"
                  rows={3}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-amber-400 focus:border-transparent resize-none"
                />
              </div>
              <Button 
                type="submit" 
                className="w-full bg-amber-400 hover:bg-amber-500 text-amber-950 py-3 text-lg"
              >
                Request Beta Access
              </Button>
            </form>
            
            <div className="mt-6 pt-6 border-t">
              <p className="text-sm text-muted-foreground mb-4">
                Already have beta access?
              </p>
              <Link href="/download">
                <Button variant="outline" className="w-full">
                  Go to Downloads
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
          
          <div className="mt-8 flex flex-col sm:flex-row gap-4 justify-center items-center text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-amber-500" />
              <span>Free beta access</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-amber-500" />
              <span>Priority support</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-amber-500" />
              <span>Exclusive features</span>
            </div>
          </div>
        </div>
      </section>

      {/* Privacy Section */}
      <section className="py-20 px-4 bg-yellow-50/10">
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