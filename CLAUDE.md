# Asmbli Development Guidelines

## Design System Rules

### ALWAYS Use Existing Design System
- **Location**: `lib/core/design_system/`
- **Import**: `import 'core/design_system/design_system.dart';`
- **Use the Multi-Color Scheme System** - supports multiple color palettes

### Color Scheme System
The app now supports multiple color schemes that users can select in Settings > Appearance:

#### Available Color Schemes:
1. **Mint Green** (default) - Mint/forest green palette
2. **Cool Blue** - Professional blue tones
3. **Forest Green** - Rich forest greens
4. **Sunset Orange** - Warm orange/red tones

#### Theme Colors Usage:
```dart
// ALWAYS use ThemeColors for dynamic color scheme support
final colors = ThemeColors(context);

// Core colors that adapt to selected scheme
colors.background              // Main background
colors.surface                // Card/surface backgrounds
colors.primary                // Primary brand color
colors.onSurface              // Main text color
colors.onSurfaceVariant       // Secondary text color
colors.border                 // Border color
colors.accent                 // Accent/tertiary color

// Special gradient colors (adapt to color scheme)
colors.backgroundGradientStart
colors.backgroundGradientMiddle  
colors.backgroundGradientEnd
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
- **Font**: Fustat (Google Fonts) throughout
- **Brand Title**: `TextStyles.brandTitle` (bold italic)
- **Page Titles**: `TextStyles.pageTitle`
- **Body Text**: `TextStyles.bodyMedium`

### Interactive States
- All components have built-in hover/pressed states
- Use theme-appropriate overlays that match selected color scheme
- Consistent 150ms transitions

## Development Rules

### When Adding New Features
1. **ALWAYS** use `ThemeColors(context)` for colors
2. **ALWAYS** use existing components first
3. **EXTEND** existing components if needed
4. **MAINTAIN** color scheme compatibility
5. **TEST** all color schemes work consistently

### Color Scheme Management
```dart
// Access current theme state
final themeState = ref.watch(themeServiceProvider);
final themeService = ref.read(themeServiceProvider.notifier);

// Change color scheme
themeService.setColorScheme(AppColorSchemes.coolBlue);

// Change theme mode (light/dark)
themeService.setTheme(ThemeMode.dark);

// Get theme-aware colors with specific scheme
final colors = ThemeColors(context, colorScheme: themeState.colorScheme);
```

### Adding New Color Schemes
To add new color schemes, edit `lib/core/theme/color_schemes.dart`:
1. Add scheme ID constant to `AppColorSchemes`
2. Add entry to `AppColorSchemes.all` list
3. Add case to `getTheme()` method
4. Implement light and dark theme variants

### Forbidden Practices
- ❌ Using `Color(0xFF...)` directly
- ❌ Hardcoding colors instead of using ThemeColors
- ❌ Using `Container()` without design system
- ❌ Hardcoding spacing values
- ❌ Creating color schemes outside the system

### Required Practices  
- ✅ Import design system in every new file
- ✅ Use `ThemeColors(context)` for all colors
- ✅ Apply consistent spacing tokens
- ✅ Follow existing layout patterns
- ✅ Test all color schemes and theme modes