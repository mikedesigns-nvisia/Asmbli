# Design System Usage Guide

## ⚠️ CRITICAL: Use ThemeColors, Not SemanticColors

**ALWAYS** use `ThemeColors(context)` for dynamic color scheme support.
**NEVER** use `SemanticColors.*` (deprecated) or hardcoded `Color(0xFF...)`.

---

## Quick Reference

### Colors (Multi-Scheme Support)
```dart
// ✅ CORRECT - Supports all 5 color schemes
final colors = ThemeColors(context);

colors.background              // Main background
colors.surface                // Card/surface backgrounds
colors.primary                // Primary brand color
colors.accent                 // Accent/tertiary color
colors.onSurface              // Main text color
colors.onSurfaceVariant       // Secondary text color
colors.border                 // Border color

// Gradient colors (adapt to selected scheme)
colors.backgroundGradientStart
colors.backgroundGradientMiddle
colors.backgroundGradientEnd

// Status colors
colors.success
colors.warning
colors.error

// ❌ WRONG - Deprecated, breaks color scheme switching
// SemanticColors.primary  // DON'T USE THIS
// Color(0xFF123456)       // DON'T USE THIS
```

### Available Color Schemes
Users can select from 5 color schemes in Settings > Appearance:
1. **Warm Neutral** (default) - Cream/brown tones
2. **Cool Blue** - Professional blue palette
3. **Forest Green** - Rich green tones
4. **Sunset Orange** - Warm orange/red
5. **Silver Onyx** - Monochrome elegance

### Components
```dart
// Cards
AsmblCard(child: ...)
AsmblStatsCard(title: "...", value: "...", icon: Icons.smart_toy)

// Buttons
AsmblButton.primary(text: "Save", icon: Icons.save, onPressed: () {})
AsmblButton.accent(text: "Create", onPressed: () {})
AsmblButton.secondary(text: "Cancel", onPressed: () {})
AsmblButton.outline(text: "Learn More", onPressed: () {})
AsmblButton.destructive(text: "Delete", onPressed: () {})
HeaderButton(text: "Templates", icon: Icons.library_books, onPressed: () {})

// Typography
TextStyles.pageTitle              // 32px bold
TextStyles.sectionTitle           // 24px semibold
TextStyles.cardTitle              // 18px semibold
TextStyles.bodyMedium             // 14px regular
TextStyles.brandTitle             // 20px bold italic
```

### Spacing
```dart
// Golden ratio-based spacing system
SpacingTokens.xs            // 4px
SpacingTokens.sm            // 8px
SpacingTokens.md            // 13px
SpacingTokens.lg            // 16px
SpacingTokens.xl            // 21px
SpacingTokens.xxl           // 24px (standard page padding)
SpacingTokens.headerPadding // 24px
SpacingTokens.sectionSpacing // 24px
```

### Border Radius
```dart
BorderRadiusTokens.sm       // 2px
BorderRadiusTokens.md       // 6px
BorderRadiusTokens.lg       // 8px
BorderRadiusTokens.xl       // 12px (cards)
```

---

## Layout Pattern

### ✅ CORRECT Implementation
```dart
import 'core/design_system/design_system.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);  // ✅ Get theme-aware colors

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            colors.backgroundGradientStart,   // ✅ Dynamic colors
            colors.backgroundGradientMiddle,
            colors.backgroundGradientEnd,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(children: [
        // Header with semi-transparent background
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.headerPadding,  // ✅ Use tokens
            vertical: SpacingTokens.pageVertical,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.8),  // ✅ Dynamic color
            border: Border(
              bottom: BorderSide(color: colors.border.withOpacity(0.1)),
            ),
          ),
          child: // Navigation
        ),
        // Content with standard padding
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xxl),  // ✅ Token
            child: // Page content
          ),
        ),
      ]),
    );
  }
}
```

### ❌ WRONG Implementation
```dart
// DON'T DO THIS:
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF5F1E8),  // ❌ Hardcoded color
  ),
  padding: EdgeInsets.all(24),  // ❌ Magic number
  child: Text(
    'Hello',
    style: TextStyle(        // ❌ Custom style
      fontSize: 16,
      color: Colors.black,    // ❌ Hardcoded color
    ),
  ),
)
```

---

## Checklist for New Components

- [ ] Imports `core/design_system/design_system.dart`
- [ ] Uses `ThemeColors(context)` for ALL colors (not SemanticColors)
- [ ] Uses `SpacingTokens.*` instead of hardcoded spacing
- [ ] Uses `TextStyles.*` instead of custom TextStyle
- [ ] Uses `BorderRadiusTokens.*` for rounded corners
- [ ] Includes hover/pressed states with animations
- [ ] Tests with all 5 color schemes (switch in Settings)
- [ ] Tests in both light and dark mode
- [ ] Has consistent 150ms transitions

---

## Common Mistakes

### ❌ Using Deprecated SemanticColors
```dart
// WRONG
color: SemanticColors.primary

// RIGHT
final colors = ThemeColors(context);
color: colors.primary
```

### ❌ Hardcoded Colors
```dart
// WRONG
color: Color(0xFF4ECDC4)
color: Colors.blue

// RIGHT
final colors = ThemeColors(context);
color: colors.primary
```

### ❌ Hardcoded Spacing
```dart
// WRONG
padding: EdgeInsets.all(16)

// RIGHT
padding: const EdgeInsets.all(SpacingTokens.lg)
```

### ❌ Custom Text Styles
```dart
// WRONG
Text('Title', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))

// RIGHT
Text('Title', style: TextStyles.sectionTitle)
```

---

## Testing Color Schemes

To verify your component works with all color schemes:

1. Run the app
2. Go to **Settings > Appearance**
3. Try each color scheme:
   - Warm Neutral (cream/brown)
   - Cool Blue (professional blue)
   - Forest Green (rich greens)
   - Sunset Orange (warm orange)
   - Silver Onyx (monochrome)
4. Toggle between Light and Dark mode
5. Ensure all colors adapt correctly

---

## Migration from SemanticColors

If you have existing code using `SemanticColors`, update it:

```dart
// OLD (deprecated)
color: SemanticColors.primary

// NEW (correct)
final colors = ThemeColors(context);
color: colors.primary
```

Run this find/replace across your codebase:
- Find: `SemanticColors.`
- Replace with: `colors.` (after adding `final colors = ThemeColors(context);`)

---

## Questions?

See `CLAUDE.md` for full development guidelines or ask the team.