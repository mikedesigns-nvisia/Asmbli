import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/agent_config.dart';
import '../models/extension.dart';
import '../services/extension_service.dart';
import '../services/agent_builder_service.dart';

class AsmbliAgentBuilder extends StatefulWidget {
  final Function(dynamic)? onDeploy;
  final VoidCallback? onBack;
  
  const AsmbliAgentBuilder({super.key, this.onDeploy, this.onBack});

  @override
  State<AsmbliAgentBuilder> createState() => _AsmbliAgentBuilderState();
}

class _AsmbliAgentBuilderState extends State<AsmbliAgentBuilder> with TickerProviderStateMixin {
  late TabController _tabController;
  late AgentConfig _config;
  List<Extension> _allExtensions = [];
  Map<String, List<Extension>> _groupedExtensions = {};
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _config = AgentBuilderService.createDefaultConfig();
    _loadExtensions();
  }

  Future<void> _loadExtensions() async {
    try {
      final extensions = await ExtensionService.loadExtensions();
      setState(() {
        _allExtensions = extensions;
        _groupedExtensions = ExtensionService.groupExtensionsByCategory(extensions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF8F9FE),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0A0E27), const Color(0xFF1A1F3A)]
              : [const Color(0xFFF8F9FE), const Color(0xFFE8ECFD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildExtensionsTab(),
                    _buildConfigurationTab(),
                    _buildDeployTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent Builder',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0A0E27),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your custom AI agent with MCP extensions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        TextButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.save_outlined, size: 20),
          label: const Text('Save Draft'),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _handleDeploy,
          icon: const Icon(Icons.rocket_launch, size: 20),
          label: const Text('Deploy Agent'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Profile', icon: Icon(Icons.person_outline, size: 20)),
          Tab(text: 'Extensions', icon: Icon(Icons.extension, size: 20)),
          Tab(text: 'Configuration', icon: Icon(Icons.settings_outlined, size: 20)),
          Tab(text: 'Deploy', icon: Icon(Icons.rocket_launch_outlined, size: 20)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Agent Identity', 'Define your agent\'s basic information'),
          const SizedBox(height: 24),
          
          _buildInputField(
            controller: _nameController,
            label: 'Agent Name',
            hint: 'e.g., DevOps Assistant',
            icon: Icons.badge_outlined,
            onChanged: (value) => setState(() {
              _config = _config.copyWith(agentName: value);
            }),
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Brief description of what your agent does',
            icon: Icons.description_outlined,
            maxLines: 3,
            onChanged: (value) => setState(() {
              _config = _config.copyWith(agentDescription: value);
            }),
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _purposeController,
            label: 'Primary Purpose',
            hint: 'What is the main goal of this agent?',
            icon: Icons.flag_outlined,
            maxLines: 2,
            onChanged: (value) => setState(() {
              _config = _config.copyWith(primaryPurpose: value);
            }),
          ),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Agent Role', 'Select the primary role for your agent'),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Target Environment', 'Where will this agent be deployed?'),
          const SizedBox(height: 16),
          _buildEnvironmentSelector(),
        ],
      ),
    );
  }

  Widget _buildExtensionsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        _buildExtensionHeader(),
        Expanded(
          child: _buildExtensionGrid(),
        ),
      ],
    );
  }

  Widget _buildExtensionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSearchBar(),
              ),
              const SizedBox(width: 16),
              _buildCategoryFilter(),
            ],
          ),
          const SizedBox(height: 16),
          _buildExtensionStats(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onChanged: (value) => setState(() {
          _searchQuery = value;
        }),
        decoration: InputDecoration(
          hintText: 'Search extensions...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['all', 'core', 'development', 'database', 'communication', 'productivity', 'cloud', 'ai'];
    
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: const Icon(Icons.filter_list, size: 20),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          dropdownColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          onChanged: (value) => setState(() {
            _selectedCategory = value ?? 'all';
          }),
          items: categories.map((category) => DropdownMenuItem(
            value: category,
            child: Text(category.toUpperCase()),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildExtensionStats() {
    final selectedCount = _config.extensions.where((e) => e.enabled).length;
    final totalCount = _allExtensions.length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$selectedCount selected · $totalCount available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _config = _config.copyWith(extensions: []);
          }),
          child: const Text('Clear All'),
        ),
      ],
    );
  }

  Widget _buildExtensionGrid() {
    List<Extension> filteredExtensions = _allExtensions;
    
    // Apply category filter
    if (_selectedCategory != 'all') {
      filteredExtensions = filteredExtensions.where((e) => e.category == _selectedCategory).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredExtensions = filteredExtensions.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.description.toLowerCase().contains(query) ||
        e.category.toLowerCase().contains(query)
      ).toList();
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 180,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredExtensions.length,
      itemBuilder: (context, index) {
        final extension = filteredExtensions[index];
        return _buildExtensionCard(extension);
      },
    );
  }

  Widget _buildExtensionCard(Extension extension) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _config.extensions.any((e) => e.id == extension.id && e.enabled);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
          ? const Color(0xFF6366F1).withValues(alpha: 0.1)
          : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
            ? const Color(0xFF6366F1)
            : isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleExtension(extension),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(extension.category).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getExtensionIcon(extension.icon ?? 'extension'),
                        color: _getCategoryColor(extension.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            extension.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            extension.provider,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  extension.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildMiniTag(extension.complexity.name, _getComplexityColor(extension.complexity)),
                    const SizedBox(width: 8),
                    _buildMiniTag(extension.category, _getCategoryColor(extension.category)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConfigurationTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Response Settings', 'Configure how your agent responds'),
          const SizedBox(height: 24),
          
          _buildSliderSetting(
            'Response Length',
            'Maximum words per response',
            _config.responseLength.toDouble(),
            100,
            2000,
            (value) => setState(() {
              _config = _config.copyWith(responseLength: value.round());
            }),
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Security Settings', 'Configure security and access controls'),
          const SizedBox(height: 24),
          
          _buildSwitchSetting(
            'Rate Limiting',
            'Prevent abuse by limiting requests',
            _config.security.rateLimiting,
            (value) => setState(() {
              _config = _config.copyWith(
                security: _config.security.copyWith(rateLimiting: value),
              );
            }),
          ),
          
          _buildSwitchSetting(
            'Audit Logging',
            'Log all interactions for review',
            _config.security.auditLogging,
            (value) => setState(() {
              _config = _config.copyWith(
                security: _config.security.copyWith(auditLogging: value),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: const Color(0xFF6366F1).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Deploy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your agent configuration is ready. Click deploy to generate the ChatMCP package.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleDeploy,
              icon: const Icon(Icons.download),
              label: const Text('Generate Package'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionTitle(String title, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0A0E27),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      {'role': AgentRole.developer, 'icon': Icons.code, 'label': 'Developer'},
      {'role': AgentRole.analyst, 'icon': Icons.analytics, 'label': 'Analyst'},
      {'role': AgentRole.assistant, 'icon': Icons.support_agent, 'label': 'Assistant'},
      {'role': AgentRole.creative, 'icon': Icons.palette, 'label': 'Creative'},
      {'role': AgentRole.specialist, 'icon': Icons.science, 'label': 'Specialist'},
    ];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: roles.map((item) {
        final isSelected = _config.role == item['role'];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return InkWell(
          onTap: () => setState(() {
            _config = _config.copyWith(role: item['role'] as AgentRole);
          }),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                  ? const Color(0xFF6366F1)
                  : isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: isSelected ? const Color(0xFF6366F1) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF6366F1) : null,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnvironmentSelector() {
    final environments = [
      {'env': TargetEnvironment.development, 'icon': Icons.code, 'label': 'Development'},
      {'env': TargetEnvironment.staging, 'icon': Icons.preview, 'label': 'Staging'},
      {'env': TargetEnvironment.production, 'icon': Icons.rocket_launch, 'label': 'Production'},
    ];
    
    return Row(
      children: environments.map((item) {
        final isSelected = _config.targetEnvironment == item['env'];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() {
                _config = _config.copyWith(targetEnvironment: item['env'] as TargetEnvironment);
              }),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                    : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                      ? const Color(0xFF6366F1)
                      : isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: isSelected ? const Color(0xFF6366F1) : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF6366F1) : null,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Text(
                '${value.round()} words',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF6366F1),
              overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 100).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _toggleExtension(Extension extension) {
    setState(() {
      final existingIndex = _config.extensions.indexWhere((e) => e.id == extension.id);
      if (existingIndex != -1) {
        // Update existing extension using copyWith
        _config.extensions[existingIndex] = _config.extensions[existingIndex].copyWith(
          enabled: !_config.extensions[existingIndex].enabled,
        );
      } else {
        // Add new extension with enabled = true
        final newExt = extension.copyWith(enabled: true);
        _config.extensions.add(newExt);
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'core': return const Color(0xFF10B981);
      case 'development': return const Color(0xFF3B82F6);
      case 'database': return const Color(0xFFF59E0B);
      case 'communication': return const Color(0xFF8B5CF6);
      case 'productivity': return const Color(0xFFEC4899);
      case 'cloud': return const Color(0xFF06B6D4);
      case 'ai': return const Color(0xFFF97316);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _getComplexityColor(ExtensionComplexity complexity) {
    switch (complexity) {
      case ExtensionComplexity.low: return const Color(0xFF10B981);
      case ExtensionComplexity.medium: return const Color(0xFFF59E0B);
      case ExtensionComplexity.high: return const Color(0xFFEF4444);
    }
  }

  IconData _getExtensionIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'folder': return Icons.folder_outlined;
      case 'github': return Icons.code;
      case 'globe': return Icons.language;
      case 'database': return Icons.storage;
      case 'save': return Icons.save_outlined;
      case 'message': return Icons.message_outlined;
      case 'container': return Icons.widgets_outlined;
      case 'cloud': return Icons.cloud_outlined;
      case 'drive': return Icons.drive_file_move_outlined;
      case 'payment': return Icons.payment_outlined;
      case 'note': return Icons.note_outlined;
      case 'task': return Icons.task_outlined;
      case 'cache': return Icons.cached_outlined;
      case 'cluster': return Icons.hub_outlined;
      case 'search': return Icons.search_outlined;
      case 'brain': return Icons.psychology_outlined;
      case 'chat': return Icons.chat_outlined;
      case 'phone': return Icons.phone_outlined;
      case 'email': return Icons.email_outlined;
      case 'shop': return Icons.shopping_cart_outlined;
      case 'gitlab': return Icons.merge_outlined;
      case 'table': return Icons.table_chart_outlined;
      case 'firebase': return Icons.local_fire_department_outlined;
      default: return Icons.extension_outlined;
    }
  }

  Future<void> _handleSave() async {
    try {
      await AgentBuilderService.saveAgentConfig(_config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent configuration saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _handleDeploy() async {
    final errors = AgentBuilderService.validateConfig(_config);
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }

    try {
      final package = await AgentBuilderService.generateChatMCPPackage(_config);
      if (mounted) {
        _showDeploymentDialog(package);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeploymentDialog(ChatMCPPackage package) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Agent Package Generated',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      package.config.toJsonString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: package.config.toJsonString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configuration copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy to Clipboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}