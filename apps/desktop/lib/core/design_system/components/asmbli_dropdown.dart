import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

// Theme-aware dropdown component
class AsmblDropdown<T> extends StatelessWidget {
 final T value;
 final List<T> items;
 final ValueChanged<T?> onChanged;
 final String? hint;
 final Widget Function(T)? itemBuilder;
 final bool isExpanded;
 final String? Function(T)? validator;

 const AsmblDropdown({
 super.key,
 required this.value,
 required this.items,
 required this.onChanged,
 this.hint,
 this.itemBuilder,
 this.isExpanded = true,
 this.validator,
 });

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
 decoration: BoxDecoration(
 border: Border.all(color: colors.border),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 color: colors.surface.withOpacity( 0.8),
 ),
 child: DropdownButtonHideUnderline(
 child: DropdownButton<T>(
 value: value,
 isExpanded: isExpanded,
 hint: hint != null
 ? Text(
 hint!,
 style: TextStyle(
 color: colors.onSurfaceVariant,
 ),
 )
 : null,
 icon: Icon(
 Icons.keyboard_arrow_down,
 color: colors.onSurfaceVariant,
 size: 20,
 ),
 onChanged: onChanged,
 style: TextStyle(
 color: colors.onSurface,
 fontWeight: FontWeight.w500,
 ),
 dropdownColor: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 elevation: 8,
 menuMaxHeight: 300,
 items: items.map((item) {
 return DropdownMenuItem<T>(
 value: item,
 child: Container(
 padding: const EdgeInsets.symmetric(vertical: 8),
 child: itemBuilder != null
 ? itemBuilder!(item)
 : Text(
 item.toString(),
 style: TextStyle(
 color: colors.onSurface,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 );
 }).toList(),
 ),
 ),
 );
 }
}

// Simple string dropdown for common use cases
class AsmblStringDropdown extends StatelessWidget {
 final String value;
 final List<String> items;
 final ValueChanged<String?> onChanged;
 final String? hint;
 final bool isExpanded;

 const AsmblStringDropdown({
 super.key,
 required this.value,
 required this.items,
 required this.onChanged,
 this.hint,
 this.isExpanded = true,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblDropdown<String>(
 value: value,
 items: items,
 onChanged: onChanged,
 hint: hint,
 isExpanded: isExpanded,
 );
 }
}

// Enhanced dropdown with search functionality
class AsmblSearchableDropdown<T> extends StatefulWidget {
 final T value;
 final List<T> items;
 final ValueChanged<T?> onChanged;
 final String? hint;
 final Widget Function(T)? itemBuilder;
 final String Function(T) searchStringBuilder;
 final bool isExpanded;

 const AsmblSearchableDropdown({
 super.key,
 required this.value,
 required this.items,
 required this.onChanged,
 required this.searchStringBuilder,
 this.hint,
 this.itemBuilder,
 this.isExpanded = true,
 });

 @override
 State<AsmblSearchableDropdown<T>> createState() => _AsmblSearchableDropdownState<T>();
}

class _AsmblSearchableDropdownState<T> extends State<AsmblSearchableDropdown<T>> {
 String searchQuery = '';
 bool isOpen = false;
 final TextEditingController searchController = TextEditingController();

 List<T> get filteredItems {
 if (searchQuery.isEmpty) return widget.items;
 return widget.items
 .where((item) => widget.searchStringBuilder(item)
 .toLowerCase()
 .contains(searchQuery.toLowerCase()))
 .toList();
 }

 @override
 void dispose() {
 searchController.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Main dropdown button
 GestureDetector(
 onTap: () => setState(() => isOpen = !isOpen),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: BoxDecoration(
 border: Border.all(color: colors.border),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 color: colors.surface.withOpacity( 0.8),
 ),
 child: Row(
 children: [
 Expanded(
 child: Text(
 widget.itemBuilder != null
 ? widget.searchStringBuilder(widget.value)
 : widget.value.toString(),
 style: TextStyle(
 color: colors.onSurface,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 Icon(
 isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
 color: colors.onSurfaceVariant,
 size: 20,
 ),
 ],
 ),
 ),
 ),
 
 // Dropdown content
 if (isOpen)
 Container(
 margin: const EdgeInsets.only(top: 4),
 decoration: BoxDecoration(
 color: colors.surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 border: Border.all(color: colors.border),
 boxShadow: [
 BoxShadow(
 color: colors.onSurface.withOpacity( 0.1),
 blurRadius: 8,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // Search field
 Container(
 padding: const EdgeInsets.all(8),
 child: TextField(
 controller: searchController,
 decoration: InputDecoration(
 hintText: 'Search...',
 hintStyle: TextStyle(
 color: colors.onSurfaceVariant,
 ),
 prefixIcon: Icon(
 Icons.search,
 color: colors.onSurfaceVariant,
 size: 16,
 ),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 borderSide: BorderSide(color: colors.border),
 ),
 contentPadding: const EdgeInsets.symmetric(
 horizontal: 12,
 vertical: 8,
 ),
 ),
 style: TextStyle(
 color: colors.onSurface,
 ),
 onChanged: (value) => setState(() => searchQuery = value),
 ),
 ),
 
 // Items list
 Container(
 constraints: const BoxConstraints(maxHeight: 200),
 child: ListView.builder(
 shrinkWrap: true,
 itemCount: filteredItems.length,
 itemBuilder: (context, index) {
 final item = filteredItems[index];
 final isSelected = item == widget.value;
 
 return Material(
 color: Colors.transparent,
 child: InkWell(
 onTap: () {
 widget.onChanged(item);
 setState(() => isOpen = false);
 searchController.clear();
 searchQuery = '';
 },
 child: Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 16,
 vertical: 12,
 ),
 decoration: BoxDecoration(
 color: isSelected
 ? colors.primary.withOpacity( 0.1)
 : Colors.transparent,
 ),
 child: Row(
 children: [
 Expanded(
 child: widget.itemBuilder != null
 ? widget.itemBuilder!(item)
 : Text(
 widget.searchStringBuilder(item),
 style: TextStyle(
 color: isSelected
 ? colors.primary
 : colors.onSurface,
 fontWeight: isSelected
 ? FontWeight.w600
 : FontWeight.w500,
 ),
 ),
 ),
 if (isSelected)
 Icon(
 Icons.check,
 color: colors.primary,
 size: 16,
 ),
 ],
 ),
 ),
 ),
 );
 },
 ),
 ),
 ],
 ),
 ),
 ],
 );
 }
}