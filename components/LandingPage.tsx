import React from 'react';
import { Button } from './ui/button';
import { Card, CardContent } from './ui/card';
import { Badge } from './ui/badge';
import { 
  ArrowRight, 
  Sparkles, 
  Shield, 
  Zap, 
  Code2, 
  Users, 
  Globe, 
  CheckCircle, 
  Star,
  Library,
  Clock,
  Download,
  TrendingUp,
  Crown,
  Gift,
  Rocket,
  Eye,
  Heart,
  Plus,
  Building2,
  Layers,
  Network,
  BookOpen,
  Share2,
  Lightbulb,
  GraduationCap,
  Brain,
  Workflow,
  MessageSquare,
  Database,
  Bot,
  Cpu,
  GitBranch,
  Plug,
  Settings,
  ChevronRight,
  Terminal,
  Cloud,
  FileText,
  Search,
  Target,
  Cog,
  BookmarkPlus
} from 'lucide-react';

interface LandingPageProps {
  onGetStarted: () => void;
  onViewTemplates?: () => void;
}

export function LandingPage({ onGetStarted, onViewTemplates }: LandingPageProps) {
  const features = [
    {
      icon: Code2,
      title: "Universal Agent Builder",
      description: "Create AI agents that work across Claude Desktop, Copilot Studio, Power Platform, and custom APIs with zero configuration complexity."
    },
    {
      icon: Shield,
      title: "Enterprise Security",
      description: "Built-in OAuth 2.1, mTLS, and vault integration with HashiCorp Vault, AWS Secrets Manager, and 1Password support."
    },
    {
      icon: Zap,
      title: "One-Click Deployment",
      description: "Deploy to desktop extensions, Docker Compose, Kubernetes, or raw JSON with automated configuration generation."
    },
    {
      icon: Globe,
      title: "Multi-Platform Extensions",
      description: "13+ real company integrations including GitHub, Slack, Notion, Linear, and more with seamless authentication flows."
    },
    {
      icon: Sparkles,
      title: "AI-Powered Optimization",
      description: "Intelligent prompt generation, behavioral tuning, and performance optimization based on your specific use cases."
    },
    {
      icon: Target,
      title: "Template System",
      description: "Save and reuse your agent configurations as templates. Build once, deploy everywhere with consistent results."
    }
  ];

  const stats = [
    { number: "500+", label: "Agentic Combinations" },
    { number: "Alpha", label: "Version" },
    { number: "13+", label: "Platform Integrations" }
  ];

  const testimonials = [
    {
      quote: "This could completely change how we think about AI agent deployment. The vision is exactly what the industry needs.",
      author: "Alex Shulko",
      role: "Senior Architect",
      company: "nvisia"
    },
    {
      quote: "The prototype shows incredible promise. If they can execute on this vision, it'll be revolutionary for enterprise AI.",
      author: "Shawn Spartz",
      role: "AI Research Director",
      company: "nvisia"
    },
    {
      quote: "Finally, someone is tackling the real complexity of multi-platform AI agents. Early days, but the potential is massive.",
      author: "Patricia Yee",
      role: "Technical Sales Director",
      company: "Articulate"
    }
  ];

  const useCases = [
    {
      id: 1,
      icon: Building2,
      title: "Enterprise Automation",
      description: "Build agents that automate complex business workflows across multiple systems and platforms.",
      examples: ["HR onboarding workflows", "Customer support automation", "Sales pipeline management"]
    },
    {
      id: 2,
      icon: Code2,
      title: "Developer Productivity",
      description: "Create specialized coding assistants that understand your codebase and integrate with your development tools.",
      examples: ["Code review automation", "Documentation generation", "Bug triage and routing"]
    },
    {
      id: 3,
      icon: Cog,
      title: "Custom AI Solutions",
      description: "Design domain-specific agents tailored to your industry needs with specialized knowledge and capabilities.",
      examples: ["Financial analysis", "Medical research", "Legal document processing"]
    }
  ];

  // How It Works workflow steps
  const workflowSteps = [
    {
      id: 1,
      icon: MessageSquare,
      title: "You Chat with an LLM",
      description: "You ask ChatGPT, Claude, or any LLM to help with a task",
      example: "\"Help me analyze my sales data and create a report\"",
      color: "#10B981"
    },
    {
      id: 2,
      icon: Bot,
      title: "LLM Creates an AI Agent",
      description: "The LLM breaks down your request and creates a specialized agent to handle it",
      example: "Creates a \"Sales Analysis Agent\" with specific capabilities",
      color: "#6366F1"
    },
    {
      id: 3,
      icon: Workflow,
      title: "Agent Uses Tools",
      description: "The agent connects to tools and services through APIs and MCP to accomplish the task",
      example: "Connects to your CRM, spreadsheet tools, and report generators",
      color: "#F59E0B"
    },
    {
      id: 4,
      icon: CheckCircle,
      title: "Task Completed",
      description: "The agent completes your request using the right combination of tools and returns the results",
      example: "Delivers a complete sales analysis report with charts and insights",
      color: "#EF4444"
    }
  ];

  const toolTypes = [
    {
      icon: Database,
      title: "Data Sources",
      description: "Connect to databases, spreadsheets, and data warehouses",
      examples: ["PostgreSQL", "Google Sheets", "Snowflake", "Airtable"]
    },
    {
      icon: Cloud,
      title: "Cloud Services",
      description: "Integrate with cloud platforms and SaaS applications",
      examples: ["AWS", "GitHub", "Slack", "Notion"]
    },
    {
      icon: Terminal,
      title: "Development Tools",
      description: "Access code repositories, CI/CD, and development workflows",
      examples: ["Git", "Docker", "Jenkins", "VS Code"]
    },
    {
      icon: FileText,
      title: "Content & Documents",
      description: "Process documents, generate content, and manage files",
      examples: ["PDF parsing", "Word docs", "Image processing", "Text generation"]
    }
  ];

  return (
    <div className="min-h-screen bg-background relative overflow-hidden">
      {/* Background Depth Layers */}
      <div className="fixed inset-0 z-0">
        {/* Main gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-background via-background to-background/95" />
        
        {/* Blur depth layer 1 - Large orbs */}
        <div className="absolute inset-0">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl animate-pulse" 
               style={{ animationDuration: '4s' }} />
          <div className="absolute top-3/4 right-1/4 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl animate-pulse" 
               style={{ animationDuration: '6s', animationDelay: '2s' }} />
          <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-pink-500/3 rounded-full blur-3xl animate-pulse" 
               style={{ animationDuration: '5s', animationDelay: '1s' }} />
        </div>
        
        {/* Blur depth layer 2 - Medium orbs */}
        <div className="absolute inset-0">
          <div className="absolute top-1/6 right-1/3 w-48 h-48 bg-primary/8 rounded-full blur-2xl" />
          <div className="absolute bottom-1/4 left-1/6 w-56 h-56 bg-purple-400/6 rounded-full blur-2xl" />
          <div className="absolute top-2/3 right-1/6 w-40 h-40 bg-indigo-500/7 rounded-full blur-2xl" />
        </div>
        
        {/* Shimmer wave layer */}
        <div className="absolute inset-0 opacity-30">
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-primary/5 to-transparent animate-shimmer" 
               style={{ 
                 background: 'linear-gradient(90deg, transparent, rgba(99, 102, 241, 0.02), transparent)',
                 backgroundSize: '200% 100%',
                 animation: 'shimmer-wave 8s ease-in-out infinite'
               }} />
        </div>
        
        {/* Secondary shimmer wave */}
        <div className="absolute inset-0 opacity-20">
          <div className="absolute inset-0 bg-gradient-to-l from-transparent via-purple-400/3 to-transparent"
               style={{ 
                 background: 'linear-gradient(-90deg, transparent, rgba(147, 51, 234, 0.015), transparent)',
                 backgroundSize: '150% 100%',
                 animation: 'shimmer-wave-reverse 12s ease-in-out infinite'
               }} />
        </div>
        
        {/* Noise texture overlay */}
        <div className="absolute inset-0 opacity-[0.02] bg-gradient-to-br from-white to-transparent mix-blend-overlay" />
      </div>

      {/* Header */}
      <header className="fixed top-0 w-full z-50 backdrop-blur-2xl bg-background/40 border-b border-border/30 shadow-lg shadow-black/5">
        <div className="max-width-container responsive-padding">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-2">
              <span className="font-bold text-xl bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent font-[Noto_Sans_JP] text-[20px] not-italic">
             Agent/Engine  
              </span>
            </div>
            <div className="hidden md:flex items-center space-x-8">
              <a href="#features" className="text-muted-foreground hover:text-foreground transition-colors">Features</a>
              <a href="#how-it-works" className="text-muted-foreground hover:text-foreground transition-colors">How It Works</a>
              <a href="#use-cases" className="text-muted-foreground hover:text-foreground transition-colors">Use Cases</a>
              <a href="#templates" className="text-muted-foreground hover:text-foreground transition-colors">Templates</a>
              <Button onClick={onGetStarted} className="bg-primary hover:bg-primary/90">
                Try Early Access
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="pt-32 pb-20 responsive-padding relative z-10">
        <div className="max-width-container">
          <div className="text-center space-y-8 max-w-4xl mx-auto">
            <div className="space-y-4">
              <Badge className="bg-primary/10 text-primary border-primary/30 px-4 py-2 text-sm">
                Early Access • Enterprise-Ready
              </Badge>
              <h1 className="text-5xl md:text-7xl font-bold tracking-tight font-[Noto_Sans_JP]">
                Build Powerful AI Agents
                <span className="bg-gradient-to-r from-primary via-purple-400 to-pink-400 bg-clip-text text-transparent block m-[0px] px-[0px] py-[16px]">
                  For Any Platform
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
                The complete toolkit for designing, building, and deploying AI agents that work seamlessly across 
                Claude Desktop, Microsoft Copilot, and your custom applications.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-8">
              <Button 
                onClick={onGetStarted}
                size="lg" 
                className="bg-primary hover:bg-primary/90 text-lg px-8 py-6 h-auto group"
              >
                <Rocket className="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" />
                Start Building Your Agent
                <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
              </Button>
              <Button 
                onClick={onViewTemplates}
                variant="outline" 
                size="lg"
                className="text-lg px-8 py-6 h-auto border-primary/30 hover:bg-primary/5 group"
              >
                <Library className="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" />
                Browse Templates
              </Button>
            </div>

            <div className="flex items-center justify-center gap-8 pt-12 text-sm text-muted-foreground">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-success" />
                Enterprise Security
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-success" />
                Multi-Platform Deploy
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-success" />
                Zero Configuration
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-12 border-y border-border/30 backdrop-blur-sm bg-background/20 relative z-10">
        <div className="max-width-container responsive-padding">
          <div className="grid grid-cols-2 md:grid-cols-3 gap-8 text-center">
            {stats.map((stat, index) => (
              <div key={index} className="space-y-2">
                <div className="text-3xl md:text-4xl font-bold bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
                  {stat.number}
                </div>
                <div className="text-muted-foreground">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="py-20 responsive-padding relative z-10">
        <div className="max-width-container">
          <div className="text-center space-y-8 mb-16">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Badge className="bg-gradient-to-r from-green-500/20 to-blue-500/20 text-primary border-primary/30 px-4 py-2">
                <Brain className="w-4 h-4 mr-2" />
                How AI Agents Work
              </Badge>
            </div>
            
            <h2 className="text-4xl md:text-6xl font-bold font-[Noto_Sans_JP] mt-[0px] mr-[0px] mb-[37px] ml-[0px]">
              Understanding AI Agents:
              <span className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent block italic font-bold mx-[0px] my-[10px]">
                From Chat to Action
              </span>
            </h2>
            
            <p className="text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
              Ever wondered how AI assistants actually get things done? Here's the journey from your simple chat message 
              to real-world results, and how you can build your own specialized agents.
            </p>
          </div>

          {/* Workflow Steps */}
          <div className="space-y-12 mb-16">
            <div className="text-center">
              <h3 className="text-2xl font-bold mb-4">The AI Agent Workflow</h3>
              <p className="text-muted-foreground max-w-2xl mx-auto">
                Every time you interact with an AI assistant, this process happens behind the scenes
              </p>
            </div>

            <div className="relative">
              {/* Connecting lines for larger screens */}
              <div className="hidden lg:block absolute top-16 left-0 right-0 h-0.5 bg-gradient-to-r from-green-500 via-primary via-yellow-500 to-red-500 opacity-30"></div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                {workflowSteps.map((step, index) => {
                  const Icon = step.icon;
                  return (
                    <div key={step.id} className="relative">
                      {/* Step connector for mobile */}
                      {index < workflowSteps.length - 1 && (
                        <div className="lg:hidden absolute left-1/2 -translate-x-1/2 top-full h-8 w-0.5 bg-gradient-to-b from-current to-transparent opacity-30 mt-4"></div>
                      )}
                      
                      <Card className="selection-card h-full text-center">
                        <CardContent className="p-6 space-y-4">
                          {/* Step number and icon */}
                          <div className="flex items-center justify-center gap-3">
                            <div 
                              className="w-8 h-8 rounded-full flex items-center justify-center text-white font-bold text-sm"
                              style={{ backgroundColor: step.color }}
                            >
                              {step.id}
                            </div>
                            <div 
                              className="w-12 h-12 rounded-xl flex items-center justify-center"
                              style={{ backgroundColor: step.color + '20' }}
                            >
                              <Icon className="w-6 h-6" style={{ color: step.color }} />
                            </div>
                          </div>
                          
                          <div className="space-y-3">
                            <h4 className="text-lg font-semibold">{step.title}</h4>
                            <p className="text-muted-foreground text-sm leading-relaxed">
                              {step.description}
                            </p>
                            
                            {/* Example */}
                            <div className="bg-muted/50 rounded-lg p-3 mt-4">
                              <p className="text-xs text-muted-foreground mb-1">Example:</p>
                              <p className="text-sm italic">"{step.example}"</p>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* What Are Tools? Section */}
          <div className="space-y-12">
            <div className="text-center space-y-4">
              <Badge className="bg-yellow-500/20 text-yellow-400 border-yellow-400/30">
                <Plug className="w-4 h-4 mr-2" />
                Tools & APIs
              </Badge>
              <h3 className="text-3xl font-bold">What Are "Tools" Exactly?</h3>
              <p className="text-muted-foreground max-w-3xl mx-auto text-lg">
                Tools are the secret sauce that make AI agents actually useful. They're connections to real services 
                and applications that let agents do more than just chat—they can take action.
              </p>
            </div>

            {/* Tool Types Grid */}
            <div className="responsive-grid-4">
              {toolTypes.map((toolType, index) => {
                const Icon = toolType.icon;
                return (
                  <Card key={index} className="selection-card">
                    <CardContent className="p-6 space-y-4">
                      <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center">
                        <Icon className="w-6 h-6 text-primary" />
                      </div>
                      
                      <div className="space-y-2">
                        <h4 className="font-semibold">{toolType.title}</h4>
                        <p className="text-muted-foreground text-sm leading-relaxed">
                          {toolType.description}
                        </p>
                      </div>
                      
                      <div className="space-y-2">
                        <p className="text-xs font-medium text-muted-foreground">Popular Examples:</p>
                        <div className="flex flex-wrap gap-1">
                          {toolType.examples.map((example, idx) => (
                            <Badge key={idx} variant="secondary" className="text-xs">
                              {example}
                            </Badge>
                          ))}
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>

          {/* MCP Explanation */}
          <div className="mt-16 space-y-8">
            <Card className="selection-card bg-gradient-to-br from-blue-500/10 to-purple-500/10">
              <CardContent className="p-8 space-y-6">
                <div className="text-center space-y-4">
                  <Badge className="bg-blue-500/20 text-blue-400 border-blue-400/30">
                    <Settings className="w-4 h-4 mr-2" />
                    Model Context Protocol (MCP)
                  </Badge>
                  <h3 className="text-2xl font-bold">The Future of AI Agent Tools</h3>
                </div>
                
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
                  <div className="space-y-4">
                    <p className="text-muted-foreground leading-relaxed">
                      <strong className="text-foreground">MCP</strong> is a new standard that makes it incredibly easy for AI agents 
                      to connect to any service or tool. Think of it as a universal translator that lets agents understand 
                      and use any software, from your email to your spreadsheets to your code repositories.
                    </p>
                    
                    <div className="space-y-3">
                      <div className="flex items-start gap-3">
                        <CheckCircle className="w-5 h-5 text-success mt-0.5 flex-shrink-0" />
                        <div>
                          <p className="font-medium">Universal Compatibility</p>
                          <p className="text-sm text-muted-foreground">One agent can work with any MCP-compatible service</p>
                        </div>
                      </div>
                      <div className="flex items-start gap-3">
                        <CheckCircle className="w-5 h-5 text-success mt-0.5 flex-shrink-0" />
                        <div>
                          <p className="font-medium">Secure by Design</p>
                          <p className="text-sm text-muted-foreground">Built-in authentication and permission controls</p>
                        </div>
                      </div>
                      <div className="flex items-start gap-3">
                        <CheckCircle className="w-5 h-5 text-success mt-0.5 flex-shrink-0" />
                        <div>
                          <p className="font-medium">Easy Integration</p>
                          <p className="text-sm text-muted-foreground">Connect new tools without complex configuration</p>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="bg-background/50 rounded-xl p-6">
                    <h4 className="font-semibold mb-4">Real-World Example</h4>
                    <div className="space-y-3 text-sm">
                      <div className="flex items-center gap-2">
                        <MessageSquare className="w-4 h-4 text-blue-400" />
                        <span className="text-muted-foreground">You: "Create a project plan for our mobile app"</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <ArrowRight className="w-4 h-4 text-primary" />
                        <span className="text-muted-foreground">Agent connects to Notion (via MCP)</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <ArrowRight className="w-4 h-4 text-primary" />
                        <span className="text-muted-foreground">Agent connects to GitHub (via MCP)</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <ArrowRight className="w-4 h-4 text-primary" />
                        <span className="text-muted-foreground">Agent connects to Calendar (via MCP)</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-success" />
                        <span className="text-success">Complete project plan created across all tools!</span>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Why This Matters */}
          <div className="mt-16 text-center space-y-8">
            <div className="space-y-4">
              <h3 className="text-3xl font-bold">Why AgentEngine?</h3>
              <p className="text-muted-foreground max-w-3xl mx-auto text-lg">
                Building AI agents from scratch is complex. AgentEngine simplifies the entire process, 
                from design to deployment, so you can focus on solving problems instead of managing infrastructure.
              </p>
            </div>

            <div className="bg-gradient-to-r from-primary/10 to-purple-500/10 rounded-xl p-8">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
                <div className="space-y-2">
                  <Rocket className="w-8 h-8 text-primary mx-auto" />
                  <h4 className="font-semibold">Build Once, Deploy Everywhere</h4>
                  <p className="text-sm text-muted-foreground">Create agents that work across multiple platforms seamlessly</p>
                </div>
                <div className="space-y-2">
                  <Shield className="w-8 h-8 text-primary mx-auto" />
                  <h4 className="font-semibold">Enterprise-Ready Security</h4>
                  <p className="text-sm text-muted-foreground">Built-in security controls and compliance features</p>
                </div>
                <div className="space-y-2">
                  <Zap className="w-8 h-8 text-primary mx-auto" />
                  <h4 className="font-semibold">Zero Configuration</h4>
                  <p className="text-sm text-muted-foreground">Automated setup and deployment without technical complexity</p>
                </div>
              </div>
            </div>

            <Button 
              onClick={onGetStarted}
              size="lg" 
              className="bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 text-lg px-8 py-6 h-auto group shadow-lg shadow-primary/20"
            >
              <Lightbulb className="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" />
              Start Building Your Agent
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </Button>
          </div>
        </div>
      </section>

      {/* Use Cases Section */}
      <section id="use-cases" className="py-20 responsive-padding relative z-10 bg-gradient-to-br from-primary/5 via-transparent to-purple-500/5">
        <div className="max-width-container">
          <div className="text-center space-y-8 mb-16">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Badge className="bg-gradient-to-r from-purple-500/20 to-primary/20 text-primary border-primary/30 px-4 py-2">
                <Target className="w-4 h-4 mr-2" />
                Use Cases
              </Badge>
            </div>
            
            <h2 className="text-4xl md:text-6xl font-bold font-[Noto_Sans_JP]">
              Built for real-world problems.
              <span className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent block italic font-bold">
                Designed for your needs.
              </span>
            </h2>
            
            <p className="text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
              Whether you're automating business processes, enhancing developer productivity, 
              or building custom AI solutions, AgentEngine provides the foundation you need.
            </p>
          </div>

          <div className="responsive-grid-3">
            {useCases.map((useCase) => {
              const Icon = useCase.icon;
              return (
                <Card key={useCase.id} className="selection-card border-border/40 hover:border-primary/40 group backdrop-blur-xl bg-background/80 hover:bg-background/90 shadow-lg shadow-black/5 relative overflow-hidden">
                  <CardContent className="p-6 space-y-4">
                    <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                      <Icon className="w-6 h-6 text-primary" />
                    </div>
                    
                    <div className="space-y-2">
                      <h4 className="text-xl font-semibold group-hover:text-primary transition-colors">
                        {useCase.title}
                      </h4>
                      <p className="text-muted-foreground leading-relaxed">
                        {useCase.description}
                      </p>
                    </div>

                    <div className="space-y-2 pt-2">
                      <p className="text-sm font-medium text-muted-foreground">Example Applications:</p>
                      <div className="space-y-1">
                        {useCase.examples.map((example, idx) => (
                          <div key={idx} className="text-sm text-muted-foreground flex items-center gap-2">
                            <div className="w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0" />
                            {example}
                          </div>
                        ))}
                      </div>
                    </div>
                  </CardContent>

                  {/* Gradient overlay for premium feel */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/2 via-transparent to-purple-500/2 pointer-events-none" />
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 responsive-padding relative z-10">
        <div className="max-width-container">
          <div className="text-center space-y-4 mb-16">
            <Badge className="bg-primary/10 text-primary border-primary/30">Platform Features</Badge>
            <h2 className="text-4xl md:text-5xl font-bold">
              Everything you need to build AI agents
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              From design to deployment, AgentEngine provides enterprise-grade tools 
              for building sophisticated AI agents at scale.
            </p>
          </div>

          <div className="responsive-grid-3">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card key={index} className="selection-card border-border/40 hover:border-primary/40 group backdrop-blur-xl bg-background/60 hover:bg-background/80 shadow-lg shadow-black/5">
                  <CardContent className="p-6 space-y-4">
                    <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                      <Icon className="w-6 h-6 text-primary" />
                    </div>
                    <h3 className="text-xl font-semibold">{feature.title}</h3>
                    <p className="text-muted-foreground leading-relaxed">
                      {feature.description}
                    </p>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Templates Section */}
      <section id="templates" className="py-20 responsive-padding relative z-10 bg-muted/10 backdrop-blur-sm">
        <div className="max-width-container">
          <div className="text-center space-y-8 mb-16">
            <div className="flex items-center justify-center gap-2 mb-4">
              <Badge className="bg-gradient-to-r from-orange-500/20 to-red-500/20 text-primary border-primary/30 px-4 py-2">
                <Library className="w-4 h-4 mr-2" />
                Template System
              </Badge>
            </div>
            
            <h2 className="text-4xl md:text-6xl font-bold font-[Noto_Sans_JP]">
              Start faster with templates.
              <span className="bg-gradient-to-r from-orange-500 to-red-500 bg-clip-text text-transparent block italic font-bold">
                Save time, share knowledge.
              </span>
            </h2>
            
            <p className="text-xl text-muted-foreground max-w-3xl mx-auto leading-relaxed">
              Use pre-built templates to accelerate development, or create and save your own configurations 
              as reusable templates for consistent deployments.
            </p>
          </div>

          <div className="text-center space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center max-w-4xl mx-auto">
              <div className="space-y-2">
                <Library className="w-8 h-8 text-primary mx-auto" />
                <h4 className="font-semibold">Pre-built Templates</h4>
                <p className="text-sm text-muted-foreground">Start with proven configurations for common use cases</p>
              </div>
              <div className="space-y-2">
                <BookmarkPlus className="w-8 h-8 text-primary mx-auto" />
                <h4 className="font-semibold">Save Your Work</h4>
                <p className="text-sm text-muted-foreground">Turn any agent configuration into a reusable template</p>
              </div>
              <div className="space-y-2">
                <Share2 className="w-8 h-8 text-primary mx-auto" />
                <h4 className="font-semibold">Share & Collaborate</h4>
                <p className="text-sm text-muted-foreground">Export templates to share with your team or community</p>
              </div>
            </div>

            <Button 
              onClick={onViewTemplates}
              size="lg" 
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-500/90 hover:to-red-500/90 text-lg px-8 py-6 h-auto group shadow-lg shadow-orange-500/20"
            >
              <Library className="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" />
              Browse Templates
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </Button>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-muted/10 backdrop-blur-sm responsive-padding relative z-10">
        <div className="max-width-container">
          <div className="text-center space-y-4 mb-16">
            <Badge className="bg-primary/10 text-primary border-primary/30">Early Feedback</Badge>
            <h2 className="text-4xl md:text-5xl font-bold">
              Industry leaders see the potential
            </h2>
          </div>

          <div className="responsive-grid-3">
            {testimonials.map((testimonial, index) => (
              <Card key={index} className="selection-card border-border/40 backdrop-blur-xl bg-background/60 shadow-lg shadow-black/5">
                <CardContent className="p-6 space-y-4">
                  <div className="flex gap-1 mb-4">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 fill-yellow-500 text-yellow-500" />
                    ))}
                  </div>
                  <blockquote className="text-muted-foreground italic leading-relaxed">
                    "{testimonial.quote}"
                  </blockquote>
                  <div className="border-t border-border/50 pt-4 space-y-1">
                    <div className="font-semibold">{testimonial.author}</div>
                    <div className="text-sm text-muted-foreground">
                      {testimonial.role} at {testimonial.company}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 responsive-padding relative z-10">
        <div className="max-width-container">
          <Card className="selection-card border-primary/40 bg-gradient-to-br from-primary/8 to-purple-500/8 backdrop-blur-xl shadow-xl shadow-primary/5">
            <CardContent className="p-12 text-center space-y-8">
              <div className="space-y-4">
                <h2 className="text-4xl md:text-5xl font-bold">
                  Ready to build your AI agent?
                </h2>
                <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
                  Join the early access program and start building powerful AI agents 
                  that work seamlessly across any platform.
                </p>
              </div>
              
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                <Button 
                  onClick={onGetStarted}
                  size="lg" 
                  className="bg-primary hover:bg-primary/90 text-lg px-8 py-6 h-auto group"
                >
                  <Rocket className="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" />
                  Start Building
                  <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
                </Button>
                <Button 
                  onClick={onViewTemplates}
                  variant="outline" 
                  size="lg"
                  className="text-lg px-8 py-6 h-auto border-primary/30 hover:bg-primary/5"
                >
                  <Library className="w-5 h-5 mr-2" />
                  Explore Templates
                </Button>
              </div>

              <div className="flex items-center justify-center gap-8 pt-8 text-sm text-muted-foreground">
                <div className="flex items-center gap-2">
                  <Shield className="w-4 h-4 text-success" />
                  Enterprise Security
                </div>
                <div className="flex items-center gap-2">
                  <Zap className="w-4 h-4 text-success" />
                  Zero Configuration
                </div>
                <div className="flex items-center gap-2">
                  <Globe className="w-4 h-4 text-success" />
                  Multi-Platform
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-border/30 backdrop-blur-sm bg-background/20 responsive-padding relative z-10">
        <div className="max-width-container">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <span className="font-semibold bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
                AgentEngine
              </span>
            </div>
            <div className="text-sm text-muted-foreground">
              © 2025 AgentEngine. Empowering the future of AI agents.
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}