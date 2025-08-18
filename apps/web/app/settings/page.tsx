'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Switch } from '@/components/ui/switch'
import { ArrowLeft, Key, Server, Shield, Zap, Eye, EyeOff, Save, TestTube, CheckCircle, XCircle } from 'lucide-react'
import { Navigation } from '@/components/Navigation'

export default function SettingsPage() {
  const [showApiKey, setShowApiKey] = useState(false)
  const [apiSettings, setApiSettings] = useState({
    provider: 'openai',
    apiKey: '',
    model: 'gpt-4',
    baseUrl: '',
    temperature: '0.7',
    maxTokens: '2048'
  })
  const [isTestingConnection, setIsTestingConnection] = useState(false)
  const [connectionStatus, setConnectionStatus] = useState<'idle' | 'success' | 'error'>('idle')

  const handleSave = () => {
    // Save settings logic here
    console.log('Saving settings:', apiSettings)
  }

  const testConnection = async () => {
    setIsTestingConnection(true)
    // Simulate API test
    await new Promise(resolve => setTimeout(resolve, 2000))
    setConnectionStatus(Math.random() > 0.3 ? 'success' : 'error')
    setIsTestingConnection(false)
  }

  return (
    <div className="min-h-screen bg-background">
      <Navigation showBackButton backHref="/chat" backLabel="Back to Chat" />

      <div className="container mx-auto px-4 py-8 max-w-4xl">
        <div className="space-y-8">
          <div>
            <h1 className="text-3xl font-bold">API Settings</h1>
            <p className="text-muted-foreground mt-2">
              Configure your AI provider settings and manage API connections
            </p>
          </div>

          <Tabs defaultValue="api" className="space-y-6">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="api">API Configuration</TabsTrigger>
              <TabsTrigger value="security">Security</TabsTrigger>
              <TabsTrigger value="advanced">Advanced</TabsTrigger>
            </TabsList>

            <TabsContent value="api" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Key className="h-5 w-5" />
                    AI Provider Configuration
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="provider">AI Provider</Label>
                      <Select value={apiSettings.provider} onValueChange={(value) => 
                        setApiSettings(prev => ({ ...prev, provider: value }))}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="openai">OpenAI</SelectItem>
                          <SelectItem value="anthropic">Anthropic (Claude)</SelectItem>
                          <SelectItem value="google">Google (Gemini)</SelectItem>
                          <SelectItem value="custom">Custom Provider</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="model">Model</Label>
                      <Select value={apiSettings.model} onValueChange={(value) => 
                        setApiSettings(prev => ({ ...prev, model: value }))}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {apiSettings.provider === 'openai' && (
                            <>
                              <SelectItem value="gpt-4">GPT-4</SelectItem>
                              <SelectItem value="gpt-4-turbo">GPT-4 Turbo</SelectItem>
                              <SelectItem value="gpt-3.5-turbo">GPT-3.5 Turbo</SelectItem>
                            </>
                          )}
                          {apiSettings.provider === 'anthropic' && (
                            <>
                              <SelectItem value="claude-3-opus">Claude 3 Opus</SelectItem>
                              <SelectItem value="claude-3-sonnet">Claude 3 Sonnet</SelectItem>
                              <SelectItem value="claude-3-haiku">Claude 3 Haiku</SelectItem>
                            </>
                          )}
                          {apiSettings.provider === 'google' && (
                            <>
                              <SelectItem value="gemini-pro">Gemini Pro</SelectItem>
                              <SelectItem value="gemini-pro-vision">Gemini Pro Vision</SelectItem>
                            </>
                          )}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="apiKey">API Key</Label>
                    <div className="relative">
                      <Input
                        id="apiKey"
                        type={showApiKey ? 'text' : 'password'}
                        placeholder="Enter your API key"
                        value={apiSettings.apiKey}
                        onChange={(e) => setApiSettings(prev => ({ ...prev, apiKey: e.target.value }))}
                        className="pr-10"
                      />
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                        onClick={() => setShowApiKey(!showApiKey)}
                      >
                        {showApiKey ? (
                          <EyeOff className="h-4 w-4" />
                        ) : (
                          <Eye className="h-4 w-4" />
                        )}
                      </Button>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      Your API key is stored locally and never shared with our servers
                    </p>
                  </div>

                  {apiSettings.provider === 'custom' && (
                    <div className="space-y-2">
                      <Label htmlFor="baseUrl">Base URL</Label>
                      <Input
                        id="baseUrl"
                        placeholder="https://api.example.com/v1"
                        value={apiSettings.baseUrl}
                        onChange={(e) => setApiSettings(prev => ({ ...prev, baseUrl: e.target.value }))}
                      />
                    </div>
                  )}

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="temperature">Temperature</Label>
                      <Select value={apiSettings.temperature} onValueChange={(value) => 
                        setApiSettings(prev => ({ ...prev, temperature: value }))}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="0">0 (Most focused)</SelectItem>
                          <SelectItem value="0.3">0.3</SelectItem>
                          <SelectItem value="0.7">0.7 (Balanced)</SelectItem>
                          <SelectItem value="1.0">1.0 (More creative)</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="maxTokens">Max Tokens</Label>
                      <Select value={apiSettings.maxTokens} onValueChange={(value) => 
                        setApiSettings(prev => ({ ...prev, maxTokens: value }))}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="1024">1024</SelectItem>
                          <SelectItem value="2048">2048</SelectItem>
                          <SelectItem value="4096">4096</SelectItem>
                          <SelectItem value="8192">8192</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 pt-4">
                    <Button onClick={testConnection} disabled={isTestingConnection || !apiSettings.apiKey}>
                      <TestTube className="h-4 w-4 mr-2" />
                      {isTestingConnection ? 'Testing...' : 'Test Connection'}
                    </Button>

                    {connectionStatus === 'success' && (
                      <div className="flex items-center gap-2 text-green-600">
                        <CheckCircle className="h-4 w-4" />
                        <span className="text-sm">Connection successful</span>
                      </div>
                    )}

                    {connectionStatus === 'error' && (
                      <div className="flex items-center gap-2 text-red-600">
                        <XCircle className="h-4 w-4" />
                        <span className="text-sm">Connection failed</span>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="security" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Shield className="h-5 w-5" />
                    Security Settings
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Encrypt API Keys</Label>
                      <p className="text-sm text-muted-foreground">
                        Encrypt stored API keys with a local passphrase
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Request Logging</Label>
                      <p className="text-sm text-muted-foreground">
                        Log API requests for debugging (keys are never logged)
                      </p>
                    </div>
                    <Switch />
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Auto-lock Session</Label>
                      <p className="text-sm text-muted-foreground">
                        Automatically lock the session after 30 minutes of inactivity
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="advanced" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Zap className="h-5 w-5" />
                    Advanced Settings
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Stream Responses</Label>
                      <p className="text-sm text-muted-foreground">
                        Enable streaming for faster response display
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-0.5">
                      <Label>Retry Failed Requests</Label>
                      <p className="text-sm text-muted-foreground">
                        Automatically retry failed API requests
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="timeout">Request Timeout (seconds)</Label>
                    <Select defaultValue="60">
                      <SelectTrigger className="w-48">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="30">30</SelectItem>
                        <SelectItem value="60">60</SelectItem>
                        <SelectItem value="120">120</SelectItem>
                        <SelectItem value="300">300</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          <div className="flex justify-end">
            <Button onClick={handleSave} size="lg">
              <Save className="h-4 w-4 mr-2" />
              Save Settings
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}