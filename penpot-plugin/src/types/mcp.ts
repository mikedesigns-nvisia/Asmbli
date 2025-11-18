/**
 * MCP Tool Types for PenPOT Plugin
 * Based on the MCP tools from mcp_penpot_server.dart
 */

export interface MCPToolRequest {
  tool: string;
  parameters: Record<string, any>;
}

export interface MCPToolResponse {
  success: boolean;
  data?: any;
  error?: string;
}

// CREATE operations
export interface CreateRectangleParams {
  x: number;
  y: number;
  width: number;
  height: number;
  fillColor?: string;
  strokeColor?: string;
  strokeWidth?: number;
  borderRadius?: number;
}

export interface CreateEllipseParams {
  x: number;
  y: number;
  width: number;
  height: number;
  fillColor?: string;
  strokeColor?: string;
  strokeWidth?: number;
}

export interface CreateTextParams {
  x: number;
  y: number;
  content: string;
  fontSize?: number;
  fontFamily?: string;
  fontWeight?: string;
  color?: string;
  align?: 'left' | 'center' | 'right';
}

export interface CreateFrameParams {
  x: number;
  y: number;
  width: number;
  height: number;
  name?: string;
  backgroundColor?: string;
}

// UPDATE operations
export interface UpdateElementParams {
  elementId: string;
  properties: {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    fillColor?: string;
    strokeColor?: string;
    strokeWidth?: number;
    content?: string;
    fontSize?: number;
    fontFamily?: string;
    [key: string]: any;
  };
}

// QUERY operations
export interface QueryElementsParams {
  type?: 'rectangle' | 'ellipse' | 'text' | 'frame' | 'path' | 'image';
  name?: string;
}

export interface GetElementDetailsParams {
  elementId: string;
}

// TRANSFORM operations
export interface RotateElementParams {
  elementId: string;
  degrees: number;
}

export interface ScaleElementParams {
  elementId: string;
  scaleX: number;
  scaleY?: number;
}

export interface FlipElementParams {
  elementId: string;
  direction: 'horizontal' | 'vertical';
}

// DELETE operations
export interface DeleteElementParams {
  elementId: string;
  permanent?: boolean;
}

// DUPLICATE operations
export interface DuplicateElementParams {
  elementId: string;
  offsetX?: number;
  offsetY?: number;
}

// GROUP operations
export interface GroupElementsParams {
  elementIds: string[];
  name?: string;
}

export interface UngroupElementsParams {
  groupId: string;
}

// REORDER operations
export interface ReorderElementParams {
  elementId: string;
  operation: 'toFront' | 'toBack' | 'forward' | 'backward';
}

// LAYOUT operations
export interface AlignElementsParams {
  elementIds: string[];
  alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom';
}

export interface DistributeElementsParams {
  elementIds: string[];
  direction: 'horizontal' | 'vertical';
  spacing?: number;
}

export interface SetConstraintsParams {
  elementId: string;
  constraints: {
    horizontal?: 'left' | 'right' | 'leftRight' | 'center' | 'scale';
    vertical?: 'top' | 'bottom' | 'topBottom' | 'center' | 'scale';
  };
}

// COMPONENT operations
export interface CreateComponentParams {
  elementIds: string[];
  name?: string;
}

export interface DetachComponentParams {
  instanceId: string;
}

export interface CreateComponentInstanceParams {
  componentId: string;
  x: number;
  y: number;
}

// EXPORT operations
export interface ExportElementParams {
  elementId: string;
  format: 'png' | 'svg' | 'pdf';
  scale?: number;
  quality?: number;
}

export interface ExportPageParams {
  format: 'png' | 'svg' | 'pdf';
  scale?: number;
  quality?: number;
}

export interface ExportSelectionParams {
  format: 'png' | 'svg' | 'pdf';
  scale?: number;
  quality?: number;
}

// Canvas state
export interface CanvasState {
  elements: CanvasElement[];
  selectedElements: string[];
}

export interface CanvasElement {
  id: string;
  type: 'rectangle' | 'ellipse' | 'text' | 'frame' | 'path' | 'image';
  x: number;
  y: number;
  width: number;
  height: number;
  properties: Record<string, any>;
}
