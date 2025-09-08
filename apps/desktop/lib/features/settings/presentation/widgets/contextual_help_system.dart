import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import 'apple_style_feedback_widgets.dart';

/// Apple-style contextual help and guidance system
class ContextualHelpSystem extends StatelessWidget {
  final Widget child;
  final List<HelpTip> tips;
  final bool showInitialTip;

  const ContextualHelpSystem({
    super.key,
    required this.child,
    required this.tips,
    this.showInitialTip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showInitialTip && tips.isNotEmpty)
          _buildInitialTip(context, tips.first),
      ],
    );
  }

  Widget _buildInitialTip(BuildContext context, HelpTip tip) {
    return Positioned(
      top: tip.position.dy,
      left: tip.position.dx,
      child: _HelpTipWidget(tip: tip),
    );
  }
}

class _HelpTipWidget extends StatefulWidget {
  final HelpTip tip;

  const _HelpTipWidget({required this.tip});

  @override
  State<_HelpTipWidget> createState() => _HelpTipWidgetState();
}

class _HelpTipWidgetState extends State<_HelpTipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                boxShadow: [
                  BoxShadow(
                    color: colors.onSurface.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: colors.border.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.tip.icon,
                          size: 14,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          widget.tip.title,
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _controller.reverse(),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  Text(
                    widget.tip.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (widget.tip.actionText != null) ...[
                    SizedBox(height: SpacingTokens.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppleStyleButton(
                        onPressed: widget.tip.onAction,
                        backgroundColor: colors.primary,
                        borderRadius: BorderRadius.circular(16),
                        padding: EdgeInsets.symmetric(
                          horizontal: SpacingTokens.md,
                          vertical: SpacingTokens.sm,
                        ),
                        child: Text(
                          widget.tip.actionText!,
                          style: TextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Smart help suggestions based on context
class SmartHelpProvider {
  
  /// Get contextual help for OAuth connection process
  static List<HelpTip> getConnectionHelp(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return [
          HelpTip(
            id: 'github_permissions',
            title: 'GitHub Permissions',
            description: 'We only request access to what you need. You can always change this later in settings.',
            icon: Icons.security,
            position: const Offset(20, 100),
            priority: HelpPriority.high,
          ),
          HelpTip(
            id: 'github_private',
            title: 'Private Repository Access',
            description: 'Enable this if you want help with private repositories. Public repos work without this.',
            icon: Icons.lock,
            position: const Offset(20, 200),
            priority: HelpPriority.medium,
          ),
        ];
      case OAuthProvider.slack:
        return [
          HelpTip(
            id: 'slack_workspace',
            title: 'Workspace Access',
            description: 'You\'ll be connected to the workspace you select during sign-in.',
            icon: Icons.workspaces,
            position: const Offset(20, 100),
            priority: HelpPriority.high,
          ),
        ];
      default:
        return [];
    }
  }

  /// Get onboarding help tips
  static List<HelpTip> getOnboardingHelp() {
    return [
      HelpTip(
        id: 'first_connection',
        title: 'Your First Connection',
        description: 'Start with the service you use most. We recommend beginning with basic permissions.',
        icon: Icons.emoji_objects,
        position: const Offset(20, 120),
        priority: HelpPriority.high,
        actionText: 'Got it',
      ),
      HelpTip(
        id: 'security_first',
        title: 'Privacy & Security',
        description: 'All connections are encrypted and stored securely. You can disconnect anytime.',
        icon: Icons.shield,
        position: const Offset(20, 200),
        priority: HelpPriority.medium,
      ),
    ];
  }

  /// Get help for permissions screen
  static List<HelpTip> getPermissionsHelp(OAuthProvider provider) {
    return [
      HelpTip(
        id: 'required_permissions',
        title: 'Required Permissions',
        description: 'Some permissions are required for basic functionality and cannot be disabled.',
        icon: Icons.info,
        position: const Offset(20, 150),
        priority: HelpPriority.high,
      ),
      HelpTip(
        id: 'permission_categories',
        title: 'Permission Categories',
        description: 'Tap categories to see detailed permissions. Orange icons indicate higher risk permissions.',
        icon: Icons.category,
        position: const Offset(20, 220),
        priority: HelpPriority.medium,
      ),
    ];
  }

  /// Get smart suggestions based on user behavior
  static List<SmartGuide> getSmartSuggestions(UserContext context) {
    final suggestions = <SmartGuide>[];

    if (context.isFirstTime) {
      suggestions.add(SmartGuide(
        id: 'welcome_guide',
        type: GuideType.onboarding,
        title: 'Welcome to Connected Accounts',
        steps: [
          GuideStep(
            title: 'Connect Safely',
            description: 'We use industry-standard OAuth2 for secure connections.',
            icon: Icons.security,
          ),
          GuideStep(
            title: 'Start Simple',
            description: 'Begin with basic permissions. You can always add more later.',
            icon: Icons.start,
          ),
          GuideStep(
            title: 'Stay in Control',
            description: 'Review and modify permissions anytime in settings.',
            icon: Icons.tune,
          ),
        ],
      ));
    }

    if (context.connectedProviders.isEmpty) {
      suggestions.add(SmartGuide(
        id: 'first_connection_guide',
        type: GuideType.feature,
        title: 'Connect Your First Account',
        description: 'Choose a service you use regularly to get started.',
        quickActions: [
          QuickAction(
            title: 'GitHub for Code',
            description: 'Access repositories and collaborate',
            icon: Icons.code,
            provider: OAuthProvider.github,
          ),
          QuickAction(
            title: 'Slack for Teams',
            description: 'Send messages and get notifications',
            icon: Icons.chat,
            provider: OAuthProvider.slack,
          ),
        ],
      ));
    }

    if (context.hasExpiringSoon) {
      suggestions.add(SmartGuide(
        id: 'expiring_tokens',
        type: GuideType.maintenance,
        title: 'Refresh Needed',
        description: 'Some connections expire soon. Refresh them to continue using integrations.',
        actionText: 'Refresh Now',
      ));
    }

    return suggestions;
  }

  /// Get contextual tooltips
  static Map<String, String> getTooltips() {
    return {
      'connection_status': 'Green means active, yellow means expiring soon, red means disconnected',
      'required_scope': 'This permission is required for the integration to work properly',
      'high_risk_scope': 'This permission grants significant access. Only enable if needed',
      'auto_refresh': 'Automatically renew tokens before they expire',
      'secure_storage': 'All tokens are encrypted and stored securely on your device',
    };
  }
}

/// Inline help component for quick tips
class InlineHelp extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? color;

  const InlineHelp({
    super.key,
    required this.message,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: (color ?? colors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: (color ?? colors.primary).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.info_outline,
            size: 16,
            color: color ?? colors.primary,
          ),
          SizedBox(width: SpacingTokens.sm),
          Flexible(
            child: Text(
              message,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progressive disclosure widget for advanced options
class ProgressiveDisclosure extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? icon;

  const ProgressiveDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.icon,
  });

  @override
  State<ProgressiveDisclosure> createState() => _ProgressiveDisclosureState();
}

class _ProgressiveDisclosureState extends State<ProgressiveDisclosure>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    if (_isExpanded) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            });
            AppleStyleFeedback.selectionClick();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: SpacingTokens.sm,
              horizontal: SpacingTokens.md,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: colors.primary,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyles.labelMedium.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _controller.value,
                child: Padding(
                  padding: EdgeInsets.only(top: SpacingTokens.md),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Data classes
class HelpTip {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Offset position;
  final HelpPriority priority;
  final String? actionText;
  final VoidCallback? onAction;

  HelpTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.position,
    required this.priority,
    this.actionText,
    this.onAction,
  });
}

class SmartGuide {
  final String id;
  final GuideType type;
  final String title;
  final String? description;
  final List<GuideStep>? steps;
  final List<QuickAction>? quickActions;
  final String? actionText;
  final VoidCallback? onAction;

  SmartGuide({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.steps,
    this.quickActions,
    this.actionText,
    this.onAction,
  });
}

class GuideStep {
  final String title;
  final String description;
  final IconData icon;

  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class QuickAction {
  final String title;
  final String description;
  final IconData icon;
  final OAuthProvider? provider;
  final VoidCallback? onTap;

  QuickAction({
    required this.title,
    required this.description,
    required this.icon,
    this.provider,
    this.onTap,
  });
}

class UserContext {
  final bool isFirstTime;
  final List<OAuthProvider> connectedProviders;
  final bool hasExpiringSoon;
  final int totalConnections;

  UserContext({
    required this.isFirstTime,
    required this.connectedProviders,
    required this.hasExpiringSoon,
    required this.totalConnections,
  });
}

enum HelpPriority {
  high,
  medium,
  low,
}

enum GuideType {
  onboarding,
  feature,
  maintenance,
}