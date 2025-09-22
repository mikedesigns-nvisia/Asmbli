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
        // Console output removed for production
        // Still show success to user for better UX
        setIsSubmitted(true);
      }
    } catch (error) {
      // Console output removed for production
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
              <Badge className="bg-orange-500/20 text-orange-300 border-orange-500/30">
                Alpha
              </Badge>
            </div>
            <nav className="hidden md:flex items-center space-x-6" role="navigation" aria-label="Main navigation">
              <a href="#vision" className="text-slate-300 hover:text-white transition-colors">Our Vision</a>
              <a href="#contribute" className="text-slate-300 hover:text-white transition-colors">Contribute</a>
              <Button
                variant="outline"
                onClick={() => window.open('https://github.com/WereNext/Asmbli', '_blank')}
                className="border-primary/50 text-primary hover:bg-primary/20 bg-transparent"
              >
                <Github className="w-4 h-4 mr-2" />
                GitHub
              </Button>
              <Button
                variant="default"
                onClick={onGetStarted}
                className="bg-primary hover:bg-primary/90 text-primary-foreground"
              >
                Try Alpha
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
            {/* Alpha Badge */}
            <div className="flex justify-center">
              <Badge className="bg-gradient-to-r from-orange-500 to-red-500 text-white px-4 py-1 text-sm font-medium">
                <AlertTriangle className="w-4 h-4 mr-2" />
                Experimental Alpha - Not Production Ready
              </Badge>
            </div>

            {/* Main Headline */}
            <div className="space-y-8">
              <h1 className="text-5xl md:text-6xl font-bold gradient-text leading-tight tracking-tight" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                The Future of Local AI Agents
              </h1>
              <p className="text-2xl md:text-3xl text-slate-200 max-w-3xl mx-auto leading-relaxed font-medium">
                An experimental vision for private, controllable AI
              </p>
              <div className="bg-orange-500/10 border border-orange-500/20 rounded-lg p-4 max-w-2xl mx-auto">
                <p className="text-orange-300 font-medium text-lg">
                  ⚠️ Alpha Software: Experimental project - expect bugs, incomplete features, and breaking changes
                </p>
              </div>
            </div>

            {/* Quick CTA */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center max-w-lg mx-auto">
              <Button
                onClick={() => document.getElementById('contribute')?.scrollIntoView({ behavior: 'smooth' })}
                size="lg"
                className="bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary/80 text-primary-foreground px-8 py-4 text-lg"
              >
                Help Build the Future
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
              <Button
                variant="outline"
                size="lg"
                onClick={() => document.getElementById('vision')?.scrollIntoView({ behavior: 'smooth' })}
                className="border-primary/50 text-primary hover:bg-primary/20 bg-transparent px-8 py-4 text-lg"
              >
                Our Vision
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Current Reality Section */}
      <section className="py-20 bg-slate-800/50">
        <div className="max-width-container section-spacing-x">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-8">
              <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                Current Reality
              </h2>
              <div className="bg-orange-500/10 border border-orange-500/20 rounded-lg p-8">
                <div className="flex items-start space-x-4">
                  <AlertTriangle className="w-8 h-8 text-orange-400 flex-shrink-0 mt-1" />
                  <div className="text-left">
                    <p className="text-lg text-slate-300 leading-relaxed mb-4">
                      This is an experimental alpha project exploring what local AI agents could become.
                      Many features are broken, incomplete, or don't work as expected.
                    </p>
                    <p className="text-xl font-semibold text-orange-400" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                      We're building toward a vision, not a finished product.
                    </p>
                  </div>
                </div>
              </div>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-8">
                <p className="text-lg text-slate-300 leading-relaxed">
                  If you're looking for working software, this isn't it yet. But if you want to help explore
                  what's possible with truly local, private AI agents, you're in the right place.
                </p>
                <div className="mt-4 bg-red-500/10 border border-red-500/20 rounded-lg p-4">
                  <p className="text-red-300 text-sm font-medium">
                    ⚠️ Honest Warning: Expect crashes, bugs, data loss, and features that simply don't work.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Vision Section */}
      <section id="vision" className="py-20 bg-black/10">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              Our Vision for Local AI
            </h2>
            <p className="text-xl text-slate-300 max-w-3xl mx-auto">
              What we're working toward (even if we're not there yet)
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {/* True Privacy */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Lock className="w-6 h-6 text-blue-400" />
                  <div>
                    <CardTitle className="text-blue-400">🔒 True Privacy</CardTitle>
                    <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30 mt-2">
                      Vision
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">AI agents that run entirely on your hardware, with your API keys, accessing only what you choose</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• No data leaves your computer without permission</li>
                  <li>• You control every integration and connection</li>
                </ul>
              </CardContent>
            </Card>

            {/* User Control */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Settings className="w-6 h-6 text-purple-400" />
                  <div>
                    <CardTitle className="text-purple-400">🎛️ User Control</CardTitle>
                    <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30 mt-2">
                      Vision
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Predictable, reliable AI that works the same way regardless of model updates</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Your workflows stay consistent</li>
                  <li>• No surprise changes from cloud updates</li>
                </ul>
              </CardContent>
            </Card>

            {/* Open Ecosystem */}
            <Card className="bg-slate-800/50 border-slate-700/50 hover:bg-slate-800/70 transition-colors">
              <CardHeader>
                <div className="flex items-center space-x-3">
                  <Users className="w-6 h-6 text-green-400" />
                  <div>
                    <CardTitle className="text-green-400">🌐 Open Ecosystem</CardTitle>
                    <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30 mt-2">
                      Vision
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Community-driven development where everyone can contribute and improve</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Open source and transparent</li>
                  <li>• Built by and for the community</li>
                </ul>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* What We're Learning Section */}
      <section className="py-20 bg-black/20">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
              What We're Learning
            </h2>
            <p className="text-xl text-slate-300 max-w-2xl mx-auto">
              Experiments and discoveries from building local AI agents
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardHeader>
                <CardTitle className="text-blue-400">🧪 Technical Challenges</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Building reliable local AI agents is harder than we expected:</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Model context management across conversations</li>
                  <li>• MCP server reliability and compatibility</li>
                  <li>• Cross-platform desktop application complexity</li>
                  <li>• Balancing features with performance</li>
                </ul>
              </CardContent>
            </Card>

            <Card className="bg-slate-800/50 border-slate-700/50">
              <CardHeader>
                <CardTitle className="text-green-400">🔍 What's Working</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-slate-300">Some concepts are showing promise:</p>
                <ul className="text-sm text-slate-400 space-y-2">
                  <li>• Flutter for cross-platform desktop apps</li>
                  <li>• Model Context Protocol for integrations</li>
                  <li>• Local-first approach for privacy</li>
                  <li>• Community interest in the vision</li>
                </ul>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Coded with Claude Section */}
      <section className="py-20 bg-slate-800/30">
        <div className="max-width-container section-spacing-x">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-8">
              <h2 className="text-3xl md:text-4xl font-bold" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                🤖 Coded with Claude
              </h2>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-8">
                <div className="flex items-start space-x-4">
                  <Code2 className="w-8 h-8 text-blue-400 flex-shrink-0 mt-1" />
                  <div className="text-left">
                    <p className="text-lg text-slate-300 leading-relaxed mb-4">
                      This entire project is being built using Claude Code - an AI coding assistant that writes, debugs,
                      and iterates on code in real-time. It's a practical example of human-AI collaboration in software development.
                    </p>
                    <p className="text-xl font-semibold text-blue-400" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                      Meta-experiment: AI building tools for AI.
                    </p>
                  </div>
                </div>
              </div>
              <div className="bg-purple-500/10 border border-purple-500/20 rounded-lg p-8">
                <p className="text-lg text-slate-300 leading-relaxed mb-4">
                  Every component, every feature, and even this website was developed through conversations with Claude.
                  The code is transparent, the process is documented, and the results speak for themselves -
                  both the successes and the inevitable AI-generated bugs.
                </p>
                <p className="text-md text-slate-400 leading-relaxed">
                  Special thanks to GitHub Copilot for code completion and suggestions, and Kiro for additional development assistance.
                  This project showcases collaboration between multiple AI coding tools working together.
                </p>
                <div className="mt-4 bg-green-500/10 border border-green-500/20 rounded-lg p-4">
                  <p className="text-green-300 text-sm font-medium">
                    💡 Living proof that AI can be a powerful coding partner, not just a code generator.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Help Build the Future Section */}
      <section id="contribute" className="py-24">
        <div className="max-width-container section-spacing-x">
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-slate-500/10 to-blue-500/15 rounded-3xl blur-xl"></div>
            <Card className="relative bg-gradient-to-r from-slate-800/50 to-blue-900/30 border-slate-600/50">
              <CardContent className="p-12 text-center">
                <div className="space-y-6">
                  <div className="flex items-center justify-center space-x-2">
                    <Users className="w-6 h-6 text-primary" />
                    <Badge className="bg-orange-500/20 text-orange-400 border-orange-500/30">
                      Community Driven
                    </Badge>
                  </div>

                  <h3 className="text-3xl md:text-4xl font-bold text-white" style={{ fontFamily: '"Noto Sans JP", sans-serif' }}>
                    Help Build the Future
                  </h3>

                  <p className="text-xl text-slate-300 max-w-2xl mx-auto">
                    This is an experimental alpha project that needs contributors, testers, and feedback
                    to become what it could be.
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-3xl mx-auto">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-blue-400">Code</div>
                      <div className="text-sm text-slate-400">Contribute to development</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-green-400">Test</div>
                      <div className="text-sm text-slate-400">Help find bugs and issues</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-purple-400">Ideas</div>
                      <div className="text-sm text-slate-400">Shape the future vision</div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-4">
                      <p className="text-slate-300">
                        🚧 Want to experiment with broken software? 🚧
                      </p>
                      <div className="flex flex-col sm:flex-row gap-3 justify-center max-w-lg mx-auto">
                        <Button
                          onClick={onGetStarted}
                          className="bg-gradient-to-r from-primary to-primary/90 hover:from-primary/90 hover:to-primary/80"
                        >
                          Try the Alpha
                          <ArrowRight className="w-4 h-4 ml-2" />
                        </Button>
                        <Button
                          variant="outline"
                          onClick={() => window.open('https://github.com/WereNext/Asmbli', '_blank')}
                          className="border-primary/50 text-primary hover:bg-primary/20 bg-transparent"
                        >
                          <Github className="w-4 h-4 mr-2" />
                          Contribute on GitHub
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-black/40 border-t border-white/10">
        <div className="max-width-container section-spacing-x">
          <div className="text-center">
            <div className="text-sm text-slate-400">
              © 2025 Asmbli. All rights reserved. Patent Pending.
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}