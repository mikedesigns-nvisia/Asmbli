import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import 'header_button.dart';
import 'asmbli_button.dart';
import '../../services/theme_service.dart';

// Centralized navigation bar for all screens
class AppNavigationBar extends ConsumerWidget {
  final String currentRoute;
  
  const AppNavigationBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeService = ref.read(themeServiceProvider.notifier);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.headerPadding,
        vertical: SpacingTokens.pageVertical,
      ),
      decoration: const BoxDecoration(
        color: SemanticColors.headerBackground,
        border: Border(bottom: BorderSide(color: SemanticColors.headerBorder)),
      ),
      child: Row(
        children: [
          // Brand Title
          GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
              'Asmbli',
              style: TextStyles.brandTitle.copyWith(
                color: SemanticColors.onSurface,
              ),
            ),
          ),
          const Spacer(),
          
          // Navigation Buttons
          HeaderButton(
            text: 'Templates',
            icon: Icons.library_books,
            onPressed: () => context.go('/templates'),
            isActive: currentRoute == '/templates',
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          HeaderButton(
            text: 'My Agents',
            icon: Icons.smart_toy,
            onPressed: () => context.go('/agents'),
            isActive: currentRoute == '/agents',
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          HeaderButton(
            text: 'Library',
            icon: Icons.folder,
            onPressed: () => context.go('/dashboard'),
            isActive: currentRoute == '/dashboard',
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          HeaderButton(
            text: 'Settings',
            icon: Icons.settings,
            onPressed: () => context.go('/settings'),
            isActive: currentRoute == '/settings',
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          // Theme toggle button
          GestureDetector(
            onTap: () {
              themeService.toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: SemanticColors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    themeService.getThemeIcon(),
                    size: 16,
                    color: SemanticColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    themeService.getThemeName(),
                    style: TextStyles.caption.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.xxl),
          
          // New Chat Button
          AsmblButton.primary(
            text: 'New Chat',
            icon: Icons.add,
            onPressed: () => context.go('/chat'),
          ),
        ],
      ),
    );
  }
}