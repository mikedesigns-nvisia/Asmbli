import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  ToolSchema,
  ResourceSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

import { CanvasEngine } from './canvas/CanvasEngine.js';
import {
  CreateElementSchema,
  ModifyElementSchema,
  RenderDesignSchema,
  ExportCodeSchema,
  LoadDesignSystemSchema,
  DesignSystem,
  CanvasElement,
  ElementType,
} from './types.js';
import { DesignRenderer } from './services/DesignRenderer.js';
import { CodeExporter } from './services/CodeExporter.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export class CanvasServer {
  private server: Server;
  private canvas: CanvasEngine;
  private designSystems: Map<string, DesignSystem> = new Map();
  private designRenderer: DesignRenderer;
  private codeExporter: CodeExporter;

  constructor() {
    this.canvas = new CanvasEngine({
      name: 'Asmbli Canvas',
      width: 800,
      height: 600,
    });
    
    this.designRenderer = new DesignRenderer(this.canvas);
    this.codeExporter = new CodeExporter();
    
    this.server = new Server(
      {
        name: 'asmbli-canvas',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.setupHandlers();
    this.loadDefaultDesignSystems();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'create_element',
          description: 'Create a new UI element on the canvas',
          inputSchema: {
            type: 'object',
            properties: {
              type: { 
                type: 'string',
                enum: ['container', 'text', 'button', 'input', 'image', 'icon', 'card'],
                description: 'Type of element to create'
              },
              x: { type: 'number', description: 'X position' },
              y: { type: 'number', description: 'Y position' },
              width: { type: 'number', description: 'Element width' },
              height: { type: 'number', description: 'Element height' },
              style: { type: 'object', description: 'Style properties' },
              text: { type: 'string', description: 'Text content (for text/button elements)' },
              component: { type: 'string', description: 'Design system component name' },
              variant: { type: 'string', description: 'Component variant' },
            },
            required: ['type', 'x', 'y', 'width', 'height'],
          },
        },
        {
          name: 'modify_element',
          description: 'Modify properties of an existing element',
          inputSchema: {
            type: 'object',
            properties: {
              elementId: { type: 'string', description: 'ID of element to modify' },
              updates: {
                type: 'object',
                properties: {
                  x: { type: 'number' },
                  y: { type: 'number' },
                  width: { type: 'number' },
                  height: { type: 'number' },
                  style: { type: 'object' },
                  text: { type: 'string' },
                },
              },
            },
            required: ['elementId', 'updates'],
          },
        },
        {
          name: 'delete_element',
          description: 'Delete an element from the canvas',
          inputSchema: {
            type: 'object',
            properties: {
              elementId: { type: 'string', description: 'ID of element to delete' },
            },
            required: ['elementId'],
          },
        },
        {
          name: 'render_design',
          description: 'Render a complete UI design from a description',
          inputSchema: {
            type: 'object',
            properties: {
              description: { type: 'string', description: 'Natural language description of the UI' },
              designSystemId: { type: 'string', description: 'Design system to use' },
              style: { 
                type: 'string',
                enum: ['material3', 'ios', 'fluent', 'minimal'],
                description: 'Design style preference'
              },
            },
            required: ['description'],
          },
        },
        {
          name: 'export_code',
          description: 'Export canvas to code (Flutter, React, HTML, SwiftUI)',
          inputSchema: {
            type: 'object',
            properties: {
              format: {
                type: 'string',
                enum: ['flutter', 'react', 'html', 'swiftui'],
                description: 'Target code format'
              },
              includeTokens: { 
                type: 'boolean', 
                description: 'Include design tokens in export',
                default: true 
              },
              componentize: { 
                type: 'boolean', 
                description: 'Create reusable components',
                default: true 
              },
            },
            required: ['format'],
          },
        },
        {
          name: 'clear_canvas',
          description: 'Clear all elements from the canvas',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'get_canvas_state',
          description: 'Get the current canvas state',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'undo',
          description: 'Undo last canvas operation',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'redo',
          description: 'Redo previously undone operation',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'load_design_system',
          description: 'Load a design system from available systems',
          inputSchema: {
            type: 'object',
            properties: {
              designSystemId: { type: 'string', description: 'ID of design system to load' },
              merge: { 
                type: 'boolean', 
                description: 'Merge with current system or replace',
                default: false 
              },
            },
            required: ['designSystemId'],
          },
        },
        {
          name: 'align_elements',
          description: 'Align selected elements',
          inputSchema: {
            type: 'object',
            properties: {
              alignment: {
                type: 'string',
                enum: ['left', 'center', 'right', 'top', 'middle', 'bottom'],
                description: 'Alignment direction'
              },
              elementIds: {
                type: 'array',
                items: { type: 'string' },
                description: 'IDs of elements to align'
              },
            },
            required: ['alignment', 'elementIds'],
          },
        },
      ],
    }));

    // List available resources (design systems)
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: Array.from(this.designSystems.entries()).map(([id, ds]) => ({
        uri: `design-system://${id}`,
        name: ds.name,
        description: `${ds.name} design system (v${ds.version})`,
        mimeType: 'application/json',
      })),
    }));

    // Read design system resource
    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const uri = request.params.uri;
      const match = uri.match(/^design-system:\/\/(.+)$/);
      
      if (!match) {
        throw new Error('Invalid resource URI');
      }

      const designSystemId = match[1];
      const designSystem = this.designSystems.get(designSystemId);
      
      if (!designSystem) {
        throw new Error(`Design system not found: ${designSystemId}`);
      }

      return {
        contents: [
          {
            uri,
            mimeType: 'application/json',
            text: JSON.stringify(designSystem, null, 2),
          },
        ],
      };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'create_element': {
            const params = CreateElementSchema.parse(args);
            const element = this.canvas.addElement(params);
            return {
              content: [
                {
                  type: 'text',
                  text: `Created ${params.type} element with ID: ${element.id}`,
                },
                {
                  type: 'text',
                  text: JSON.stringify(element, null, 2),
                },
              ],
            };
          }

          case 'modify_element': {
            const params = ModifyElementSchema.parse(args);
            const success = this.canvas.updateElement(params.elementId, params.updates);
            return {
              content: [
                {
                  type: 'text',
                  text: success 
                    ? `Successfully updated element ${params.elementId}`
                    : `Element ${params.elementId} not found`,
                },
              ],
            };
          }

          case 'delete_element': {
            const { elementId } = args as { elementId: string };
            const success = this.canvas.deleteElement(elementId);
            return {
              content: [
                {
                  type: 'text',
                  text: success
                    ? `Successfully deleted element ${elementId}`
                    : `Element ${elementId} not found`,
                },
              ],
            };
          }

          case 'render_design': {
            const params = RenderDesignSchema.parse(args);
            const elements = await this.designRenderer.renderFromDescription(
              params.description,
              params.designSystemId || 'material3',
              params.style
            );
            
            return {
              content: [
                {
                  type: 'text',
                  text: `Rendered design with ${elements.length} elements`,
                },
                {
                  type: 'text',
                  text: JSON.stringify(this.canvas.getState(), null, 2),
                },
              ],
            };
          }

          case 'export_code': {
            const params = ExportCodeSchema.parse(args);
            const state = this.canvas.getState();
            const designSystem = this.designSystems.get(state.designSystemId || 'material3');
            
            const code = await this.codeExporter.export(
              state,
              params.format,
              designSystem,
              {
                includeTokens: params.includeTokens,
                componentize: params.componentize,
              }
            );
            
            return {
              content: [
                {
                  type: 'text',
                  text: `Generated ${params.format} code:`,
                },
                {
                  type: 'text',
                  text: code,
                },
              ],
            };
          }

          case 'clear_canvas': {
            this.canvas.clear();
            return {
              content: [
                {
                  type: 'text',
                  text: 'Canvas cleared successfully',
                },
              ],
            };
          }

          case 'get_canvas_state': {
            return {
              content: [
                {
                  type: 'text',
                  text: JSON.stringify(this.canvas.getState(), null, 2),
                },
              ],
            };
          }

          case 'undo': {
            const success = this.canvas.undo();
            return {
              content: [
                {
                  type: 'text',
                  text: success ? 'Undo successful' : 'Nothing to undo',
                },
              ],
            };
          }

          case 'redo': {
            const success = this.canvas.redo();
            return {
              content: [
                {
                  type: 'text',
                  text: success ? 'Redo successful' : 'Nothing to redo',
                },
              ],
            };
          }

          case 'load_design_system': {
            const params = LoadDesignSystemSchema.parse(args);
            const designSystem = this.designSystems.get(params.designSystemId);
            
            if (!designSystem) {
              throw new Error(`Design system not found: ${params.designSystemId}`);
            }
            
            this.canvas.loadDesignSystem(designSystem);
            return {
              content: [
                {
                  type: 'text',
                  text: `Loaded design system: ${designSystem.name} v${designSystem.version}`,
                },
              ],
            };
          }

          case 'align_elements': {
            const { alignment, elementIds } = args as { 
              alignment: 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom';
              elementIds: string[];
            };
            
            this.canvas.selectElements(elementIds);
            this.canvas.alignElements(alignment);
            
            return {
              content: [
                {
                  type: 'text',
                  text: `Aligned ${elementIds.length} elements to ${alignment}`,
                },
              ],
            };
          }

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error instanceof Error ? error.message : String(error)}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  private loadDefaultDesignSystems() {
    // Load Material 3
    const material3Path = join(__dirname, '../assets/design-systems/material3.json');
    if (existsSync(material3Path)) {
      const material3 = JSON.parse(readFileSync(material3Path, 'utf-8')) as DesignSystem;
      this.designSystems.set(material3.id, material3);
      this.canvas.loadDesignSystem(material3);
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Asmbli Canvas MCP Server running on stdio');
  }
}

// Start the server if run directly
if (import.meta.url.startsWith('file:')) {
  const server = new CanvasServer();
  server.run().catch(console.error);
}