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
          // Brand Title
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Text(
              'Asmbli',
              style: TextStyles.brandTitle.copyWith(
                color: colors.onSurface,
              ),
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