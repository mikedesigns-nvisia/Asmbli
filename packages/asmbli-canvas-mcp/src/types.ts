import { z } from 'zod';

// Canvas Element Types
export enum ElementType {
  CONTAINER = 'container',
  TEXT = 'text',
  BUTTON = 'button',
  INPUT = 'input',
  IMAGE = 'image',
  ICON = 'icon',
  CARD = 'card',
  LIST = 'list',
  GRID = 'grid',
}

// Design System Types
export interface DesignToken {
  colors: Record<string, string>;
  typography: Record<string, TypographyStyle>;
  spacing: Record<string, number>;
  borderRadius: Record<string, number>;
  elevation: Record<string, ElevationStyle>;
  breakpoints: Record<string, number>;
}

export interface TypographyStyle {
  fontSize: number;
  lineHeight: number;
  fontWeight: number | string;
  letterSpacing?: number;
  fontFamily?: string;
}

export interface ElevationStyle {
  shadowColor: string;
  shadowOffset: { x: number; y: number };
  shadowRadius: number;
  shadowOpacity: number;
}

export interface ComponentVariant {
  name: string;
  props: Record<string, any>;
  children?: CanvasElement[];
}

export interface DesignSystem {
  id: string;
  name: string;
  version: string;
  extends?: string; // Parent design system
  tokens: DesignToken;
  components: Record<string, ComponentDefinition>;
}

export interface ComponentDefinition {
  type: ElementType;
  variants: Record<string, ComponentVariant>;
  defaultVariant: string;
  props: Record<string, any>;
}

// Canvas Element
export interface CanvasElement {
  id: string;
  type: ElementType;
  x: number;
  y: number;
  width: number;
  height: number;
  rotation?: number;
  opacity?: number;
  visible?: boolean;
  locked?: boolean;
  
  // Styling
  style?: ElementStyle;
  
  // Content
  text?: string;
  src?: string; // For images
  placeholder?: string; // For inputs
  
  // Hierarchy
  children?: CanvasElement[];
  parent?: string; // Parent element ID
  
  // Interaction
  onClick?: string; // Action ID
  href?: string; // For links
  
  // Design system reference
  component?: string; // Component name from design system
  variant?: string; // Component variant
  tokenOverrides?: Record<string, any>; // Override specific tokens
}

export interface ElementStyle {
  // Background
  backgroundColor?: string;
  backgroundImage?: string;
  backgroundGradient?: GradientStyle;
  
  // Border
  borderColor?: string;
  borderWidth?: number;
  borderStyle?: 'solid' | 'dashed' | 'dotted';
  borderRadius?: number | [number, number, number, number];
  
  // Text
  color?: string;
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: number | string;
  lineHeight?: number;
  textAlign?: 'left' | 'center' | 'right' | 'justify';
  
  // Layout
  padding?: number | [number, number, number, number];
  margin?: number | [number, number, number, number];
  
  // Flexbox
  display?: 'flex' | 'grid' | 'block' | 'inline';
  flexDirection?: 'row' | 'column';
  justifyContent?: 'start' | 'center' | 'end' | 'space-between' | 'space-around';
  alignItems?: 'start' | 'center' | 'end' | 'stretch';
  gap?: number;
  
  // Effects
  boxShadow?: string;
  filter?: string;
}

export interface GradientStyle {
  type: 'linear' | 'radial';
  colors: string[];
  stops?: number[];
  angle?: number; // For linear
  center?: { x: number; y: number }; // For radial
}

// Canvas State
export interface CanvasState {
  id: string;
  name: string;
  width: number;
  height: number;
  backgroundColor: string;
  elements: CanvasElement[];
  selectedElements: string[];
  designSystemId?: string;
  grid?: {
    enabled: boolean;
    size: number;
    snap: boolean;
  };
  guides?: {
    enabled: boolean;
    smart: boolean;
  };
}

// MCP Tool Schemas
export const CreateElementSchema = z.object({
  type: z.enum(['container', 'text', 'button', 'input', 'image', 'icon', 'card']),
  x: z.number(),
  y: z.number(),
  width: z.number(),
  height: z.number(),
  style: z.record(z.any()).optional(),
  text: z.string().optional(),
  component: z.string().optional(),
  variant: z.string().optional(),
});

export const ModifyElementSchema = z.object({
  elementId: z.string(),
  updates: z.object({
    x: z.number().optional(),
    y: z.number().optional(),
    width: z.number().optional(),
    height: z.number().optional(),
    style: z.record(z.any()).optional(),
    text: z.string().optional(),
  }),
});

export const RenderDesignSchema = z.object({
  description: z.string(),
  designSystemId: z.string().optional(),
  style: z.enum(['material3', 'ios', 'fluent', 'minimal']).optional(),
});

export const ExportCodeSchema = z.object({
  format: z.enum(['flutter', 'react', 'html', 'swiftui']),
  includeTokens: z.boolean().default(true),
  componentize: z.boolean().default(true),
});

export const LoadDesignSystemSchema = z.object({
  designSystemId: z.string(),
  merge: z.boolean().default(false),
});