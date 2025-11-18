# Context Library Integration for Spec-Driven Design

**Date**: 2025-11-15
**Status**: PLANNING
**Goal**: Integrate user's context library (brand guidelines, design tokens, style guides) into the spec-driven design workflow

---

## Overview

The agent needs access to your **Context Library** - documents and resources that define your brand, design system, and style guidelines. This context should be automatically pulled into the spec generation process.

---

## Context Library Structure

### What Goes in the Context Library

```
context_library/
├── brand/
│   ├── brand_guidelines.md      # Brand identity (mission, values, voice)
│   ├── logo_usage.md            # Logo specs and usage rules
│   ├── color_palette.md         # Brand colors with hex codes
│   └── typography.md            # Font families, sizes, weights
├── design_system/
│   ├── design_tokens.json       # Programmatic tokens (colors, spacing, etc.)
│   ├── component_library.md     # UI component specifications
│   ├── spacing_system.md        # Grid system (8pt, golden ratio, etc.)
│   └── accessibility.md         # WCAG standards, contrast ratios
├── style_guides/
│   ├── visual_style.md          # Visual design principles
│   ├── illustration_guide.md    # Illustration style and usage
│   ├── photography_guide.md     # Photo style and treatment
│   └── iconography.md           # Icon style and library
├── templates/
│   ├── dashboard_patterns.md    # Standard dashboard layouts
│   ├── form_patterns.md         # Form design patterns
│   └── navigation_patterns.md   # Navigation structures
└── references/
    ├── competitor_analysis.pdf  # Competitive research
    ├── user_research.pdf        # User testing insights
    └── design_inspiration/      # Saved design examples
```

---

## How Context is Used in Each Phase

### Phase 0: Context Already in Session (User-Controlled)

**User adds context via Agent Panel UI (before starting conversation):**

```
Agent Panel UI:
┌─────────────────────────────────────────┐
│  Design Agent                           │
├─────────────────────────────────────────┤
│  📚 Session Context:                    │
│    ✓ Brand Guidelines          [Remove]│
│    ✓ Design Tokens             [Remove]│
│                                          │
│  [+ Add from Context Library]           │
│  [+ Upload Document]                    │
├─────────────────────────────────────────┤
│  Chat:                                  │
│                                          │
│  You: Create a pricing page             │
│                                          │
│  Agent: I see you've added:             │
│  • Brand Guidelines (transparency value)│
│  • Design Tokens (#4ecdc4 primary)      │
│                                          │
│  What pricing tiers do you want?        │
└─────────────────────────────────────────┘
```

**Agent receives context passively:**
- User explicitly adds docs to session context
- Context appears in agent's system message
- Agent references what's been provided
- No automatic searching or loading

### Phase 1: Requirements (With Brand Context)

**Requirements informed by brand guidelines:**

```markdown
# Design Requirements: Pricing Page

## Context Loaded
- Brand Guidelines: "Professional, approachable, transparent"
- Target Audience: "Startups and SMBs"
- Brand Values: "Simplicity, honesty, customer-first"

## R1: Pricing Tiers Display
**As a** potential customer
**I want** to see clear pricing options
**So that** I can choose the right plan

**Acceptance Criteria:**
- GIVEN I view the pricing page
- WHEN I scroll to tiers
- THEN I see 3 plans: Starter, Professional, Enterprise

**Visual Requirements (from brand guidelines):**
- Use "approachable" tone: rounded corners, soft shadows
- Highlight "Professional" tier (most popular)
- Transparent pricing: no "Contact us" - show exact numbers
- Colors: Primary #4ecdc4 (from design_tokens.json)
```

**Agent pulls from context:**
- Brand voice → tone of design
- Brand values → transparency requirement
- Design tokens → exact color codes

---

### Phase 2: Design Spec (With Design System)

**Spec automatically applies design system:**

```markdown
# Design Specification: Pricing Page

## Context Applied

### From design_tokens.json
- **Primary Color**: #4ecdc4 (loaded automatically)
- **Surface Color**: #1a1d29
- **Spacing**: 8pt grid system (xs:4, sm:8, md:16, lg:24)
- **Typography**: Space Grotesk (headings), Inter (body)
- **Border Radius**: 8px (from tokens)

### From brand_guidelines.md
- **Tone**: Professional but approachable
- **Visual Style**: Clean, modern, minimal
- **Photography**: Avoid stock photos, use illustrations

### From accessibility.md
- **Contrast Ratio**: Minimum 4.5:1 (WCAG AA)
- **Touch Targets**: Minimum 44x44px
- **Focus Indicators**: 2px outline, primary color

## Component Specifications

### Pricing Card Component
**Based on component_library.md pattern:**
- Container: 360x480px (from standard card dimensions)
- Border radius: 8px (from design_tokens.json)
- Padding: 32px (spacing.xl from tokens)
- Shadow: 0 4px 12px rgba(0,0,0,0.1) (from visual_style.md)

**Structure (from component_library.md):**
1. Plan name (Typography: heading3, 24px)
2. Price (Typography: display2, 48px, SemiBold)
3. Feature list (Typography: body, 16px, line-height 1.6)
4. CTA button (Component: PrimaryButton from library)

### Color Application (from color_palette.md)
- **Free Tier**: Neutral colors (surface + border)
- **Professional Tier**: Primary accent (#4ecdc4) - highlighted
- **Enterprise Tier**: Gradient (primary → accent)

## Layout Structure

### From templates/pricing_patterns.md
Standard 3-column pricing layout:
- Hero section: 200px tall
- Pricing cards: 3-column grid, 24px gap
- FAQ section: below cards
- CTA footer: sticky bottom
```

**Agent pulls from:**
- Design tokens → exact values (no guessing)
- Component library → reusable patterns
- Brand guidelines → visual tone
- Accessibility standards → compliance

---

## Context Library MCP Tools

**Note**: Agent does NOT search or load context automatically. User controls what context is added to the session via UI.

### Tool 1: Get Session Context

```dart
/// Get context documents that user has added to this session
Future<Map<String, dynamic>> getSessionContext() async {
  final sessionService = ServiceLocator.instance.get<ChatSessionService>();

  final sessionContext = await sessionService.getAttachedContext();

  return {
    'documents': sessionContext.map((doc) => {
      'title': doc.title,
      'category': doc.category,
      'content': doc.content,
      'added_at': doc.addedAt.toIso8601String(),
    }).toList(),
    'total': sessionContext.length,
  };
}
```

**Usage:**
```dart
// Agent reads what user has attached to session
final context = await getSessionContext();

// Returns only documents user explicitly added:
// - brand/brand_guidelines.md (user added)
// - design_system/design_tokens.json (user added)
```

### Tool 2: Get Design Tokens

```dart
/// Get design tokens from session context or app defaults
Future<Map<String, dynamic>> getDesignTokens() async {
  final sessionService = ServiceLocator.instance.get<ChatSessionService>();

  // Check if user added design tokens to session
  final sessionContext = await sessionService.getAttachedContext();
  final tokensDoc = sessionContext.firstWhere(
    (doc) => doc.title == 'design_tokens.json' || doc.category == 'design_tokens',
    orElse: () => null,
  );

  if (tokensDoc != null) {
    // Use tokens from user's context
    return jsonDecode(tokensDoc.content);
  }

  // Fallback to app's built-in design system
  return _getAppDesignTokens();
}

Map<String, dynamic> _getAppDesignTokens() {
  final colors = ThemeColors(context);

  return {
    'colors': {
      'primary': colors.primary.toHex(),
      'accent': colors.accent.toHex(),
      'surface': colors.surface.toHex(),
      'background': colors.background.toHex(),
      'on_surface': colors.onSurface.toHex(),
      'border': colors.border.toHex(),
      'success': colors.success.toHex(),
      'warning': colors.warning.toHex(),
      'error': colors.error.toHex(),
    },
    'spacing': {
      'xs': SpacingTokens.xs,
      'sm': SpacingTokens.sm,
      'md': SpacingTokens.md,
      'lg': SpacingTokens.lg,
      'xl': SpacingTokens.xl,
      'xxl': SpacingTokens.xxl,
    },
    'typography': {
      'page_title': _serializeTextStyle(TextStyles.pageTitle),
      'section_title': _serializeTextStyle(TextStyles.sectionTitle),
      'card_title': _serializeTextStyle(TextStyles.cardTitle),
      'body_large': _serializeTextStyle(TextStyles.bodyLarge),
      'body_medium': _serializeTextStyle(TextStyles.bodyMedium),
    },
    'border_radius': {
      'sm': BorderRadiusTokens.sm,
      'md': BorderRadiusTokens.md,
      'lg': BorderRadiusTokens.lg,
      'xl': BorderRadiusTokens.xl,
    },
  };
}
```

### Tool 3: Parse Session Context

```dart
/// Extract structured data from session context documents
Future<Map<String, dynamic>> parseSessionContext() async {
  final sessionContext = await getSessionContext();
  final parsed = <String, dynamic>{};

  for (final doc in sessionContext['documents']) {
    final category = doc['category'];
    final content = doc['content'];

    if (category == 'brand') {
      parsed['brand'] = _parseBrandGuidelines(content);
    } else if (category == 'design_tokens') {
      parsed['design_tokens'] = jsonDecode(content);
    } else if (category == 'components') {
      parsed['components'] = _parseComponentLibrary(content);
    }
  }

  return parsed;
}
```

**Note**: These tools are **read-only**. Agent cannot add/remove context - only user can via UI.

---

## Updated Spec-Driven Workflow with Context

### Phase 0: User Adds Context (UI-Driven)

```
[User opens Agent Panel]

User clicks: [+ Add from Context Library]
  → Selects: Brand Guidelines ✓
  → Selects: Design Tokens ✓

[Context appears in session]

📚 Session Context:
  ✓ Brand Guidelines
  ✓ Design Tokens

[User starts conversation]

User: "Create a pricing page"

Agent (reads session context automatically):
"I see you've added Brand Guidelines and Design Tokens.
Your brand values transparency - I'll show exact pricing.
Using primary color #4ecdc4 from your tokens.

What pricing tiers do you want?"
```

### Phase 1: Requirements (Context-Aware)

```
Agent generates requirements informed by:
- Brand voice (from brand_guidelines.md)
- Target audience (from brand_guidelines.md)
- Existing patterns (from templates/pricing_patterns.md)

Example requirement:
"R1: Transparent Pricing Display
(Based on brand value: 'transparency' from brand_guidelines.md)
- No 'Contact Us' pricing
- Show exact dollar amounts
- Clearly list what's included"
```

### Phase 2: Design Spec (Token-Driven)

```
Agent generates spec using:
- Colors from design_tokens.json (exact hex codes)
- Spacing from design_tokens.json (8pt grid values)
- Typography from design_tokens.json (font families, sizes)
- Component patterns from component_library.md
- Visual style from visual_style.md

Example spec:
"Pricing Card Component
- Width: 360px (from component_library.md standard card)
- Padding: 32px (spacing.xl from design_tokens.json)
- Border radius: 8px (border_radius.md from tokens)
- Primary color: #4ecdc4 (colors.primary from tokens)
- Font: Space Grotesk 24px (typography.heading3 from tokens)"
```

### Phase 3: Tasks (Context-Referenced)

```
Agent generates tasks that reference context:

Task 2: Create Pricing Card Component
- [ ] Use dimensions from component_library.md: 360x480px
- [ ] Apply spacing from tokens: padding 32px (xl)
- [ ] Apply colors from tokens: primary #4ecdc4
- [ ] Apply typography from tokens: Space Grotesk 24px
- [ ] Match visual_style.md: rounded corners, soft shadow

Validates: Component matches brand design system
```

---

## Context Library UI in App

### Context Management Screen

```
┌─────────────────────────────────────────┐
│  Context Library                        │
├─────────────────────────────────────────┤
│  📁 Brand                               │
│    📄 brand_guidelines.md         [View]│
│    📄 logo_usage.md               [View]│
│    📄 color_palette.md            [View]│
│                                          │
│  📁 Design System                       │
│    📄 design_tokens.json          [View]│
│    📄 component_library.md        [View]│
│    📄 spacing_system.md           [View]│
│                                          │
│  📁 Templates                           │
│    📄 dashboard_patterns.md       [View]│
│    📄 form_patterns.md            [View]│
│                                          │
│  [+ Upload Document]  [+ Create New]     │
└─────────────────────────────────────────┘
```

### Context in Canvas Library Screen

**Agent chat shows loaded context:**

```
┌─────────────────────────────────────────┐
│  Design Agent Chat                      │
├─────────────────────────────────────────┤
│  📚 Context Loaded:                     │
│    ✓ Brand Guidelines                   │
│    ✓ Design Tokens                      │
│    ✓ Component Library                  │
│                                          │
│  You: Create a dashboard                │
│                                          │
│  Agent: I've loaded your brand context. │
│  I see you use:                          │
│  • Primary color: #4ecdc4 (teal)        │
│  • 8pt spacing grid                     │
│  • Space Grotesk for headings           │
│                                          │
│  What metrics should the dashboard show?│
└─────────────────────────────────────────┘
```

---

## Example: Brand Guidelines Document

### `brand/brand_guidelines.md`

```markdown
# Brand Guidelines

## Mission
Empower developers to build intelligent applications with AI agents.

## Brand Values
- **Simplicity**: Make complex AI accessible
- **Transparency**: Open about capabilities and limitations
- **Developer-First**: Tools that developers love to use

## Voice & Tone
- **Professional** but not corporate
- **Approachable** but not casual
- **Confident** but not arrogant
- **Technical** but not jargon-heavy

## Target Audience
- Primary: Software developers, technical leads
- Secondary: Product managers, CTOs
- Skill level: Intermediate to advanced

## Visual Principles
1. **Clean and Modern**: Avoid clutter, embrace whitespace
2. **Data-Driven**: Visualizations over decorative elements
3. **Accessible**: WCAG AA minimum, AAA preferred
4. **Consistent**: Use design system tokens exclusively

## Design Philosophy
- Form follows function
- Every element should have a purpose
- Delight users with subtle interactions
- Performance is a feature

## Color Usage
- **Primary (#4ecdc4)**: Interactive elements, CTAs, emphasis
- **Accent (#ff6b6b)**: Warnings, highlights, secondary actions
- **Surface (#1a1d29)**: Card backgrounds, containers
- **Background (#13161f)**: Page backgrounds

## Typography Hierarchy
1. **Headings**: Space Grotesk (geometric, modern, technical)
2. **Body**: Inter (readable, professional, versatile)
3. **Code**: Fira Code (monospace with ligatures)

## Pricing Philosophy
- Transparent pricing: always show exact numbers
- No "Contact us" for pricing
- Highlight value, not just features
- Annual discounts clearly shown
```

### `design_system/design_tokens.json`

```json
{
  "colors": {
    "primary": "#4ecdc4",
    "accent": "#ff6b6b",
    "surface": "#1a1d29",
    "background": "#13161f",
    "on_surface": "#ffffff",
    "on_surface_variant": "rgba(255, 255, 255, 0.6)",
    "border": "#2a2f3a",
    "success": "#2ecc71",
    "warning": "#f39c12",
    "error": "#e74c3c"
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48
  },
  "typography": {
    "font_families": {
      "heading": "Space Grotesk",
      "body": "Inter",
      "code": "Fira Code"
    },
    "sizes": {
      "xs": 12,
      "sm": 14,
      "base": 16,
      "lg": 18,
      "xl": 24,
      "2xl": 32,
      "3xl": 48
    },
    "weights": {
      "normal": 400,
      "medium": 500,
      "semibold": 600,
      "bold": 700
    },
    "line_heights": {
      "tight": 1.2,
      "normal": 1.5,
      "relaxed": 1.8
    }
  },
  "border_radius": {
    "sm": 2,
    "md": 6,
    "lg": 8,
    "xl": 12,
    "full": 9999
  },
  "shadows": {
    "sm": "0 1px 2px rgba(0, 0, 0, 0.05)",
    "md": "0 4px 6px rgba(0, 0, 0, 0.1)",
    "lg": "0 10px 15px rgba(0, 0, 0, 0.1)",
    "xl": "0 20px 25px rgba(0, 0, 0, 0.15)"
  },
  "grid": {
    "base_unit": 8,
    "columns": 12,
    "gutter": 16,
    "max_width": 1440
  }
}
```

---

## Agent System Prompt Updates

Add to `design_agent_system_prompt.md`:

```markdown
## Context Integration (PASSIVE)

User controls what context is available in your session. You cannot search or load context yourself.

### Reading Session Context

1. **Check Session Context**:
   - Call `getSessionContext()` to see what user has added
   - User adds context via UI before/during conversation
   - You read passively - never search or load

2. **Extract Information**:
   - Parse brand guidelines for voice, values, principles
   - Parse design tokens for exact color/spacing/typography values
   - Parse component library for reusable patterns

3. **Acknowledge Context**:
   - Tell user what context you see
   - Example: "I see you've added Brand Guidelines and Design Tokens"
   - Confirm you'll use their values

### Using Context in Each Phase

**Phase 1: Requirements**
- Apply brand voice from guidelines (if user added them)
- Reference brand values in acceptance criteria
- Use target audience from guidelines

**Phase 2: Design Spec**
- Use EXACT values from design_tokens.json (if user added it)
- Never guess colors, spacing, or typography
- Reference component patterns (if component library added)
- Follow visual principles from brand guidelines

**Phase 3: Tasks**
- Reference token names in tasks
- Example: "Apply primary color #4ecdc4 from design_tokens.json"
- Link to component library patterns (if available)

**Phase 4: Execution**
- Use exact token values in MCP commands
- Validate against brand guidelines (if provided)

### Context-Aware Language

**Good** (when context provided):
"Using your primary color (#4ecdc4) from design_tokens.json"
"Following your brand value of 'transparency' from guidelines"
"Applying 8pt grid from your design system"

**Good** (when no context):
"I'll use a professional color scheme. You can add design tokens for exact brand colors."
"I'll create standard spacing. Add design_tokens.json for your specific grid system."

**Never**:
- Search or load context automatically
- Add/remove context documents (user controls this)
- Assume context exists if not in session
```

---

## Benefits of Context Library Integration

✅ **Consistency**: Design system tokens ensure all designs match brand
✅ **Speed**: No need to explain brand every time
✅ **Accuracy**: Agent uses exact values, not approximations
✅ **Scalability**: Update tokens once, affects all future designs
✅ **Traceability**: Every design decision traces to documented guidelines
✅ **Onboarding**: New team members upload context, agent applies it

---

## Implementation Timeline

### Week 1: Context Service
- [ ] Create ContextService for document management
- [ ] Implement context library storage (Hive/SQLite)
- [ ] Add document search and indexing
- [ ] Create context management UI

### Week 2: MCP Integration
- [ ] Implement `searchContextLibrary()` tool
- [ ] Implement `getDesignTokens()` tool
- [ ] Implement `getBrandGuidelines()` tool
- [ ] Implement `getComponentLibrary()` tool
- [ ] Update agent system prompt

### Week 3: Spec Workflow Integration
- [ ] Add context loading to Phase 0
- [ ] Update requirements template (use brand context)
- [ ] Update design spec template (use tokens)
- [ ] Update tasks template (reference context)

### Week 4: UI & Testing
- [ ] Build Context Library screen
- [ ] Add context upload flow
- [ ] Show loaded context in agent chat
- [ ] Test with real brand guidelines

---

## Example Workflow with Context

```
User: "Create a pricing page"

Agent (internal):
[Searches context library: "pricing"]
[Loads: brand_guidelines.md, design_tokens.json, pricing_patterns.md]
[Extracts: brand values, color scheme, spacing, typography]

Agent: "I've loaded your context:
✓ Brand Guidelines (transparency, simplicity)
✓ Design Tokens (#4ecdc4 primary, 8pt grid)
✓ Pricing Patterns (3-column layout standard)

What pricing tiers would you like? (e.g., Free, Pro, Enterprise)"

User: "3 tiers: Starter $29/mo, Pro $79/mo, Enterprise $199/mo"

Agent: "Generating requirements based on your brand value of 'transparency'...
[Creates requirements.md with exact pricing, no 'Contact Us']

Does this match your vision?"

User: "Yes"

Agent: "Creating design spec using your design tokens...
[Uses #4ecdc4 from tokens, 8pt spacing, Space Grotesk typography]

This follows your component_library.md card pattern (360x480px).
Approve?"

User: "Looks perfect"

Agent: "Breaking into tasks with token references...
[Task 2: Apply primary color #4ecdc4 from design_tokens.json]

Shall I execute?"

User: "Go"

Agent: [Executes tasks with exact token values]
"✅ All tasks complete. Pricing page created using your design system."
```

---

**Status**: ✅ READY TO IMPLEMENT

**Dependencies**:
- Context Service implementation
- Penpot integration (for canvas execution)
- Spec-driven workflow (Phase 0-4 structure)

**Recommended**: Implement context library during Penpot migration Week 3 (Flutter Integration)
