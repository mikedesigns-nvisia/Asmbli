
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Lock, Shield, CheckCircle, ArrowUp } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { WizardData } from '../../types/wizard';
import { Step3SecurityAccess } from './Step3SecurityAccess';

interface RoleBasedSecurityStepProps {
  data: WizardData;
  onUpdate: (updates: Partial<WizardData>) => void;
  onNext: () => void;
  onPrev: () => void;
}

export function RoleBasedSecurityStep({ data, onUpdate, onNext, onPrev }: RoleBasedSecurityStepProps) {
  const { user, updateUserRole } = useAuth();

  if (!user) return null;

  // Beginner users get pre-configured security settings
  if (user.role === 'beginner') {
    return (
      <div className="space-y-8 animate-fadeIn">
        <div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Security & Access</h2>
          <p className="text-muted-foreground">
            Your security settings are pre-configured for optimal safety and ease of use.
          </p>
        </div>

        <Card className="border-green-500/20 bg-green-500/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-green-600">
              <Shield className="w-5 h-5" />
              Pre-Configured Security
            </CardTitle>
            <CardDescription>
              Perfect for beginners - secure defaults with no configuration needed
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center gap-3 p-3 bg-background rounded-lg border">
                <CheckCircle className="w-5 h-5 text-green-500" />
                <div>
                  <div className="font-medium">No Authentication</div>
                  <div className="text-sm text-muted-foreground">Simple and secure for local use</div>
                </div>
              </div>
              
              <div className="flex items-center gap-3 p-3 bg-background rounded-lg border">
                <CheckCircle className="w-5 h-5 text-green-500" />
                <div>
                  <div className="font-medium">Read-Only Permissions</div>
                  <div className="text-sm text-muted-foreground">Safe default access level</div>
                </div>
              </div>
              
              <div className="flex items-center gap-3 p-3 bg-background rounded-lg border">
                <CheckCircle className="w-5 h-5 text-green-500" />
                <div>
                  <div className="font-medium">Rate Limiting</div>
                  <div className="text-sm text-muted-foreground">Prevents abuse and overuse</div>
                </div>
              </div>
              
              <div className="flex items-center gap-3 p-3 bg-background rounded-lg border">
                <CheckCircle className="w-5 h-5 text-green-500" />
                <div>
                  <div className="font-medium">1 Hour Sessions</div>
                  <div className="text-sm text-muted-foreground">Automatic timeout for security</div>
                </div>
              </div>
            </div>

            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start gap-3">
                <Lock className="w-5 h-5 text-blue-600 mt-0.5" />
                <div>
                  <h4 className="font-medium text-blue-900">Ready for LM Studio & Claude Desktop</h4>
                  <p className="text-sm text-blue-700 mt-1">
                    These settings work perfectly with local AI tools like LM Studio and Claude Desktop. 
                    Your agent will be secure and ready to deploy immediately.
                  </p>
                </div>
              </div>
            </div>

            <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
              <div className="flex items-start gap-3">
                <ArrowUp className="w-5 h-5 text-orange-600 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-medium text-orange-900">Want Custom Security?</h4>
                  <p className="text-sm text-orange-700 mt-1">
                    Upgrade to Power User or Enterprise to customize authentication, permissions, and advanced security settings.
                  </p>
                  <div className="flex gap-2 mt-3">
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="border-orange-300 text-orange-700 hover:bg-orange-100"
                      onClick={() => updateUserRole('power_user')}
                    >
                      Upgrade to Power User ($29/mo)
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      className="border-orange-300 text-orange-700 hover:bg-orange-100"
                      onClick={() => updateUserRole('enterprise')}
                    >
                      Upgrade to Enterprise ($199/mo)
                    </Button>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex justify-between pt-4">
              <Button variant="outline" onClick={onPrev}>
                Previous
              </Button>
              <Button onClick={onNext} className="bg-green-600 hover:bg-green-700">
                Continue with Pre-Configured Security
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Power User and Enterprise get full security customization
  return <Step3SecurityAccess data={data} onUpdate={onUpdate} onNext={onNext} onPrev={onPrev} />;
}