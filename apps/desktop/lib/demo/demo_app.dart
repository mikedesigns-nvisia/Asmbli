import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import 'services/demo_mode_service.dart';
import 'scenarios/vc_demo_scenario.dart';

/// Main demo application that routes to appropriate demo scenario
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late DemoModeService _demoService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _demoService = DemoModeService.instance;
    _initializeDemo();
  }

  Future<void> _initializeDemo() async {
    await _demoService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Asmbli Demo Loading',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing Demo Mode...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Asmbli Demo - ${_demoService.configuration.title}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _buildDemoScenario(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildDemoScenario() {
    switch (_demoService.demoScenario) {
      case DemoScenario.vcDemo:
        return const VCDemoScenario();
      
      case DemoScenario.enterpriseDemo:
        return _buildPlaceholderDemo('Enterprise Demo');
      
      case DemoScenario.technicalDemo:
        return _buildPlaceholderDemo('Technical Demo');
    }
  }

  Widget _buildPlaceholderDemo(String title) {
    final colors = ThemeColors(context);
    
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: SpacingTokens.lg),
              Text(
                '$title Coming Soon',
                style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                'This demo scenario is currently under development.',
                style: TextStyles.bodyLarge.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: SpacingTokens.xl),
              AsmblButton.primary(
                text: 'Switch to VC Demo',
                onPressed: () {
                  // For now, just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('To run VC demo: flutter run --dart-define=DEMO_SCENARIO=vc_demo'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Demo selector widget for development
class DemoSelector extends StatelessWidget {
  const DemoSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

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
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              children: [
                Text(
                  'Asmbli Demo Scenarios',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xl),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 1,
                    mainAxisSpacing: SpacingTokens.lg,
                    childAspectRatio: 3,
                    children: [
                      _buildDemoCard(
                        context,
                        'VC/Investor Demo',
                        '8 minutes',
                        'Real-time confidence, uncertainty intervention',
                        'The "Holy Shit" moment for investors',
                        Icons.trending_up,
                        colors,
                        DemoScenario.vcDemo,
                      ),
                      
                      _buildDemoCard(
                        context,
                        'Enterprise Demo',
                        '12 minutes',
                        'ROI focus, cost savings, governance',
                        'Business value for CTOs and decision makers',
                        Icons.business,
                        colors,
                        DemoScenario.enterpriseDemo,
                      ),
                      
                      _buildDemoCard(
                        context,
                        'Technical Demo',
                        '15 minutes',
                        'Architecture deep-dive, implementation details',
                        'Under the hood for engineers',
                        Icons.code,
                        colors,
                        DemoScenario.technicalDemo,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: SpacingTokens.lg),
                Text(
                  'To run a specific demo:\nflutter run --dart-define=DEMO_MODE=true --dart-define=DEMO_SCENARIO=vc_demo',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'Courier',
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

  Widget _buildDemoCard(
    BuildContext context,
    String title,
    String duration,
    String features,
    String description,
    IconData icon,
    ThemeColors colors,
    DemoScenario scenario,
  ) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Row(
          children: [
            Icon(
              icon,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(width: SpacingTokens.lg),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          duration,
                          style: TextStyles.bodySmall.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    description,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    features,
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}