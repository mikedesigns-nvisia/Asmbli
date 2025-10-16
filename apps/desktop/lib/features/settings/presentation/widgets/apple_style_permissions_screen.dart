import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_extensions.dart';
import '../../../../core/services/oauth_integration_service.dart';

/// Apple-style permissions screen with progressive disclosure
class AppleStylePermissionsScreen extends ConsumerStatefulWidget {
  final OAuthProvider provider;

  const AppleStylePermissionsScreen({
    super.key,
    required this.provider,
  });

  @override
  ConsumerState<AppleStylePermissionsScreen> createState() => _AppleStylePermissionsScreenState();
}

class _AppleStylePermissionsScreenState extends ConsumerState<AppleStylePermissionsScreen>
    with TickerProviderStateMixin {
  
  List<OAuthScope> _availableScopes = [];
  List<String> _grantedScopes = [];
  Map<String, bool> _expandedSections = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final oauthService = ref.read(oauthIntegrationServiceProvider);
    
    try {
      final availableScopes = oauthService.getAvailableScopes(widget.provider);
      final grantedScopes = await oauthService.getGrantedScopes(widget.provider);
      
      if (mounted) {
        setState(() {
          _availableScopes = availableScopes;
          _grantedScopes = grantedScopes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: _isLoading 
                  ? _buildLoadingState(colors)
                  : _buildContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.headerPadding,
        MediaQuery.of(context).padding.top + SpacingTokens.lg,
        SpacingTokens.headerPadding,
        SpacingTokens.lg,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: colors.primary,
                size: 18,
              ),
            ),
          ),
          
          SizedBox(width: SpacingTokens.lg),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.provider.displayName} Permissions',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose what this app can access',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading permissions...',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors colors) {
    // Group scopes by category
    final groupedScopes = <String, List<OAuthScope>>{};
    for (final scope in _availableScopes) {
      groupedScopes.putIfAbsent(scope.category, () => []).add(scope);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _buildPermissionsSummary(colors),
          
          SizedBox(height: SpacingTokens.xl),
          
          // Permission categories
          ...groupedScopes.entries.map((entry) => 
            _buildPermissionCategory(entry.key, entry.value, colors)
          ),
          
          SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  Widget _buildPermissionsSummary(ThemeColors colors) {
    final grantedCount = _grantedScopes.length;
    final totalCount = _availableScopes.length;
    final percentage = totalCount > 0 ? (grantedCount / totalCount) : 0.0;
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.xl),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_circle,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              
              SizedBox(width: SpacingTokens.lg),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$grantedCount of $totalCount permissions',
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap categories below to review',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 3,
                  backgroundColor: colors.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCategory(String category, List<OAuthScope> scopes, ThemeColors colors) {
    final isExpanded = _expandedSections[category] ?? false;
    final grantedInCategory = scopes.where((scope) => _grantedScopes.contains(scope.id)).length;
    
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            // Category header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedSections[category] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                child: Padding(
                  padding: EdgeInsets.all(SpacingTokens.lg),
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: _getCategoryColor(category),
                          size: 20,
                        ),
                      ),
                      
                      SizedBox(width: SpacingTokens.lg),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyles.bodyLarge.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '$grantedInCategory of ${scopes.length} granted',
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Expand/collapse icon
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Expandable content
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isExpanded ? null : 0,
              child: isExpanded ? Column(
                children: [
                  Divider(
                    color: colors.border.withValues(alpha: 0.3),
                    height: 1,
                    indent: SpacingTokens.lg,
                    endIndent: SpacingTokens.lg,
                  ),
                  ...scopes.map((scope) => _buildPermissionItem(scope, colors)),
                ],
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(OAuthScope scope, ThemeColors colors) {
    final isGranted = _grantedScopes.contains(scope.id);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permission toggle
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: isGranted,
              onChanged: scope.isRequired ? null : (value) {
                setState(() {
                  if (value) {
                    _grantedScopes.add(scope.id);
                  } else {
                    _grantedScopes.remove(scope.id);
                  }
                });
              },
              activeColor: colors.primary,
            ),
          ),
          
          SizedBox(width: SpacingTokens.md),
          
          // Permission info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      scope.displayName,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (scope.isRequired) ...[
                      SizedBox(width: SpacingTokens.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'REQUIRED',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (scope.riskLevel == OAuthRiskLevel.high) ...[
                      SizedBox(width: SpacingTokens.sm),
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  scope.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'user':
        return Colors.blue;
      case 'repository':
      case 'files':
        return Colors.green;
      case 'email':
      case 'chat':
        return Colors.orange;
      case 'calendar':
        return Colors.purple;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'user':
        return Icons.person;
      case 'repository':
        return Icons.code;
      case 'files':
        return Icons.folder;
      case 'email':
        return Icons.email;
      case 'chat':
        return Icons.chat;
      case 'calendar':
        return Icons.calendar_today;
      case 'channels':
        return Icons.tag;
      case 'general':
      default:
        return Icons.settings;
    }
  }
}