import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Slider } from '../ui/slider';
import { ArrowRight, ArrowLeft, Shield, Lock, Key, Users, AlertTriangle, CheckCircle, Clock, Database } from 'lucide-react';

interface Step3SecurityAccessProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function Step3SecurityAccess({ data, onUpdate, onNext, onPrev }: Step3SecurityAccessProps) {
  const [securityConfig, setSecurityConfig] = useState(data.security || {
    authMethod: null,
    permissions: [],
    vaultIntegration: 'none',
    auditLogging: false,
    rateLimiting: true,
    sessionTimeout: 3600
  });

  const authMethods = [
    {
      id: 'oauth',
      name: 'OAuth 2.1',
      description: 'Enterprise-grade authentication with PKCE and refresh tokens',
      securityLevel: 'high',
      features: ['PKCE Flow', 'Refresh Tokens', 'Scope Management', 'Multi-tenant Support'],
      recommended: true
    },
    {
      id: 'apikey',
      name: 'API Key Authentication',
      description: 'Simple API key based authentication with rotation support',
      securityLevel: 'medium',
      features: ['Key Rotation', 'Rate Limiting', 'IP Whitelisting', 'Usage Analytics']
    },
    {
      id: 'mtls',
      name: 'Mutual TLS (mTLS)',
      description: 'Certificate-based mutual authentication for maximum security',
      securityLevel: 'high',
      features: ['Certificate Validation', 'Client Certificates', 'CA Management', 'Auto Renewal']
    }
  ];

  const permissionOptions = [
    { id: 'read', name: 'Read Access', description: 'View and retrieve data', icon: Database },
    { id: 'write', name: 'Write Access', description: 'Create and modify data', icon: Key },
    { id: 'delete', name: 'Delete Access', description: 'Remove data and resources', icon: AlertTriangle },
    { id: 'admin', name: 'Admin Access', description: 'Full system administration', icon: Users }
  ];

  const vaultOptions = [
    {
      id: 'hashicorp',
      name: 'HashiCorp Vault',
      description: 'Enterprise secret management with dynamic secrets',
      features: ['Dynamic Secrets', 'Secret Rotation', 'Audit Logging', 'Policy Management']
    },
    {
      id: 'aws',
      name: 'AWS Secrets Manager',
      description: 'Cloud-native secret management with automatic rotation',
      features: ['Auto Rotation', 'Cross-Region Replication', 'Fine-grained IAM', 'CloudTrail Integration']
    },
    {
      id: '1password',
      name: '1Password Secrets',
      description: 'Developer-friendly secret management with CLI integration',
      features: ['CLI Integration', 'Team Sharing', 'Audit Trails', 'SDK Support']
    },
    {
      id: 'none',
      name: 'No Vault Integration',
      description: 'Use environment variables or configuration files',
      features: ['Simple Setup', 'No External Dependencies']
    }
  ];

  const updateSecurityConfig = (field: string, value: any) => {
    const updated = { ...securityConfig, [field]: value };
    setSecurityConfig(updated);
    onUpdate({ security: updated });
  };

  const togglePermission = (permission: string) => {
    const permissions = securityConfig.permissions || [];
    const newPermissions = permissions.includes(permission)
      ? permissions.filter((p: string) => p !== permission)
      : [...permissions, permission];
    updateSecurityConfig('permissions', newPermissions);
  };

  const getSecurityScore = () => {
    let score = 0;
    if (securityConfig.authMethod) score += 25;
    if (securityConfig.permissions?.length > 0) score += 15;
    if (securityConfig.vaultIntegration !== 'none') score += 25;
    if (securityConfig.auditLogging) score += 20;
    if (securityConfig.rateLimiting) score += 15;
    return Math.min(score, 100);
  };

  const securityScore = getSecurityScore();
  const scoreColor = securityScore >= 80 ? 'text-success' : securityScore >= 60 ? 'text-warning' : 'text-destructive';

  const formatTimeout = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          Security & Access Control
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Configure authentication, authorization, and security measures for your AI agent.
          Ensure your deployment meets enterprise security standards and compliance requirements.
        </p>
      </div>

      {/* Security Score Dashboard */}
      <Card className="selection-card border-primary/30">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Shield className="w-6 h-6 text-primary" />
              <CardTitle>Security Configuration Score</CardTitle>
            </div>
            <div className={`text-2xl font-bold ${scoreColor}`}>
              {securityScore}/100
            </div>
          </div>
          <CardDescription>
            Your current security configuration strength and recommendations
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="w-full bg-muted rounded-full h-3">
              <div 
                className={`h-3 rounded-full transition-all duration-500 ${
                  securityScore >= 80 ? 'bg-success' : 
                  securityScore >= 60 ? 'bg-warning' : 'bg-destructive'
                }`}
                style={{ width: `${securityScore}%` }}
              />
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div className="flex items-center gap-2">
                {securityConfig.authMethod ? <CheckCircle className="w-4 h-4 text-success" /> : <AlertTriangle className="w-4 h-4 text-muted-foreground" />}
                <span>Authentication</span>
              </div>
              <div className="flex items-center gap-2">
                {securityConfig.permissions?.length > 0 ? <CheckCircle className="w-4 h-4 text-success" /> : <AlertTriangle className="w-4 h-4 text-muted-foreground" />}
                <span>Permissions</span>
              </div>
              <div className="flex items-center gap-2">
                {securityConfig.vaultIntegration !== 'none' ? <CheckCircle className="w-4 h-4 text-success" /> : <AlertTriangle className="w-4 h-4 text-muted-foreground" />}
                <span>Secret Management</span>
              </div>
              <div className="flex items-center gap-2">
                {securityConfig.auditLogging ? <CheckCircle className="w-4 h-4 text-success" /> : <AlertTriangle className="w-4 h-4 text-muted-foreground" />}
                <span>Audit Logging</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Authentication Method */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Lock className="w-5 h-5 text-primary" />
            Authentication Method
          </CardTitle>
          <CardDescription>
            Choose how users will authenticate with your AI agent
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {authMethods.map((method) => {
              const isSelected = securityConfig.authMethod === method.id;
              
              return (
                <div
                  key={method.id}
                  className={`p-6 rounded-xl border cursor-pointer transition-all duration-300 hover:border-primary/50 hover:-translate-y-1 ${
                    isSelected
                      ? 'border-primary bg-gradient-to-br from-primary/10 to-transparent shadow-lg'
                      : 'border-border hover:shadow-md'
                  }`}
                  onClick={() => updateSecurityConfig('authMethod', method.id)}
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold">{method.name}</h3>
                        {method.recommended && (
                          <Badge variant="secondary" className="chip-hug text-xs bg-primary/20 text-primary">
                            Recommended
                          </Badge>
                        )}
                      </div>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                    
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {method.description}
                    </p>

                    <div className="flex flex-wrap gap-1">
                      {method.features.map((feature) => (
                        <Badge key={feature} variant="outline" className="chip-hug text-xs">
                          {feature}
                        </Badge>
                      ))}
                    </div>

                    <div className="flex items-center gap-2">
                      <Badge 
                        variant="outline" 
                        className={`chip-hug text-xs ${
                          method.securityLevel === 'high' ? 'border-success/30 text-success' : 'border-warning/30 text-warning'
                        }`}
                      >
                        {method.securityLevel.toUpperCase()} Security
                      </Badge>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Permissions & Access Control */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5 text-primary" />
            Permissions & Access Control
          </CardTitle>
          <CardDescription>
            Define what actions authenticated users can perform
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {permissionOptions.map((permission) => {
              const Icon = permission.icon;
              const isSelected = securityConfig.permissions?.includes(permission.id);
              
              return (
                <div
                  key={permission.id}
                  className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 hover:border-primary/50 ${
                    isSelected 
                      ? 'border-primary bg-primary/5' 
                      : 'border-border'
                  }`}
                  onClick={() => togglePermission(permission.id)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Icon className={`w-5 h-5 ${isSelected ? 'text-primary' : 'text-muted-foreground'}`} />
                      <div>
                        <h4 className="font-medium">{permission.name}</h4>
                        <p className="text-sm text-muted-foreground">{permission.description}</p>
                      </div>
                    </div>
                    {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Secret Management Integration */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Key className="w-5 h-5 text-primary" />
            Secret Management Integration
          </CardTitle>
          <CardDescription>
            Choose how sensitive data like API keys and credentials are managed
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {vaultOptions.map((vault) => {
              const isSelected = securityConfig.vaultIntegration === vault.id;
              
              return (
                <div
                  key={vault.id}
                  className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 hover:border-primary/50 ${
                    isSelected 
                      ? 'border-primary bg-primary/5' 
                      : 'border-border'
                  }`}
                  onClick={() => updateSecurityConfig('vaultIntegration', vault.id)}
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <h4 className="font-medium">{vault.name}</h4>
                      {isSelected && <CheckCircle className="w-5 h-5 text-primary" />}
                    </div>
                    
                    <p className="text-sm text-muted-foreground">{vault.description}</p>

                    <div className="flex flex-wrap gap-1">
                      {vault.features.map((feature) => (
                        <Badge key={feature} variant="outline" className="chip-hug text-xs">
                          {feature}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Advanced Security Settings */}
      <Card className="selection-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-primary" />
            Advanced Security Settings
          </CardTitle>
          <CardDescription>
            Additional security measures and monitoring options
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <h4 className="font-medium">Audit Logging</h4>
              <p className="text-sm text-muted-foreground">
                Enable comprehensive logging of all user actions and system events
              </p>
            </div>
            <div className="flex items-center justify-center p-1 rounded-lg bg-muted/30 border border-border/50 transition-all duration-200 hover:bg-muted/40 hover:border-border/70">
              <Switch
                checked={securityConfig.auditLogging}
                onCheckedChange={(checked) => updateSecurityConfig('auditLogging', checked)}
                className="data-[state=checked]:bg-primary data-[state=unchecked]:bg-muted-foreground/20"
              />
            </div>
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <h4 className="font-medium">Rate Limiting</h4>
              <p className="text-sm text-muted-foreground">
                Protect against abuse by limiting request frequency per user
              </p>
            </div>
            <div className="flex items-center justify-center p-1 rounded-lg bg-muted/30 border border-border/50 transition-all duration-200 hover:bg-muted/40 hover:border-border/70">
              <Switch
                checked={securityConfig.rateLimiting}
                onCheckedChange={(checked) => updateSecurityConfig('rateLimiting', checked)}
                className="data-[state=checked]:bg-primary data-[state=unchecked]:bg-muted-foreground/20"
              />
            </div>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h4 className="font-medium">Session Timeout</h4>
              <span className="text-sm text-muted-foreground">
                {formatTimeout(securityConfig.sessionTimeout)}
              </span>
            </div>
            <div className="space-y-2">
              <Slider
                value={[securityConfig.sessionTimeout]}
                onValueChange={(value) => updateSecurityConfig('sessionTimeout', value[0])}
                min={300}
                max={28800}
                step={300}
                className="w-full"
              />
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>5 min</span>
                <span>4 hours</span>
                <span>8 hours</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Navigation */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={onPrev} className="px-8">
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button 
          onClick={onNext}
          className="px-8 py-2 bg-primary hover:bg-primary/90 text-primary-foreground"
        >
          Configure Behavior
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}