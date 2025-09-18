import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';

class ContextFilterBar extends StatelessWidget {
 final ContextType? selectedType;
 final String searchQuery;
 final Function(ContextType?) onTypeChanged;
 final Function(String) onSearchChanged;

 const ContextFilterBar({
 super.key,
 required this.selectedType,
 required this.searchQuery,
 required this.onTypeChanged,
 required this.onSearchChanged,
 });

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return Row(
 children: [
 // Search Field
 Expanded(
 flex: 2,
 child: TextField(
 decoration: InputDecoration(
 hintText: 'Search documents...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant.withOpacity( 0.6),
 ),
 prefixIcon: Icon(
 Icons.search,
 color: colors.onSurfaceVariant,
 ),
 filled: true,
 fillColor: colors.surfaceVariant.withOpacity( 0.3),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.border),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.border),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.primary),
 ),
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.lg,
 vertical: SpacingTokens.md,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
 onChanged: onSearchChanged,
 ),
 ),

 const SizedBox(width: SpacingTokens.lg),

 // Type Filter Dropdown
 Expanded(
 child: DropdownButtonFormField<ContextType?>(
 value: selectedType,
 decoration: InputDecoration(
 labelText: 'Filter by type',
 labelStyle: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 filled: true,
 fillColor: colors.surfaceVariant.withOpacity( 0.3),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.border),
 ),
 enabledBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.border),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.primary),
 ),
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.lg,
 vertical: SpacingTokens.md,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
 dropdownColor: colors.surface,
 items: [
 DropdownMenuItem<ContextType?>(
 value: null,
 child: Text(
 'All Types',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 ),
 ),
 ),
 ...ContextType.values.map((type) {
 return DropdownMenuItem<ContextType?>(
 value: type,
 child: Text(
 type.displayName,
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 ),
 ),
 );
 }),
 ],
 onChanged: onTypeChanged,
 ),
 ),

 const SizedBox(width: SpacingTokens.lg),

 // Clear Filters Button (if any filters are active)
 if (selectedType != null || searchQuery.isNotEmpty)
 AsmblButton.secondary(
 text: 'Clear',
 icon: Icons.clear,
 onPressed: () {
 onTypeChanged(null);
 onSearchChanged('');
 },
 ),
 ],
 );
 }
}