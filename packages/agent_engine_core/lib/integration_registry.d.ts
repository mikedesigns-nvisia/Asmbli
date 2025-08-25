// TypeScript declarations for IntegrationRegistry
// This allows web apps to import and use the unified integration definitions

export enum IntegrationCategory {
  local = 'local',
  cloudAPIs = 'cloudAPIs',  
  databases = 'databases',
  utilities = 'utilities',
  aiML = 'aiML'
}

export interface IntegrationDefinition {
  readonly id: string;
  readonly name: string;
  readonly description: string;
  readonly category: IntegrationCategory;
  readonly difficulty: 'Easy' | 'Medium' | 'Hard';
  readonly tags: readonly string[];
  readonly command: string;
  readonly args: readonly string[];
  readonly workingDirectory?: string;
  readonly configFields: readonly IntegrationField[];
  readonly prerequisites: readonly string[];
  readonly capabilities: readonly string[];
  readonly documentationUrl?: string;
  readonly isPopular: boolean;
  readonly isRecommended: boolean;
  readonly isAvailable: boolean;
}

export interface IntegrationField {
  readonly id: string;
  readonly label: string;
  readonly description?: string;
  readonly placeholder?: string;
  readonly required: boolean;
  readonly fieldType: IntegrationFieldType;
  readonly options: Record<string, any>;
  readonly defaultValue?: any;
}

export enum IntegrationFieldType {
  text = 'text',
  password = 'password',
  email = 'email',
  url = 'url',
  number = 'number',
  boolean = 'boolean',
  select = 'select',
  multiSelect = 'multiSelect',
  path = 'path',
  file = 'file',
  directory = 'directory',
  apiToken = 'apiToken',
  oauth = 'oauth',
  database = 'database'
}

export class IntegrationRegistry {
  static readonly allIntegrations: readonly IntegrationDefinition[];
  
  static getByCategory(category: IntegrationCategory): readonly IntegrationDefinition[];
  static getById(id: string): IntegrationDefinition | undefined;
  static search(query: string): readonly IntegrationDefinition[];
}

// Export all individual integration definitions
export declare const filesystem: IntegrationDefinition;
export declare const git: IntegrationDefinition;
export declare const terminal: IntegrationDefinition;
export declare const memory: IntegrationDefinition;
export declare const github: IntegrationDefinition;
export declare const figma: IntegrationDefinition;
export declare const slack: IntegrationDefinition;
export declare const notion: IntegrationDefinition;
export declare const googleDrive: IntegrationDefinition;
export declare const linearApp: IntegrationDefinition;
export declare const postgresql: IntegrationDefinition;
export declare const mysql: IntegrationDefinition;
export declare const mongodb: IntegrationDefinition;
export declare const webSearch: IntegrationDefinition;
export declare const httpClient: IntegrationDefinition;
export declare const calendar: IntegrationDefinition;
export declare const time: IntegrationDefinition;
export declare const sequentialThinking: IntegrationDefinition;