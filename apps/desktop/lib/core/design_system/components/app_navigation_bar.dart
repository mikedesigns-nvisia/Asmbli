import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';
import 'header_button.dart';
import 'asmbli_button.dart';
import '../../constants/routes.dart';
import '../../../providers/conversation_provider.dart';

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
 padding: const EdgeInsets.only(
 left: SpacingTokens.headerPadding,
 right: SpacingTokens.headerPadding,
 top: SpacingTokens.pageVertical,
 bottom: 0,  // No bottom padding to eliminate gap
 ),
 decoration: BoxDecoration(
 color: colors.headerBackground,
 border: Border(bottom: BorderSide(color: colors.headerBorder)),
 ),
 child: Container(
 height: 60, // Explicit height to maintain header size
 child: Row(
 mainAxisAlignment: MainAxisAlignment.start,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 // Brand Title
 GestureDetector(
 onTap: () => context.go(AppRoutes.home),
 child: Row(
 children: [
 // Brand Title
 Text(
 'Asmbli',
 style: TextStyles.brandTitle.copyWith(
 color: colors.primary,
 fontWeight: FontWeight.bold,
 fontSize: 24,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: SpacingTokens.xxl),
 
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
 text: 'Reasoning Flows',
 icon: Icons.account_tree,
 onPressed: () => context.go(AppRoutes.orchestration),
 isActive: currentRoute == AppRoutes.orchestration,
 ),
 const SizedBox(width: SpacingTokens.lg),
 
 HeaderButton(
 text: 'Settings',
 icon: Icons.settings,
 onPressed: () => context.go(AppRoutes.settings),
 isActive: currentRoute == AppRoutes.settings,
 ),
 const SizedBox(width: SpacingTokens.lg),
 
 // Temporary Reasoning Demo button (remove after demos)
 HeaderButton(
 text: 'Reasoning Demo',
 icon: Icons.psychology,
 onPressed: () => context.go(AppRoutes.reasoningDemo),
 isActive: currentRoute == AppRoutes.reasoningDemo,
 ),
 
 // Spacer to push New Chat button to the right
 const Spacer(),
 
 // New Chat button (only visible on Chat route)
 if (currentRoute == AppRoutes.chat)
   AsmblButton.primary(
     text: 'New Chat',
     icon: Icons.add,
     onPressed: () => _startNewChat(context, ref),
   ),
 ],
 ),
 ),
 );
 }
 
 Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
   try {
     // Create a new conversation
     final createConversation = ref.read(createConversationProvider);
     final conversation = await createConversation(title: 'New Chat');
     
     // Set as selected conversation
     ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
     
     // Refresh conversations list
     ref.invalidate(conversationsProvider);
     
     // Show success feedback
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: const Row(
             children: [
               Icon(Icons.chat_bubble, color: Colors.white, size: 16),
               SizedBox(width: 8),
               Text('New conversation started'),
             ],
           ),
           backgroundColor: ThemeColors(context).success,
           behavior: SnackBarBehavior.floating,
           duration: const Duration(seconds: 2),
         ),
       );
     }
   } catch (e) {
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Failed to create new chat: $e'),
           backgroundColor: ThemeColors(context).error,
         ),
       );
     }
   }
 }
}