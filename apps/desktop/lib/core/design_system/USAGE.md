# Design System Usage Guide

## Quick Reference

### Colors (Warm Neutrals)
```dart
SemanticColors.background           // Cream background
SemanticColors.surface             // Card background  
SemanticColors.primary             // Dark brown actions
SemanticColors.onSurface           // Dark text
SemanticColors.onSurfaceVariant    // Muted text
SemanticColors.border              // Subtle borders
```

### Components
```dart
// Cards
AsmblCard(child: ...)
AsmblStatsCard(title: "...", value: "...", icon: Icons.smart_toy)

// Buttons  
AsmblButton.primary(text: "Save", icon: Icons.save, onPressed: () {})
AsmblButton.secondary(text: "Cancel", onPressed: () {})
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
SpacingTokens.xs      // 4px
SpacingTokens.sm      // 8px  
SpacingTokens.lg      // 16px
SpacingTokens.xxl     // 24px (standard page padding)
SpacingTokens.headerPadding // 24px
SpacingTokens.sectionSpacing // 24px
```

### Layout Pattern
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        SemanticColors.backgroundGradientStart,
        SemanticColors.backgroundGradientEnd,
      ],
    ),
  ),
  child: Column(children: [
    // Header with semi-transparent background
    Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.headerPadding,
        vertical: SpacingTokens.pageVertical,
      ),
      decoration: BoxDecoration(
        color: SemanticColors.headerBackground,
        border: Border(bottom: BorderSide(color: SemanticColors.headerBorder)),
      ),
      child: // Navigation
    ),
    // Content with standard padding
    Padding(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: // Page content
    ),
  ]),
)
```

## Checklist for New Components

- [ ] Imports `core/design_system/design_system.dart`
- [ ] Uses `SemanticColors.*` instead of hardcoded colors
- [ ] Uses `SpacingTokens.*` instead of hardcoded spacing
- [ ] Uses `TextStyles.*` instead of custom TextStyle
- [ ] Uses `BorderRadiusTokens.*` for rounded corners
- [ ] Includes hover/pressed states
- [ ] Follows warm neutral palette
- [ ] Has consistent 150ms transitions