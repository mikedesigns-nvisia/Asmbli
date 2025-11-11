# Asmbli Design Tokens Reference

A comprehensive guide to all design tokens available in the Asmbli design system. Design tokens are the foundational building blocks that ensure consistency across the entire application.

---

## 🎨 Color Tokens

### Multi-Color Scheme System

Asmbli supports **5 user-selectable color schemes** that adapt to both light and dark modes:

1. **Warm Neutral** (default) - Cream and brown tones
2. **Cool Blue** - Professional blue palette  
3. **Forest Green** - Rich green tones
4. **Sunset Orange** - Warm orange and red
5. **Silver Onyx** - Monochrome elegance

### Usage

```dart
// ✅ ALWAYS use ThemeColors for dynamic color scheme support
final colors = ThemeColors(context);

// ❌ NEVER use these (deprecated/breaks multi-scheme support)
// SemanticColors.primary
// Color(0xFF123456)
```

### Core Color Tokens

#### Surface Colors
```dart
colors.background              // Main app background
colors.surface                // Card and component backgrounds
colors.surfaceVariant          // Secondary surface (subtle contrast)
colors.surfaceSecondary        // Alternative surface option
```

#### Background Gradients
```dart
colors.backgroundGradientStart    // Lighter center of gradient
colors.backgroundGradientMiddle   // Main gradient color
colors.backgroundGradientEnd      // Darker edges of gradient
```

#### Text Colors
```dart
colors.onSurface              // Primary text (high contrast)
colors.onSurfaceVariant       // Secondary text (medium contrast)
colors.onBackground           // Text on background surfaces
colors.onSurfaceSecondary     // Alternative secondary text
colors.mutedForeground        // Muted/disabled text
```

#### Brand Colors
```dart
colors.primary                // Primary brand color
colors.onPrimary             // Text/icons on primary color
colors.accent                // Accent/tertiary color
colors.onAccent              // Text/icons on accent color
```

#### Border Colors
```dart
colors.border                // Standard borders
colors.borderSubtle          // Subtle/faded borders (50% opacity)
```

#### Semantic Colors
```dart
colors.success               // Success states (green)
colors.warning               // Warning states (yellow/orange)  
colors.error                 // Error states (red)
colors.info                  // Info states (blue)
```

#### Interactive States
```dart
colors.hover                 // Hover overlay (light opacity)
colors.pressed               // Pressed/active overlay
colors.focus                 // Focus indicator overlay
```

#### Special Colors
```dart
colors.headerBackground      // Navigation header background
colors.headerBorder          // Navigation header border
colors.cardBackground        // Card component background
colors.cardBorder            // Card component border
colors.inputBackground       // Form input background
```

### Color Scheme Values

#### Light Mode Primary Colors
```dart
// Warm Neutral: #8B6F47
// Cool Blue: #1E3A8A  
// Forest Green: #1E3B2B
// Sunset Orange: #9A3412
// Silver Onyx: #4A4A4A
```

#### Dark Mode Primary Colors
```dart
// Warm Neutral: #E6C794
// Cool Blue: #60A5FA
// Forest Green: #B8E6C8  
// Sunset Orange: #D4956B
// Silver Onyx: #B8B8B8
```

---

## 📏 Spacing Tokens

### Golden Ratio System

Asmbli uses a **golden ratio-based spacing system** (φ = 1.618) built on an 8px base unit for harmonious proportions.

```dart
// Base system
SpacingTokens.baseUnit = 8.0   // 8px base
SpacingTokens.phi = 1.618      // Golden ratio constant
```

### Core Spacing Scale

```dart
SpacingTokens.none = 0.0       // 0px
SpacingTokens.xxs = 2.0        // 2px  
SpacingTokens.xs = 4.0         // 4px
SpacingTokens.sm = 8.0         // 8px (base unit)
SpacingTokens.md = 13.0        // 13px (base × φ)
SpacingTokens.lg = 21.0        // 21px (base × φ²)
SpacingTokens.xl = 34.0        // 34px (base × φ³)
SpacingTokens.xxl = 55.0       // 55px (base × φ⁴)
SpacingTokens.xxxl = 89.0      // 89px (base × φ⁵)
SpacingTokens.huge = 144.0     // 144px (base × φ⁶)
```

### Layout-Specific Spacing

```dart
// Page layout
SpacingTokens.pageHorizontal = 34.0     // Page side margins
SpacingTokens.pageVertical = 34.0       // Page top/bottom spacing
SpacingTokens.headerPadding = 34.0      // Navigation header padding

// Content hierarchy  
SpacingTokens.sectionSpacing = 55.0     // Between major sections
SpacingTokens.elementSpacing = 21.0     // Between related elements
SpacingTokens.componentSpacing = 13.0   // Within components
```

### Component-Specific Spacing

```dart
// Buttons
SpacingTokens.buttonPadding = 21.0         // Horizontal padding
SpacingTokens.buttonPaddingVertical = 13.0 // Vertical padding

// Cards
SpacingTokens.cardPadding = 21.0           // Internal card padding
SpacingTokens.cardSpacing = 13.0           // Between card elements

// Lists and icons
SpacingTokens.iconSpacing = 8.0            // Icon to text spacing
SpacingTokens.listItemSpacing = 13.0       // List item spacing

// Typography
SpacingTokens.textLineSpacing = 8.0        // Small line spacing
SpacingTokens.textParagraphSpacing = 21.0  // Paragraph spacing
SpacingTokens.textSectionSpacing = 34.0    // Section spacing
```

### Usage Examples

```dart
// ✅ CORRECT - Use tokens
Padding(
  padding: const EdgeInsets.all(SpacingTokens.lg),
  child: Column(
    children: [
      Text('Title'),
      const SizedBox(height: SpacingTokens.md),
      Text('Content'),
    ],
  ),
)

// ❌ WRONG - Magic numbers
Padding(
  padding: const EdgeInsets.all(16),  // Use SpacingTokens.lg instead
  child: Column(
    children: [
      Text('Title'),
      const SizedBox(height: 8),      // Use SpacingTokens.sm instead
      Text('Content'),
    ],
  ),
)
```

---

## 🎯 Border Radius Tokens

### Scale

```dart
BorderRadiusTokens.none = 0.0      // 0px - No radius
BorderRadiusTokens.xs = 2.0        // 2px - Subtle rounding
BorderRadiusTokens.sm = 4.0        // 4px - Small components
BorderRadiusTokens.md = 6.0        // 6px - Standard buttons
BorderRadiusTokens.lg = 8.0        // 8px - Input fields
BorderRadiusTokens.xl = 12.0       // 12px - Cards, panels
BorderRadiusTokens.pill = 999.0    // 999px - Pill/fully rounded
```

### Usage Examples

```dart
// Buttons
BorderRadius.circular(BorderRadiusTokens.md)     // 6px

// Cards  
BorderRadius.circular(BorderRadiusTokens.xl)     // 12px

// Input fields
BorderRadius.circular(BorderRadiusTokens.lg)     // 8px

// Pills/badges
BorderRadius.circular(BorderRadiusTokens.pill)   // Fully rounded
```

---

## ✍️ Typography Tokens

### Font Family

```dart
TypographyTokens.fontFamily        // Google Fonts Fustat
```

### Font Weights

```dart
TypographyTokens.regular = FontWeight.w400    // Normal text
TypographyTokens.medium = FontWeight.w500     // Emphasis
TypographyTokens.semiBold = FontWeight.w600   // Headings
TypographyTokens.bold = FontWeight.w700       // Strong emphasis
```

### Font Sizes

```dart
TypographyTokens.fontSizeXXL = 32.0    // Page titles
TypographyTokens.fontSizeXL = 24.0     // Section headers
TypographyTokens.fontSizeLG = 20.0     // Card titles
TypographyTokens.fontSizeMD = 16.0     // Body text (accessibility baseline)
TypographyTokens.fontSizeSM = 14.0     // Small text, labels
TypographyTokens.fontSizeXS = 12.0     // Captions, metadata
```

### Text Styles (Ready-to-Use)

#### Headings
```dart
TextStyles.pageTitle               // 32px bold, page headers
TextStyles.sectionTitle            // 24px semibold, sections
TextStyles.cardTitle               // 20px semibold, cards
TextStyles.brandTitle              // 20px bold italic, "Asmbli"
```

#### Body Text
```dart
TextStyles.bodyLarge               // 16px regular, main content
TextStyles.bodyMedium              // 14px regular, secondary content  
TextStyles.bodySmall               // 12px regular, captions
```

#### Interactive Elements
```dart
TextStyles.button                  // 14px medium, buttons
TextStyles.navButton               // 14px medium, navigation
```

#### Labels & Metadata
```dart
TextStyles.labelLarge              // 14px medium, form labels
TextStyles.labelMedium             // 12px medium, secondary labels
TextStyles.caption                 // 12px regular, helper text
```

### Typography Usage

```dart
// ✅ CORRECT - Use predefined styles
Text(
  'Welcome to Asmbli',
  style: TextStyles.pageTitle,
)

Text(
  'Section Header',  
  style: TextStyles.sectionTitle,
)

Text(
  'Body content goes here...',
  style: TextStyles.bodyMedium,
)

// ❌ WRONG - Custom styles
Text(
  'Welcome to Asmbli',
  style: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,  // Use TextStyles.pageTitle instead
  ),
)
```

---

## 🎛️ Interactive State Tokens

### Animation Durations

```dart
// Standard transition duration
const Duration(milliseconds: 150)   // Hover, pressed states

// Layout transitions  
const Duration(milliseconds: 300)   // Sidebar, modal animations

// Page transitions
const Duration(milliseconds: 500)   // Route changes
```

### Opacity Values

```dart
// Disabled states
0.38                               // Material Design disabled opacity

// Overlay states
0.04 - 0.08                       // Hover overlays (light/dark)
0.08 - 0.12                       // Pressed overlays (light/dark)
0.12 - 0.16                       // Focus overlays (light/dark)

// Background opacity
0.7 - 0.9                         // Semi-transparent backgrounds
```

---

## 📐 Layout Tokens

### Content Width Constraints

```dart
// Maximum content width for readability
maxWidth: 1200.0                   // Desktop layout max width

// Sidebar widths
sidebarWidth: 280.0                // Standard sidebar
sidebarCollapsed: 48.0             // Collapsed sidebar
```

### Z-Index Layers

```dart
// Modal/overlay layers
zIndexModal: 1000                  // Modal dialogs
zIndexTooltip: 1100               // Tooltips
zIndexDropdown: 1200              // Dropdown menus
```

---

## 🔧 Usage Best Practices

### 1. Always Use Design Tokens

```dart
// ✅ DO THIS
final colors = ThemeColors(context);
Container(
  padding: const EdgeInsets.all(SpacingTokens.lg),
  decoration: BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
  ),
  child: Text(
    'Content',
    style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
  ),
)

// ❌ DON'T DO THIS  
Container(
  padding: EdgeInsets.all(16),           // Use SpacingTokens.lg
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),            // Use colors.surface
    borderRadius: BorderRadius.circular(12), // Use BorderRadiusTokens.xl
  ),
  child: Text(
    'Content',
    style: TextStyle(                    // Use TextStyles.bodyMedium
      fontSize: 14,
      color: Colors.black,
    ),
  ),
)
```

### 2. Test Across All Color Schemes

Your components should work with all 5 color schemes:

1. Go to **Settings > Appearance** 
2. Test each color scheme in both light and dark mode
3. Verify text contrast and visual hierarchy
4. Ensure interactive states are visible

### 3. Follow Spacing Hierarchy

```dart
// Page structure spacing (largest to smallest)
SpacingTokens.sectionSpacing    // 55px - Between major sections
SpacingTokens.elementSpacing    // 21px - Between related elements  
SpacingTokens.componentSpacing  // 13px - Within components
SpacingTokens.iconSpacing       // 8px - Icon to text
```

### 4. Typography Hierarchy

```dart
// Use appropriate hierarchy
TextStyles.pageTitle        // Page-level headings
TextStyles.sectionTitle     // Section headings
TextStyles.cardTitle        // Component headings
TextStyles.bodyMedium       // Main content
TextStyles.bodySmall        // Secondary content
TextStyles.caption          // Metadata/helpers
```

---

## 🚀 Quick Reference Card

### Most Common Tokens

```dart
// Colors
final colors = ThemeColors(context);
colors.surface, colors.onSurface, colors.primary, colors.border

// Spacing  
SpacingTokens.sm (8px), SpacingTokens.lg (21px), SpacingTokens.xxl (55px)

// Typography
TextStyles.bodyMedium, TextStyles.cardTitle, TextStyles.sectionTitle

// Border Radius
BorderRadiusTokens.md (6px), BorderRadiusTokens.xl (12px)
```

### Import Statement

```dart
import 'core/design_system/design_system.dart';
```

---

## 📋 Component Checklist

When creating new components, ensure:

- [ ] Uses `ThemeColors(context)` for all colors
- [ ] Uses `SpacingTokens.*` for all spacing
- [ ] Uses `TextStyles.*` for all text
- [ ] Uses `BorderRadiusTokens.*` for border radius
- [ ] Tests with all 5 color schemes
- [ ] Tests in light and dark mode
- [ ] Includes proper interactive states
- [ ] Uses 150ms transition duration

---

## 🔗 Related Documentation

- [`USAGE.md`](./USAGE.md) - Design system implementation guide
- [`CLAUDE.md`](../../CLAUDE.md) - Development guidelines
- [`design_system.dart`](./design_system.dart) - Main exports

---

*Design tokens are the foundation of consistent, scalable design. When in doubt, always use tokens over hardcoded values.*