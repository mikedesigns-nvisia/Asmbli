import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent } from '../ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Eye, EyeOff, Mail, Lock, User, Shield, Zap, Building, CheckCircle } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { UserRole, ROLE_CONFIGURATIONS } from '../../types/auth';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultTab?: 'login' | 'signup';
}

export function AuthModal({ isOpen, onClose, defaultTab = 'login' }: AuthModalProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  const [showPassword, setShowPassword] = useState(false);
  const [selectedRole, setSelectedRole] = useState<UserRole>(() => {
    // Auto-select beta role if user signed up for beta
    const betaEmail = localStorage.getItem('beta_signup_email');
    return betaEmail ? 'beta' : 'beginner';
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const [loginForm, setLoginForm] = useState({
    email: '',
    password: ''
  });
  
  const [signupForm, setSignupForm] = useState(() => {
    // Pre-fill email if user signed up for beta
    const betaEmail = localStorage.getItem('beta_signup_email');
    return {
      name: '',
      email: betaEmail || '',
      password: '',
      confirmPassword: ''
    };
  });

  const { login, signup } = useAuth();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      await login(loginForm);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    if (signupForm.password !== signupForm.confirmPassword) {
      setError('Passwords do not match');
      setIsLoading(false);
      return;
    }

    try {
      await signup({
        name: signupForm.name,
        email: signupForm.email,
        password: signupForm.password,
        role: selectedRole
      });
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Signup failed');
    } finally {
      setIsLoading(false);
    }
  };

  const roleIcons = {
    beta: Shield,
    beginner: User,
    power_user: Zap,
    enterprise: Building
  };

  const roleColors = {
    beta: 'bg-orange-500/10 text-orange-600 border-orange-500/20',
    beginner: 'bg-green-500/10 text-green-600 border-green-500/20',
    power_user: 'bg-blue-500/10 text-blue-600 border-blue-500/20',
    enterprise: 'bg-purple-500/10 text-purple-600 border-purple-500/20'
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="!max-w-5xl !w-full max-h-[90vh] overflow-y-auto p-8 sm:!max-w-5xl">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold">Welcome to AI Agent Builder</h2>
            <p className="text-muted-foreground">Sign in to start building your AI agents</p>
          </div>
        </div>

        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as 'login' | 'signup')}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="login">Sign In</TabsTrigger>
            <TabsTrigger value="signup">Create Account</TabsTrigger>
          </TabsList>

          <TabsContent value="login" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Shield className="w-5 h-5" />
                  Sign In
                </CardTitle>
                <CardDescription>
                  Access your AI agent builder dashboard
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleLogin} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="email">Email</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="email"
                        type="email"
                        placeholder="Enter your email"
                        className="pl-10"
                        value={loginForm.email}
                        onChange={(e) => setLoginForm(prev => ({ ...prev, email: e.target.value }))}
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="password">Password</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="password"
                        type={showPassword ? 'text' : 'password'}
                        placeholder="Enter your password"
                        className="pl-10 pr-10"
                        value={loginForm.password}
                        onChange={(e) => setLoginForm(prev => ({ ...prev, password: e.target.value }))}
                        required
                      />
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                        onClick={() => setShowPassword(!showPassword)}
                      >
                        {showPassword ? (
                          <EyeOff className="h-4 w-4 text-muted-foreground" />
                        ) : (
                          <Eye className="h-4 w-4 text-muted-foreground" />
                        )}
                      </Button>
                    </div>
                  </div>

                  {error && (
                    <div className="text-sm text-red-600 bg-red-50 p-3 rounded-md">
                      {error}
                    </div>
                  )}

                  <Button type="submit" className="w-full" disabled={isLoading}>
                    {isLoading ? 'Signing in...' : 'Sign In'}
                  </Button>
                </form>

                <div className="mt-6 space-y-2">
                  <p className="text-sm text-muted-foreground">Demo accounts:</p>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                    <div className="p-2 bg-orange-50 rounded border border-orange-200">
                      <div className="font-medium text-orange-700">Beta Tester</div>
                      <div className="text-orange-600">beta@example.com</div>
                      <div className="text-orange-600">password</div>
                      <div className="text-[10px] text-orange-500 mt-1">MVP Wizard</div>
                    </div>
                    <div className="p-2 bg-green-50 rounded border">
                      <div className="font-medium">Beginner</div>
                      <div className="text-muted-foreground">beginner@example.com</div>
                      <div className="text-muted-foreground">password</div>
                    </div>
                    <div className="p-2 bg-blue-50 rounded border">
                      <div className="font-medium">Power User</div>
                      <div className="text-muted-foreground">power@example.com</div>
                      <div className="text-muted-foreground">password</div>
                    </div>
                    <div className="p-2 bg-purple-50 rounded border">
                      <div className="font-medium">Enterprise</div>
                      <div className="text-muted-foreground">enterprise@example.com</div>
                      <div className="text-muted-foreground">password</div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="signup" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Choose Your Plan</CardTitle>
                <CardDescription>
                  Select the plan that best fits your needs
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 mb-8">
                  {Object.entries(ROLE_CONFIGURATIONS).map(([role, config]) => {
                    const IconComponent = roleIcons[role as UserRole];
                    const isSelected = selectedRole === role;
                    
                    return (
                      <Card
                        key={role}
                        className={`cursor-pointer transition-all duration-200 ${
                          isSelected ? 'ring-2 ring-primary shadow-lg' : 'hover:shadow-md'
                        }`}
                        onClick={() => setSelectedRole(role as UserRole)}
                      >
                        <CardHeader className="text-center pb-2">
                          <div className={`w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-2 ${roleColors[role as UserRole]}`}>
                            <IconComponent className="w-6 h-6" />
                          </div>
                          <CardTitle className="text-lg">{config.displayName}</CardTitle>
                          <CardDescription className="text-xl font-bold text-foreground">
                            {config.price}
                          </CardDescription>
                        </CardHeader>
                        <CardContent className="pt-0">
                          <p className="text-sm text-muted-foreground mb-4">{config.description}</p>
                          <div className="space-y-2">
                            <div className="flex items-center gap-2 text-sm">
                              <CheckCircle className="w-3 h-3 text-green-500" />
                              <span>{config.features.maxAgents === -1 ? 'Unlimited' : config.features.maxAgents} agents</span>
                            </div>
                            {config.features.securityCustomization && (
                              <div className="flex items-center gap-2 text-sm">
                                <CheckCircle className="w-3 h-3 text-green-500" />
                                <span>Security customization</span>
                              </div>
                            )}
                            {config.features.advancedExtensions && (
                              <div className="flex items-center gap-2 text-sm">
                                <CheckCircle className="w-3 h-3 text-green-500" />
                                <span>Advanced extensions</span>
                              </div>
                            )}
                            {config.features.prioritySupport && (
                              <div className="flex items-center gap-2 text-sm">
                                <CheckCircle className="w-3 h-3 text-green-500" />
                                <span>Priority support</span>
                              </div>
                            )}
                          </div>
                          {isSelected && (
                            <div className="mt-4">
                              <Badge className="w-full justify-center bg-primary/20 text-primary border-primary/30">
                                Selected
                              </Badge>
                            </div>
                          )}
                        </CardContent>
                      </Card>
                    );
                  })}
                </div>

                <form onSubmit={handleSignup} className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="space-y-2">
                      <Label htmlFor="signup-name">Full Name</Label>
                      <Input
                        id="signup-name"
                        type="text"
                        placeholder="Enter your full name"
                        value={signupForm.name}
                        onChange={(e) => setSignupForm(prev => ({ ...prev, name: e.target.value }))}
                        required
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="signup-email">Email</Label>
                      <Input
                        id="signup-email"
                        type="email"
                        placeholder="Enter your email"
                        value={signupForm.email}
                        onChange={(e) => setSignupForm(prev => ({ ...prev, email: e.target.value }))}
                        required
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="space-y-2">
                      <Label htmlFor="signup-password">Password</Label>
                      <Input
                        id="signup-password"
                        type="password"
                        placeholder="Create a password"
                        value={signupForm.password}
                        onChange={(e) => setSignupForm(prev => ({ ...prev, password: e.target.value }))}
                        required
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="confirm-password">Confirm Password</Label>
                      <Input
                        id="confirm-password"
                        type="password"
                        placeholder="Confirm your password"
                        value={signupForm.confirmPassword}
                        onChange={(e) => setSignupForm(prev => ({ ...prev, confirmPassword: e.target.value }))}
                        required
                      />
                    </div>
                  </div>

                  {error && (
                    <div className="text-sm text-red-600 bg-red-50 p-3 rounded-md">
                      {error}
                    </div>
                  )}

                  <Button type="submit" className="w-full" disabled={isLoading}>
                    {isLoading ? 'Creating account...' : `Create ${ROLE_CONFIGURATIONS[selectedRole].displayName} Account`}
                  </Button>
                </form>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}