import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Design template for rapid design creation
///
/// Week 3: Templates enable agents to quickly instantiate common design patterns
class DesignTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final List<TemplateElement> elements;
  final Map<String, VariableDefinition> variables;
  final Map<String, dynamic> metadata;

  const DesignTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.elements,
    this.variables = const {},
    this.metadata = const {},
  });

  /// Built-in templates
  static List<DesignTemplate> get builtInTemplates => [
        cardTemplate(),
        buttonTemplate(),
        heroSectionTemplate(),
        navbarTemplate(),
      ];

  /// Card template
  static DesignTemplate cardTemplate() {
    return DesignTemplate(
      id: 'card_basic',
      name: 'Basic Card',
      description: 'A simple card with title, description, and optional action',
      category: TemplateCategory.component,
      variables: {
        'title': VariableDefinition(
          name: 'title',
          type: VariableType.text,
          defaultValue: 'Card Title',
          description: 'Card heading text',
        ),
        'description': VariableDefinition(
          name: 'description',
          type: VariableType.text,
          defaultValue: 'Card description goes here.',
          description: 'Card body text',
        ),
        'width': VariableDefinition(
          name: 'width',
          type: VariableType.number,
          defaultValue: 320,
          description: 'Card width in pixels',
        ),
        'height': VariableDefinition(
          name: 'height',
          type: VariableType.number,
          defaultValue: 200,
          description: 'Card height in pixels',
        ),
      },
      elements: [
        TemplateElement(
          type: 'frame',
          properties: {
            'name': 'Card',
            'width': '\${width}',
            'height': '\${height}',
            'x': 0,
            'y': 0,
          },
          children: [
            TemplateElement(
              type: 'rectangle',
              properties: {
                'name': 'Background',
                'width': '\${width}',
                'height': '\${height}',
                'fill': '\${tokens.colors.surface}',
                'borderRadius': 8,
              },
            ),
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Title',
                'content': '\${title}',
                'x': 24,
                'y': 24,
                'fontSize': 24,
                'fontWeight': 600,
                'color': '\${tokens.colors.text}',
              },
            ),
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Description',
                'content': '\${description}',
                'x': 24,
                'y': 64,
                'fontSize': 16,
                'color': '\${tokens.colors.textSecondary}',
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Button template
  static DesignTemplate buttonTemplate() {
    return DesignTemplate(
      id: 'button_primary',
      name: 'Primary Button',
      description: 'A primary action button',
      category: TemplateCategory.component,
      variables: {
        'label': VariableDefinition(
          name: 'label',
          type: VariableType.text,
          defaultValue: 'Click Me',
          description: 'Button label text',
        ),
        'width': VariableDefinition(
          name: 'width',
          type: VariableType.number,
          defaultValue: 120,
          description: 'Button width',
        ),
      },
      elements: [
        TemplateElement(
          type: 'frame',
          properties: {
            'name': 'Button',
            'width': '\${width}',
            'height': 48,
            'x': 0,
            'y': 0,
          },
          children: [
            TemplateElement(
              type: 'rectangle',
              properties: {
                'name': 'Background',
                'width': '\${width}',
                'height': 48,
                'fill': '\${tokens.colors.primary}',
                'borderRadius': 8,
              },
            ),
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Label',
                'content': '\${label}',
                'x': '\${width / 2}',
                'y': 24,
                'fontSize': 16,
                'fontWeight': 600,
                'color': '#FFFFFF',
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Hero section template
  static DesignTemplate heroSectionTemplate() {
    return DesignTemplate(
      id: 'hero_section',
      name: 'Hero Section',
      description: 'Landing page hero section with headline and CTA',
      category: TemplateCategory.section,
      variables: {
        'headline': VariableDefinition(
          name: 'headline',
          type: VariableType.text,
          defaultValue: 'Build Amazing Products',
          description: 'Main headline',
        ),
        'subheadline': VariableDefinition(
          name: 'subheadline',
          type: VariableType.text,
          defaultValue: 'Create professional designs with AI assistance',
          description: 'Supporting text',
        ),
        'ctaText': VariableDefinition(
          name: 'ctaText',
          type: VariableType.text,
          defaultValue: 'Get Started',
          description: 'Call-to-action button text',
        ),
      },
      elements: [
        TemplateElement(
          type: 'frame',
          properties: {
            'name': 'Hero Section',
            'width': 1200,
            'height': 600,
            'x': 0,
            'y': 0,
          },
          children: [
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Headline',
                'content': '\${headline}',
                'x': 100,
                'y': 200,
                'fontSize': 48,
                'fontWeight': 700,
                'color': '\${tokens.colors.text}',
              },
            ),
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Subheadline',
                'content': '\${subheadline}',
                'x': 100,
                'y': 280,
                'fontSize': 24,
                'color': '\${tokens.colors.textSecondary}',
              },
            ),
            TemplateElement(
              type: 'frame',
              properties: {
                'name': 'CTA Button',
                'width': 160,
                'height': 56,
                'x': 100,
                'y': 360,
              },
              children: [
                TemplateElement(
                  type: 'rectangle',
                  properties: {
                    'name': 'Background',
                    'width': 160,
                    'height': 56,
                    'fill': '\${tokens.colors.primary}',
                    'borderRadius': 12,
                  },
                ),
                TemplateElement(
                  type: 'text',
                  properties: {
                    'name': 'Label',
                    'content': '\${ctaText}',
                    'x': 80,
                    'y': 28,
                    'fontSize': 18,
                    'fontWeight': 600,
                    'color': '#FFFFFF',
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Navbar template
  static DesignTemplate navbarTemplate() {
    return DesignTemplate(
      id: 'navbar_basic',
      name: 'Navigation Bar',
      description: 'Horizontal navigation bar with logo and links',
      category: TemplateCategory.section,
      variables: {
        'logoText': VariableDefinition(
          name: 'logoText',
          type: VariableType.text,
          defaultValue: 'Brand',
          description: 'Brand/logo text',
        ),
      },
      elements: [
        TemplateElement(
          type: 'frame',
          properties: {
            'name': 'Navbar',
            'width': 1200,
            'height': 80,
            'x': 0,
            'y': 0,
          },
          children: [
            TemplateElement(
              type: 'rectangle',
              properties: {
                'name': 'Background',
                'width': 1200,
                'height': 80,
                'fill': '\${tokens.colors.surface}',
              },
            ),
            TemplateElement(
              type: 'text',
              properties: {
                'name': 'Logo',
                'content': '\${logoText}',
                'x': 40,
                'y': 40,
                'fontSize': 24,
                'fontWeight': 700,
                'color': '\${tokens.colors.primary}',
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Parse from JSON
  factory DesignTemplate.fromJson(Map<String, dynamic> json) {
    return DesignTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: TemplateCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TemplateCategory.custom,
      ),
      elements: (json['elements'] as List)
          .map((e) => TemplateElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              VariableDefinition.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'elements': elements.map((e) => e.toJson()).toList(),
      'variables': variables.map((key, value) => MapEntry(key, value.toJson())),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [id, name, description, category, elements, variables, metadata];
}

/// Template categories
enum TemplateCategory {
  component, // Buttons, cards, inputs
  section, // Hero, navbar, footer
  layout, // Grid, flexbox layouts
  pattern, // Login, pricing, dashboard
  custom, // User-defined
}

/// Template element definition
class TemplateElement extends Equatable {
  final String type; // 'rectangle', 'text', 'frame', etc.
  final Map<String, dynamic> properties;
  final List<TemplateElement> children;

  const TemplateElement({
    required this.type,
    required this.properties,
    this.children = const [],
  });

  factory TemplateElement.fromJson(Map<String, dynamic> json) {
    return TemplateElement(
      type: json['type'] as String,
      properties: json['properties'] as Map<String, dynamic>,
      children: (json['children'] as List?)
              ?.map((e) => TemplateElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'properties': properties,
      if (children.isNotEmpty) 'children': children.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [type, properties, children];
}

/// Variable definition for templates
class VariableDefinition extends Equatable {
  final String name;
  final VariableType type;
  final dynamic defaultValue;
  final String description;

  const VariableDefinition({
    required this.name,
    required this.type,
    required this.defaultValue,
    this.description = '',
  });

  factory VariableDefinition.fromJson(Map<String, dynamic> json) {
    return VariableDefinition(
      name: json['name'] as String,
      type: VariableType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VariableType.text,
      ),
      defaultValue: json['defaultValue'],
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'defaultValue': defaultValue,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [name, type, defaultValue, description];
}

/// Variable types
enum VariableType {
  text,
  number,
  color,
  boolean,
}
