import { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '../ui/dropdown-menu';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { User, Settings, LogOut, Crown, Zap, Building, ChevronDown, CheckCircle, X, ArrowUp, Shield } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { UserRole, ROLE_CONFIGURATIONS } from '../../types/auth';

export function UserProfile() {
  const { user, logout, updateUserRole } = useAuth();
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  
  if (!user) return null;

  const currentRoleConfig = ROLE_CONFIGURATIONS[user.role];
  
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

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

  const handleRoleUpgrade = (newRole: UserRole) => {
    updateUserRole(newRole);
    setShowUpgradeModal(false);
  };

  const RoleIcon = roleIcons[user.role];

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="flex items-center gap-3 h-auto p-2">
            <Avatar className="h-8 w-8">
              <AvatarFallback className="text-xs">
                {getInitials(user.name)}
              </AvatarFallback>
            </Avatar>
            <div className="text-left hidden sm:block">
              <div className="text-sm font-medium">{user.name}</div>
              <div className="text-xs text-muted-foreground flex items-center gap-1">
                <RoleIcon className="w-3 h-3" />
                {currentRoleConfig.displayName}
              </div>
            </div>
            <ChevronDown className="w-4 h-4 text-muted-foreground" />
          </Button>
        </DropdownMenuTrigger>
        
        <DropdownMenuContent align="end" className="w-72">
          <div className="p-4 border-b">
            <div className="flex items-center gap-3">
              <Avatar className="h-12 w-12">
                <AvatarFallback>
                  {getInitials(user.name)}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <div className="font-medium">{user.name}</div>
                <div className="text-sm text-muted-foreground">{user.email}</div>
                <Badge className={`mt-1 ${roleColors[user.role]}`}>
                  <RoleIcon className="w-3 h-3 mr-1" />
                  {currentRoleConfig.displayName}
                </Badge>
              </div>
            </div>
          </div>

          <div className="p-2 border-b">
            <div className="text-xs text-muted-foreground mb-2">Current Plan Features</div>
            <div className="space-y-1">
              <div className="flex items-center justify-between text-sm">
                <span>Agents</span>
                <span className="font-medium">
                  {currentRoleConfig.features.maxAgents === -1 ? 'Unlimited' : currentRoleConfig.features.maxAgents}
                </span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span>Security</span>
                <span className={currentRoleConfig.features.securityCustomization ? 'text-green-600' : 'text-red-600'}>
                  {currentRoleConfig.features.securityCustomization ? 'Custom' : 'Basic'}
                </span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span>Extensions</span>
                <span className={currentRoleConfig.features.advancedExtensions ? 'text-green-600' : 'text-red-600'}>
                  {currentRoleConfig.features.advancedExtensions ? 'Advanced' : 'Basic'}
                </span>
              </div>
            </div>
          </div>

          <DropdownMenuItem className="flex items-center gap-2" disabled>
            <Settings className="w-4 h-4" />
            Settings
          </DropdownMenuItem>
          
          {user.role !== 'enterprise' && (
            <DropdownMenuItem 
              className="flex items-center gap-2 text-blue-600" 
              onClick={() => setShowUpgradeModal(true)}
            >
              <ArrowUp className="w-4 h-4" />
              Upgrade Plan
            </DropdownMenuItem>
          )}
          
          <DropdownMenuSeparator />
          
          <DropdownMenuItem 
            className="flex items-center gap-2 text-red-600" 
            onClick={logout}
          >
            <LogOut className="w-4 h-4" />
            Sign Out
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      {/* Upgrade Modal */}
      <Dialog open={showUpgradeModal} onOpenChange={setShowUpgradeModal}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Crown className="w-5 h-5 text-yellow-500" />
              Upgrade Your Plan
            </DialogTitle>
            <DialogDescription>
              Unlock more features and capabilities for your AI agents
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {Object.entries(ROLE_CONFIGURATIONS).map(([role, config]) => {
              const IconComponent = roleIcons[role as UserRole];
              const isCurrentPlan = user.role === role;
              const isUpgrade = (role === 'power_user' && user.role === 'beginner') || 
                              (role === 'enterprise' && ['beginner', 'power_user'].includes(user.role));
              
              return (
                <Card
                  key={role}
                  className={`relative ${
                    isCurrentPlan ? 'ring-2 ring-green-500 bg-green-50/50' : 
                    isUpgrade ? 'ring-1 ring-primary/20 hover:ring-primary/40 cursor-pointer' : 
                    'opacity-50'
                  }`}
                  onClick={isUpgrade ? () => handleRoleUpgrade(role as UserRole) : undefined}
                >
                  {isCurrentPlan && (
                    <div className="absolute -top-2 -right-2">
                      <Badge className="bg-green-500 text-white">
                        Current
                      </Badge>
                    </div>
                  )}
                  
                  <CardHeader className="text-center pb-4">
                    <div className={`w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-3 ${roleColors[role as UserRole]}`}>
                      <IconComponent className="w-8 h-8" />
                    </div>
                    <CardTitle className="text-xl">{config.displayName}</CardTitle>
                    <div className="text-2xl font-bold text-foreground">
                      {config.price}
                    </div>
                  </CardHeader>
                  
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center gap-2 text-sm">
                        <CheckCircle className="w-4 h-4 text-green-500" />
                        <span>{config.features.maxAgents === -1 ? 'Unlimited' : config.features.maxAgents} agents</span>
                      </div>
                      
                      <div className="flex items-center gap-2 text-sm">
                        <CheckCircle className="w-4 h-4 text-green-500" />
                        <span>
                          {config.features.securityCustomization ? 'Advanced security' : 'Basic security'}
                        </span>
                      </div>
                      
                      <div className="flex items-center gap-2 text-sm">
                        <CheckCircle className="w-4 h-4 text-green-500" />
                        <span>
                          {config.features.advancedExtensions ? 'All extensions' : 'Basic extensions'}
                        </span>
                      </div>
                      
                      {config.features.prioritySupport && (
                        <div className="flex items-center gap-2 text-sm">
                          <CheckCircle className="w-4 h-4 text-green-500" />
                          <span>Priority support</span>
                        </div>
                      )}
                      
                      {config.features.teamCollaboration && (
                        <div className="flex items-center gap-2 text-sm">
                          <CheckCircle className="w-4 h-4 text-green-500" />
                          <span>Team collaboration</span>
                        </div>
                      )}
                    </div>
                    
                    {isUpgrade && (
                      <Button className="w-full mt-4" onClick={() => handleRoleUpgrade(role as UserRole)}>
                        Upgrade to {config.displayName}
                      </Button>
                    )}
                    
                    {isCurrentPlan && (
                      <div className="mt-4 text-center text-sm text-green-600 font-medium">
                        ✓ Your current plan
                      </div>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </div>

          <div className="flex justify-end pt-4">
            <Button variant="outline" onClick={() => setShowUpgradeModal(false)}>
              <X className="w-4 h-4 mr-2" />
              Close
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}