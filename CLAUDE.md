# AgentEngine Development Guidelines

## Design System Rules

### ALWAYS Use Existing Design System
- **Location**: `lib/core/design_system/`
- **Import**: `import 'core/design_system/design_system.dart';`
- **Never** create new color schemes - use existing warm neutral palette

### Color Palette (Warm Neutrals Only)
```dart
// ALWAYS use these semantic colors
SemanticColors.background           // #FBF9F5
SemanticColors.surface             // #FCFAF7  
SemanticColors.primary             // #3D3328 (dark brown)
SemanticColors.onSurface           // #3D3328
SemanticColors.onSurfaceVariant    // #736B5F
SemanticColors.border              // #E8E1D3
```

### Component Usage
```dart
// ALWAYS use design system components
AsmblCard(child: ...)              // Instead of Card()
AsmblButton.primary(text: "...")   // Instead of ElevatedButton()
HeaderButton(text: "...", icon: ...)  // For navigation
TextStyles.pageTitle               // Instead of TextStyle()
SpacingTokens.xxl                  // Instead of EdgeInsets.all(24)
```

### Layout Patterns
- **Page Structure**: Gradient background + semi-transparent header + content
- **Header Padding**: `SpacingTokens.headerPadding` (24px)
- **Page Padding**: `SpacingTokens.xxl` (24px)
- **Element Spacing**: `SpacingTokens.lg` (16px)
- **Border Radius**: `BorderRadiusTokens.xl` (12px for cards)

### Typography
- **Font**: Space Grotesk throughout
- **Brand Title**: `TextStyles.brandTitle` (bold italic)
- **Page Titles**: `TextStyles.pageTitle`
- **Body Text**: `TextStyles.bodyMedium`

### Interactive States
- All components have built-in hover/pressed states
- Use warm overlays, not blue highlights
- Consistent 150ms transitions

## Development Rules

### When Adding New Features
1. **NEVER** create new design tokens
2. **ALWAYS** use existing components first
3. **EXTEND** existing components if needed
4. **MAINTAIN** warm neutral aesthetic
5. **TEST** hover states work consistently

### Forbidden Practices
- ❌ Using `Color(0xFF...)` directly
- ❌ Creating blue color schemes
- ❌ Using `Container()` without design system
- ❌ Hardcoding spacing values
- ❌ Mixing different color palettes

### Required Practices  
- ✅ Import design system in every new file
- ✅ Use semantic color names
- ✅ Apply consistent spacing tokens
- ✅ Follow existing layout patterns
- ✅ Test all interactive states