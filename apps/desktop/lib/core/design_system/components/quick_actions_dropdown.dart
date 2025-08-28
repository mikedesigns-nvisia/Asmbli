import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';
import 'asmbli_card_enhanced.dart';
import '../../../features/chat/presentation/widgets/add_context_modal.dart';
import '../../constants/routes.dart';

// Quick Actions Dropdown Component
class QuickActionsDropdown extends ConsumerStatefulWidget {
 const QuickActionsDropdown({super.key});

 @override
 ConsumerState<QuickActionsDropdown> createState() => _QuickActionsDropdownState();
}

class _QuickActionsDropdownState extends ConsumerState<QuickActionsDropdown> {
 bool _isOpen = false;
 late OverlayEntry _overlayEntry;
 final LayerLink _layerLink = LayerLink();
 
 @override
 void dispose() {
 if (_isOpen) {
 _overlayEntry.remove();
 }
 super.dispose();
 }

 void _toggleDropdown() {
 if (_isOpen) {
 _closeDropdown();
 } else {
 _openDropdown();
 }
 }

 void _openDropdown() {
 _overlayEntry = _createOverlayEntry();
 Overlay.of(context).insert(_overlayEntry);
 setState(() {
 _isOpen = true;
 });
 }

 void _closeDropdown() {
 _overlayEntry.remove();
 setState(() {
 _isOpen = false;
 });
 }

 OverlayEntry _createOverlayEntry() {
 final colors = ThemeColors(context);
 
 return OverlayEntry(
 builder: (context) => GestureDetector(
 onTap: _closeDropdown,
 child: Container(
 color: Colors.transparent,
 child: Stack(
 children: [
 Positioned(
 width: 280,
 child: CompositedTransformFollower(
 link: _layerLink,
 showWhenUnlinked: false,
 offset: Offset(-260, 40),
 child: Material(
 elevation: 8,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
 shadowColor: colors.onSurface.withValues(alpha: 0.15),
 color: colors.surface,
 child: Container(
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
 border: Border.all(
 color: colors.border.withValues(alpha: 0.8),
 width: 1,
 ),
 ),
 padding: EdgeInsets.all(SpacingTokens.cardPadding),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 // Header
 Container(
 padding: EdgeInsets.only(
 bottom: SpacingTokens.componentSpacing,
 ),
 decoration: BoxDecoration(
 border: Border(
 bottom: BorderSide(
 color: colors.border.withValues(alpha: 0.3),
 width: 1,
 ),
 ),
 ),
 child: Row(
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 Icons.dashboard,
 size: 16,
 color: colors.primary,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Text(
 'Quick Actions',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 ],
 ),
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Actions
 _buildDropdownAction(
 icon: Icons.add,
 title: 'New Chat',
 description: 'Start a conversation',
 onTap: () {
 _closeDropdown();
 context.go(AppRoutes.chat);
 },
 color: colors.accent,
 ),
 
 _buildDropdownAction(
 icon: Icons.build,
 title: 'Create Agent',
 description: 'Build custom AI agent',
 onTap: () {
 _closeDropdown();
 context.go(AppRoutes.agentWizard);
 },
 color: colors.primary,
 ),
 
 _buildDropdownAction(
 icon: Icons.library_books,
 title: 'Browse Templates',
 description: 'Explore agent templates',
 onTap: () {
 _closeDropdown();
 context.go(AppRoutes.context);
 },
 color: colors.info,
 ),
 
 _buildDropdownAction(
 icon: Icons.school,
 title: 'Manage Knowledge',
 description: 'Browse context library',
 onTap: () {
 _closeDropdown();
 context.go(AppRoutes.context);
 },
 color: colors.warning,
 ),
 
 _buildDropdownAction(
 icon: Icons.library_add,
 title: 'Add Context',
 description: 'Upload documents',
 onTap: () {
 _closeDropdown();
 _showAddContextModal(context);
 },
 color: colors.success,
 ),
 
 Container(
 height: 1,
 margin: EdgeInsets.symmetric(
 vertical: SpacingTokens.componentSpacing,
 ),
 decoration: BoxDecoration(
 color: colors.border.withValues(alpha: 0.3),
 ),
 ),
 
 _buildDropdownAction(
 icon: Icons.settings,
 title: 'Settings',
 description: 'App configuration',
 onTap: () {
 _closeDropdown();
 context.go(AppRoutes.settings);
 },
 color: colors.onSurfaceVariant,
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildDropdownAction({
 required IconData icon,
 required String title,
 required String description,
 required VoidCallback onTap,
 required Color color,
 }) {
 final colors = ThemeColors(context);
 
 return Padding(
 padding: EdgeInsets.symmetric(vertical: SpacingTokens.xs_precise),
 child: Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: onTap,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 hoverColor: color.withValues(alpha: 0.05),
 splashColor: color.withValues(alpha: 0.15),
 child: Container(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 border: Border.all(
 color: Colors.transparent,
 width: 1,
 ),
 ),
 child: Row(
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.iconSpacing),
 decoration: BoxDecoration(
 color: color.withValues(alpha: 0.12),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 icon,
 size: 16,
 color: color,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.xs_precise),
 Text(
 description,
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs_precise),
 child: Icon(
 Icons.arrow_forward_ios,
 size: 12,
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 );
 }

 void _showAddContextModal(BuildContext context) {
 showDialog(
 context: context,
 builder: (context) => const AddContextModal(),
 );
 }

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return CompositedTransformTarget(
 link: _layerLink,
 child: Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: _toggleDropdown,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 hoverColor: colors.primary.withValues(alpha: 0.04),
 splashColor: colors.primary.withValues(alpha: 0.12),
 child: AnimatedContainer(
 duration: Duration(milliseconds: 200),
 curve: Curves.easeInOut,
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.iconSpacing,
 ),
 decoration: BoxDecoration(
 border: Border.all(
 color: _isOpen 
 ? colors.primary
 : colors.border,
 width: _isOpen ? 1.5 : 1,
 ),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 color: _isOpen 
 ? colors.primary.withValues(alpha: 0.05)
 : colors.surface.withValues(alpha: 0.8),
 boxShadow: _isOpen 
 ? [
 BoxShadow(
 color: colors.primary.withValues(alpha: 0.1),
 blurRadius: 4,
 offset: Offset(0, 2),
 ),
 ]
 : null,
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 AnimatedContainer(
 duration: Duration(milliseconds: 200),
 curve: Curves.easeInOut,
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: (_isOpen ? colors.primary : colors.onSurfaceVariant).withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 Icons.dashboard,
 size: 16,
 color: _isOpen ? colors.primary : colors.onSurfaceVariant,
 ),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 Text(
 'Quick Actions',
 style: TextStyles.bodyMedium.copyWith(
 color: _isOpen ? colors.primary : colors.onSurface,
 fontWeight: _isOpen ? FontWeight.w600 : FontWeight.w500,
 ),
 ),
 SizedBox(width: SpacingTokens.iconSpacing),
 AnimatedRotation(
 turns: _isOpen ? 0.5 : 0,
 duration: Duration(milliseconds: 200),
 curve: Curves.easeInOut,
 child: Icon(
 Icons.expand_more,
 size: 16,
 color: _isOpen ? colors.primary : colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 );
 }
}