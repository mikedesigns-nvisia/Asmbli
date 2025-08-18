import React from 'react';
import { Extension as ExtensionFromLibrary } from '../../../types/wizard';

export interface Extension extends ExtensionFromLibrary {
  enabled?: boolean;
  selectedPlatforms?: string[];
  status?: 'configuring' | 'configured' | 'error';
  configProgress?: number;
}

export interface ExtensionCategory {
  id: string;
  name: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  extensions: Extension[];
}

export interface Step2ExtensionsProps {
  data: any;
  onUpdate: (updates: any) => void;
  onNext: () => void;
  onPrev: () => void;
}

export type ViewMode = 'grid' | 'list' | 'compact';
export type SortBy = 'popular' | 'recent' | 'alphabetical' | 'security';