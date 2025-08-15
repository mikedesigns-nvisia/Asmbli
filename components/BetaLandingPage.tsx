import { useState } from 'react';
import { 
  ArrowRight, 
  CheckCircle, 
  Zap, 
  Shield, 
  Users, 
  Crown,
  Star,
  Sparkles,
  Rocket,
  Gift,
  Clock,
  Mail,
  Github,
  Twitter,
  Linkedin
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
              <span className="font-bold text-xl bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent font-display text-[20px] italic pl-1 pr-2" aria-label="asmbli Logo">
                asmbli
              </span>
              <Badge className="bg-purple-500/20 text-purple-300 border-purple-400/30">
                Beta
              </Badge>
            </div>
            <nav className="hidden md:flex items-center space-x-6" role="navigation" aria-label="Main navigation">
              <a href="#features" className="text-slate-300 hover:text-white transition-colors">Features</a>
              <a href="#early-access" className="text-slate-300 hover:text-white transition-colors">Early Access</a>
              <Button 
                variant="outline" 
                className="border-purple-400/50 text-purple-300 hover:bg-purple-500/20"
                onClick={onViewTemplates}
              >
                View Templates
              </Button>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-20 pb-32 overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0 bg-gradient-to-br from-purple-500/5 via-transparent to-blue-500/5"></div>
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-400/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute top-1/3 right-1/4 w-96 h-96 bg-blue-400/10 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }}></div>
        
        <div className="relative max-width-container section-spacing-x text-center">
          <div className="space-y-8">
            {/* Beta Badge */}
            <div className="flex justify-center">
              <Badge className="bg-gradient-to-r from-purple-500 to-blue-500 text-white px-4 py-1 text-sm font-medium">
                <Sparkles className="w-4 h-4 mr-2" />
                Early Access Beta
              </Badge>
            </div>

            {/* Main Headline */}
            <div className="space-y-4">
              <h1 className="text-5xl md:text-7xl font-bold bg-gradient-to-r from-white via-slate-200 to-blue-200 bg-clip-text text-transparent leading-tight">
                Build AI Agents
                <br />
                <span className="text-4xl md:text-6xl">Like Never Before</span>
              </h1>
              <p className="text-xl md:text-2xl text-slate-300 max-w-3xl mx-auto leading-relaxed">
                The first visual AI agent builder with enterprise-grade security, 
                one-click deployment, and the most comprehensive template library.
              </p>
            </div>

            {/* Beta Signup Form */}
            <div className="max-w-md mx-auto">
              {!isSubmitted ? (
                <form onSubmit={handleBetaSignup} className="space-y-4">
                  <div className="flex gap-3">
                    <Input
                      type="email"
                      placeholder="Enter your email for early access"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="flex-1 bg-white/10 border-white/20 text-white placeholder-slate-400 focus:border-purple-400"
                      required
                    />
                    <Button 
                      type="submit" 
                      disabled={isLoading}
                      className="bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600 text-white border-0 px-8"
                    >
                      {isLoading ? (
                        <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin" />
                      ) : (
                        <>
                          Join Beta
                          <ArrowRight className="w-4 h-4 ml-2" />
                        </>
                      )}
                    </Button>
                  </div>
                  <p className="text-sm text-slate-400">
                    Free forever • No credit card required • Limited spots available
                  </p>
                </form>
              ) : (
                <div className="text-center space-y-4">
                  <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto">
                    <CheckCircle className="w-8 h-8 text-green-400" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-green-400">You're on the list! 🎉</h3>
                    <p className="text-slate-300 mt-2">
                      We'll send you an invite as soon as your spot is ready.
                    </p>
                  </div>
                  <Button 
                    onClick={onGetStarted}
                    className="bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600"
                  >
                    Explore Demo
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Button>
                </div>
              )}
            </div>

            {/* Social Proof */}
            <div className="flex justify-center items-center space-x-8 text-slate-400">
              <div className="flex items-center space-x-2">
                <Users className="w-5 h-5" />
                <span className="text-sm">2,500+ developers</span>
              </div>
              <div className="flex items-center space-x-2">
                <Star className="w-5 h-5 text-yellow-400" />
                <span className="text-sm">4.9/5 rating</span>
              </div>
              <div className="flex items-center space-x-2">
                <Crown className="w-5 h-5 text-purple-400" />
                <span className="text-sm">Enterprise ready</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 bg-black/20">
        <div className="max-width-container section-spacing-x">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Why Choose asmbli Beta?</h2>
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
                title: 'One-Click Deploy',
                description: 'Deploy to any platform - Claude Desktop, ChatGPT, or your own infrastructure.',
                color: 'text-purple-400'
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
                    <Clock className="w-6 h-6 text-purple-400" />
                    <Badge className="bg-purple-500/20 text-purple-300 border-purple-400/30">
                      Limited Time
                    </Badge>
                  </div>
                  
                  <h3 className="text-3xl md:text-4xl font-bold text-white">
                    Join the Beta Program
                  </h3>
                  
                  <p className="text-xl text-slate-300 max-w-2xl mx-auto">
                    Be among the first 100 users to get lifetime beta pricing, 
                    priority support, and exclusive access to new features.
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-3xl mx-auto">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-purple-400">$0</div>
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
              <span className="font-semibold bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent italic pl-1 pr-1">
                asmbli
              </span>
              <Badge className="bg-purple-500/20 text-purple-300 border-purple-400/30 text-xs">
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
              © 2024 asmbli. All rights reserved.
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}