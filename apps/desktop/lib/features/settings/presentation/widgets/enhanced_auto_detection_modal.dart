import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/simple_detection_service.dart';

class EnhancedAutoDetectionModal extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const EnhancedAutoDetectionModal({
    super.key,
    this.onComplete,
  });

  @override
  ConsumerState<EnhancedAutoDetectionModal> createState() => _EnhancedAutoDetectionModalState();
}

class _EnhancedAutoDetectionModalState extends ConsumerState<EnhancedAutoDetectionModal> {
  bool _isDetecting = false;
  SimpleDetectionResult? _detectionResult;
  String _currentStep = 'overview';
  String _selectedCategory = 'all';

  final List<DetectionCategory> _categories = [
    const DetectionCategory(
      id: 'all',
      name: 'All Integrations',
      icon: Icons.dashboard,
      description: 'Detect everything at once',
      color: Colors.purple,
    ),
    const DetectionCategory(
      id: 'development',
      name: 'Development Tools',
      icon: Icons.code,
      description: 'VS Code, Git, GitHub CLI',
      color: Colors.blue,
    ),
    const DetectionCategory(
      id: 'browsers',
      name: 'Web Browsers',
      icon: Icons.web,
      description: 'Chrome, Brave, Firefox, Edge',
      color: Colors.orange,
    ),
    const DetectionCategory(
      id: 'databases',
      name: 'Databases',
      icon: Icons.storage,
      description: 'PostgreSQL, MySQL, MongoDB',
      color: Colors.green,
    ),
    const DetectionCategory(
      id: 'communication',
      name: 'Communication',
      icon: Icons.chat_bubble,
      description: 'Slack, Discord, Teams',
      color: Colors.pink,
    ),
    const DetectionCategory(
      id: 'cloud',
      name: 'Cloud Services',
      icon: Icons.cloud,
      description: 'AWS, Azure, Google Cloud',
      color: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SemanticColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: SemanticColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                border: Border(
                  right: BorderSide(color: SemanticColors.border),
                ),
              ),
              child: Column(
                children: [
                  _buildSidebarHeader(),
                  Expanded(child: _buildSidebarContent()),
                  _buildSidebarFooter(),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildMainHeader(),
                  Expanded(child: _buildMainContent()),
                  _buildMainFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SemanticColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SemanticColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_fix_high,
                  color: SemanticColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Auto-Detection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SemanticColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Steps/Navigation
        _buildSidebarSection('DETECTION STEPS'),
        _buildSidebarItem(
          'Overview',
          Icons.info_outline,
          _currentStep == 'overview',
          () => setState(() => _currentStep = 'overview'),
        ),
        _buildSidebarItem(
          'Select Categories',
          Icons.category,
          _currentStep == 'categories',
          () => setState(() => _currentStep = 'categories'),
        ),
        _buildSidebarItem(
          'Detection Progress',
          Icons.radar,
          _currentStep == 'detecting',
          () => {},
          enabled: _isDetecting,
        ),
        _buildSidebarItem(
          'Results',
          Icons.check_circle_outline,
          _currentStep == 'results',
          () => {},
          enabled: _detectionResult != null,
        ),
        
        const SizedBox(height: 20),
        
        // Categories filter (visible in results)
        if (_detectionResult != null) ...[
          _buildSidebarSection('FILTER BY CATEGORY'),
          ..._categories.map((cat) => _buildCategoryFilterItem(cat)),
        ],
      ],
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: SemanticColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String label, IconData icon, bool isActive, VoidCallback onTap, {bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? SemanticColors.primary.withOpacity( 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: SemanticColors.primary.withOpacity( 0.2)) : null,
      ),
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          size: 20,
          color: enabled
            ? (isActive ? SemanticColors.primary : SemanticColors.onSurfaceVariant)
            : SemanticColors.onSurfaceVariant.withOpacity( 0.3),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: enabled
              ? (isActive ? SemanticColors.primary : SemanticColors.onSurface)
              : SemanticColors.onSurfaceVariant.withOpacity( 0.5),
          ),
        ),
        onTap: enabled ? onTap : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Widget _buildCategoryFilterItem(DetectionCategory category) {
    final isSelected = _selectedCategory == category.id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? category.color.withOpacity( 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          category.icon,
          size: 18,
          color: isSelected ? category.color : SemanticColors.onSurfaceVariant,
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? category.color : SemanticColors.onSurface,
          ),
        ),
        onTap: () => setState(() => _selectedCategory = category.id),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SemanticColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_detectionResult != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity( 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_detectionResult!.totalFound} Tools Found',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SemanticColors.background.withOpacity( 0.5),
        border: const Border(bottom: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SemanticColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepDescription(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentStep) {
      case 'overview':
        return _buildOverviewContent();
      case 'categories':
        return _buildCategoriesContent();
      case 'detecting':
        return _buildDetectingContent();
      case 'results':
        return _buildResultsContent();
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SemanticColors.primary.withOpacity( 0.2),
                  SemanticColors.primary.withOpacity( 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 40,
              color: SemanticColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Auto-Detection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: SemanticColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'ll automatically scan your system for installed tools and services,\nthen configure them for seamless integration with Asmbli.',
            style: TextStyle(
              fontSize: 14,
              color: SemanticColors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureCard(Icons.speed, 'Fast Scan', 'Under 10 seconds'),
              const SizedBox(width: 16),
              _buildFeatureCard(Icons.auto_fix_high, 'Zero Config', 'Automatic setup'),
              const SizedBox(width: 16),
              _buildFeatureCard(Icons.security, 'Safe & Secure', 'Read-only scan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SemanticColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: SemanticColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: SemanticColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: SemanticColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose what to detect',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SemanticColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select specific categories or detect everything at once',
            style: TextStyle(
              fontSize: 14,
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category.id;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? category.color.withOpacity( 0.1)
                        : SemanticColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                          ? category.color.withOpacity( 0.5)
                          : SemanticColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity( 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            category.icon,
                            size: 24,
                            color: category.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? category.color : SemanticColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: const TextStyle(
                            fontSize: 10,
                            color: SemanticColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectingContent() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
                ),
                Icon(
                  Icons.radar,
                  size: 48,
                  color: SemanticColors.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Scanning your system...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SemanticColors.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Detecting installed tools and services',
            style: TextStyle(
              fontSize: 16,
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32),
          SizedBox(
            width: 400,
            child: LinearProgressIndicator(
              backgroundColor: SemanticColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    if (_detectionResult == null) return const SizedBox();

    // Filter results based on selected category
    final filteredResults = _selectedCategory == 'all' 
      ? _detectionResult!.detections.entries.toList()
      : _detectionResult!.detections.entries.where((e) => 
          _getCategoryForTool(e.key) == _selectedCategory
        ).toList();

    // Sort: found items first
    filteredResults.sort((a, b) {
      if (a.value != b.value) {
        return b.value ? 1 : -1;
      }
      return a.key.compareTo(b.key);
    });

    return Column(
      children: [
        // Summary cards
        Container(
          padding: const EdgeInsets.all(24),
          color: SemanticColors.background.withOpacity( 0.5),
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard(
                'Total Scanned',
                _detectionResult!.detections.length.toString(),
                Icons.search,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard(
                'Found & Ready',
                _detectionResult!.totalFound.toString(),
                Icons.check_circle,
                Colors.green,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard(
                'Not Found',
                (_detectionResult!.detections.length - _detectionResult!.totalFound).toString(),
                Icons.cancel,
                Colors.grey,
              )),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final entry = filteredResults[index];
              final isFound = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isFound 
                    ? Colors.green.withOpacity( 0.05)
                    : SemanticColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFound 
                      ? Colors.green.withOpacity( 0.3)
                      : SemanticColors.border,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isFound
                        ? Colors.green.withOpacity( 0.15)
                        : Colors.grey.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForTool(entry.key),
                      color: isFound ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SemanticColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    isFound ? 'Detected and ready to use' : 'Not detected on this system',
                    style: const TextStyle(
                      fontSize: 13,
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFound 
                        ? Colors.green.withOpacity( 0.15)
                        : Colors.grey.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFound ? '✓ Ready' : 'Install',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFound ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity( 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SemanticColors.background.withOpacity( 0.5),
        border: const Border(top: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress indicator
          if (_currentStep != 'overview' && _currentStep != 'results') 
            Row(
              children: _getProgressSteps(),
            )
          else
            const SizedBox(),
          
          // Action buttons
          Row(
            children: [
              if (_currentStep != 'overview' && _currentStep != 'detecting')
                TextButton(
                  onPressed: _goToPreviousStep,
                  style: TextButton.styleFrom(
                    foregroundColor: SemanticColors.onSurfaceVariant,
                  ),
                  child: const Text('Back'),
                ),
              const SizedBox(width: 12),
              if (_currentStep == 'results')
                AsmblButton.secondary(
                  text: 'Scan Again',
                  onPressed: () {
                    setState(() {
                      _detectionResult = null;
                      _currentStep = 'overview';
                    });
                  },
                ),
              const SizedBox(width: 12),
              AsmblButton.primary(
                text: _getActionButtonText(),
                onPressed: _isDetecting ? null : _handleActionButton,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _getProgressSteps() {
    final steps = ['overview', 'categories', 'detecting', 'results'];
    final currentIndex = steps.indexOf(_currentStep);
    
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final isActive = index <= currentIndex;
      final isCompleted = index < currentIndex;
      
      return Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? SemanticColors.primary : SemanticColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.white : SemanticColors.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
          if (index < steps.length - 1)
            Container(
              width: 40,
              height: 2,
              color: isActive ? SemanticColors.primary : SemanticColors.border,
            ),
        ],
      );
    }).toList();
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 'overview':
        return 'Auto-Detection Setup';
      case 'categories':
        return 'Select Detection Categories';
      case 'detecting':
        return 'Detecting Integrations';
      case 'results':
        return 'Detection Results';
      default:
        return 'Auto-Detection';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 'overview':
        return 'Automatically configure all your tools and services';
      case 'categories':
        return 'Choose which types of integrations to detect';
      case 'detecting':
        return 'Please wait while we scan your system';
      case 'results':
        return '${_detectionResult?.totalFound ?? 0} integrations found and ready to use';
      default:
        return '';
    }
  }

  String _getActionButtonText() {
    switch (_currentStep) {
      case 'overview':
        return 'Get Started';
      case 'categories':
        return 'Start Detection';
      case 'detecting':
        return 'Detecting...';
      case 'results':
        return 'Complete Setup';
      default:
        return 'Continue';
    }
  }

  void _handleActionButton() {
    switch (_currentStep) {
      case 'overview':
        setState(() => _currentStep = 'categories');
        break;
      case 'categories':
        _startDetection();
        break;
      case 'results':
        print('EnhancedAutoDetectionModal: Complete Setup button pressed');
        print('EnhancedAutoDetectionModal: onComplete callback exists: ${widget.onComplete != null}');
        
        if (widget.onComplete != null) {
          print('EnhancedAutoDetectionModal: Calling onComplete callback');
          widget.onComplete!.call();
          print('EnhancedAutoDetectionModal: onComplete callback executed');
        } else {
          print('EnhancedAutoDetectionModal: WARNING - onComplete callback is null');
        }
        
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
          print('EnhancedAutoDetectionModal: Dialog closed successfully');
        } else {
          print('EnhancedAutoDetectionModal: WARNING - Cannot close dialog, context not mounted');
        }
        break;
    }
  }

  void _goToPreviousStep() {
    switch (_currentStep) {
      case 'categories':
        setState(() => _currentStep = 'overview');
        break;
      case 'results':
        setState(() => _currentStep = 'categories');
        break;
    }
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _currentStep = 'detecting';
    });

    try {
      // Simulate longer detection for better UX
      await Future.delayed(const Duration(seconds: 2));
      
      final detectionService = ref.read(simpleDetectionServiceProvider);
      _detectionResult = await detectionService.detectBasicTools();
      
      // Add a small delay before showing results
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _currentStep = 'results';
      });
    } catch (e) {
      setState(() {
        _currentStep = 'categories';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  String _getCategoryForTool(String toolName) {
    if (toolName.contains('Code') || toolName.contains('Git') || toolName.contains('Node') || 
        toolName.contains('Python') || toolName.contains('Docker')) {
      return 'development';
    }
    if (toolName.contains('Browser') || toolName.contains('Chrome') || toolName.contains('Brave')) {
      return 'browsers';
    }
    return 'all';
  }

  IconData _getIconForTool(String toolName) {
    if (toolName.contains('VS Code')) return Icons.code;
    if (toolName.contains('Git')) return Icons.source;
    if (toolName.contains('Node')) return Icons.javascript;
    if (toolName.contains('Python')) return Icons.code;
    if (toolName.contains('Docker')) return Icons.dock;
    if (toolName.contains('Browser') || toolName.contains('Chrome') || toolName.contains('Brave')) return Icons.web;
    return Icons.extension;
  }
}

class DetectionCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  const DetectionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });
}