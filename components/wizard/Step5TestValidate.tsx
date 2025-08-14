import React, { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Progress } from '../ui/progress';
import { ArrowRight, ArrowLeft, Play, CheckCircle, XCircle, Clock, Zap, Shield, Database, AlertTriangle, RefreshCw } from 'lucide-react';

interface Step5TestValidateProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function Step5TestValidate({ data, onUpdate, onNext, onPrev }: Step5TestValidateProps) {
  const [testResults, setTestResults] = useState(data.testResults || {
    connectionTests: {},
    latencyTests: {},
    securityValidation: false,
    overallStatus: 'pending'
  });
  
  const [isRunningTests, setIsRunningTests] = useState(false);
  const [currentTest, setCurrentTest] = useState('');

  const testSuites = [
    {
      id: 'connection',
      name: 'Extension Connectivity',
      description: 'Test connections to all configured extensions',
      icon: Database,
      tests: data.extensions?.filter((s: any) => s.enabled).map((server: any) => ({
        id: server.id,
        name: `${server.name} Connection`,
        description: `Test ${server.transport} connection to ${server.name}`,
        timeout: 5000
      })) || []
    },
    {
      id: 'latency',
      name: 'Performance & Latency',
      description: 'Measure response times and performance metrics',
      icon: Zap,
      tests: [
        {
          id: 'prompt-processing',
          name: 'Prompt Processing Speed',
          description: 'Test system prompt compilation and processing time',
          timeout: 3000
        },
        {
          id: 'extension-response',
          name: 'Extension Response Time',
          description: 'Measure average extension response latency',
          timeout: 10000
        }
      ]
    },
    {
      id: 'security',
      name: 'Security Validation',
      description: 'Validate authentication and security configurations',
      icon: Shield,
      tests: [
        {
          id: 'auth-config',
          name: 'Authentication Configuration',
          description: 'Verify authentication method setup',
          timeout: 2000
        },
        {
          id: 'permission-check',
          name: 'Permission Validation',
          description: 'Test permission scoping and access controls',
          timeout: 3000
        },
        ...(data.security?.vaultIntegration !== 'none' ? [{
          id: 'vault-connection',
          name: 'Secret Management Connection',
          description: `Test ${data.security.vaultIntegration} integration`,
          timeout: 5000
        }] : [])
      ]
    },
    {
      id: 'integration',
      name: 'Integration Testing',
      description: 'End-to-end workflow validation',
      icon: RefreshCw,
      tests: [
        {
          id: 'sample-prompt',
          name: 'Sample Prompt Execution',
          description: 'Test agent response with sample input',
          timeout: 15000
        },
        {
          id: 'error-handling',
          name: 'Error Handling',
          description: 'Test graceful error handling and recovery',
          timeout: 5000
        }
      ]
    }
  ];

  // Mock test execution
  const runTests = async () => {
    setIsRunningTests(true);
    const newResults = {
      connectionTests: {},
      latencyTests: {},
      securityValidation: false,
      overallStatus: 'pending' as const
    };

    for (const suite of testSuites) {
      for (const test of suite.tests) {
        setCurrentTest(`${suite.name}: ${test.name}`);
        
        // Simulate test execution
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        // Mock test results (90% success rate)
        const success = Math.random() > 0.1;
        const latency = Math.floor(50 + Math.random() * 500); // 50-550ms
        
        if (suite.id === 'connection') {
          newResults.connectionTests[test.id] = success;
        } else if (suite.id === 'latency') {
          newResults.latencyTests[test.id] = latency;
        } else if (suite.id === 'security') {
          if (test.id === 'auth-config' && success) {
            newResults.securityValidation = true;
          }
        }
      }
    }

    // Determine overall status
    const connectionsPassed = Object.values(newResults.connectionTests).every(result => result);
    const latencyGood = Object.values(newResults.latencyTests).every(latency => latency < 1000);
    
    newResults.overallStatus = connectionsPassed && latencyGood && newResults.securityValidation ? 'passed' : 'failed';
    
    setTestResults(newResults);
    onUpdate({ testResults: newResults });
    setIsRunningTests(false);
    setCurrentTest('');
  };

  const getTestProgress = () => {
    const totalTests = testSuites.reduce((acc, suite) => acc + suite.tests.length, 0);
    const completedTests = 
      Object.keys(testResults.connectionTests).length +
      Object.keys(testResults.latencyTests).length +
      (testResults.securityValidation ? 2 : 0); // Approximate for security tests
    
    return Math.min((completedTests / totalTests) * 100, 100);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'passed': return <CheckCircle className="w-5 h-5 text-success" />;
      case 'failed': return <XCircle className="w-5 h-5 text-destructive" />;
      default: return <Clock className="w-5 h-5 text-muted-foreground" />;
    }
  };

  const getLatencyColor = (latency: number) => {
    if (latency < 200) return 'text-success';
    if (latency < 500) return 'text-warning';
    return 'text-destructive';
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      <div className="text-center space-y-4">
        <h1 className="bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
          Test & Validation
        </h1>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Validate your agent configuration by running comprehensive tests on connectivity,
          performance, security, and end-to-end functionality before deployment.
        </p>
      </div>

      {/* Test Overview */}
      <Card className="selection-card border-primary/30">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Play className="w-6 h-6 text-primary" />
              <CardTitle>Test Suite Overview</CardTitle>
            </div>
            <div className="flex items-center gap-2">
              {getStatusIcon(testResults.overallStatus)}
              <Badge 
                variant={testResults.overallStatus === 'passed' ? 'default' : 
                         testResults.overallStatus === 'failed' ? 'destructive' : 'secondary'}
                className="chip-hug capitalize"
              >
                {testResults.overallStatus === 'pending' ? 'Ready to Test' : testResults.overallStatus}
              </Badge>
            </div>
          </div>
          <CardDescription>
            Comprehensive validation of your agent configuration and dependencies
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {isRunningTests && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">Running Tests...</span>
                <span className="text-sm text-muted-foreground">{Math.round(getTestProgress())}%</span>
              </div>
              <Progress value={getTestProgress()} className="w-full" />
              {currentTest && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  <span>{currentTest}</span>
                </div>
              )}
            </div>
          )}

          {!isRunningTests && (
            <Button 
              onClick={runTests}
              className="w-full bg-primary hover:bg-primary/90"
              size="lg"
            >
              <Play className="w-5 h-5 mr-2" />
              Run All Tests
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Test Results */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {testSuites.map((suite) => {
          const Icon = suite.icon;
          const suiteResults = suite.tests.map(test => {
            if (suite.id === 'connection') {
              return { ...test, result: testResults.connectionTests[test.id], type: 'connection' };
            } else if (suite.id === 'latency') {
              return { ...test, result: testResults.latencyTests[test.id], type: 'latency' };
            } else if (suite.id === 'security') {
              return { ...test, result: testResults.securityValidation, type: 'security' };
            } else {
              return { ...test, result: testResults.overallStatus === 'passed', type: 'integration' };
            }
          });
          
          const suitePassed = suiteResults.every(result => 
            result.type === 'latency' ? (result.result as number) < 1000 : result.result === true
          );

          return (
            <Card key={suite.id} className="selection-card">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Icon className="w-5 h-5 text-primary" />
                    <CardTitle className="text-base">{suite.name}</CardTitle>
                  </div>
                  {Object.keys(testResults.connectionTests).length > 0 && getStatusIcon(suitePassed ? 'passed' : 'failed')}
                </div>
                <CardDescription>{suite.description}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {suiteResults.map((test) => (
                    <div key={test.id} className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                      <div className="space-y-1">
                        <h4 className="font-medium text-sm">{test.name}</h4>
                        <p className="text-xs text-muted-foreground">{test.description}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        {test.type === 'latency' && typeof test.result === 'number' ? (
                          <div className="text-right">
                            <div className={`font-mono text-sm ${getLatencyColor(test.result)}`}>
                              {test.result}ms
                            </div>
                            <div className="text-xs text-muted-foreground">latency</div>
                          </div>
                        ) : test.result !== undefined ? (
                          getStatusIcon(test.result ? 'passed' : 'failed')
                        ) : (
                          <Clock className="w-4 h-4 text-muted-foreground" />
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Configuration Summary */}
      {testResults.overallStatus !== 'pending' && (
        <Card className="selection-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-primary" />
              Configuration Summary
            </CardTitle>
            <CardDescription>
              Review your validated agent configuration before deployment
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 text-sm">
              <div className="space-y-2">
                <h4 className="font-medium">Agent Profile</h4>
                <div className="space-y-1 text-muted-foreground">
                  <div>{data.agentName || 'Unnamed Agent'}</div>
                  <div className="capitalize">{data.primaryPurpose?.replace('-', ' ')}</div>
                  <div className="capitalize">{data.targetEnvironment} environment</div>
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-medium">Extensions</h4>
                <div className="space-y-1 text-muted-foreground">
                  {data.extensions?.filter((s: any) => s.enabled).map((server: any) => (
                    <div key={server.id} className="flex items-center gap-2">
                      <div className={`w-2 h-2 rounded-full ${
                        testResults.connectionTests[server.id] ? 'bg-success' : 'bg-destructive'
                      }`} />
                      {server.name}
                    </div>
                  )) || <div>No extensions configured</div>}
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-medium">Security</h4>
                <div className="space-y-1 text-muted-foreground">
                  <div className="capitalize">{data.security?.authMethod || 'No auth'}</div>
                  <div>{data.security?.permissions?.length || 0} permissions</div>
                  <div className="capitalize">{data.security?.vaultIntegration === 'none' ? 'No vault' : data.security?.vaultIntegration}</div>
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-medium">Behavior</h4>
                <div className="space-y-1 text-muted-foreground">
                  <div className="capitalize">{data.tone} tone</div>
                  <div>Length level {data.responseLength}/5</div>
                  <div>{data.constraints?.length || 0} constraints</div>
                </div>
              </div>
            </div>

            {testResults.overallStatus === 'failed' && (
              <div className="mt-6 p-4 bg-destructive/10 border border-destructive/30 rounded-lg">
                <div className="flex items-center gap-2 text-destructive">
                  <AlertTriangle className="w-5 h-5" />
                  <h4 className="font-medium">Test Failures Detected</h4>
                </div>
                <p className="text-sm text-muted-foreground mt-1">
                  Some tests failed. Review the configuration and test results before proceeding to deployment.
                  You may still proceed, but consider addressing the issues for optimal performance.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Navigation */}
      <div className="flex justify-between pt-6">
        <Button variant="outline" onClick={onPrev} className="px-8">
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <Button 
          onClick={onNext}
          className="px-8 py-2 bg-primary hover:bg-primary/90 text-primary-foreground"
          disabled={testResults.overallStatus === 'pending'}
        >
          Deploy Agent
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}