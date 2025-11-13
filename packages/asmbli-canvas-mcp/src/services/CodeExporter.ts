import { CanvasState, CanvasElement, DesignSystem, ElementType } from '../types';

interface ExportOptions {
  includeTokens: boolean;
  componentize: boolean;
  useAsmbliDesignSystem?: boolean;
  targetFramework?: 'material3' | 'cupertino' | 'custom';
  responsiveBreakpoints?: boolean;
  accessibility?: boolean;
  darkModeSupport?: boolean;
}

export class CodeExporter {
  async export(
    state: CanvasState,
    format: 'flutter' | 'react' | 'html' | 'swiftui',
    designSystem?: DesignSystem,
    options: ExportOptions = { 
      includeTokens: true, 
      componentize: true,
      useAsmbliDesignSystem: true,
      targetFramework: 'material3',
      responsiveBreakpoints: false,
      accessibility: true,
      darkModeSupport: false
    }
  ): Promise<string> {
    switch (format) {
      case 'flutter':
        return this.exportFlutter(state, designSystem, options);
      case 'react':
        return this.exportReact(state, designSystem, options);
      case 'html':
        return this.exportHTML(state, designSystem, options);
      case 'swiftui':
        return this.exportSwiftUI(state, designSystem, options);
      default:
        throw new Error(`Unsupported export format: ${format}`);
    }
  }

  private exportFlutter(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions = { includeTokens: true, componentize: true }
  ): string {
    const imports = [
      "import 'package:flutter/material.dart';",
    ];

    // Use Asmbli design system imports if specified
    if (options.useAsmbliDesignSystem) {
      imports.push("import 'core/design_system/design_system.dart';");
    } else if (options.includeTokens && designSystem) {
      imports.push("import 'design_system.dart';");
    }

    // Add accessibility imports if needed
    if (options.accessibility) {
      imports.push("import 'package:flutter/semantics.dart';");
    }

    const className = this.toPascalCase(state.name || 'GeneratedScreen');
    
    // Generate responsive layout if enabled
    const layoutContent = options.responsiveBreakpoints 
      ? this.generateResponsiveLayout(state, designSystem, options)
      : this.generateFixedLayout(state, designSystem, options);
    
    let code = `${imports.join('\n')}

/// Generated canvas screen: ${state.name || 'Untitled'}
/// Created with Asmbli Canvas - https://asmbli.ai
class ${className} extends StatelessWidget {
  const ${className}({super.key});

  @override
  Widget build(BuildContext context) {
    ${options.useAsmbliDesignSystem ? 'final colors = ThemeColors(context);\n    ' : ''}${options.includeTokens && designSystem && !options.useAsmbliDesignSystem ? 'final tokens = DesignSystem.of(context);\n    ' : ''}
    return Scaffold(
      ${options.useAsmbliDesignSystem 
        ? 'body: Container(\n        decoration: BoxDecoration(\n          gradient: RadialGradient(\n            center: Alignment.topCenter,\n            radius: 1.5,\n            colors: [\n              colors.backgroundGradientStart,\n              colors.backgroundGradientMiddle,\n              colors.backgroundGradientEnd,\n            ],\n            stops: const [0.0, 0.6, 1.0],\n          ),\n        ),\n        child: SafeArea(\n          child: ' + layoutContent + '\n        ),\n      ),'
        : 'backgroundColor: ' + this.colorToFlutter(state.backgroundColor) + ',\n      body: SafeArea(\n        child: ' + layoutContent + '\n      ),'
      }
    );
  }
}`;

    // Add components if componentization is enabled
    if (options.componentize) {
      const components = this.generateReusableComponents(state, designSystem, options);
      if (components) {
        code += `\n\n${components}`;
      }
    }

    // Add design system if needed
    if (options.includeTokens && designSystem && !options.useAsmbliDesignSystem) {
      code += `\n\n${this.generateFlutterDesignSystem(designSystem)}`;
    }

    return code;
  }

  private elementToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions = { includeTokens: true, componentize: true },
    indent: number = 0
  ): string {
    const spacing = ' '.repeat(indent);
    
    let widget = '';
    
    switch (element.type) {
      case ElementType.CONTAINER:
        widget = this.containerToFlutter(element, designSystem, options);
        break;
      case ElementType.TEXT:
        widget = this.textToFlutter(element, designSystem, options);
        break;
      case ElementType.BUTTON:
        widget = this.buttonToFlutter(element, designSystem, options);
        break;
      case ElementType.INPUT:
        widget = this.inputToFlutter(element, designSystem, options);
        break;
      case ElementType.IMAGE:
        widget = this.imageToFlutter(element);
        break;
      case ElementType.CARD:
        widget = this.cardToFlutter(element, designSystem, options);
        break;
      default:
        widget = 'Container()';
    }

    return `${spacing}Positioned(
${spacing}  left: ${element.x},
${spacing}  top: ${element.y},
${spacing}  width: ${element.width},
${spacing}  height: ${element.height},
${spacing}  child: ${widget},
${spacing})`;
  }

  private containerToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const style = element.style || {};
    let decoration = 'decoration: BoxDecoration(\n';
    
    if (style.backgroundColor) {
      decoration += `        color: ${this.colorToFlutter(style.backgroundColor)},\n`;
    }
    
    if (style.borderRadius) {
      const radius = Array.isArray(style.borderRadius) 
        ? style.borderRadius 
        : [style.borderRadius, style.borderRadius, style.borderRadius, style.borderRadius];
      decoration += `        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(${radius[0]}),
          topRight: Radius.circular(${radius[1]}),
          bottomRight: Radius.circular(${radius[2]}),
          bottomLeft: Radius.circular(${radius[3]}),
        ),\n`;
    }
    
    if (style.borderWidth && style.borderColor) {
      decoration += `        border: Border.all(
          color: ${this.colorToFlutter(style.borderColor)},
          width: ${style.borderWidth},
        ),\n`;
    }
    
    if (style.boxShadow) {
      decoration += `        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],\n`;
    }
    
    decoration += '      )';

    const padding = style.padding 
      ? `padding: ${this.paddingToFlutter(style.padding)},\n      ` 
      : '';

    return `Container(
      ${padding}${decoration},
      ${element.children && element.children.length > 0 
        ? `child: Stack(
        children: [
${element.children.map(child => this.elementToFlutter(child, designSystem, options, 10)).join(',\n')}
        ],
      ),` 
        : ''}
    )`;
  }

  private textToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const style = element.style || {};
    const textStyle: string[] = [];
    
    if (style.fontSize) textStyle.push(`fontSize: ${style.fontSize}`);
    if (style.fontWeight) {
      const weight = typeof style.fontWeight === 'number' 
        ? `FontWeight.w${style.fontWeight}` 
        : `FontWeight.${style.fontWeight}`;
      textStyle.push(`fontWeight: ${weight}`);
    }
    if (style.color) textStyle.push(`color: ${this.colorToFlutter(style.color)}`);
    if (style.letterSpacing) textStyle.push(`letterSpacing: ${style.letterSpacing}`);
    if (style.lineHeight) textStyle.push(`height: ${style.lineHeight / (style.fontSize || 16)}`);

    const textAlign = style.textAlign 
      ? `\n      textAlign: TextAlign.${style.textAlign},` 
      : '';

    return `Text(
      '${element.text || ''}',${textAlign}
      style: TextStyle(
        ${textStyle.join(',\n        ')},
      ),
    )`;
  }

  private buttonToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    if (element.component === 'button' && element.variant && designSystem) {
      const variant = element.variant;
      
      switch (variant) {
        case 'filled':
          return `FilledButton(
      onPressed: () {},
      child: Text('${element.text || 'Button'}'),
    )`;
        case 'outlined':
          return `OutlinedButton(
      onPressed: () {},
      child: Text('${element.text || 'Button'}'),
    )`;
        case 'text':
          return `TextButton(
      onPressed: () {},
      child: Text('${element.text || 'Button'}'),
    )`;
        case 'elevated':
          return `ElevatedButton(
      onPressed: () {},
      child: Text('${element.text || 'Button'}'),
    )`;
        default:
          break;
      }
    }

    // Fallback to custom button
    const style = element.style || {};
    return `ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: ${this.colorToFlutter(style.backgroundColor || '#6750A4')},
        foregroundColor: ${this.colorToFlutter(style.color || '#FFFFFF')},
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(${style.borderRadius || 20}),
        ),
      ),
      child: Text('${element.text || 'Button'}'),
    )`;
  }

  private inputToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const variant = element.variant || 'outlined';
    const style = element.style || {};

    return `TextField(
      decoration: InputDecoration(
        hintText: '${element.placeholder || ''}',
        ${variant === 'filled' ? 'filled: true,\n        fillColor: Colors.grey[100],' : ''}
        border: ${variant === 'outlined' ? 'const OutlineInputBorder()' : 'const UnderlineInputBorder()'},
      ),
    )`;
  }

  private imageToFlutter(element: CanvasElement): string {
    if (element.src?.startsWith('http')) {
      return `Image.network(
      '${element.src}',
      fit: BoxFit.cover,
    )`;
    } else {
      return `Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 48, color: Colors.grey),
    )`;
    }
  }

  private cardToFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const variant = element.variant || 'elevated';
    const style = element.style || {};
    
    if (variant === 'elevated') {
      return `Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        ${element.children && element.children.length > 0 
          ? `child: Stack(
          children: [
${element.children.map(child => this.elementToFlutter(child, designSystem, options, 12)).join(',\n')}
          ],
        ),` 
          : ''}
      ),
    )`;
    } else if (variant === 'outlined') {
      return `Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
      ),
    )`;
    } else {
      return `Card(
      color: Colors.grey[100],
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
      ),
    )`;
    }
  }

  private generateFlutterDesignSystem(designSystem: DesignSystem): string {
    return `
// Design System
class DesignSystem extends InheritedWidget {
  final DesignTokens tokens;

  const DesignSystem({
    super.key,
    required this.tokens,
    required super.child,
  });

  static DesignTokens of(BuildContext context) {
    final designSystem = context.dependOnInheritedWidgetOfExactType<DesignSystem>();
    assert(designSystem != null, 'No DesignSystem found in context');
    return designSystem!.tokens;
  }

  @override
  bool updateShouldNotify(DesignSystem oldWidget) => tokens != oldWidget.tokens;
}

class DesignTokens {
  final ColorTokens colors;
  final SpacingTokens spacing;
  final TypographyTokens typography;

  const DesignTokens({
    required this.colors,
    required this.spacing,
    required this.typography,
  });
}

class ColorTokens {
  ${Object.entries(designSystem.tokens.colors)
    .map(([key, value]) => `final Color ${this.toCamelCase(key)};`)
    .join('\n  ')}

  const ColorTokens({
    ${Object.entries(designSystem.tokens.colors)
      .map(([key]) => `required this.${this.toCamelCase(key)},`)
      .join('\n    ')}
  });
}

class SpacingTokens {
  ${Object.entries(designSystem.tokens.spacing)
    .map(([key, value]) => `static const double ${key} = ${value};`)
    .join('\n  ')}
}

class TypographyTokens {
  ${Object.entries(designSystem.tokens.typography)
    .map(([key]) => `final TextStyle ${this.toCamelCase(key)};`)
    .join('\n  ')}

  const TypographyTokens({
    ${Object.entries(designSystem.tokens.typography)
      .map(([key]) => `required this.${this.toCamelCase(key)},`)
      .join('\n    ')}
  });
}`;
  }

  private exportReact(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const componentName = this.toPascalCase(state.name || 'GeneratedComponent');
    
    return `import React from 'react';
import styled from 'styled-components';

const Container = styled.div\`
  width: ${state.width}px;
  height: ${state.height}px;
  background-color: ${state.backgroundColor};
  position: relative;
\`;

${state.elements.map((el, i) => this.elementToReactStyled(el, i)).join('\n')}

export const ${componentName} = () => {
  return (
    <Container>
      ${state.elements.map((el, i) => this.elementToReactJSX(el, i)).join('\n      ')}
    </Container>
  );
};`;
  }

  private elementToReactStyled(element: CanvasElement, index: number): string {
    const style = element.style || {};
    let css = `
  position: absolute;
  left: ${element.x}px;
  top: ${element.y}px;
  width: ${element.width}px;
  height: ${element.height}px;`;

    if (style.backgroundColor) css += `\n  background-color: ${style.backgroundColor};`;
    if (style.color) css += `\n  color: ${style.color};`;
    if (style.fontSize) css += `\n  font-size: ${style.fontSize}px;`;
    if (style.fontWeight) css += `\n  font-weight: ${style.fontWeight};`;
    if (style.borderRadius) {
      const radius = Array.isArray(style.borderRadius) ? style.borderRadius[0] : style.borderRadius;
      css += `\n  border-radius: ${radius}px;`;
    }
    if (style.padding) {
      const padding = Array.isArray(style.padding) 
        ? `${style.padding[0]}px ${style.padding[1]}px ${style.padding[2]}px ${style.padding[3]}px`
        : `${style.padding}px`;
      css += `\n  padding: ${padding};`;
    }

    const componentType = this.getReactComponent(element.type);
    return `const Element${index} = styled.${componentType}\`${css}\n\`;`;
  }

  private elementToReactJSX(element: CanvasElement, index: number): string {
    switch (element.type) {
      case ElementType.TEXT:
        return `<Element${index}>${element.text || ''}</Element${index}>`;
      case ElementType.BUTTON:
        return `<Element${index} as="button">${element.text || 'Button'}</Element${index}>`;
      case ElementType.INPUT:
        return `<Element${index} as="input" placeholder="${element.placeholder || ''}" />`;
      default:
        return `<Element${index} />`;
    }
  }

  private getReactComponent(type: ElementType): string {
    switch (type) {
      case ElementType.TEXT:
        return 'span';
      case ElementType.BUTTON:
        return 'button';
      case ElementType.INPUT:
        return 'input';
      default:
        return 'div';
    }
  }

  private exportHTML(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${state.name || 'Generated Page'}</title>
  <style>
    .canvas-container {
      width: ${state.width}px;
      height: ${state.height}px;
      background-color: ${state.backgroundColor};
      position: relative;
      margin: 0 auto;
    }
    ${state.elements.map((el, i) => this.elementToCSS(el, i)).join('\n    ')}
  </style>
</head>
<body>
  <div class="canvas-container">
    ${state.elements.map((el, i) => this.elementToHTML(el, i)).join('\n    ')}
  </div>
</body>
</html>`;
  }

  private elementToCSS(element: CanvasElement, index: number): string {
    const style = element.style || {};
    let css = `.element-${index} {
      position: absolute;
      left: ${element.x}px;
      top: ${element.y}px;
      width: ${element.width}px;
      height: ${element.height}px;`;

    if (style.backgroundColor) css += `\n      background-color: ${style.backgroundColor};`;
    if (style.color) css += `\n      color: ${style.color};`;
    if (style.fontSize) css += `\n      font-size: ${style.fontSize}px;`;
    if (style.fontWeight) css += `\n      font-weight: ${style.fontWeight};`;
    if (style.textAlign) css += `\n      text-align: ${style.textAlign};`;
    if (style.borderRadius) {
      const radius = Array.isArray(style.borderRadius) ? style.borderRadius[0] : style.borderRadius;
      css += `\n      border-radius: ${radius}px;`;
    }
    
    css += '\n    }';
    return css;
  }

  private elementToHTML(element: CanvasElement, index: number): string {
    switch (element.type) {
      case ElementType.TEXT:
        return `<div class="element-${index}">${element.text || ''}</div>`;
      case ElementType.BUTTON:
        return `<button class="element-${index}">${element.text || 'Button'}</button>`;
      case ElementType.INPUT:
        return `<input class="element-${index}" type="text" placeholder="${element.placeholder || ''}" />`;
      case ElementType.IMAGE:
        return `<img class="element-${index}" src="${element.src || ''}" alt="" />`;
      default:
        return `<div class="element-${index}"></div>`;
    }
  }

  private exportSwiftUI(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const viewName = this.toPascalCase(state.name || 'GeneratedView');
    
    return `import SwiftUI

struct ${viewName}: View {
    var body: some View {
        ZStack {
            Color(hex: "${state.backgroundColor}")
                .frame(width: ${state.width}, height: ${state.height})
            
            ${state.elements.map(el => this.elementToSwiftUI(el)).join('\n            ')}
        }
    }
}

${state.elements.some(el => el.style?.backgroundColor) ? this.swiftUIColorExtension() : ''}`;
  }

  private elementToSwiftUI(element: CanvasElement): string {
    let view = '';
    
    switch (element.type) {
      case ElementType.TEXT:
        view = `Text("${element.text || ''}")`;
        if (element.style?.fontSize) view += `\n                .font(.system(size: ${element.style.fontSize}))`;
        if (element.style?.fontWeight) view += `\n                .fontWeight(.${this.swiftUIFontWeight(element.style.fontWeight)})`;
        if (element.style?.color) view += `\n                .foregroundColor(Color(hex: "${element.style.color}"))`;
        break;
        
      case ElementType.BUTTON:
        view = `Button("${element.text || 'Button'}") { }`;
        if (element.style?.backgroundColor) {
          view += `\n                .background(Color(hex: "${element.style.backgroundColor}"))`;
        }
        if (element.style?.color) {
          view += `\n                .foregroundColor(Color(hex: "${element.style.color}"))`;
        }
        break;
        
      case ElementType.INPUT:
        view = `TextField("${element.placeholder || ''}", text: .constant(""))`;
        view += '\n                .textFieldStyle(RoundedBorderTextFieldStyle())';
        break;
        
      default:
        view = 'Rectangle()';
        if (element.style?.backgroundColor) {
          view += `\n                .fill(Color(hex: "${element.style.backgroundColor}"))`;
        }
    }
    
    view += `\n                .frame(width: ${element.width}, height: ${element.height})`;
    view += `\n                .position(x: ${element.x + element.width/2}, y: ${element.y + element.height/2})`;
    
    return view;
  }

  private swiftUIFontWeight(weight: string | number): string {
    if (typeof weight === 'number') {
      if (weight >= 700) return 'bold';
      if (weight >= 600) return 'semibold';
      if (weight >= 500) return 'medium';
      return 'regular';
    }
    return weight;
  }

  private swiftUIColorExtension(): string {
    return `
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}`;
  }

  // Utility methods
  private colorToFlutter(color: string): string {
    if (color.startsWith('#')) {
      return `const Color(0xFF${color.slice(1)})`;
    }
    if (color.startsWith('rgb')) {
      // Parse RGB values
      const match = color.match(/\d+/g);
      if (match && match.length >= 3) {
        const [r, g, b] = match;
        return `const Color.fromRGBO(${r}, ${g}, ${b}, 1.0)`;
      }
    }
    // Try to match common color names
    const colorMap: Record<string, string> = {
      'white': 'Colors.white',
      'black': 'Colors.black',
      'red': 'Colors.red',
      'blue': 'Colors.blue',
      'green': 'Colors.green',
      'transparent': 'Colors.transparent',
    };
    return colorMap[color.toLowerCase()] || 'Colors.grey';
  }

  private paddingToFlutter(padding: number | number[]): string {
    if (Array.isArray(padding)) {
      if (padding.length === 4) {
        return `EdgeInsets.fromLTRB(${padding[3]}, ${padding[0]}, ${padding[1]}, ${padding[2]})`;
      }
      return `EdgeInsets.all(${padding[0]})`;
    }
    return `EdgeInsets.all(${padding})`;
  }

  private toPascalCase(str: string): string {
    return str
      .replace(/[-_\s]+(.)?/g, (_, c) => (c ? c.toUpperCase() : ''))
      .replace(/^(.)/, (c) => c.toUpperCase());
  }

  private toCamelCase(str: string): string {
    return str
      .replace(/[-_\s]+(.)?/g, (_, c) => (c ? c.toUpperCase() : ''))
      .replace(/^(.)/, (c) => c.toLowerCase());
  }

  // New helper methods for enhanced code generation

  private generateFixedLayout(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions = { includeTokens: true, componentize: true }
  ): string {
    return `Stack(
        children: [
${state.elements.map(el => this.elementToFlutter(el, designSystem, options, 10)).join(',\n')}
        ],
      )`;
  }

  private generateResponsiveLayout(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions = { includeTokens: true, componentize: true }
  ): string {
    return `LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 768;
          final isMobile = constraints.maxWidth <= 768;
          
          return Stack(
            children: [
${state.elements.map(el => this.elementToResponsiveFlutter(el, designSystem, options, 14)).join(',\n')}
            ],
          );
        },
      )`;
  }

  private elementToResponsiveFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions = { includeTokens: true, componentize: true },
    indent: number = 0
  ): string {
    const spacing = ' '.repeat(indent);
    
    // Calculate responsive positions and sizes
    const responsiveX = `constraints.maxWidth * ${(element.x / 800).toFixed(3)}`;
    const responsiveY = `constraints.maxHeight * ${(element.y / 600).toFixed(3)}`;
    const responsiveWidth = `constraints.maxWidth * ${(element.width / 800).toFixed(3)}`;
    const responsiveHeight = `constraints.maxHeight * ${(element.height / 600).toFixed(3)}`;

    let widget = '';
    
    switch (element.type) {
      case ElementType.CONTAINER:
        widget = this.containerToFlutter(element, designSystem, options);
        break;
      case ElementType.TEXT:
        widget = this.textToResponsiveFlutter(element, designSystem, options);
        break;
      case ElementType.BUTTON:
        widget = this.buttonToFlutter(element, designSystem, options);
        break;
      case ElementType.INPUT:
        widget = this.inputToFlutter(element, designSystem, options);
        break;
      case ElementType.IMAGE:
        widget = this.imageToFlutter(element);
        break;
      case ElementType.CARD:
        widget = this.cardToFlutter(element, designSystem, options);
        break;
      default:
        widget = 'Container()';
    }

    return `${spacing}Positioned(
${spacing}  left: ${responsiveX},
${spacing}  top: ${responsiveY},
${spacing}  width: ${responsiveWidth},
${spacing}  height: ${responsiveHeight},
${spacing}  child: ${widget},
${spacing})`;
  }

  private textToResponsiveFlutter(
    element: CanvasElement,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const style = element.style || {};
    const textStyle: string[] = [];
    
    // Make font size responsive
    if (style.fontSize) {
      textStyle.push(`fontSize: isMobile ? ${style.fontSize * 0.8} : ${style.fontSize}`);
    }
    
    if (style.fontWeight) {
      const weight = typeof style.fontWeight === 'number' 
        ? `FontWeight.w${style.fontWeight}` 
        : `FontWeight.${style.fontWeight}`;
      textStyle.push(`fontWeight: ${weight}`);
    }
    
    if (options.useAsmbliDesignSystem) {
      textStyle.push('color: colors.onSurface');
    } else if (style.color) {
      textStyle.push(`color: ${this.colorToFlutter(style.color)}`);
    }
    
    if (style.letterSpacing) textStyle.push(`letterSpacing: ${style.letterSpacing}`);
    if (style.lineHeight) textStyle.push(`height: ${style.lineHeight / (style.fontSize || 16)}`);

    const textAlign = style.textAlign 
      ? `\n      textAlign: TextAlign.${style.textAlign},` 
      : '';

    // Add accessibility semantics if enabled
    const semantics = options.accessibility 
      ? `\n      semanticsLabel: '${element.text || ''}',` 
      : '';

    return `Text(
      '${element.text || ''}',${textAlign}${semantics}
      style: TextStyle(
        ${textStyle.join(',\n        ')},
      ),
    )`;
  }

  private generateReusableComponents(
    state: CanvasState,
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    // Group similar elements to create reusable components
    const elementsByType = new Map<ElementType, CanvasElement[]>();
    
    state.elements.forEach(element => {
      const elements = elementsByType.get(element.type) || [];
      elements.push(element);
      elementsByType.set(element.type, elements);
    });

    let components = '';

    // Generate button component if multiple buttons exist
    const buttons = elementsByType.get(ElementType.BUTTON);
    if (buttons && buttons.length > 1) {
      components += this.generateButtonComponent(buttons, designSystem, options);
    }

    // Generate text component if multiple text elements with similar styles exist
    const texts = elementsByType.get(ElementType.TEXT);
    if (texts && texts.length > 2) {
      components += this.generateTextComponent(texts, designSystem, options);
    }

    // Generate card component if multiple cards exist
    const cards = elementsByType.get(ElementType.CARD);
    if (cards && cards.length > 1) {
      components += this.generateCardComponent(cards, designSystem, options);
    }

    return components;
  }

  private generateButtonComponent(
    buttons: CanvasElement[],
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    const commonStyles = this.findCommonStyles(buttons);
    
    return `
/// Reusable button component
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    ${options.useAsmbliDesignSystem ? 'final colors = ThemeColors(context);' : ''}
    
    switch (variant) {
      case ButtonVariant.primary:
        return ${options.useAsmbliDesignSystem ? 'AsmblButton.primary(' : 'ElevatedButton('}
          ${options.useAsmbliDesignSystem ? 'text: text,' : 'child: Text(text),'}
          onPressed: onPressed,
        );
      case ButtonVariant.secondary:
        return ${options.useAsmbliDesignSystem ? 'AsmblButton.secondary(' : 'OutlinedButton('}
          ${options.useAsmbliDesignSystem ? 'text: text,' : 'child: Text(text),'}
          onPressed: onPressed,
        );
      case ButtonVariant.accent:
        return ${options.useAsmbliDesignSystem ? 'AsmblButton.accent(' : 'TextButton('}
          ${options.useAsmbliDesignSystem ? 'text: text,' : 'child: Text(text),'}
          onPressed: onPressed,
        );
    }
  }
}

enum ButtonVariant { primary, secondary, accent }`;
  }

  private generateTextComponent(
    texts: CanvasElement[],
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    return `
/// Reusable text component
class CustomText extends StatelessWidget {
  final String text;
  final TextVariant variant;

  const CustomText({
    super.key,
    required this.text,
    this.variant = TextVariant.body,
  });

  @override
  Widget build(BuildContext context) {
    ${options.useAsmbliDesignSystem ? 'final colors = ThemeColors(context);' : ''}
    
    TextStyle style;
    switch (variant) {
      case TextVariant.title:
        style = ${options.useAsmbliDesignSystem ? 'TextStyles.cardTitle' : 'Theme.of(context).textTheme.titleLarge!'};
        break;
      case TextVariant.subtitle:
        style = ${options.useAsmbliDesignSystem ? 'TextStyles.bodyLarge' : 'Theme.of(context).textTheme.titleMedium!'};
        break;
      case TextVariant.body:
      default:
        style = ${options.useAsmbliDesignSystem ? 'TextStyles.bodyMedium' : 'Theme.of(context).textTheme.bodyMedium!'};
        break;
    }
    
    ${options.useAsmbliDesignSystem ? 'style = style.copyWith(color: colors.onSurface);' : ''}
    
    return Text(
      text,
      style: style,
      ${options.accessibility ? 'semanticsLabel: text,' : ''}
    );
  }
}

enum TextVariant { title, subtitle, body }`;
  }

  private generateCardComponent(
    cards: CanvasElement[],
    designSystem?: DesignSystem,
    options: ExportOptions
  ): string {
    return `
/// Reusable card component
class CustomCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;

  const CustomCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
  });

  @override
  Widget build(BuildContext context) {
    ${options.useAsmbliDesignSystem ? 'final colors = ThemeColors(context);' : ''}
    
    switch (variant) {
      case CardVariant.elevated:
        return ${options.useAsmbliDesignSystem ? 'AsmblCard(' : 'Card('}
          ${options.useAsmbliDesignSystem ? '' : 'elevation: 2,'}
          child: Padding(
            padding: ${options.useAsmbliDesignSystem ? 'const EdgeInsets.all(SpacingTokens.lg)' : 'const EdgeInsets.all(16)'},
            child: child,
          ),
        );
      case CardVariant.outlined:
        return ${options.useAsmbliDesignSystem ? 'AsmblCardEnhanced.outlined(' : 'Card('}
          ${options.useAsmbliDesignSystem ? '' : 'elevation: 0,'}
          ${options.useAsmbliDesignSystem ? '' : 'shape: RoundedRectangleBorder(side: BorderSide(color: colors.border)),'}
          child: Padding(
            padding: ${options.useAsmbliDesignSystem ? 'const EdgeInsets.all(SpacingTokens.lg)' : 'const EdgeInsets.all(16)'},
            child: child,
          ),
        );
    }
  }
}

enum CardVariant { elevated, outlined }`;
  }

  private findCommonStyles(elements: CanvasElement[]): Record<string, any> {
    const commonStyles: Record<string, any> = {};
    
    if (elements.length === 0) return commonStyles;
    
    const firstStyle = elements[0].style || {};
    
    for (const [key, value] of Object.entries(firstStyle)) {
      const allHaveSameValue = elements.every(el => 
        el.style && el.style[key] === value
      );
      
      if (allHaveSameValue) {
        commonStyles[key] = value;
      }
    }
    
    return commonStyles;
  }

  // Enhanced color conversion with Asmbli design system support
  private colorToFlutterEnhanced(color: string, useAsmbliDesignSystem: boolean): string {
    if (useAsmbliDesignSystem) {
      // Map common colors to Asmbli design system
      const asmbliColorMap: Record<string, string> = {
        '#6750A4': 'colors.primary',
        '#FFFFFF': 'colors.surface',
        '#000000': 'colors.onSurface',
        '#F5F5F5': 'colors.background',
        '#E0E0E0': 'colors.border',
        '#4CAF50': 'colors.success',
        '#FF9800': 'colors.warning',
        '#F44336': 'colors.error',
      };
      
      return asmbliColorMap[color.toUpperCase()] || this.colorToFlutter(color);
    }
    
    return this.colorToFlutter(color);
  }
}