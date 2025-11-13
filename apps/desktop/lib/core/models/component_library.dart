import 'package:flutter/material.dart';

/// Centralized component library for Flutter UI components
/// Used by both the UI and the design agent for consistent component definitions
class ComponentLibrary {
  
  /// Flutter component categories and their components
  static const Map<String, List<ComponentDefinition>> components = {
    'material': [
      ComponentDefinition(
        key: 'appBar',
        name: 'AppBar',
        description: 'Material Design app bar with title and actions',
        icon: Icons.web_asset,
        category: 'material',
        flutterWidget: 'AppBar',
        excalidrawElements: ['rectangle', 'text'],
      ),
      ComponentDefinition(
        key: 'floatingActionButton',
        name: 'FAB',
        description: 'Circular floating action button',
        icon: Icons.add_circle,
        category: 'material',
        flutterWidget: 'FloatingActionButton',
        excalidrawElements: ['ellipse', 'text'],
      ),
      ComponentDefinition(
        key: 'elevatedButton',
        name: 'Button',
        description: 'Material elevated button',
        icon: Icons.smart_button,
        category: 'material',
        flutterWidget: 'ElevatedButton',
        excalidrawElements: ['rectangle', 'text'],
      ),
      ComponentDefinition(
        key: 'card',
        name: 'Card',
        description: 'Material Design card container',
        icon: Icons.credit_card,
        category: 'material',
        flutterWidget: 'Card',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'listTile',
        name: 'ListTile',
        description: 'Single fixed-height row',
        icon: Icons.list,
        category: 'material',
        flutterWidget: 'ListTile',
        excalidrawElements: ['rectangle', 'text', 'ellipse'],
      ),
    ],
    
    'layout': [
      ComponentDefinition(
        key: 'container',
        name: 'Container',
        description: 'Box model container widget',
        icon: Icons.crop_square,
        category: 'layout',
        flutterWidget: 'Container',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'column',
        name: 'Column',
        description: 'Vertical layout widget',
        icon: Icons.view_column,
        category: 'layout',
        flutterWidget: 'Column',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'row',
        name: 'Row',
        description: 'Horizontal layout widget',
        icon: Icons.view_week,
        category: 'layout',
        flutterWidget: 'Row',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'stack',
        name: 'Stack',
        description: 'Overlay layout widget',
        icon: Icons.layers,
        category: 'layout',
        flutterWidget: 'Stack',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'gridView',
        name: 'GridView',
        description: 'Scrollable grid layout',
        icon: Icons.grid_view,
        category: 'layout',
        flutterWidget: 'GridView',
        excalidrawElements: ['rectangle'],
      ),
    ],
    
    'forms': [
      ComponentDefinition(
        key: 'textField',
        name: 'TextField',
        description: 'Text input field',
        icon: Icons.text_fields,
        category: 'forms',
        flutterWidget: 'TextField',
        excalidrawElements: ['rectangle', 'text'],
      ),
      ComponentDefinition(
        key: 'checkbox',
        name: 'Checkbox',
        description: 'Checkbox input',
        icon: Icons.check_box,
        category: 'forms',
        flutterWidget: 'Checkbox',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'radioButton',
        name: 'Radio',
        description: 'Radio button input',
        icon: Icons.radio_button_checked,
        category: 'forms',
        flutterWidget: 'Radio',
        excalidrawElements: ['ellipse'],
      ),
      ComponentDefinition(
        key: 'dropdown',
        name: 'Dropdown',
        description: 'Dropdown selection',
        icon: Icons.arrow_drop_down,
        category: 'forms',
        flutterWidget: 'DropdownButton',
        excalidrawElements: ['rectangle', 'text'],
      ),
      ComponentDefinition(
        key: 'slider',
        name: 'Slider',
        description: 'Range slider input',
        icon: Icons.linear_scale,
        category: 'forms',
        flutterWidget: 'Slider',
        excalidrawElements: ['line', 'ellipse'],
      ),
    ],
    
    'asmbli': [
      ComponentDefinition(
        key: 'asmblButton',
        name: 'AsmblButton',
        description: 'Custom Asmbli button component',
        icon: Icons.smart_button,
        category: 'asmbli',
        flutterWidget: 'AsmblButton',
        excalidrawElements: ['rectangle', 'text'],
      ),
      ComponentDefinition(
        key: 'asmblCard',
        name: 'AsmblCard',
        description: 'Custom Asmbli card component',
        icon: Icons.credit_card,
        category: 'asmbli',
        flutterWidget: 'AsmblCard',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'asmblModal',
        name: 'Modal',
        description: 'Asmbli modal dialog',
        icon: Icons.open_in_new,
        category: 'asmbli',
        flutterWidget: 'AsmblModal',
        excalidrawElements: ['rectangle'],
      ),
      ComponentDefinition(
        key: 'asmblToast',
        name: 'Toast',
        description: 'Asmbli toast notification',
        icon: Icons.notification_important,
        category: 'asmbli',
        flutterWidget: 'AsmblToast',
        excalidrawElements: ['rectangle', 'text'],
      ),
    ],
  };

  /// Get all components for a specific category
  static List<ComponentDefinition> getComponentsForCategory(String category) {
    return components[category] ?? [];
  }

  /// Get all available categories
  static List<String> getCategories() {
    return components.keys.toList();
  }

  /// Get a specific component by key
  static ComponentDefinition? getComponent(String key) {
    for (final category in components.values) {
      for (final component in category) {
        if (component.key == key) {
          return component;
        }
      }
    }
    return null;
  }

  /// Get components as a map for UI building
  static Map<String, List<Map<String, dynamic>>> getComponentsAsMap() {
    final Map<String, List<Map<String, dynamic>>> result = {};
    
    for (final entry in components.entries) {
      result[entry.key] = entry.value.map((component) => component.toMap()).toList();
    }
    
    return result;
  }

  /// Convert component library to JavaScript format for Excalidraw
  static String toJavaScript() {
    final buffer = StringBuffer();
    buffer.writeln('// Asmbli Design Library - Auto-generated');
    buffer.writeln('window.asmblDesignLibrary = {');
    
    for (final entry in components.entries) {
      buffer.writeln('  ${entry.key}: {');
      for (final component in entry.value) {
        buffer.writeln('    ${component.key}: {');
        buffer.writeln('      name: "${component.name}",');
        buffer.writeln('      description: "${component.description}",');
        buffer.writeln('      category: "${component.category}",');
        buffer.writeln('      flutterWidget: "${component.flutterWidget}",');
        buffer.writeln('      excalidrawElements: ${component.excalidrawElements}');
        buffer.writeln('    },');
      }
      buffer.writeln('  },');
    }
    
    buffer.writeln('};');
    return buffer.toString();
  }
}

/// Component definition model
class ComponentDefinition {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final String category;
  final String flutterWidget;
  final List<String> excalidrawElements;

  const ComponentDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.flutterWidget,
    required this.excalidrawElements,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'flutterWidget': flutterWidget,
      'excalidrawElements': excalidrawElements,
    };
  }
}