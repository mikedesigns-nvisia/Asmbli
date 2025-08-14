import React from 'react';
import { FlowNode, WizardData } from '../types/wizard';

interface FlowDiagramProps {
  wizardData: WizardData;
}

export function FlowDiagram({ wizardData }: FlowDiagramProps) {
  const enabledExtensions = wizardData.extensions?.filter(s => s.enabled) || [];
  
  const nodes: FlowNode[] = [
    { id: 'user', label: 'User Input', status: 'active' },
    ...(wizardData.security?.authMethod ? [{ id: 'auth', label: 'Authentication', status: 'active' }] : []),
    { id: 'agent', label: wizardData.agentName || 'AI Agent', status: 'active' },
    ...(enabledExtensions.length > 0 ? [{ id: 'extensions', label: 'Extensions', status: 'active' }] : []),
    ...(wizardData.security?.auditLogging ? [{ id: 'audit', label: 'Audit Log', status: 'active' }] : []),
    { id: 'response', label: 'Response', status: 'active' }
  ];

  const getStatusColor = (status: FlowNode['status']) => {
    switch (status) {
      case 'active': return 'border-primary bg-primary/10';
      case 'pending': return 'border-muted-foreground/30 bg-muted/50';
      case 'error': return 'border-destructive bg-destructive/10';
      default: return 'border-muted-foreground/30';
    }
  };

  return (
    <div className="flex flex-wrap items-center justify-center p-6 gap-4">
      {nodes.map((node, index) => (
        <React.Fragment key={node.id}>
          <div className={`backdrop-blur-xl px-3 py-2 rounded-lg border transition-all duration-300 ${getStatusColor(node.status)}`} style={{
            background: 'rgba(24, 24, 27, 0.8)',
            boxShadow: '0 0 0 1px rgba(255, 255, 255, 0.05)'
          }}>
            <div className="text-xs font-medium text-foreground">{node.label}</div>
            {node.id === 'extensions' && (
              <div className="text-xs text-muted-foreground mt-1">
                {enabledExtensions.length} active
              </div>
            )}
          </div>
          {index < nodes.length - 1 && (
            <div className="text-primary animate-pulse">→</div>
          )}
        </React.Fragment>
      ))}
    </div>
  );
}