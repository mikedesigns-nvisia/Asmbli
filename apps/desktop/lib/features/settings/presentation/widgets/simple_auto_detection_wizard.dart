import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/simple_detection_service.dart';

class SimpleAutoDetectionWizard extends ConsumerStatefulWidget {
  final void Function(SimpleDetectionResult result)? onComplete;

  const SimpleAutoDetectionWizard({
    super.key,
    this.onComplete,
  });

  @override
  ConsumerState<SimpleAutoDetectionWizard> createState() => _SimpleAutoDetectionWizardState();
}

class _SimpleAutoDetectionWizardState extends ConsumerState<SimpleAutoDetectionWizard> {
  bool _isDetecting = false;
  SimpleDetectionResult? _detectionResult;
  String _currentStep = 'overview';
  String _selectedCategory = 'all';

  final Map<String, String> _categories = {
    'all': 'All Tools',
    'development': 'Development',
    'browsers': 'Browsers',
    'productivity': 'Productivity',
  };

  final Map<String, String> _categoryIcons = {
    'all': 'auto_fix_high',
    'development': 'code',
    'browsers': 'web',
    'productivity': 'work',
  };

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildSidebar(colors),
            Expanded(child: _buildMainContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeColors colors) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-Detect\nIntegrations',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Steps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgressStep(colors, 'Overview', 'overview', Icons.info_outline),
                _buildProgressStep(colors, 'Categories', 'categories', Icons.category_outlined),
                _buildProgressStep(colors, 'Detection', 'detecting', Icons.search),
                _buildProgressStep(colors, 'Results', 'results', Icons.check_circle_outline),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category Filters (show only when appropriate)
          if (_currentStep == 'categories' || _currentStep == 'results') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categories.entries.map((entry) =>
                    _buildCategoryFilter(colors, entry.key, entry.value)
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Summary (show when detection is complete)
          if (_detectionResult != null) ...[
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detection Complete',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_detectionResult!.totalFound} Tools Ready',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors) {
    return Column(
      children: [
        _buildMainHeader(colors),
        Expanded(child: _buildStepContent(colors)),
        _buildMainFooter(colors),
      ],
    );
  }
  
  Widget _buildMainHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepTitle(),
                  style: TextStyles.pageTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepDescription(),
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepContent(ThemeColors colors) {
    switch (_currentStep) {
      case 'overview':
        return _buildOverviewStep(colors);
      case 'categories':
        return _buildCategoriesStep(colors);
      case 'detecting':
        return _buildDetectingStep(colors);
      case 'results':
        return _buildResultsStep();
      default:
        return _buildOverviewStep(colors);
    }
  }

  Widget _buildOverviewStep(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_fix_high,
              size: 48,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Automatic Integration Detection',
            style: TextStyles.pageTitle.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ll scan your system for installed development tools, browsers, and productivity apps, then automatically configure the ones we find. No manual setup required.',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Feature highlights
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  colors,
                  Icons.speed,
                  'Fast Detection',
                  'Scans your entire system in seconds',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  colors,
                  Icons.shield_outlined,
                  'Safe & Secure',
                  'Only reads installation paths, no private data',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  colors,
                  Icons.widgets_outlined,
                  'Smart Config',
                  'Automatically configures found tools',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesStep(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'What would you like to detect?',
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the categories you want us to scan for, or select all to detect everything.',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Category cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: _categories.entries.map((entry) {
              return _buildCategoryCard(colors, entry.key, entry.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectingStep(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Scanning Your System',
            style: TextStyles.pageTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'Detecting installed tools and applications...',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _buildDetectionProgress(colors, 'Development Tools', true),
                _buildDetectionProgress(colors, 'Web Browsers', true),
                _buildDetectionProgress(colors, 'Productivity Apps', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_detectionResult == null) return const SizedBox();

    // Filter detections by category
    final filteredDetections = _getFilteredDetections();
    
    // Sort detections: found items first
    final sortedDetections = filteredDetections.entries.toList()
      ..sort((a, b) {
        if (a.value != b.value) {
          return b.value ? -1 : 1; // Found items first
        }
        return a.key.compareTo(b.key);
      });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: AsmblButton.secondary(
                    text: entry.value,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = entry.key;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Results grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: sortedDetections.length,
              itemBuilder: (context, index) {
                final colors = ThemeColors(context);
                final entry = sortedDetections[index];
                final isFound = entry.value;
                return _buildResultCard(colors, entry.key, isFound);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFooter(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (except on first step)
          if (_currentStep != 'overview')
            AsmblButton.secondary(
              text: 'Back',
              onPressed: _goToPreviousStep,
            )
          else
            const SizedBox(),
          
          // Forward/Action buttons
          Row(
            children: [
              AsmblButton.secondary(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 16),
              if (_currentStep == 'overview')
                AsmblButton.primary(
                  text: 'Get Started',
                  onPressed: () => setState(() => _currentStep = 'categories'),
                )
              else if (_currentStep == 'categories')
                AsmblButton.primary(
                  text: 'Start Detection',
                  onPressed: _startDetection,
                )
              else if (_currentStep == 'results')
                AsmblButton.primary(
                  text: 'Complete Setup',
                  onPressed: () {
                    if (_detectionResult != null) {
                      widget.onComplete?.call(_detectionResult!);
                    } else {
                      // If nothing detected, still call with empty result
                      widget.onComplete?.call(const SimpleDetectionResult(detections: {}, totalFound: 0, confidence: 0));
                    }
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getStepTitle() {
    switch (_currentStep) {
      case 'overview':
        return 'Welcome to Auto-Detection';
      case 'categories':
        return 'Choose Detection Categories';
      case 'detecting':
        return 'Scanning System';
      case 'results':
        return 'Detection Results';
      default:
        return 'Auto-Detection';
    }
  }
  
  String _getStepDescription() {
    switch (_currentStep) {
      case 'overview':
        return 'Automatically detect and configure your development tools';
      case 'categories':
        return 'Select the types of tools you want us to find';
      case 'detecting':
        return 'Please wait while we scan your system';
      case 'results':
        return 'Review and configure the tools we found';
      default:
        return '';
    }
  }
  
  void _goToPreviousStep() {
    setState(() {
      switch (_currentStep) {
        case 'categories':
          _currentStep = 'overview';
          break;
        case 'detecting':
          _currentStep = 'categories';
          break;
        case 'results':
          _currentStep = 'categories';
          break;
      }
    });
  }
  
  Map<String, bool> _getFilteredDetections() {
    if (_detectionResult == null || _selectedCategory == 'all') {
      return _detectionResult?.detections ?? {};
    }
    
    // Simple category filtering based on tool names
    final filtered = <String, bool>{};
    _detectionResult!.detections.forEach((key, value) {
      switch (_selectedCategory) {
        case 'development':
          if (key.contains('VS Code') || key.contains('Git') || key.contains('GitHub') || 
              key.contains('Node.js') || key.contains('Python') || key.contains('Docker')) {
            filtered[key] = value;
          }
          break;
        case 'browsers':
          if (key.contains('Chrome') || key.contains('Firefox') || key.contains('Safari') || 
              key.contains('Edge') || key.contains('Brave')) {
            filtered[key] = value;
          }
          break;
        case 'productivity':
          // Add productivity tools here
          break;
      }
    });
    return filtered;
  }
  
  Widget _buildProgressStep(ThemeColors colors, String title, String step, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _getStepIndex(_currentStep) > _getStepIndex(step);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                ? Colors.green
                : isActive
                  ? colors.primary
                  : colors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              size: 12,
              color: isCompleted || isActive
                ? Colors.white
                : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyles.bodySmall.copyWith(
              color: isActive
                ? colors.onSurface
                : colors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  int _getStepIndex(String step) {
    switch (step) {
      case 'overview': return 0;
      case 'categories': return 1;
      case 'detecting': return 2;
      case 'results': return 3;
      default: return 0;
    }
  }
  
  Widget _buildCategoryFilter(ThemeColors colors, String key, String label) {
    final isSelected = _selectedCategory == key;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(key),
                size: 16,
                color: isSelected
                  ? colors.primary
                  : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: isSelected
                    ? colors.primary
                    : colors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all': return Icons.auto_fix_high;
      case 'development': return Icons.code;
      case 'browsers': return Icons.web;
      case 'productivity': return Icons.work;
      default: return Icons.category;
    }
  }
  
  Widget _buildFeatureCard(ThemeColors colors, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(ThemeColors colors, String key, String label) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
            ? colors.primary.withValues(alpha: 0.1)
            : colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
              ? colors.primary
              : colors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(key),
              color: isSelected
                ? colors.primary
                : colors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: isSelected
                  ? colors.primary
                  : colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetectionProgress(ThemeColors colors, String label, bool isComplete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isComplete
                ? Colors.green
                : colors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isComplete
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : const SizedBox(),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isComplete
                ? Colors.green.shade700
                : colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (!isComplete)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(ThemeColors colors, String name, bool isFound) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFound
          ? Colors.green.withValues(alpha: 0.05)
          : colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFound
            ? Colors.green.withValues(alpha: 0.3)
            : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isFound
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isFound ? Icons.check : Icons.close,
              color: isFound ? Colors.green.shade700 : Colors.grey,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyles.bodySmall.copyWith(
                color: isFound
                  ? colors.onSurface
                  : colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _currentStep = 'detecting';
    });

    try {
      final detectionService = ref.read(simpleDetectionServiceProvider);
      _detectionResult = await detectionService.detectBasicTools();
      
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
}