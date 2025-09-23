import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../providers/context_provider.dart';
import '../widgets/context_hub_widget.dart';
import '../widgets/context_creation_flow.dart';
import '../../data/models/context_document.dart';

class ContextLibraryScreen extends ConsumerStatefulWidget {
  const ContextLibraryScreen({super.key});

  @override
  ConsumerState<ContextLibraryScreen> createState() => _ContextLibraryScreenState();
}

class _ContextLibraryScreenState extends ConsumerState<ContextLibraryScreen> {
  String searchQuery = '';
  String _selectedFilter = 'All';
  bool _showCreateFlow = false;

  // Filter categories with colors and icons
  final Map<String, Map<String, dynamic>> filterCategories = {
    'All': {'color': Colors.grey, 'icon': Icons.apps},
    'System Prompts': {'color': Colors.blue, 'icon': Icons.psychology},
    'Context Docs': {'color': Colors.green, 'icon': Icons.description},
    'Code Samples': {'color': Colors.purple, 'icon': Icons.code},
    'Documentation': {'color': Colors.teal, 'icon': Icons.menu_book},
    'Guidelines': {'color': Colors.indigo, 'icon': Icons.rule},
    'Examples': {'color': Colors.cyan, 'icon': Icons.lightbulb},
  };


  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final contextAsync = ref.watch(contextDocumentsWithVectorProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Navigation Bar
              const AppNavigationBar(currentRoute: AppRoutes.context),
              
              // Page Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.headerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeaderButton(
                          text: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                        const Spacer(),
                        Text(
                          'Context Library',
                          style: TextStyles.pageTitle.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        HeaderButton(
                          text: 'Add Context',
                          icon: Icons.add,
                          onPressed: _showCreateContextFlow,
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    Text(
                      'Manage your context documents, agent templates, and knowledge samples',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search context library...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          filled: true,
                          fillColor: colors.surface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SpacingTokens.lg),

              // Filter Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterCategories.entries.map((entry) {
                      final filterName = entry.key;
                      final filterData = entry.value;
                      final isSelected = _selectedFilter == filterName;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: SpacingTokens.sm),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filterData['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : filterData['color'],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                filterName,
                                style: TextStyles.bodySmall.copyWith(
                                  color: isSelected ? Colors.white : colors.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filterName);
                          },
                          selectedColor: filterData['color'],
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: isSelected ? filterData['color'] : colors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          elevation: isSelected ? 2 : 0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: SpacingTokens.lg),

              // Main Content - Filtered View
              Expanded(
                child: _buildFilteredContent(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredContent(ThemeColors colors) {
    switch (_selectedFilter) {
      case 'Context Docs':
      case 'System Prompts':
      case 'Documentation':
      case 'Guidelines':
      case 'Examples':
      case 'Code Samples':
        return _buildContextSamplesSection(colors);
      case 'All':
      default:
        return _buildAllContentSection(colors);
    }
  }

  Widget _buildAllContentSection(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Samples Section
          Text(
            'Context Samples & Knowledge',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Ready-to-use context examples and knowledge templates',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          const ContextHubWidget(),
        ],
      ),
    );
  }


  Widget _buildContextSamplesSection(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context Samples & Knowledge',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Ready-to-use context examples filtered by category',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          const Expanded(
            child: ContextHubWidget(),
          ),
        ],
      ),
    );
  }

  void _showCreateContextFlow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ContextCreationFlow(
          onSave: (contextDocument) async {
            Navigator.of(context).pop();
            try {
              final notifier = ref.read(contextDocumentNotifierProvider.notifier);
              await notifier.createDocument(
                title: contextDocument.title,
                content: contextDocument.content,
                type: contextDocument.type,
                tags: contextDocument.tags,
                metadata: contextDocument.metadata,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Context document "${contextDocument.title}" created successfully'),
                    backgroundColor: ThemeColors(context).success,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create context document: $e'),
                    backgroundColor: ThemeColors(context).error,
                  ),
                );
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

}