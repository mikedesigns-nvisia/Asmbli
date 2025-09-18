import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/oauth_extensions.dart';

/// Dialog for managing OAuth scopes for a specific provider
class OAuthScopeManagementDialog extends ConsumerStatefulWidget {
  final OAuthProvider provider;
  final List<String> currentScopes;
  final VoidCallback? onScopesUpdated;

  const OAuthScopeManagementDialog({
    super.key,
    required this.provider,
    required this.currentScopes,
    this.onScopesUpdated,
  });

  @override
  ConsumerState<OAuthScopeManagementDialog> createState() => _OAuthScopeManagementDialogState();
}

class _OAuthScopeManagementDialogState extends ConsumerState<OAuthScopeManagementDialog> {
  late Set<String> _selectedScopes;
  List<OAuthScope> _availableScopes = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  String _searchQuery = '';
  OAuthScopeFilter _currentFilter = OAuthScopeFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedScopes = Set.from(widget.currentScopes);
    _loadAvailableScopes();
  }

  void _loadAvailableScopes() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      _availableScopes = oauthService.getAvailableScopes(widget.provider);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load available scopes: $e';
      });
    }
  }

  List<OAuthScope> get _filteredScopes {
    var scopes = _availableScopes.where((scope) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!scope.displayName.toLowerCase().contains(query) &&
            !scope.description.toLowerCase().contains(query) &&
            !scope.category.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      switch (_currentFilter) {
        case OAuthScopeFilter.granted:
          return _selectedScopes.contains(scope.id);
        case OAuthScopeFilter.required:
          return scope.isRequired;
        case OAuthScopeFilter.optional:
          return !scope.isRequired;
        case OAuthScopeFilter.highRisk:
          return scope.riskLevel == OAuthRiskLevel.high;
        case OAuthScopeFilter.all:
        default:
          return true;
      }
    }).toList();

    // Group by category and sort
    scopes.sort((a, b) {
      // Required scopes first
      if (a.isRequired != b.isRequired) {
        return a.isRequired ? -1 : 1;
      }
      
      // Then by category
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      
      // Finally by name
      return a.displayName.compareTo(b.displayName);
    });

    return scopes;
  }

  Map<String, List<OAuthScope>> get _scopesByCategory {
    final map = <String, List<OAuthScope>>{};
    for (final scope in _filteredScopes) {
      map.putIfAbsent(scope.category, () => []).add(scope);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
      child: Container(
        width: 600,
        height: 700,
        child: Column(
          children: [
            _buildHeader(colors),
            if (_isLoading) 
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(child: _buildError(colors))
            else ...[
              _buildSearchAndFilters(colors),
              Expanded(child: _buildScopesList(colors)),
              _buildFooter(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Provider icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getProviderColor().withOpacity( 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getProviderIcon(),
              color: _getProviderColor(),
              size: 20,
            ),
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage ${widget.provider.displayName} Permissions',
                  style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Control what data and actions this integration can access',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: Icon(Icons.close, color: colors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search permissions...',
              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                borderSide: BorderSide(color: colors.border),
              ),
              filled: true,
              fillColor: colors.inputBackground,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          // Filter chips and summary
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: OAuthScopeFilter.values.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: SpacingTokens.xs),
                        child: FilterChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _currentFilter = filter);
                          },
                          backgroundColor: colors.surface,
                          selectedColor: colors.primary.withOpacity( 0.2),
                          labelStyle: TextStyles.caption.copyWith(
                            color: isSelected ? colors.primary : colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Summary
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                ),
                child: Text(
                  '${_selectedScopes.length} selected',
                  style: TextStyles.caption.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopesList(ThemeColors colors) {
    if (_filteredScopes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colors.onSurfaceVariant.withOpacity( 0.5),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'No permissions found',
              style: TextStyles.sectionTitle.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'No permissions match the current filter',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      children: _scopesByCategory.entries.map((entry) {
        return _buildScopeCategory(entry.key, entry.value, colors);
      }).toList(),
    );
  }

  Widget _buildScopeCategory(String category, List<OAuthScope> scopes, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
          child: Row(
            children: [
              Text(
                category,
                style: TextStyles.labelLarge.copyWith(color: colors.onSurface),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                ),
                child: Text(
                  '${scopes.length}',
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        
        // Scopes in category
        ...scopes.map((scope) => _buildScopeItem(scope, colors)),
        
        const SizedBox(height: SpacingTokens.md),
      ],
    );
  }

  Widget _buildScopeItem(OAuthScope scope, ThemeColors colors) {
    final isSelected = _selectedScopes.contains(scope.id);
    final canToggle = !scope.isRequired;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
              ? colors.primary.withOpacity( 0.3)
              : colors.border.withOpacity( 0.3),
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        color: isSelected 
            ? colors.primary.withOpacity( 0.05)
            : colors.surface,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: canToggle ? (value) {
          setState(() {
            if (value == true) {
              _selectedScopes.add(scope.id);
            } else {
              _selectedScopes.remove(scope.id);
            }
          });
        } : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                scope.displayName,
                style: TextStyles.bodyMedium.copyWith(
                  color: canToggle ? colors.onSurface : colors.onSurfaceVariant,
                  fontWeight: scope.isRequired ? TypographyTokens.medium : null,
                ),
              ),
            ),
            
            // Risk level indicator
            _buildRiskIndicator(scope.riskLevel, colors),
            
            // Required badge
            if (scope.isRequired) ...[
              const SizedBox(width: SpacingTokens.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.warning.withOpacity( 0.2),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
                ),
                child: Text(
                  'Required',
                  style: TextStyles.caption.copyWith(color: colors.warning),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: SpacingTokens.xs),
          child: Text(
            scope.description,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: colors.primary,
        checkColor: colors.onPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.xs,
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(OAuthRiskLevel riskLevel, ThemeColors colors) {
    Color color;
    IconData icon;
    String tooltip;
    
    switch (riskLevel) {
      case OAuthRiskLevel.low:
        color = colors.success;
        icon = Icons.check_circle;
        tooltip = 'Low risk - Safe to grant';
        break;
      case OAuthRiskLevel.medium:
        color = colors.warning;
        icon = Icons.warning;
        tooltip = 'Medium risk - Review carefully';
        break;
      case OAuthRiskLevel.high:
        color = colors.error;
        icon = Icons.error;
        tooltip = 'High risk - Grants significant access';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildError(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colors.error.withOpacity( 0.5),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Failed to Load Permissions',
            style: TextStyles.sectionTitle.copyWith(color: colors.error),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
            child: Text(
              _error!,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          AsmblButton.secondary(
            text: 'Retry',
            icon: Icons.refresh,
            onPressed: _loadAvailableScopes,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeColors colors) {
    final hasChanges = !_selectedScopes.toSet().difference(widget.currentScopes.toSet()).isEmpty ||
                      !widget.currentScopes.toSet().difference(_selectedScopes).isEmpty;
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Risk summary
          Expanded(
            child: _buildRiskSummary(colors),
          ),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Action buttons
          Row(
            children: [
              AsmblButton.secondary(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.primary(
                text: _isUpdating ? 'Updating...' : 'Update Permissions',
                isLoading: _isUpdating,
                onPressed: hasChanges ? _updateScopes : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummary(ThemeColors colors) {
    final selectedScopeObjects = _availableScopes
        .where((scope) => _selectedScopes.contains(scope.id))
        .toList();
    
    final highRiskCount = selectedScopeObjects
        .where((scope) => scope.riskLevel == OAuthRiskLevel.high)
        .length;
    
    if (highRiskCount > 0) {
      return Row(
        children: [
          Icon(Icons.warning, color: colors.warning, size: 16),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            '$highRiskCount high-risk permission${highRiskCount != 1 ? 's' : ''} selected',
            style: TextStyles.bodySmall.copyWith(color: colors.warning),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Icon(Icons.check_circle, color: colors.success, size: 16),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Safe permission selection',
          style: TextStyles.bodySmall.copyWith(color: colors.success),
        ),
      ],
    );
  }

  // Helper methods
  Color _getProviderColor() {
    switch (widget.provider) {
      case OAuthProvider.github:
        return const Color(BrandColors.github);
      case OAuthProvider.slack:
        return const Color(0xFF4A154B);
      case OAuthProvider.linear:
        return const Color(0xFF5E6AD2);
      case OAuthProvider.microsoft:
        return const Color(BrandColors.microsoft);
      default:
        return const Color(BrandColors.defaultBrand);
    }
  }

  IconData _getProviderIcon() {
    switch (widget.provider) {
      case OAuthProvider.github:
        return Icons.code;
      case OAuthProvider.slack:
        return Icons.chat;
      case OAuthProvider.linear:
        return Icons.linear_scale;
      case OAuthProvider.microsoft:
        return Icons.business;
      default:
        return Icons.integration_instructions;
    }
  }

  String _getFilterLabel(OAuthScopeFilter filter) {
    switch (filter) {
      case OAuthScopeFilter.all:
        return 'All (${_availableScopes.length})';
      case OAuthScopeFilter.granted:
        return 'Selected (${_selectedScopes.length})';
      case OAuthScopeFilter.required:
        final count = _availableScopes.where((s) => s.isRequired).length;
        return 'Required ($count)';
      case OAuthScopeFilter.optional:
        final count = _availableScopes.where((s) => !s.isRequired).length;
        return 'Optional ($count)';
      case OAuthScopeFilter.highRisk:
        final count = _availableScopes.where((s) => s.riskLevel == OAuthRiskLevel.high).length;
        return 'High Risk ($count)';
    }
  }

  Future<void> _updateScopes() async {
    setState(() => _isUpdating = true);
    
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final success = await oauthService.updateScopes(
        widget.provider,
        _selectedScopes.toList(),
      );
      
      if (success) {
        widget.onScopesUpdated?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to update scopes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permissions: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}

// Supporting enums
enum OAuthScopeFilter {
  all,
  granted,
  required,
  optional,
  highRisk,
}