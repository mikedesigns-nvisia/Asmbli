import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';

class ContextHubWidget extends ConsumerStatefulWidget {
  const ContextHubWidget({super.key});

  @override
  ConsumerState<ContextHubWidget> createState() => _ContextHubWidgetState();
}

class _ContextHubWidgetState extends ConsumerState<ContextHubWidget> {
  ContextHubCategory _selectedCategory = ContextHubCategory.all;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCardEnhanced.outlined(
      isInteractive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Knowledge Library',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Placeholder content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books,
                  size: 48,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Context Library Coming Soon',
                  style: GoogleFonts.fustat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'A comprehensive knowledge library with templates and examples will be available in a future update.',
                  style: GoogleFonts.fustat(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}