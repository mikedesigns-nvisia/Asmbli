import React from 'react';
import { FlowNode, WizardData } from '../types/wizard';

interface FlowDiagramProps {
  wizardData: WizardData;
}

export function FlowDiagram({ wizardData }: FlowDiagramProps) {
  const enabledExtensions = wizardData.extensions?.filter(s => s.enabled) || [];
  
  const nodes: FlowNode[] = [
    { id: 'user', label: 'User Input', status: 'active' as const },
    ...(wizardData.security?.authMethod ? [{ id: 'auth', label: 'Authentication', status: 'active' as const }] : []),
    { id: 'agent', label: wizardData.agentName || 'AI Agent', status: 'active' as const },
    ...(enabledExtensions.length > 0 ? [{ id: 'extensions', label: 'Extensions', status: 'active' as const }] : []),
    ...(wizardData.security?.auditLogging ? [{ id: 'audit', label: 'Audit Log', status: 'active' as const }] : []),
    { id: 'response', label: 'Response', status: 'active' as const }
  ];

  const getStatusColor = (status: FlowNode['status']) => {
    switch (status) {
      case 'active': return 'border-primary bg-primary/20 ring-1 ring-primary/20';
      case 'pending': return 'border-muted-foreground/50 bg-muted/30';
      case 'error': return 'border-destructive bg-destructive/20';
      default: return 'border-muted-foreground/50';
    }
  };

  return (
    <div className="flex flex-wrap items-center justify-center p-6 gap-4">
      {nodes.map((node, index) => (
        <React.Fragment key={node.id}>
          <div className={`backdrop-blur-xl px-3 py-2 rounded-lg border transition-all duration-300 bg-card text-card-foreground shadow-md ${getStatusColor(node.status)}`}>
            <div className="text-xs font-medium text-foreground">{node.label}</div>
            {node.id === 'extensions' && (
              <div className="text-xs text-muted-foreground mt-1">
                {enabledExtensions.length} active
              </div>
            )}
          </div>
          {index < nodes.length - 1 && (
            <div className="text-primary font-bold text-lg animate-pulse px-2">→</div>
          )}
        </React.Fragment>
      ))}
    </div>
  );
}