# Design Intelligence Enhancement Plan
**Transform Excalidraw Integration into Professional Software Design Tool**

**Date**: 2025-11-14
**Current Maturity**: 20-25%
**Target Maturity**: 80-90%
**Timeline**: Phased approach (4-6 weeks)

---

## Executive Summary

The current Excalidraw integration provides basic shape manipulation but lacks the intelligence needed for professional software design. This plan outlines 6 major enhancement areas to transform it into a true design intelligence system.

**Key Gaps Identified:**
1. ❌ No intelligent layout algorithms (random positioning)
2. ❌ No comprehensive component library with variants
3. ❌ No software architecture diagram support (UML, flowcharts)
4. ❌ No design system integration (colors, spacing, typography)
5. ❌ No design pattern recognition or application
6. ❌ No responsive design capabilities

---

## Phase 1: Intelligent Layout System (Week 1-2)

### 1.1 Smart Layout Engine

**Goal**: Replace random positioning with intelligent layout algorithms

**New Service**: `CanvasLayoutEngine`

```dart
class CanvasLayoutEngine {
  /// Auto-arrange elements using force-directed graph algorithm
  Future<List<ElementPosition>> autoArrange(
    List<CanvasElement> elements, {
    LayoutStrategy strategy = LayoutStrategy.grid,
    double spacing = 16.0,
    AlignmentRule alignment = AlignmentRule.topLeft,
  });

  /// Detect and fix layout issues
  LayoutAnalysis analyzeLayout(List<CanvasElement> elements);

  /// Apply 8-point grid snapping
  Point snapToGrid(Point position, {int gridSize = 8});

  /// Distribute elements evenly
  List<ElementPosition> distributeEvenly(
    List<CanvasElement> elements,
    DistributionAxis axis,
  );

  /// Create responsive variants
  Map<Breakpoint, Layout> generateResponsiveLayouts(
    Layout baseLayout,
  );
}
```

**Layout Strategies:**
- **Grid Layout**: Auto-arrange in grid with configurable columns/rows
- **Hierarchical Tree**: For org charts, component trees
- **Force-Directed**: For network diagrams, relationships
- **Flex Layout**: Mimic CSS flexbox behavior
- **Circular**: For radial diagrams
- **Flow**: Left-to-right flow with automatic wrapping

**Implementation:**
```dart
// Example: Smart grid layout
LayoutResult layoutGrid(List<Element> elements, {
  int columns = 3,
  double gutterX = 24,
  double gutterY = 24,
  EdgeInsets padding = const EdgeInsets.all(48),
}) {
  final positions = <ElementPosition>[];

  for (var i = 0; i < elements.length; i++) {
    final row = i ~/ columns;
    final col = i % columns;

    final x = padding.left + col * (elementWidth + gutterX);
    final y = padding.top + row * (elementHeight + gutterY);

    positions.add(ElementPosition(
      elementId: elements[i].id,
      x: x,
      y: y,
      width: elementWidth,
      height: elementHeight,
    ));
  }

  return LayoutResult(positions: positions);
}
```

**Features:**
- ✅ Collision detection and avoidance
- ✅ Automatic spacing based on design tokens
- ✅ Alignment guides (snap to other elements)
- ✅ Group-aware layouts (maintain element groups)
- ✅ Undo/redo for layout changes

---

### 1.2 Design System Integration

**Goal**: Connect canvas to Asmbli's design system

**Enhanced Service**: `DesignSystemCanvasBridge`

```dart
class DesignSystemCanvasBridge {
  final ThemeData appTheme;

  /// Get canvas-friendly color from design system
  String getCanvasColor(String semanticColor) {
    switch (semanticColor) {
      case 'primary': return ThemeColors(context).primary.toHex();
      case 'accent': return ThemeColors(context).accent.toHex();
      case 'surface': return ThemeColors(context).surface.toHex();
      // ... all semantic colors
    }
  }

  /// Get spacing value from spacing tokens
  double getSpacing(SpacingToken token) {
    switch (token) {
      case SpacingToken.xs: return SpacingTokens.xs;
      case SpacingToken.sm: return SpacingTokens.sm;
      // ... all spacing tokens
    }
  }

  /// Get border radius from design system
  double getBorderRadius(BorderRadiusToken token) {
    switch (token) {
      case BorderRadiusToken.sm: return BorderRadiusTokens.sm;
      // ... all radius tokens
    }
  }

  /// Apply typography scale to text elements
  TextStyle getTypographyStyle(TypographyToken token) {
    switch (token) {
      case TypographyToken.pageTitle: return TextStyles.pageTitle;
      case TypographyToken.sectionTitle: return TextStyles.sectionTitle;
      // ... all typography tokens
    }
  }

  /// Validate canvas against design system
  List<DesignSystemViolation> validateDesign(CanvasState canvas);
}
```

**Integration Points:**
1. **Color Palette**: Canvas uses app's 5 color schemes
2. **Spacing System**: Golden ratio spacing applied to layouts
3. **Typography**: `TextStyles` applied to all text elements
4. **Border Radius**: Consistent rounding from tokens
5. **Shadows/Elevation**: Design system elevation levels

**Example Usage:**
```dart
// Agent creates a button with design system colors
final button = await agentTools.createComponent(
  type: ComponentType.button,
  variant: 'primary',
  style: DesignSystemStyle(
    fillColor: 'primary',  // Resolves to ThemeColors.primary
    textStyle: 'button',    // Resolves to TextStyles.button
    padding: 'md',          // Resolves to SpacingTokens.md
    borderRadius: 'md',     // Resolves to BorderRadiusTokens.md
  ),
);
```

---

## Phase 2: Professional Component Library (Week 2-3)

### 2.1 Comprehensive UI Component System

**Goal**: Build production-ready component library with states and variants

**New Model**: `SmartComponent`

```dart
class SmartComponent {
  final String id;
  final ComponentType type;
  final ComponentVariant variant;
  final ComponentState state;
  final Map<String, dynamic> props;

  /// Render component to Excalidraw elements
  List<ExcalidrawElement> render();

  /// Get component with different variant
  SmartComponent withVariant(ComponentVariant variant);

  /// Get component in different state
  SmartComponent withState(ComponentState state);

  /// Compose with other components
  SmartComponent compose(List<SmartComponent> children);
}

enum ComponentType {
  // Form controls
  button, textField, checkbox, radio, dropdown, slider, switch_,

  // Navigation
  navbar, sidebar, tabs, breadcrumbs, pagination,

  // Data display
  table, card, list, grid, timeline, stat,

  // Feedback
  alert, toast, modal, dialog, tooltip, badge,

  // Layout
  container, stack, grid, flex, spacer,

  // Complex
  form, dashboard, profile, settings, login,
}

enum ComponentVariant {
  primary, secondary, success, warning, error, info,
  outlined, filled, text, elevated, tonal,
  small, medium, large, fullWidth,
}

enum ComponentState {
  default_, hover, pressed, focused, disabled, loading, error,
}
```

**Component Catalog Structure:**

```dart
class ComponentCatalog {
  // UI Controls
  static SmartComponent button({
    ComponentVariant variant = ComponentVariant.primary,
    ComponentState state = ComponentState.default_,
    String? label,
    IconData? icon,
  });

  static SmartComponent textField({
    ComponentVariant variant = ComponentVariant.outlined,
    ComponentState state = ComponentState.default_,
    String? placeholder,
    String? label,
    String? helperText,
    String? errorText,
  });

  // Navigation
  static SmartComponent navbar({
    String? logo,
    List<NavItem> menuItems,
    bool hasSearch = false,
    bool hasProfile = false,
  });

  // Complex components
  static SmartComponent loginForm({
    bool hasSocialLogin = true,
    bool hasForgotPassword = true,
  });

  static SmartComponent dashboard({
    List<Metric> metrics,
    List<Chart> charts,
    LayoutStyle layout = LayoutStyle.grid,
  });
}
```

**Component Composition Example:**

```dart
// Create a complex card component
final profileCard = ComponentCatalog.card(
  variant: ComponentVariant.elevated,
).compose([
  ComponentCatalog.avatar(size: ComponentSize.large),
  ComponentCatalog.text(
    text: 'John Doe',
    style: TypographyToken.cardTitle,
  ),
  ComponentCatalog.text(
    text: 'Software Designer',
    style: TypographyToken.bodySmall,
  ),
  ComponentCatalog.divider(),
  ComponentCatalog.statGroup(stats: [
    Stat('Projects', '24'),
    Stat('Followers', '1.2k'),
  ]),
  ComponentCatalog.buttonGroup([
    ComponentCatalog.button(label: 'Follow', variant: ComponentVariant.primary),
    ComponentCatalog.button(label: 'Message', variant: ComponentVariant.outlined),
  ]),
]);

// Render to canvas
final elements = await agentTools.renderComponent(
  profileCard,
  position: Point(100, 100),
);
```

---

### 2.2 Component States & Variants

**Visual Representation:**

Each component should render differently based on state:

```dart
// Button states
ButtonComponent(
  label: 'Submit',
  state: ComponentState.default_,
  // Renders: Normal button with primary color
);

ButtonComponent(
  label: 'Submit',
  state: ComponentState.hover,
  // Renders: Slightly darker, shadow increased
);

ButtonComponent(
  label: 'Submit',
  state: ComponentState.disabled,
  // Renders: Grayed out, no shadow, opacity 0.5
);

ButtonComponent(
  label: 'Submit',
  state: ComponentState.loading,
  // Renders: With spinner icon, label grayed
);
```

**Implementation:**

```dart
class ButtonRenderer {
  List<ExcalidrawElement> render(ButtonComponent component) {
    final baseColor = _getColorForVariant(component.variant);
    final stateModifier = _getStateModifier(component.state);

    return [
      // Background rectangle
      ExcalidrawElement.rectangle(
        x: component.x,
        y: component.y,
        width: component.width,
        height: component.height,
        fillColor: _applyStateToColor(baseColor, stateModifier),
        opacity: stateModifier.opacity,
        strokeWidth: stateModifier.strokeWidth,
        borderRadius: BorderRadiusTokens.md,
      ),

      // Button text
      ExcalidrawElement.text(
        x: component.x + component.width / 2,
        y: component.y + component.height / 2,
        text: component.label,
        fontSize: _getFontSize(component.size),
        fontFamily: 'Space Grotesk',
        textAlign: 'center',
        opacity: stateModifier.opacity,
      ),

      // Loading spinner (if loading state)
      if (component.state == ComponentState.loading)
        ExcalidrawElement.ellipse(
          x: component.x + 12,
          y: component.y + component.height / 2 - 8,
          width: 16,
          height: 16,
          strokeColor: baseColor,
          strokeStyle: 'dashed',
        ),
    ];
  }
}
```

---

## Phase 3: Software Architecture Diagrams (Week 3-4)

### 3.1 UML Diagram Support

**Goal**: Full support for software architecture diagrams

**New Service**: `UMLDiagramGenerator`

```dart
class UMLDiagramGenerator {
  /// Create class diagram
  Future<CanvasState> createClassDiagram({
    required List<ClassDefinition> classes,
    List<Relationship> relationships = const [],
    LayoutStrategy layout = LayoutStrategy.hierarchical,
  });

  /// Create sequence diagram
  Future<CanvasState> createSequenceDiagram({
    required List<Actor> actors,
    required List<Interaction> interactions,
  });

  /// Create state diagram
  Future<CanvasState> createStateDiagram({
    required List<State> states,
    required List<Transition> transitions,
    State? initialState,
  });

  /// Create activity diagram
  Future<CanvasState> createActivityDiagram({
    required List<Activity> activities,
    required List<Flow> flows,
  });
}

// Usage example
final classDiagram = await umlGenerator.createClassDiagram(
  classes: [
    ClassDefinition(
      name: 'User',
      attributes: ['id: String', 'name: String', 'email: String'],
      methods: ['login()', 'logout()', 'updateProfile()'],
    ),
    ClassDefinition(
      name: 'Agent',
      attributes: ['id: String', 'type: AgentType'],
      methods: ['execute()', 'stop()'],
    ),
  ],
  relationships: [
    Relationship(
      type: RelationshipType.composition,
      from: 'User',
      to: 'Agent',
      cardinality: '1..*',
    ),
  ],
);
```

**UML Elements:**

```dart
enum UMLShapeType {
  // Class diagram
  class_, interface, abstractClass, enum_,

  // Relationships
  inheritance, composition, aggregation, association, dependency,

  // Sequence diagram
  lifeline, activation, message, returnMessage,

  // State diagram
  state, initialState, finalState, transition, choice,

  // Activity diagram
  activity, decision, fork, join, swimlane,
}

class UMLRenderer {
  /// Render class with proper UML notation
  List<ExcalidrawElement> renderClass(ClassDefinition class_) {
    return [
      // Class name compartment
      _createRectangle(x, y, width, height: 40, label: class_.name),
      _createDivider(y: y + 40),

      // Attributes compartment
      _createTextList(
        y: y + 45,
        items: class_.attributes,
        prefix: '- ',  // Private
      ),
      _createDivider(y: y + 45 + attributesHeight),

      // Methods compartment
      _createTextList(
        y: y + 45 + attributesHeight + 5,
        items: class_.methods,
        prefix: '+ ',  // Public
      ),
    ];
  }

  /// Render relationship with proper arrow
  ExcalidrawElement renderRelationship(Relationship rel) {
    return ExcalidrawElement.arrow(
      start: _getClassCenter(rel.from),
      end: _getClassCenter(rel.to),
      arrowType: _getArrowType(rel.type),
      strokeStyle: rel.type == RelationshipType.dependency ? 'dashed' : 'solid',
      label: rel.cardinality,
    );
  }
}
```

---

### 3.2 Flowchart Intelligence

**Goal**: Smart flowchart generation with auto-routing

**Enhanced Service**: `FlowchartGenerator`

```dart
class FlowchartGenerator {
  /// Create flowchart from process description
  Future<CanvasState> generateFromDescription(String description);

  /// Create flowchart from code logic
  Future<CanvasState> generateFromCode(String code);

  /// Auto-route connections with smart pathing
  List<ExcalidrawElement> autoRouteConnections(
    List<FlowchartNode> nodes,
    List<FlowchartEdge> edges,
  );

  /// Optimize flowchart layout
  Future<CanvasState> optimizeLayout(CanvasState flowchart);
}

enum FlowchartNodeType {
  start, end,                      // Terminator (ellipse)
  process,                         // Rectangle
  decision,                        // Diamond
  inputOutput,                     // Parallelogram
  predefinedProcess,              // Rectangle with double lines
  document,                        // Rectangle with wavy bottom
  multiDocument,                   // Stacked documents
  data,                           // Parallelogram
  database,                        // Cylinder
  directData,                     // Trapezoid
  manualInput,                    // Slanted rectangle
  manualOperation,                // Trapezoid (inverted)
  delay,                          // Semi-circle
  offPageConnector,               // Pentagon
  or, sumJunction,                // Circle
}

// Example: Generate login flowchart
final loginFlow = await flowchartGen.generateFromDescription('''
  1. User enters email and password
  2. If credentials are valid:
     - Generate session token
     - Redirect to dashboard
  3. If credentials are invalid:
     - Show error message
     - Allow retry (max 3 attempts)
  4. If max attempts exceeded:
     - Lock account
     - Send email notification
''');
```

**Auto-Routing Algorithm:**

```dart
class ArrowRouter {
  /// Find optimal path avoiding obstacles
  List<Point> findPath(
    Point start,
    Point end,
    List<Rectangle> obstacles,
  ) {
    // A* pathfinding with Manhattan distance
    // Prefer orthogonal paths (vertical then horizontal)
    // Add waypoints to avoid overlapping other nodes
    // Minimize total arrow length
    // Ensure minimum 8pt spacing from obstacles
  }

  /// Create smooth bezier curves for organic look
  List<Point> smoothPath(List<Point> waypoints) {
    // Convert waypoints to bezier control points
    // Ensure curves don't intersect obstacles
  }
}
```

---

### 3.3 System Architecture Diagrams

**Goal**: Visualize system architecture

**New Service**: `SystemArchitectureGenerator`

```dart
class SystemArchitectureGenerator {
  /// Create microservices architecture diagram
  Future<CanvasState> createMicroservicesArchitecture({
    required List<Service> services,
    required List<Database> databases,
    required List<Integration> integrations,
  });

  /// Create deployment diagram
  Future<CanvasState> createDeploymentDiagram({
    required List<Environment> environments,
    required List<Node> nodes,
  });

  /// Create network topology
  Future<CanvasState> createNetworkTopology({
    required List<NetworkNode> nodes,
    required List<Connection> connections,
  });

  /// Create database ER diagram
  Future<CanvasState> createERDiagram({
    required List<Table> tables,
    required List<ForeignKey> foreignKeys,
  });
}
```

**Component Examples:**

```dart
// Microservice node
final authService = ArchitectureComponent(
  type: ComponentType.microservice,
  name: 'Auth Service',
  technology: 'Node.js',
  icon: Icons.security,
  color: '#4ECDC4',
  ports: ['8001'],
  endpoints: ['/login', '/logout', '/verify'],
);

// Database node
final userDB = ArchitectureComponent(
  type: ComponentType.database,
  name: 'User Database',
  technology: 'PostgreSQL',
  icon: Icons.database,
  color: '#336791',
);

// Message queue
final eventBus = ArchitectureComponent(
  type: ComponentType.messageQueue,
  name: 'Event Bus',
  technology: 'RabbitMQ',
  icon: Icons.stream,
  color: '#FF6B6B',
);

// Generate diagram
final architecture = await sysArchGen.createMicroservicesArchitecture(
  services: [authService, userService, orderService],
  databases: [userDB, orderDB],
  integrations: [eventBus, redisCache],
);
```

---

## Phase 4: Design Patterns & Templates (Week 4-5)

### 4.1 Pattern Library

**Goal**: Comprehensive library of UI patterns and templates

**New Service**: `DesignPatternLibrary`

```dart
class DesignPatternLibrary {
  /// Navigation patterns
  static Future<CanvasState> createTopNavigation({
    String? logo,
    List<NavItem> items,
    bool hasSearch = false,
    bool hasUserMenu = false,
  });

  static Future<CanvasState> createSidebarNavigation({
    List<NavSection> sections,
    bool collapsible = true,
  });

  static Future<CanvasState> createTabNavigation({
    List<Tab> tabs,
    TabStyle style = TabStyle.underline,
  });

  /// Data display patterns
  static Future<CanvasState> createDataTable({
    List<String> columns,
    int rowCount = 5,
    bool hasActions = true,
    bool hasPagination = true,
  });

  static Future<CanvasState> createCardGrid({
    int columns = 3,
    CardVariant variant = CardVariant.elevated,
  });

  static Future<CanvasState> createMasterDetail({
    ListStyle listStyle = ListStyle.sidebar,
    DetailLayout detailLayout = DetailLayout.full,
  });

  /// Form patterns
  static Future<CanvasState> createMultiStepForm({
    List<FormStep> steps,
    bool hasProgressIndicator = true,
  });

  static Future<CanvasState> createFilterPanel({
    List<FilterOption> filters,
  });

  /// Screen templates
  static Future<CanvasState> createLoginScreen({
    bool hasSocialLogin = true,
    bool hasSignup = true,
  });

  static Future<CanvasState> createProfileScreen({
    ProfileLayout layout = ProfileLayout.sidebar,
  });

  static Future<CanvasState> createSettingsScreen({
    List<SettingCategory> categories,
  });

  static Future<CanvasState> createDashboard({
    List<Widget> widgets,
    DashboardLayout layout = DashboardLayout.grid,
  });
}
```

**Pattern Categories:**

1. **Navigation Patterns**:
   - Top navbar with dropdown menus
   - Sidebar with collapsible sections
   - Breadcrumb navigation
   - Tab navigation (horizontal/vertical)
   - Drawer navigation (mobile)
   - Pagination controls

2. **Data Display Patterns**:
   - Data tables with sorting/filtering
   - Card grids (responsive)
   - List views (simple/detailed)
   - Master-detail views
   - Timelines
   - Calendar views

3. **Form Patterns**:
   - Single-page forms
   - Multi-step wizards
   - Inline editing
   - Filter panels
   - Search interfaces
   - Settings panels

4. **Feedback Patterns**:
   - Toast notifications
   - Modal dialogs
   - Confirmation dialogs
   - Loading states
   - Empty states
   - Error states

5. **Layout Patterns**:
   - Header + sidebar + content
   - Dashboard with widgets
   - Split panes
   - Tabs + content
   - Modal overlays

---

### 4.2 Screen Templates

**Goal**: Production-ready screen templates by category

**Template Categories:**

```dart
enum ScreenCategory {
  authentication,  // Login, signup, forgot password
  profile,        // User profile, edit profile
  settings,       // App settings, preferences
  ecommerce,      // Product list, cart, checkout
  admin,          // Admin dashboard, user management
  content,        // Blog post, article, documentation
  social,         // Feed, chat, notifications
  onboarding,     // Welcome screens, tutorials
}

class ScreenTemplateLibrary {
  /// Authentication screens
  static CanvasTemplate loginScreen;
  static CanvasTemplate signupScreen;
  static CanvasTemplate forgotPasswordScreen;
  static CanvasTemplate verifyEmailScreen;

  /// E-commerce screens
  static CanvasTemplate productListScreen;
  static CanvasTemplate productDetailScreen;
  static CanvasTemplate cartScreen;
  static CanvasTemplate checkoutScreen;

  /// Admin screens
  static CanvasTemplate adminDashboard;
  static CanvasTemplate userManagement;
  static CanvasTemplate analyticsScreen;

  /// Content screens
  static CanvasTemplate blogPostList;
  static CanvasTemplate articleReader;
  static CanvasTemplate documentationScreen;
}
```

**Template Structure:**

```dart
class CanvasTemplate {
  final String id;
  final String name;
  final ScreenCategory category;
  final List<TemplateSection> sections;
  final Map<String, dynamic> metadata;

  /// Render template with custom data
  Future<CanvasState> render({
    Map<String, dynamic>? data,
    ColorScheme? colorScheme,
    TypographyScale? typography,
  });

  /// Get customizable properties
  List<TemplateProperty> getCustomizableProperties();
}

// Example: Login screen template
final loginTemplate = CanvasTemplate(
  id: 'login_screen',
  name: 'Login Screen',
  category: ScreenCategory.authentication,
  sections: [
    TemplateSection(
      id: 'header',
      type: SectionType.header,
      components: [
        ComponentSpec(type: 'logo', position: Position.centerTop),
        ComponentSpec(type: 'title', text: 'Welcome Back'),
      ],
    ),
    TemplateSection(
      id: 'form',
      type: SectionType.content,
      components: [
        ComponentSpec(type: 'textField', label: 'Email', variant: 'outlined'),
        ComponentSpec(type: 'textField', label: 'Password', variant: 'outlined', isPassword: true),
        ComponentSpec(type: 'checkbox', label: 'Remember me'),
        ComponentSpec(type: 'button', label: 'Login', variant: 'primary', fullWidth: true),
      ],
    ),
    TemplateSection(
      id: 'footer',
      type: SectionType.footer,
      components: [
        ComponentSpec(type: 'link', text: 'Forgot password?'),
        ComponentSpec(type: 'divider', text: 'OR'),
        ComponentSpec(type: 'buttonGroup', buttons: [
          ButtonSpec(icon: 'google', label: 'Continue with Google'),
          ButtonSpec(icon: 'github', label: 'Continue with GitHub'),
        ]),
      ],
    ),
  ],
);
```

---

## Phase 5: AI-Powered Design Intelligence (Week 5-6)

### 5.1 Natural Language to Design

**Goal**: Generate complete designs from natural language descriptions

**New Service**: `NaturalLanguageDesignGenerator`

```dart
class NaturalLanguageDesignGenerator {
  final UnifiedLLMService llm;

  /// Generate complete screen from description
  Future<CanvasState> generateFromDescription(String description) async {
    // 1. Parse description with LLM
    final intent = await llm.parseDesignIntent(description);

    // 2. Select appropriate template
    final template = _selectTemplate(intent);

    // 3. Customize with intent details
    final customized = await template.customize(intent);

    // 4. Apply smart layout
    final laid_out = await layoutEngine.arrange(customized);

    // 5. Validate and refine
    final validated = await _validateDesign(laid_out);

    return validated;
  }

  /// Improve existing design based on feedback
  Future<CanvasState> improveDesign(
    CanvasState current,
    String feedback,
  ) async {
    final improvements = await llm.analyzeDesignFeedback(
      design: current,
      feedback: feedback,
    );

    return await _applyImprovements(current, improvements);
  }
}

// Usage examples:
final design1 = await nlDesigner.generateFromDescription('''
  Create a login screen with:
  - Email and password fields
  - "Remember me" checkbox
  - Login button
  - Forgot password link
  - Social login buttons (Google, GitHub)
  - Company logo at top
  - Modern, clean design with blue accent color
''');

final design2 = await nlDesigner.generateFromDescription('''
  E-commerce product listing page:
  - Grid of 12 products (4 columns)
  - Each product shows image, name, price, rating
  - Filter sidebar on left (category, price range, rating)
  - Sort dropdown (price, popularity, newest)
  - Pagination at bottom
  - Shopping cart icon in header
''');

final improved = await nlDesigner.improveDesign(
  design1,
  'Make it more spacious, use larger buttons, and add more whitespace',
);
```

---

### 5.2 Design Quality Analysis

**Goal**: AI-powered design critique and suggestions

**New Service**: `DesignQualityAnalyzer`

```dart
class DesignQualityAnalyzer {
  /// Analyze design quality across multiple dimensions
  Future<DesignAnalysis> analyze(CanvasState design) async {
    return DesignAnalysis(
      layoutScore: await _analyzeLayout(design),
      colorScore: await _analyzeColors(design),
      typographyScore: await _analyzeTypography(design),
      spacingScore: await _analyzeSpacing(design),
      consistencyScore: await _analyzeConsistency(design),
      accessibilityScore: await _analyzeAccessibility(design),
      usabilityScore: await _analyzeUsability(design),
      suggestions: await _generateSuggestions(design),
    );
  }

  /// Check accessibility compliance
  Future<AccessibilityReport> checkAccessibility(CanvasState design) async {
    return AccessibilityReport(
      wcagLevel: await _determineWCAGLevel(design),
      colorContrastIssues: await _checkColorContrast(design),
      textSizeIssues: await _checkTextSizes(design),
      touchTargetIssues: await _checkTouchTargets(design),
    );
  }

  /// Suggest improvements
  Future<List<DesignSuggestion>> getSuggestions(CanvasState design) async {
    final llmAnalysis = await llm.analyzeDesign(design.toDescription());

    return [
      ...await _getLayoutSuggestions(design),
      ...await _getColorSuggestions(design),
      ...await _getTypographySuggestions(design),
      ...await _getSpacingSuggestions(design),
      ...llmAnalysis.suggestions,
    ];
  }
}

// Example analysis
final analysis = await qualityAnalyzer.analyze(currentDesign);

print('''
Design Quality Score: ${analysis.overallScore}/100

Layout: ${analysis.layoutScore}/100
  ✓ Grid alignment detected
  ⚠️ Some elements not aligned to 8pt grid

Colors: ${analysis.colorScore}/100
  ✓ Good color contrast (WCAG AA)
  ✗ Using 8 different colors (recommended: 3-5)

Typography: ${analysis.typographyScore}/100
  ✓ Consistent font family
  ⚠️ 4 different font sizes (consider reducing to 3)

Spacing: ${analysis.spacingScore}/100
  ⚠️ Inconsistent spacing (16px, 18px, 24px mixed)
  💡 Use 8pt grid: 8, 16, 24, 32px

Accessibility: ${analysis.accessibilityScore}/100
  ⚠️ 2 touch targets smaller than 44x44pt
  ✗ Low contrast on 3 text elements

Suggestions:
1. Align all elements to 8pt grid
2. Reduce color palette to 4-5 colors
3. Increase touch target sizes
4. Improve text contrast for error messages
''');
```

---

### 5.3 Design Pattern Recognition

**Goal**: Recognize patterns in existing designs

**New Service**: `DesignPatternRecognizer`

```dart
class DesignPatternRecognizer {
  /// Detect UI patterns in canvas
  Future<List<DetectedPattern>> detectPatterns(CanvasState design) async {
    final patterns = <DetectedPattern>[];

    // Detect navigation patterns
    if (_hasTopBar(design)) {
      patterns.add(DetectedPattern(
        type: PatternType.topNavigation,
        confidence: 0.95,
        elements: _getTopBarElements(design),
      ));
    }

    // Detect card grids
    final cardGroups = await _detectCardGrids(design);
    patterns.addAll(cardGroups);

    // Detect form patterns
    final forms = await _detectForms(design);
    patterns.addAll(forms);

    return patterns;
  }

  /// Convert recognized pattern to reusable component
  Future<SmartComponent> patternToComponent(DetectedPattern pattern) async {
    // Extract pattern structure
    final structure = _extractStructure(pattern);

    // Create parameterized component
    return SmartComponent.fromPattern(
      pattern: pattern,
      structure: structure,
    );
  }
}

// Example: Auto-detect patterns and suggest templates
final patterns = await recognizer.detectPatterns(userDesign);

for (final pattern in patterns) {
  print('Detected: ${pattern.type} (${pattern.confidence * 100}% confidence)');

  if (pattern.confidence > 0.8) {
    final component = await recognizer.patternToComponent(pattern);
    // Save to component library for reuse
    await componentLibrary.save(component);
  }
}
```

---

## Phase 6: Responsive Design System (Week 6)

### 6.1 Breakpoint Management

**Goal**: Generate responsive variants automatically

**New Service**: `ResponsiveDesignGenerator`

```dart
class ResponsiveDesignGenerator {
  /// Generate responsive variants
  Future<Map<Breakpoint, CanvasState>> generateResponsiveVariants(
    CanvasState baseDesign,
  ) async {
    return {
      Breakpoint.mobile: await _adaptToMobile(baseDesign),
      Breakpoint.tablet: await _adaptToTablet(baseDesign),
      Breakpoint.desktop: baseDesign, // Base is desktop
      Breakpoint.wide: await _adaptToWide(baseDesign),
    };
  }

  /// Adapt layout for different screen size
  Future<CanvasState> _adaptToMobile(CanvasState desktop) async {
    // 1. Stack elements vertically
    final stacked = await layoutEngine.stackVertically(
      desktop.elements,
      spacing: SpacingTokens.lg,
    );

    // 2. Make components full-width
    final fullWidth = _makeFullWidth(stacked);

    // 3. Collapse navigation to hamburger menu
    final collapsedNav = await _collapseNavigation(fullWidth);

    // 4. Adjust font sizes for mobile
    final mobileTypography = _scaleFonts(collapsedNav, scale: 0.9);

    return mobileTypography;
  }
}

enum Breakpoint {
  mobile(maxWidth: 640),
  tablet(maxWidth: 1024),
  desktop(maxWidth: 1440),
  wide(maxWidth: 1920),
}

// Usage
final responsive = await responsiveGen.generateResponsiveVariants(desktopDesign);

// Display all variants
await canvas.showVariants([
  Variant('Mobile', responsive[Breakpoint.mobile]),
  Variant('Tablet', responsive[Breakpoint.tablet]),
  Variant('Desktop', responsive[Breakpoint.desktop]),
  Variant('Wide', responsive[Breakpoint.wide]),
]);
```

---

## Implementation Roadmap

### Week 1-2: Foundation
- ✅ Implement `CanvasLayoutEngine` with 6 layout strategies
- ✅ Build `DesignSystemCanvasBridge` for color/spacing/typography
- ✅ Create smart grid layout algorithm
- ✅ Add collision detection and spacing rules
- ✅ 8-point grid snapping

**Deliverable**: Intelligent layouts replacing random positioning

---

### Week 2-3: Component System
- ✅ Build `SmartComponent` model with states and variants
- ✅ Create `ComponentCatalog` with 50+ components
- ✅ Implement component composition system
- ✅ Add state rendering (default, hover, disabled, etc.)
- ✅ Build component preview/storybook

**Deliverable**: Professional component library

---

### Week 3-4: Software Diagrams
- ✅ Implement `UMLDiagramGenerator` for class/sequence/state diagrams
- ✅ Build `FlowchartGenerator` with auto-routing
- ✅ Create `SystemArchitectureGenerator` for system diagrams
- ✅ Add arrow routing algorithm
- ✅ Smart connector placement

**Deliverable**: Full UML and architecture diagram support

---

### Week 4-5: Patterns & Templates
- ✅ Build `DesignPatternLibrary` with 20+ patterns
- ✅ Create 30+ screen templates across 8 categories
- ✅ Implement template customization system
- ✅ Add pattern recognition
- ✅ Build template marketplace

**Deliverable**: Comprehensive pattern and template library

---

### Week 5-6: AI Intelligence
- ✅ Implement `NaturalLanguageDesignGenerator`
- ✅ Build `DesignQualityAnalyzer` with WCAG compliance
- ✅ Create `DesignPatternRecognizer`
- ✅ Add LLM-powered design critique
- ✅ Implement design improvement suggestions

**Deliverable**: AI-powered design intelligence

---

### Week 6: Responsive Design
- ✅ Build `ResponsiveDesignGenerator`
- ✅ Implement breakpoint management
- ✅ Add automatic mobile/tablet adaptation
- ✅ Create responsive preview mode
- ✅ Add viewport switcher

**Deliverable**: Full responsive design support

---

## Success Metrics

### Quantitative Metrics:
- **Component Library**: 50+ components vs 24 current
- **Layout Algorithms**: 6 strategies vs 0 current
- **Templates**: 30+ templates vs 3 current
- **Design Patterns**: 20+ patterns vs 0 current
- **UML Support**: 4 diagram types vs 0 current
- **AI Features**: 3 AI services vs 0 current

### Qualitative Metrics:
- **Design Quality**: Professional-grade outputs
- **User Experience**: Natural language input works reliably
- **Intelligence**: Auto-layout produces good results without manual tweaking
- **Accessibility**: WCAG AA compliance by default
- **Productivity**: 10x faster to create designs than manual Excalidraw

### Target Maturity: 80-90%
**Current**: 20-25%
**After Phase 1-2**: 40-50%
**After Phase 3-4**: 60-70%
**After Phase 5-6**: 80-90%

---

## Technical Architecture

### New Services Structure:

```
lib/core/services/design_intelligence/
├── layout/
│   ├── canvas_layout_engine.dart          ← Phase 1
│   ├── layout_strategies.dart
│   ├── collision_detector.dart
│   └── grid_snapper.dart
├── components/
│   ├── smart_component.dart               ← Phase 2
│   ├── component_catalog.dart
│   ├── component_renderer.dart
│   └── component_composer.dart
├── diagrams/
│   ├── uml_diagram_generator.dart         ← Phase 3
│   ├── flowchart_generator.dart
│   ├── system_architecture_generator.dart
│   └── arrow_router.dart
├── patterns/
│   ├── design_pattern_library.dart        ← Phase 4
│   ├── screen_template_library.dart
│   ├── pattern_recognizer.dart
│   └── template_customizer.dart
├── intelligence/
│   ├── nl_design_generator.dart           ← Phase 5
│   ├── design_quality_analyzer.dart
│   ├── accessibility_checker.dart
│   └── design_suggester.dart
├── responsive/
│   ├── responsive_design_generator.dart   ← Phase 6
│   ├── breakpoint_manager.dart
│   └── viewport_adapter.dart
└── design_system_canvas_bridge.dart       ← Phase 1
```

---

## Risk Mitigation

### Technical Risks:

1. **Performance**: Complex layouts may be slow
   - **Mitigation**: Implement caching, web worker for layout computation

2. **LLM Quality**: Natural language may not parse correctly
   - **Mitigation**: Fallback to template selection, iterative refinement

3. **Complexity**: Too many options may confuse users
   - **Mitigation**: Smart defaults, progressive disclosure

### Resource Risks:

1. **Timeline**: 6 weeks is ambitious
   - **Mitigation**: Phased delivery, MVP each week

2. **Integration**: Many moving parts
   - **Mitigation**: Strong interfaces, comprehensive testing

---

## Conclusion

This enhancement plan transforms the Excalidraw integration from basic shape manipulation (20% maturity) to professional software design intelligence (80-90% maturity). The phased approach ensures incremental value delivery while building toward the full vision.

**Key Innovations:**
1. 🎯 Smart layout engine replacing random positioning
2. 🎨 50+ component library with states and variants
3. 📐 Full UML and architecture diagram support
4. 🤖 AI-powered design generation and critique
5. 📱 Automatic responsive design generation
6. ✅ WCAG accessibility compliance by default

**Next Steps:**
1. Review and approve plan
2. Prioritize phases (all 6 or subset?)
3. Begin Phase 1 implementation
4. Iterative delivery with user feedback

This will make Asmbli's design agent truly competitive with professional design tools like Figma, Sketch, and Adobe XD - but with AI intelligence built in from the ground up.
