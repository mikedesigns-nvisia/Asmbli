import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';
import 'header_button.dart';
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
 child: Row(
 children: [
 // Simple brand icon
 Icon(
 Icons.hub,
 size: 24,
 color: colors.primary,
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
 text: 'Chat',
 icon: Icons.chat_bubble_outline,
 onPressed: () => context.go(AppRoutes.chat),
 isActive: currentRoute == AppRoutes.chat,
 ),
 const SizedBox(width: SpacingTokens.lg),

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
 text: 'Tools',
 icon: Icons.extension,
 onPressed: () => context.go(AppRoutes.integrationHub),
 isActive: currentRoute == AppRoutes.integrationHub,
 ),
 const SizedBox(width: SpacingTokens.lg),
 
 HeaderButton(
 text: 'Settings',
 icon: Icons.settings,
 onPressed: () => context.go(AppRoutes.settings),
 isActive: currentRoute == AppRoutes.settings,
 ),
 ],
 ),
 );
 }
}