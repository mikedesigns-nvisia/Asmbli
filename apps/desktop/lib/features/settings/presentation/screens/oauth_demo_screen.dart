import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import 'simple_oauth_demo.dart';
import 'enhanced_oauth_settings_screen.dart';

/// Demo screen to compare the two OAuth screen approaches
class OAuthDemoScreen extends StatelessWidget {
  const OAuthDemoScreen({super.key});

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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OAuth Settings Demo',
                  style: TextStyles.pageTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: SpacingTokens.xxl),
                
                // Apple-style option
                AsmblCard(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SimpleOAuthDemo(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                    child: Padding(
                      padding: EdgeInsets.all(SpacingTokens.xl),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.apple,
                              size: 32,
                              color: colors.primary,
                            ),
                          ),
                          SizedBox(height: SpacingTokens.lg),
                          Text(
                            'Apple-Style UX',
                            style: TextStyles.bodyLarge.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: SpacingTokens.sm),
                          Text(
                            'Simplified, intuitive design with progressive disclosure and smart defaults',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: SpacingTokens.xl),
                
                // Enhanced/Complex option  
                AsmblCard(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EnhancedOAuthSettingsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                    child: Padding(
                      padding: EdgeInsets.all(SpacingTokens.xl),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.settings,
                              size: 32,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: SpacingTokens.lg),
                          Text(
                            'Enhanced/Complex UX',
                            style: TextStyles.bodyLarge.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: SpacingTokens.sm),
                          Text(
                            'Feature-rich interface with tabs, detailed controls, and comprehensive options',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: SpacingTokens.xxl),
                
                Text(
                  'Tap either option to see the different approaches',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}