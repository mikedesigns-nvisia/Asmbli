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
              
              // Page Header - compact shadcn style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Context Library',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your context documents, agent templates, and knowledge samples.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildGhostButton(
                      colors,
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                    const SizedBox(width: 8),
                    _buildPrimaryButton(
                      colors,
                      icon: Icons.add,
                      label: 'Add Context',
                      onPressed: _showCreateContextFlow,
                    ),
                  ],
                ),
              ),

              // Search Bar - compact shadcn style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search context library...',
                    hintStyle: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, size: 16, color: colors.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: colors.primary),
                    ),
                    filled: true,
                    fillColor: colors.surface.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips - compact tabs style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: filterCategories.entries.map((entry) {
                        final filterName = entry.key;
                        final filterData = entry.value;
                        final isSelected = _selectedFilter == filterName;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filterName),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: colors.border.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  filterData['icon'],
                                  size: 14,
                                  color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  filterName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                    color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context Samples Section - compact spacing
          Text(
            'Context Samples & Knowledge',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready-to-use context examples and knowledge templates',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const ContextHubWidget(),
        ],
      ),
    );
  }


  Widget _buildContextSamplesSection(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context Samples & Knowledge',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ready-to-use context examples filtered by category',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: ContextHubWidget(),
          ),
        ],
      ),
    );
  }

  // Compact shadcn-style button helpers
  Widget _buildGhostButton(ThemeColors colors, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeColors colors, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
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