import React from 'react';
import { Badge } from './ui/badge';
import { WizardData } from '../types/wizard';
import { User, Layers, Shield, MessageSquare, TestTube, Rocket } from 'lucide-react';

interface WizardSelectionTrackerProps {
  wizardData: WizardData;
  currentStep: number;
}

interface SelectionField {
  label: string;
  value: string | null;
  icon?: React.ComponentType<{ className?: string }>;
  variant?: 'default' | 'secondary' | 'success' | 'warning';
}

export function WizardSelectionTracker({ wizardData, currentStep }: WizardSelectionTrackerProps) {
  const getSelectionFields = (): SelectionField[] => {
    const enabledExtensions = wizardData.extensions?.filter(e => e.enabled) || [];
    const selectedPlatforms = new Set(enabledExtensions.flatMap(e => e.selectedPlatforms));
    
    const fields: SelectionField[] = [];

    // Agent Name
    if (wizardData.agentName) {
      fields.push({
        label: 'Agent',
        value: wizardData.agentName,
        icon: User
      });
    }

    // Purpose
    if (wizardData.primaryPurpose) {
      fields.push({
        label: 'Purpose',
        value: wizardData.primaryPurpose.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase()),
        variant: 'secondary'
      });
    }

    // Environment
    if (wizardData.targetEnvironment) {
      fields.push({
        label: 'Environment',
        value: wizardData.targetEnvironment.charAt(0).toUpperCase() + wizardData.targetEnvironment.slice(1),
        variant: wizardData.targetEnvironment === 'production' ? 'success' : 'secondary'
      });
    }

    // Extensions
    if (enabledExtensions.length > 0) {
      fields.push({
        label: 'Extensions',
        value: `${enabledExtensions.length} configured`,
        icon: Layers,
        variant: 'default'
      });
    }

    // Platforms
    if (selectedPlatforms.size > 0) {
      fields.push({
        label: 'Platforms',
        value: Array.from(selectedPlatforms).join(', ').toUpperCase(),
        variant: 'secondary'
      });
    }

    // Security
    if (wizardData.security?.authMethod) {
      const authMethod = wizardData.security.authMethod.toUpperCase();
      fields.push({
        label: 'Security',
        value: authMethod,
        icon: Shield,
        variant: authMethod === 'OAUTH' || authMethod === 'MTLS' ? 'success' : 'warning'
      });
    }

    // Vault
    if (wizardData.security?.vaultIntegration && wizardData.security.vaultIntegration !== 'none') {
      fields.push({
        label: 'Vault',
        value: wizardData.security.vaultIntegration.charAt(0).toUpperCase() + wizardData.security.vaultIntegration.slice(1),
        variant: 'secondary'
      });
    }

    // Behavior
    if (wizardData.tone) {
      fields.push({
        label: 'Tone',
        value: wizardData.tone.charAt(0).toUpperCase() + wizardData.tone.slice(1),
        icon: MessageSquare,
        variant: 'secondary'
      });
    }

    // Constraints
    if (wizardData.constraints?.length > 0) {
      fields.push({
        label: 'Constraints',
        value: `${wizardData.constraints.length} active`,
        variant: 'secondary'
      });
    }

    // Test Status
    if (wizardData.testResults?.overallStatus && wizardData.testResults.overallStatus !== 'pending') {
      fields.push({
        label: 'Tests',
        value: wizardData.testResults.overallStatus === 'passed' ? 'Passed' : 'Failed',
        icon: TestTube,
        variant: wizardData.testResults.overallStatus === 'passed' ? 'success' : 'warning'
      });
    }

    // Deployment Format
    if (wizardData.deploymentFormat) {
      const formatLabels = {
        'desktop': 'Desktop (.dxt)',
        'docker': 'Docker',
        'kubernetes': 'Kubernetes',
        'json': 'JSON Config'
      };
      fields.push({
        label: 'Deploy',
        value: formatLabels[wizardData.deploymentFormat as keyof typeof formatLabels] || wizardData.deploymentFormat.toUpperCase(),
        icon: Rocket,
        variant: 'success'
      });
    }

    return fields;
  };

  const selectionFields = getSelectionFields();

  if (selectionFields.length === 0) {
    return null;
  }

  return (
    <div className="border-b border-border bg-card/30 backdrop-blur-sm">
      <div className="max-w-4xl mx-auto px-4 lg:px-8 py-2.5">
        <div className="space-y-1.5">
          <span className="text-xs text-muted-foreground font-medium block">
            Current Selections:
          </span>
          
          <div className="flex items-center gap-2 flex-wrap">
            {selectionFields.map((field, index) => {
              const Icon = field.icon;
              return (
                <div key={index} className="flex items-center gap-1.5 flex-shrink-0">
                  {Icon && (
                    <Icon className="w-3.5 h-3.5 text-muted-foreground" />
                  )}
                  
                  <div className="flex items-center gap-1">
                    <span className="text-xs text-muted-foreground max-w-20 truncate flex-shrink-0">
                      {field.label}:
                    </span>
                    <Badge 
                      variant={field.variant || 'default'} 
                      className="chip-hug text-xs h-5 max-w-40 truncate px-2 py-1"
                      title={field.value || ''}
                    >
                      {field.value}
                    </Badge>
                  </div>
                  
                  {index < selectionFields.length - 1 && (
                    <div className="w-px h-3 bg-border ml-1" />
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}