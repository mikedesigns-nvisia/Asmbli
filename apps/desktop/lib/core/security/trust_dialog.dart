import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/design_system.dart';
import '../services/trust_service.dart';

class TrustDialog extends ConsumerStatefulWidget {
  final VoidCallback onTrusted;

  const TrustDialog({
    super.key,
    required this.onTrusted,
  });

  @override
  ConsumerState<TrustDialog> createState() => _TrustDialogState();
}

class _TrustDialogState extends ConsumerState<TrustDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      backgroundColor: colors.backgroundGradientMiddle,
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
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
              border: Border.all(color: colors.border.withOpacity( 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity( 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Security icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.warning.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: colors.warning,
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.xl),
                
                // Title
                Text(
                  'Trust This Application',
                  style: TextStyles.headlineLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.lg),
                
                // Warning message
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  decoration: BoxDecoration(
                    color: colors.warning.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(
                      color: colors.warning.withOpacity( 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 20,
                            color: colors.warning,
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Text(
                            'Security Notice',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Asmbli is a powerful AI agent platform that can:',
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      ...const [
                        '• Execute system commands and scripts',
                        '• Access files and directories on your computer',
                        '• Connect to external services and APIs',
                        '• Manage local processes and applications',
                        '• Interact with development tools and databases',
                      ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                        child: Text(
                          item,
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.lg),
                
                // Trust message
                Text(
                  'Only proceed if you trust this application and understand the security implications.',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: SpacingTokens.xl),
                
                // Don't show again checkbox
                InkWell(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _dontShowAgain ? colors.primary : Colors.transparent,
                            border: Border.all(
                              color: _dontShowAgain ? colors.primary : colors.border,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                          ),
                          child: _dontShowAgain
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: colors.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          'Don\'t show this again',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.xl),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: AsmblButton.secondary(
                        text: 'Cancel',
                        icon: Icons.close,
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.lg),
                    Expanded(
                      child: AsmblButton.primary(
                        text: 'I Trust This App',
                        icon: Icons.check_circle,
                        onPressed: () async {
                          if (_dontShowAgain) {
                            await ref.read(trustServiceProvider.notifier).setTrusted(true);
                          }
                          widget.onTrusted();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}