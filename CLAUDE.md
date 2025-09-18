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

● What NOT to Do When Coding: Anti-Patterns to Avoid

  1. Speed Over Thoughtfulness

  ❌ DON'T:

  - Rush to implement solutions without understanding the problem
  - Start coding before reading existing architecture
  - Skip the investigation phase to "save time"
  - Assume you understand the codebase from a quick glance

  ✅ DO INSTEAD:

  - Read through related code files first
  - Understand existing patterns and conventions
  - Map out how your changes fit into the current architecture
  - Plan integration points before writing code

  ---
  2. Assumptions Instead of Investigation

  ❌ DON'T:

  - Assume services, providers, or configurations exist
  - Guess at API contracts or data structures
  - Build code based on what you think should be there
  - Skip verifying your assumptions with actual code inspection

  ✅ DO INSTEAD:

  - Verify configurations and services actually exist
  - Check what providers are defined and available
  - Examine existing state management patterns
  - Trace through the codebase to understand data flow

  ---
  3. Parallel Systems Instead of Extension

  ❌ DON'T:

  - Create new services when existing ones handle similar functionality
  - Build separate state management alongside existing providers
  - Ignore established architectural patterns
  - Reinvent wheels that already exist in the codebase

  ✅ DO INSTEAD:

  - Extend existing services and providers
  - Follow established architectural patterns
  - Integrate with existing state management
  - Build on top of current foundations

  ---
  4. Surface-Level Fixes

  ❌ DON'T:

  - Focus only on making buttons "work" (call functions)
  - Ignore proper error handling and validation
  - Skip security considerations
  - Create functionality that looks right but breaks easily

  ✅ DO INSTEAD:

  - Ensure changes work correctly within the app's architecture
  - Implement proper security and validation
  - Create maintainable, robust solutions
  - Consider edge cases and error scenarios

  ---
  5. Overconfidence in Quick Solutions

  ❌ DON'T:

  - Present incomplete implementations as finished solutions
  - Mark tasks as "completed" when they're only partially working
  - Hide complexity or limitations from stakeholders
  - Claim credit for functionality that already existed

  ✅ DO INSTEAD:

  - Acknowledge complexity and unknowns upfront
  - Identify what investigation is needed before coding
  - Be honest about limitations and potential issues
  - Give credit where it's due for existing functionality

  ---
  Core Principle

  Quality over speed. It's better to take time understanding the problem and building a proper solution than to quickly create         
  something that looks functional but is actually broken, insecure, or unmaintainable.

  Remember

  This is lazy engineering - prioritizing the appearance of functionality over actual, well-integrated solutions. The goal should      
  be sustainable, maintainable code that fits naturally into the existing system, not quick hacks that create technical debt.