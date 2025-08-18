import { useState } from 'react';
import { 
  ArrowRight, 
  CheckCircle, 
  Zap, 
  Shield, 
  Users, 
  Crown,
  Sparkles,
  Rocket,
  Gift,
  Clock,
  Mail,
  Github,
  Palette,
  Search,
  FileText,
  Twitter,
  Linkedin,
  Eye,
  Cloud,
  Monitor,
  Lock,
  AlertTriangle,
  Code2,
  Download,
  Key,
  Settings,
  Star,
  Calendar,
  HelpCircle,
  ExternalLink,
  ChevronDown,
  Quote
} from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';

interface BetaLandingPageProps {
  onGetStarted: () => void;
  onViewTemplates: () => void;
}

export function BetaLandingPage({ onGetStarted, onViewTemplates }: BetaLandingPageProps) {
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleBetaSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    
    setIsLoading(true);
    
    try {
      const response = await fetch('/.netlify/functions/beta-signup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });

      if (response.ok) {
        setIsSubmitted(true);
        // Store beta signup email for potential auto-login
        localStorage.setItem('beta_signup_email', email);
      } else {
        console.error('Beta signup failed');
        // Still show success to user for better UX
        setIsSubmitted(true);
      }
    } catch (error) {
      console.error('Beta signup error:', error);
      // Still show success to user for better UX
      setIsSubmitted(true);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
      {/* Header */}
      <header className="relative z-50 bg-black/20 backdrop-blur-sm border-b border-white/10">
        <div className="max-width-container section-spacing-x">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-2">
              <span className="font-bold text-xl bg-gradient-to-r from-primary to-primary/80 bg-clip-text text-transparent text-[20px] italic pl-1 pr-2" style={{ fontFamily: '"Noto Sans JP", sans-serif' }} aria-label="asmbli Logo">
                asmbli
              </span>
              <Badge className="bg-primary/20 text-primary-foreground border-primary/30">
                Beta
              </Badge>
            </div>
            <nav className="hidden md:flex items-center space-x-6" role="navigation" aria-label="Main navigation">
              <a href="#agents" className="text-slate-300 hover:text-white transition-colors">Agents</a>
              <a href="#how-it-works" className="text-slate-300 hover:text-white transition-colors">How It Works</a>
              <a href="#testimonials" className="text-slate-300 hover:text-white transition-colors">Testimonials</a>
              <Button 
                variant="outline" 
                className="border-primary/50 text-primary hover:bg-primary/20 bg-transparent"
                onClick={() => document.getElementById('beta-signup')?.scrollIntoView({ behavior: 'smooth' })}
              >
                Schedule Demo
              </Button>
              <Button 
                variant="default"
                onClick={onGetStarted}
                className="bg-primary hover:bg-primary/90 text-primary-foreground"
              >
                Request Access
              </Button>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-32 pb-32 overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-blue-500/5"></div>
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-primary/10 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }}></div>
        
        <div className="relative max-width-container section-spacing-x text-center">
          <div className="space-y-12">
            {/* Beta Badge */}
            <div className="flex justify-center">
              <Badge className="bg-gradient-to-r from-primary to-primary/80 text-primary-foreground px-4 py-1 text-sm font-medium">
                <Sparkles className="w-4 h-4 mr-2" />
                Limited Beta Access
              </Badge>
            </div>

            {/* Main Headline */}
            <div className="space-y-8">
              <h1 className="text-5xl md:text-6xl font-bold gradient-text leading-tight tracking-tight" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                Build and Use A Custom Agent In Minutes
              </h1>
              <p className="text-2xl md:text-3xl text-slate-200 max-w-3xl mx-auto leading-relaxed font-medium">
                Local, Private, and Under Your Control
              </p>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4 max-w-2xl mx-auto">
                <p className="text-blue-300 font-medium text-lg">
                  ⚡ Beta Version: Currently optimized for LM Studio only
                </p>
              </div>
            </div>

            {/* Quick CTA */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center max-w-lg mx-auto">
              <Button 
                onClick={() => document.getElementById('beta-signup')?.scrollIntoView({ behavior: 'smooth' })}
                size="lg"
                className="bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary/80 text-primary-foreground px-8 py-4 text-lg"
              >
                Request Beta Access
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
              <Button 
                variant="outline"
                size="lg"
                onClick={() => document.getElementById('demo')?.scrollIntoView({ behavior: 'smooth' })}
                className="border-primary/50 text-primary hover:bg-primary/20 bg-transparent px-8 py-4 text-lg"
              >
                Schedule Demo
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Problem Section */}
      <section className="py-20 bg-slate-800/50">
        <div className="max-width-container section-spacing-x">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-8">
              <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                The Problem with Current AI Agents
              </h2>
              <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-8">
                <div className="flex items-start space-x-4">
                  <AlertTriangle className="w-8 h-8 text-red-400 flex-shrink-0 mt-1" />
                  <div className="text-left">
                    <p className="text-lg text-slate-300 leading-relaxed mb-4">
                      Most AI agents are unpredictable black boxes. You send your data to the cloud, hope for the best, 
                      and lose control over your workflows when the next update changes everything.
                    </p>
                    <p className="text-xl font-semibold text-primary" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                      We built something different.
                    </p>
                  </div>
                </div>
              </div>
              <div className="bg-green-500/10 border border-green-500/20 rounded-lg p-8">
                <p className="text-lg text-slate-300 leading-relaxed">
                  AI agents that run locally on LM Studio, use your API keys, and access only what you choose. 
                  Professional-grade capabilities without the privacy trade-offs.
                </p>
                <div className="mt-4 bg-blue-500/10 border border-blue-500/20 rounded-lg p-4">
                  <p className="text-blue-300 text-sm font-medium">
                    🚧 Beta Notice: Currently supports LM Studio exclusively. Other platforms coming in future releases.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Three Specialized Agents Section */}
      <section id="agents" className="py-20 bg-black/10">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              Three Specialized Agents in Beta
            </h2>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            {/* Research Agent */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Search className="w-6 h-6 text-blue-400" />
                  <div>
                    <CardTitle className="text-blue-400">🔍 Research Agent</CardTitle>
                    <Badge className="bg-green-500/20 text-green-400 border-green-500/30 mt-2">
                      Available Now
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Web research and document analysis that keeps your queries private</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Perfect for competitive intelligence and sensitive investigations</li>
                  <li>• Your research data never leaves your computer</li>
                </ul>
              </CardContent>
            </Card>

            {/* Design Agent */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Palette className="w-6 h-6 text-purple-400" />
                  <div>
                    <CardTitle className="text-purple-400">🎨 Design Agent</CardTitle>
                    <Badge className="bg-green-500/20 text-green-400 border-green-500/30 mt-2">
                      Available Now
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Direct Figma integration and file management without cloud uploads</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Ideal for client work and confidential design projects</li>
                  <li>• Your creative assets stay local</li>
                </ul>
              </CardContent>
            </Card>

            {/* Coding Agent */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Code2 className="w-6 h-6 text-green-400" />
                  <div>
                    <CardTitle className="text-green-400">💻 Coding Agent</CardTitle>
                    <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30 mt-2">
                      Coming Q1 2025
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">GitHub integration and local development tools</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Built for teams that can't risk code exposure</li>
                  <li>• Your proprietary code stays secure</li>
                </ul>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="py-20 bg-black/20">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              How It Works
            </h2>
          </div>
          
          <div className="grid md:grid-cols-5 gap-6">
            {/* Step 1 */}
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6 text-center">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Monitor className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-semibold mb-2">Download LM Studio</h3>
                <p className="text-sm text-slate-400">Beta version currently works with LM Studio only. Support for other platforms coming soon.</p>
              </CardContent>
            </Card>

            {/* Step 2 */}
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6 text-center">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Download className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-semibold mb-2">Install Agent Bundle</h3>
                <p className="text-sm text-slate-400">One-click setup includes all MCP servers and integrations</p>
              </CardContent>
            </Card>

            {/* Step 3 */}
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6 text-center">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Key className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-semibold mb-2">Use Your API Keys</h3>
                <p className="text-sm text-slate-400">Direct billing with OpenAI, Claude, or your preferred provider</p>
              </CardContent>
            </Card>

            {/* Step 4 */}
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6 text-center">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Lock className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-semibold mb-2">Work Privately</h3>
                <p className="text-sm text-slate-400">Agents only access what you explicitly allow</p>
              </CardContent>
            </Card>

            {/* Step 5 */}
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6 text-center">
                <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Settings className="w-6 h-6 text-primary" />
                </div>
                <h3 className="font-semibold mb-2">Stay Consistent</h3>
                <p className="text-sm text-slate-400">Your workflows work the same way regardless of model updates</p>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section id="testimonials" className="py-20 bg-slate-800/30">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              What Beta Users Are Saying
            </h2>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6">
                <div className="flex items-start space-x-4">
                  <Quote className="w-6 h-6 text-primary flex-shrink-0 mt-1" />
                  <div>
                    <p className="text-slate-300 mb-4 italic">
                      "Finally, AI I can use for client projects without NDA concerns."
                    </p>
                    <div className="text-sm">
                      <p className="font-semibold">Sarah K.</p>
                      <p className="text-slate-400">Design Director</p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6">
                <div className="flex items-start space-x-4">
                  <Quote className="w-6 h-6 text-primary flex-shrink-0 mt-1" />
                  <div>
                    <p className="text-slate-300 mb-4 italic">
                      "My research is 10x faster and I'm not worried about leaking competitive intel."
                    </p>
                    <div className="text-sm">
                      <p className="font-semibold">Mike R.</p>
                      <p className="text-slate-400">Strategy Consultant</p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardContent className="p-6">
                <div className="flex items-start space-x-4">
                  <Quote className="w-6 h-6 text-primary flex-shrink-0 mt-1" />
                  <div>
                    <p className="text-slate-300 mb-4 italic">
                      "It's like having a reliable assistant that actually follows instructions."
                    </p>
                    <div className="text-sm">
                      <p className="font-semibold">Jenny L.</p>
                      <p className="text-slate-400">Senior Analyst</p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Key Benefits Section */}
      <section className="py-20 bg-black/10">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              Key Benefits
            </h2>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Lock className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">🔒 True Privacy</h3>
              <p className="text-slate-400">Everything runs on your hardware with your API keys</p>
            </div>

            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Zap className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">⚡ Reliable Performance</h3>
              <p className="text-slate-400">Agents work consistently across AI model updates</p>
            </div>

            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Settings className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">🔧 Full Control</h3>
              <p className="text-slate-400">You decide exactly what each agent can access</p>
            </div>

            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Zap className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">🔌 Real Integrations</h3>
              <p className="text-slate-400">Direct connections to Figma, GitHub, filesystems, and web APIs</p>
            </div>

            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Clock className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">💰 Transparent Costs</h3>
              <p className="text-slate-400">Pay your AI provider directly, no markup or hidden fees</p>
            </div>

            <div className="text-center space-y-4">
              <div className="w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                <Users className="w-8 h-8 text-primary" />
              </div>
              <h3 className="text-xl font-semibold">💼 Professional Grade</h3>
              <p className="text-slate-400">Built for teams handling sensitive client work</p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases Section */}
      <section className="py-16 bg-black/10">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-12">
            <h2 className="text-2xl md:text-3xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>Build Agents For Any Workflow</h2>
            <p className="text-lg text-slate-300 max-w-2xl mx-auto">
              From creative work to deep research, create specialized agents that understand your unique needs
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white/5 backdrop-blur-sm rounded-xl p-6 border border-white/10">
              <div className="w-12 h-12 bg-primary/20 rounded-lg flex items-center justify-center mb-4">
                <Palette className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg font-semibold mb-2" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>Design Assistant</h3>
              <p className="text-slate-300 text-sm">
                Create agents that understand your design system, generate consistent mockups, and provide design feedback
              </p>
            </div>

            <div className="bg-white/5 backdrop-blur-sm rounded-xl p-6 border border-white/10">
              <div className="w-12 h-12 bg-primary/20 rounded-lg flex items-center justify-center mb-4">
                <Search className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg font-semibold mb-2" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>Research Agent</h3>
              <p className="text-slate-300 text-sm">
                Build agents that dive deep into topics, synthesize information, and deliver comprehensive research reports
              </p>
            </div>

            <div className="bg-white/5 backdrop-blur-sm rounded-xl p-6 border border-white/10">
              <div className="w-12 h-12 bg-primary/20 rounded-lg flex items-center justify-center mb-4">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg font-semibold mb-2" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>Content Creator</h3>
              <p className="text-slate-300 text-sm">
                Deploy agents that match your voice, understand your audience, and create consistent, on-brand content
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section id="features" className="py-24 bg-black/5">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>How It Works</h2>
            <p className="text-xl text-slate-300 max-w-2xl mx-auto">
              From concept to deployment in four simple steps. Build powerful AI agents without the complexity.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              {
                step: "01",
                title: "Configure",
                description: "Pre-configure documentation, instructions, and personality traits that define your agent's behavior and expertise.",
                icon: FileText,
                color: "text-blue-400"
              },
              {
                step: "02", 
                title: "Build",
                description: "Use our intuitive visual builder to create your custom agent with personalized workflows and decision trees.",
                icon: Palette,
                color: "text-green-400"
              },
              {
                step: "03",
                title: "Deploy Locally",
                description: "Download and run on your computer using LibreChat, Jan.ai, AnythingLLM, or other local AI platforms.",
                icon: Rocket,
                color: "text-primary"
              },
              {
                step: "04",
                title: "Scale",
                description: "Share agents with your team, version control changes, and collaborate on improvements across projects.",
                icon: Users,
                color: "text-orange-400"
              }
            ].map((item, index) => (
              <div key={index} className="text-center space-y-4">
                <div className="relative">
                  <div className="w-16 h-16 bg-white/5 backdrop-blur-sm rounded-2xl flex items-center justify-center mx-auto mb-4 border border-white/10">
                    <item.icon className={`w-8 h-8 ${item.color}`} />
                  </div>
                  <div className="absolute -top-2 -right-2 w-8 h-8 bg-gradient-to-r from-primary to-primary/80 rounded-full flex items-center justify-center text-xs font-bold text-primary-foreground">
                    {item.step}
                  </div>
                </div>
                <h3 className="text-xl font-semibold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>{item.title}</h3>
                <p className="text-slate-300 text-sm leading-relaxed">
                  {item.description}
                </p>
              </div>
            ))}
          </div>

          {/* Process Flow Connector */}
          <div className="hidden lg:block relative mt-8">
            <div className="absolute top-1/2 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent transform -translate-y-1/2"></div>
            <div className="flex justify-between items-center relative z-10">
              {[0, 1, 2, 3].map((index) => (
                <div key={index} className="w-4 h-4 bg-primary/20 rounded-full border-2 border-primary/50"></div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 bg-black/20">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>Why Choose Asmbli Beta?</h2>
            <p className="text-xl text-slate-300 max-w-2xl mx-auto">
              Get exclusive access to cutting-edge features that will transform how you build AI agents.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Zap,
                title: 'Lightning Fast Setup',
                description: 'Deploy production-ready AI agents in under 5 minutes with our visual builder.',
                color: 'text-yellow-400'
              },
              {
                icon: Shield,
                title: 'Enterprise Security',
                description: 'Bank-grade encryption, role-based access, and compliance-ready from day one.',
                color: 'text-green-400'
              },
              {
                icon: Rocket,
                title: 'Local Deployment',
                description: 'Run everything on your computer with popular platforms like LibreChat, Jan.ai, and AnythingLLM.',
                color: 'text-primary'
              },
              {
                icon: Gift,
                title: 'Premium Templates',
                description: 'Access 50+ pre-built templates for every use case, from customer service to coding.',
                color: 'text-blue-400'
              },
              {
                icon: Users,
                title: 'Team Collaboration',
                description: 'Share, version, and collaborate on AI agents with your entire team.',
                color: 'text-pink-400'
              },
              {
                icon: Crown,
                title: 'Beta Exclusive',
                description: 'Lifetime beta pricing, priority support, and input on new features.',
                color: 'text-orange-400'
              }
            ].map((feature, index) => (
              <Card key={index} className="bg-white/5 border-white/10 hover:bg-white/10 transition-all duration-300 hover:scale-105">
                <CardHeader>
                  <feature.icon className={`w-8 h-8 ${feature.color} mb-2`} />
                  <CardTitle className="text-white">{feature.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <CardDescription className="text-slate-300">
                    {feature.description}
                  </CardDescription>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Early Access CTA */}
      <section id="early-access" className="py-24">
        <div className="max-width-container section-spacing-x">
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-slate-500/10 to-blue-500/15 rounded-3xl blur-xl"></div>
            <Card className="relative bg-gradient-to-r from-slate-800/50 to-blue-900/30 border-slate-600/50">
              <CardContent className="p-12 text-center">
                <div className="space-y-6">
                  <div className="flex items-center justify-center space-x-2">
                    <Clock className="w-6 h-6 text-primary" />
                    <Badge className="bg-primary/20 text-primary-foreground border-primary/30">
                      Limited Time
                    </Badge>
                  </div>
                  
                  <h3 className="text-3xl md:text-4xl font-bold text-white" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                    Join the Beta Program
                  </h3>
                  
                  <p className="text-xl text-slate-300 max-w-2xl mx-auto">
                    Be among the first 100 users to get lifetime beta pricing, 
                    priority support, and exclusive access to new features.
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-3xl mx-auto">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-primary">$0</div>
                      <div className="text-sm text-slate-400">Forever free core plan</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-blue-400">50%</div>
                      <div className="text-sm text-slate-400">Off premium features</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-green-400">24/7</div>
                      <div className="text-sm text-slate-400">Priority support</div>
                    </div>
                  </div>

                  {!isSubmitted ? (
                    <form onSubmit={handleBetaSignup} className="max-w-md mx-auto">
                      <div className="flex gap-3">
                        <Input
                          type="email"
                          placeholder="Your email address"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          className="flex-1 bg-white/10 border-white/20 text-white placeholder-slate-400"
                          required
                        />
                        <Button 
                          type="submit" 
                          disabled={isLoading}
                          className="bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600 px-8"
                        >
                          {isLoading ? 'Joining...' : 'Get Access'}
                        </Button>
                      </div>
                    </form>
                  ) : (
                    <div className="space-y-4">
                      <div className="text-green-400 font-semibold">
                        ✨ Welcome to the beta program!
                      </div>
                      <Button 
                        onClick={onGetStarted}
                        className="bg-gradient-to-r from-green-600 to-blue-500 hover:from-green-700 hover:to-blue-600"
                      >
                        Start Building
                        <ArrowRight className="w-4 h-4 ml-2" />
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-black/40 border-t border-white/10">
        <div className="max-width-container section-spacing-x">
          <div className="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0">
            <div className="flex items-center space-x-2">
              <span className="font-semibold bg-gradient-to-r from-primary to-primary/80 bg-clip-text text-transparent italic pl-1 pr-1" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                asmbli
              </span>
              <Badge className="bg-primary/20 text-primary-foreground border-primary/30 text-xs">
                Beta
              </Badge>
            </div>
            
            <div className="flex items-center space-x-6">
              <a href="mailto:hello@asmbli.io" className="text-slate-400 hover:text-white transition-colors">
                <Mail className="w-5 h-5" />
              </a>
              <a href="#" className="text-slate-400 hover:text-white transition-colors">
                <Twitter className="w-5 h-5" />
              </a>
              <a href="#" className="text-slate-400 hover:text-white transition-colors">
                <Github className="w-5 h-5" />
              </a>
              <a href="#" className="text-slate-400 hover:text-white transition-colors">
                <Linkedin className="w-5 h-5" />
              </a>
            </div>
            
            <div className="text-sm text-slate-400">
              © 2025 Asmbli. All rights reserved.
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}