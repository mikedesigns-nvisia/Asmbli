import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';
import 'header_button.dart';
import 'asmbli_button.dart';
import 'asmbli_button_enhanced.dart';
import 'quick_actions_dropdown.dart';
import '../../constants/routes.dart';

// Centralized navigation bar for all screens
class AppNavigationBar extends ConsumerWidget {
  final String currentRoute;
  
  const AppNavigationBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.headerPadding,
        vertical: SpacingTokens.pageVertical,
      ),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(bottom: BorderSide(color: colors.headerBorder)),
      ),
      child: Row(
        children: [
          // Brand Logo and Title
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Row(
              children: [
                // Logo Mark with subtle glow
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: colors.accent.withOpacity(0.08),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image fails to load
                      return Icon(
                        Icons.hub,
                        size: 24,
                        color: colors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                // Brand Title
                Text(
                  'Asmbli',
                  style: TextStyles.brandTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          
          // Navigation Buttons
          HeaderButton(
            text: 'My Agents',
            icon: Icons.smart_toy,
            onPressed: () => context.go(AppRoutes.agents),
            isActive: currentRoute == AppRoutes.agents,
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          HeaderButton(
            text: 'Context',
            icon: Icons.library_books,
            onPressed: () => context.go(AppRoutes.context),
            isActive: currentRoute == AppRoutes.context,
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          HeaderButton(
            text: 'Settings',
            icon: Icons.settings,
            onPressed: () => context.go(AppRoutes.settings),
            isActive: currentRoute == AppRoutes.settings,
          ),
          const SizedBox(width: SpacingTokens.xxl),
          
          // Quick Actions Dropdown (will be used for sign-in flow later)
          QuickActionsDropdown(),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // New Chat Button
          AsmblButtonEnhanced.accent(
            text: 'New Chat',
            icon: Icons.add,
            onPressed: () => context.go(AppRoutes.chat),
            size: AsmblButtonSize.medium,
          ),
        ],
      ),
    );
  }
}