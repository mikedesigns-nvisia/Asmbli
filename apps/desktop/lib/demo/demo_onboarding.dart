import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../core/design_system/design_system.dart';
import '../core/constants/routes.dart';

/// Onboarding screen for demo that lets users select an agent type
class DemoOnboarding extends StatefulWidget {
  const DemoOnboarding({super.key});

  @override
  State<DemoOnboarding> createState() => _DemoOnboardingState();
}

class _DemoOnboardingState extends State<DemoOnboarding> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  int? _selectedAgent;
  int _currentFeatureIndex = 0;
  
  final PageController _pageController = PageController();
  
  final List<AgentTemplate> _agentTemplates = [
    AgentTemplate(
      id: 0,
      name: 'Business Analyst',
      icon: Icons.analytics,
      color: const Color(0xFF4ECDC4),
      description: 'Transform data into insights with AI-powered analysis',
      features: [
        'Real-time data visualization',
        'Predictive analytics',
        'Automated reporting',
        'Trend identification',
      ],
      tooltips: [
        'Watch how confidence monitoring prevents hallucinations',
        'See multi-model consensus in action',
        'Experience seamless tool integration',
      ],
    ),
    AgentTemplate(
      id: 1,
      name: 'Design Assistant',
      icon: Icons.palette,
      color: const Color(0xFFFF6B6B),
      description: 'From conversation to visual design in seconds',
      features: [
        'Live canvas integration',
        'Component generation',
        'Design system aware',
        'Real-time preview',
      ],
      tooltips: [
        'Chat naturally about your design needs',
        'Watch designs appear on the canvas instantly',
        'See how AI understands design context',
      ],
    ),
    AgentTemplate(
      id: 2,
      name: 'Operations Manager',
      icon: Icons.schedule,
      color: const Color(0xFF4E5DC0),
      description: 'Streamline operations with intelligent scheduling and notifications',
      features: [
        'Smart scheduling optimization',
        'Automated notifications',
        'Resource allocation',
        'Operational monitoring',
      ],
      tooltips: [
        'Experience intelligent operations automation',
        'See smart scheduling and notifications in action',
        'Optimize resources and workflows',
      ],
    ),
    AgentTemplate(
      id: 3,
      name: 'Coding Agent',
      icon: Icons.code,
      color: const Color(0xFF9B59B6),
      description: 'AI pair programming with real-time code generation and git integration',
      features: [
        'Intelligent code generation',
        'Git workflow automation',
        'Live preview & testing',
        'Code review assistance',
      ],
      tooltips: [
        'Experience AI-powered development workflows',
        'See code generation with git integration',
        'Watch live preview updates as you code',
      ],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _selectAgent(int index) {
    // Navigate directly to controlled onboarding with the selected agent
    context.go('${AppRoutes.controlledOnboarding}?agentType=$index');
  }
  
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      
      _slideController.forward().then((_) {
        if (_currentStep == 2) {
          // Start feature showcase
          _slideController.reset();
          _showcaseFeatures();
        }
      });
    }
  }
  
  void _showcaseFeatures() async {
    if (_selectedAgent == null) return;
    
    final features = _agentTemplates[_selectedAgent!].features;
    
    for (int i = 0; i < features.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _currentFeatureIndex = i;
        });
        _slideController.forward().then((_) {
          _slideController.reset();
        });
      }
    }
    
    // Show launch button after all features
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _currentStep = 3;
      });
    }
  }
  
  void _launchDemo() {
    if (_selectedAgent == null) return;
    
    print('🚀 Launching demo for agent type: $_selectedAgent');
    
    // Navigate to unified demo with selected agent context using GoRouter
    context.go('${AppRoutes.demoUnified}?agentType=$_selectedAgent');
  }
  
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCurrentStep(colors),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentStep(ThemeColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(colors);
      case 1:
        return _buildAgentSelectionStep(colors);
      case 2:
        return _buildFeatureShowcaseStep(colors);
      case 3:
        return _buildLaunchStep(colors);
      default:
        return _buildWelcomeStep(colors);
    }
  }
  
  Widget _buildWelcomeStep(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.xxl),
          Text(
            'Let\'s explore what AI agents can do for you',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xxl),
          AsmblButton.primary(
            text: 'Get Started',
            onPressed: _nextStep,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAgentSelectionStep(ThemeColors colors) {
    return Column(
      children: [
        const SizedBox(height: SpacingTokens.xxl),
        Text(
          'Choose Your AI Agent',
          style: TextStyles.pageTitle.copyWith(
            color: colors.onSurface,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text(
          'Each agent specializes in different capabilities',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingTokens.xxl),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: SpacingTokens.xl,
                runSpacing: SpacingTokens.xl,
                children: _agentTemplates.map((template) => 
                  _buildSimpleAgentCard(template, colors)
                ).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeatureShowcaseStep(ThemeColors colors) {
    if (_selectedAgent == null) return Container();
    
    final agent = _agentTemplates[_selectedAgent!];
    final currentFeature = agent.features[_currentFeatureIndex];
    
    return SlideTransition(
      position: _slideAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: agent.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                agent.icon,
                size: 40,
                color: agent.color,
              ),
            ),
            const SizedBox(height: SpacingTokens.xl),
            Text(
              agent.name,
              style: TextStyles.pageTitle.copyWith(
                color: colors.onSurface,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: SpacingTokens.xxl),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(SpacingTokens.xl),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                border: Border.all(color: agent.color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: agent.color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: agent.color,
                    size: 32,
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Text(
                    currentFeature,
                    style: TextStyles.sectionTitle.copyWith(
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLaunchStep(ThemeColors colors) {
    if (_selectedAgent == null) return Container();
    
    final agent = _agentTemplates[_selectedAgent!];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [agent.color, colors.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: agent.color.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch,
              size: 50,
              color: colors.surface,
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          Text(
            'Ready to Launch!',
            style: TextStyles.pageTitle.copyWith(
              color: colors.onSurface,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Your ${agent.name} is configured and ready to go',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xxl),
          AsmblButton.primary(
            text: 'Launch ${agent.name}',
            onPressed: _launchDemo,
            icon: Icons.play_arrow,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleAgentCard(AgentTemplate template, ThemeColors colors) {
    return GestureDetector(
      onTap: () => _selectAgent(template.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 250,
        height: 320, // Increased height to prevent overflow
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              Container(
                width: 56, // Slightly smaller icon
                height: 56,
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                ),
                child: Icon(
                  template.icon,
                  size: 28,
                  color: template.color,
                ),
              ),
              const SizedBox(height: SpacingTokens.md), // Reduced spacing
              Flexible(
                child: Text(
                  template.name,
                  style: TextStyles.sectionTitle.copyWith(
                    color: colors.onSurface,
                    fontSize: 18, // Slightly smaller font
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm), // Reduced spacing
              Flexible(
                child: Text(
                  template.description,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 13, // Smaller description font
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: SpacingTokens.md), // Reduced spacing
              AsmblButton.outline(
                text: 'Select',
                onPressed: () => _selectAgent(template.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(ThemeColors colors) {
    return Column(
      children: [
        // Logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 40,
            color: colors.surface,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.lg),
        
        Text(
          'Welcome to Asmbli',
          style: TextStyles.pageTitle.copyWith(
            color: colors.onSurface,
            fontSize: 32,
          ),
        ),
        
        const SizedBox(height: SpacingTokens.sm),
        
        Text(
          'Experience the future of AI agent collaboration',
          style: TextStyles.bodyLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
}

class AgentTemplate {
  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> features;
  final List<String> tooltips;
  
  const AgentTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.features,
    required this.tooltips,
  });
}