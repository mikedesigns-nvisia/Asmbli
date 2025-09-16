import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../../../../core/services/mcp_catalog_service.dart';

class MCPServerSetupDialog extends ConsumerStatefulWidget {
  final MCPCatalogEntry catalogEntry;
  final String? agentId; // Optional: if configuring for specific agent

  const MCPServerSetupDialog({
    super.key,
    required this.catalogEntry,
    this.agentId,
  });

  @override
  ConsumerState<MCPServerSetupDialog> createState() => _MCPServerSetupDialogState();
}

class _MCPServerSetupDialogState extends ConsumerState<MCPServerSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _authControllers = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each auth requirement
    for (final authReq in widget.catalogEntry.requiredAuth) {
      final authName = authReq['name'] as String? ?? authReq['displayName'] as String? ?? 'auth_${_authControllers.length}';
      _authControllers[authName] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _authControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: AsmblCard(
          child: Container(
            padding: EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                SizedBox(height: SpacingTokens.lg),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildServerInfo(colors),
                          if (widget.catalogEntry.requiredAuth.isNotEmpty) ...[
                            SizedBox(height: SpacingTokens.lg),
                            _buildAuthFields(colors),
                          ],
                          if (widget.catalogEntry.setupInstructions != null) ...[
                            SizedBox(height: SpacingTokens.lg),
                            _buildSetupInstructions(colors),
                          ],
                          if (_errorMessage != null) ...[
                            SizedBox(height: SpacingTokens.md),
                            _buildErrorMessage(colors),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SpacingTokens.lg),
                _buildActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Icon(
            _getServerIcon(),
            size: 24,
            color: colors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Setup ${widget.catalogEntry.name}',
                      style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              Text(
                widget.catalogEntry.description,
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServerInfo(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.catalogEntry.isOfficial)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: colors.primary),
                    SizedBox(width: SpacingTokens.xs),
                    Text(
                      'Official',
                      style: TextStyles.caption.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.catalogEntry.pricing != null) ...[
              if (widget.catalogEntry.isOfficial) SizedBox(width: SpacingTokens.sm),
              _buildPricingBadge(colors),
            ],
          ],
        ),
        SizedBox(height: SpacingTokens.md),
        
        // Capabilities
        if (widget.catalogEntry.capabilities.isNotEmpty) ...[
          Text(
            'Capabilities',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: widget.catalogEntry.capabilities.map((capability) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  capability.replaceAll('-', ' '),
                  style: TextStyles.caption.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthFields(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authentication',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.sm),
        
        ...widget.catalogEntry.requiredAuth.map((authReq) {
          return Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authReq['displayName'] as String? ?? authReq['name'] as String? ?? 'Auth Field',
                  style: TextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                if ((authReq['description'] as String? ?? '').isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.xs),
                  Text(
                    authReq['description'] as String? ?? '',
                    style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
                SizedBox(height: SpacingTokens.sm),
                TextFormField(
                  controller: _authControllers[authReq['name'] as String? ?? authReq['displayName'] as String? ?? 'auth_field'],
                  obscureText: authReq['isSecret'] as bool? ?? false,
                  decoration: InputDecoration(
                    hintText: authReq['placeholder'] as String? ?? 'Enter ${(authReq['displayName'] as String? ?? 'auth field').toLowerCase()}',
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    filled: true,
                    fillColor: colors.surface.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    suffixIcon: (authReq['isSecret'] as bool? ?? false)
                        ? IconButton(
                            onPressed: () {
                              // Toggle password visibility
                            },
                            icon: Icon(Icons.visibility_off, color: colors.onSurfaceVariant),
                          )
                        : null,
                  ),
                  style: TextStyle(color: colors.onSurface),
                  validator: (value) {
                    if ((authReq['required'] as bool? ?? false) && (value == null || value.isEmpty)) {
                      return '${authReq['displayName'] as String? ?? authReq['name'] as String? ?? 'This field'} is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSetupInstructions(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.accent),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Setup Instructions',
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            widget.catalogEntry.setupInstructions!,
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          if (widget.catalogEntry.documentationUrl != null) ...[
            SizedBox(height: SpacingTokens.sm),
            GestureDetector(
              onTap: () => _launchUrl(widget.catalogEntry.documentationUrl!),
              child: Text(
                'View Documentation →',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.accent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyles.bodySmall.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AsmblButton.secondary(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SizedBox(width: SpacingTokens.md),
        AsmblButton.primary(
          text: _isLoading ? 'Adding...' : 'Add to Agent',
          onPressed: _isLoading ? null : _handleSetup,
          icon: _isLoading ? null : Icons.add,
        ),
      ],
    );
  }

  Widget _buildPricingBadge(ThemeColors colors) {
    Color badgeColor;
    String badgeText;

    switch (widget.catalogEntry.pricing!) {
      case MCPPricingModel.free:
        badgeColor = colors.primary;
        badgeText = 'Free';
        break;
      case MCPPricingModel.freemium:
        badgeColor = colors.accent;
        badgeText = 'Freemium';
        break;
      case MCPPricingModel.paid:
        badgeColor = Colors.orange;
        badgeText = 'Paid';
        break;
      case MCPPricingModel.usageBased:
        badgeColor = Colors.purple;
        badgeText = 'Usage-based';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyles.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authConfig = <String, String>{};
      for (final authReq in widget.catalogEntry.requiredAuth) {
        final authName = authReq['name'] as String? ?? authReq['displayName'] as String? ?? 'auth_field';
        final value = _authControllers[authName]?.text ?? '';
        if (value.isNotEmpty) {
          authConfig[authName] = value;
        }
      }

      final catalogService = ref.read(mcpCatalogServiceProvider);
      
      // For now, we'll configure for a default agent if none specified
      // In full implementation, this would come from context or user selection
      final agentId = widget.agentId ?? 'default-agent';
      
      await catalogService.enableServerForAgent(
        agentId,
        widget.catalogEntry.id,
        authConfig,
      );

      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to configure server: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  IconData _getServerIcon() {
    final category = widget.catalogEntry.category;
    if (category == null) return Icons.extension;

    if (category == MCPServerCategory.development) return Icons.code;
    if (category == MCPServerCategory.productivity) return Icons.trending_up;
    if (category == MCPServerCategory.communication) return Icons.chat;
    if (category == MCPServerCategory.dataAnalysis) return Icons.analytics;
    if (category == MCPServerCategory.automation) return Icons.auto_awesome;
    if (category == MCPServerCategory.fileManagement) return Icons.folder;
    if (category == MCPServerCategory.webServices) return Icons.language;
    if (category == MCPServerCategory.cloud) return Icons.cloud;
    if (category == MCPServerCategory.database) return Icons.storage;
    if (category == MCPServerCategory.security) return Icons.security;
    if (category == MCPServerCategory.monitoring) return Icons.monitor;
    if (category == MCPServerCategory.ai) return Icons.psychology;
    if (category == MCPServerCategory.utility) return Icons.build;
    if (category == MCPServerCategory.experimental) return Icons.science;
    if (category == MCPServerCategory.custom) return Icons.extension;

    return Icons.extension; // fallback
  }
}