import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../settings/presentation/widgets/integration_marketplace.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              SemanticColors.primary.withValues(alpha: 0.05),
              SemanticColors.background.withValues(alpha: 0.8),
              SemanticColors.background,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: const SafeArea(
          child: Column(
            children: [
              // App Navigation Bar
              AppNavigationBar(currentRoute: AppRoutes.marketplace),
              
              // Marketplace content
              Expanded(
                child: IntegrationMarketplace(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}