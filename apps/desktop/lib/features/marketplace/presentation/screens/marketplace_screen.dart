import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../settings/presentation/widgets/integration_marketplace.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: SemanticColors.background,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SemanticColors.primary.withValues(alpha: 0.1),
                  SemanticColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: SemanticColors.primary,
                      size: 32,
                    ),
                    SizedBox(width: SpacingTokens.lg),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Integration Marketplace',
                          style: TextStyles.pageTitle,
                        ),
                        SizedBox(height: SpacingTokens.xs),
                        Text(
                          'Discover and install powerful integrations to enhance your agents',
                          style: TextStyles.bodyMedium.copyWith(
                            color: SemanticColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Marketplace content
          Expanded(
            child: IntegrationMarketplace(),
          ),
        ],
      ),
    );
  }
}