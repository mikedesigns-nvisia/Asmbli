import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/api_config_service.dart';

class ApiDropdown extends ConsumerStatefulWidget {
  const ApiDropdown({super.key});

  @override
  ConsumerState<ApiDropdown> createState() => _ApiDropdownState();
}

class _ApiDropdownState extends ConsumerState<ApiDropdown> {
  String? _selectedApiId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the unified API config service instead of MCP settings
    final allApiConfigs = ref.watch(apiConfigsProvider);
    final defaultApiConfig = ref.watch(defaultApiConfigProvider);
    
    // Set selected API ID if not set or if current selection is invalid
    if (allApiConfigs.isEmpty) {
      _selectedApiId = '__loading__';
    } else if (_selectedApiId == null || !allApiConfigs.containsKey(_selectedApiId)) {
      _selectedApiId = defaultApiConfig?.id;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surface.withOpacity(0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedApiId,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          items: [
            // Show loading or empty state if no configs
            if (allApiConfigs.isEmpty) 
              DropdownMenuItem<String>(
                value: '__loading__',
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading API configs...',
                        style: TextStyle(
                          
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Existing API keys
            ...allApiConfigs.entries.map((entry) {
              final apiConfig = entry.value;
              return DropdownMenuItem<String>(
                value: apiConfig.id,
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: apiConfig.isConfigured 
                            ? ThemeColors(context).success 
                            : theme.colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          apiConfig.name,
                          style: TextStyle(
                            
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (apiConfig.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: ThemeColors(context).primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: ThemeColors(context).primary,
                            ),
                          ),
                        ),
                      if (!apiConfig.isConfigured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: ThemeColors(context).error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'NO KEY',
                            style: TextStyle(
                              
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: ThemeColors(context).error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            
            // Divider
            if (allApiConfigs.isNotEmpty)
              const DropdownMenuItem<String>(
                enabled: false,
                value: '__divider__',
                child: Divider(height: 1),
              ),
            
            // Add new API key option
            DropdownMenuItem<String>(
              value: '__add_new__',
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: ThemeColors(context).primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New API Key',
                      style: TextStyle(
                        
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ThemeColors(context).primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Settings option
            DropdownMenuItem<String>(
              value: '__settings__',
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'API Settings',
                      style: TextStyle(
                        
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) async {
            if (value == '__add_new__') {
              _showAddApiKeyDialog();
            } else if (value == '__settings__') {
              context.go(AppRoutes.settings);
            } else if (value != '__divider__' && value != '__loading__') {
              setState(() {
                _selectedApiId = value;
              });
              _showApiSwitchedSnackbar(value!);
            }
          },
        ),
      ),
    );
  }

  void _showAddApiKeyDialog() {
    // Navigate to settings page to manage API keys
    context.go(AppRoutes.settings);
  }

  void _showApiSwitchedSnackbar(String apiId) {
    final allApiConfigs = ref.read(apiConfigsProvider);
    final apiConfig = allApiConfigs[apiId];
    if (apiConfig != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Switched to ${apiConfig.name}',
                style: GoogleFonts.fustat(),
              ),
            ],
          ),
          backgroundColor: ThemeColors(context).success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}