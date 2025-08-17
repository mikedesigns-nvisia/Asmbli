import 'package:flutter/material.dart';
import '../models/extension.dart';
import '../models/agent_config.dart';
import '../services/extension_service.dart';
import '../widgets/extension_card.dart';

class ExtensionsSelectionPage extends StatefulWidget {
  final AgentConfig initialConfig;
  final Function(AgentConfig) onConfigChanged;

  const ExtensionsSelectionPage({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  @override
  State<ExtensionsSelectionPage> createState() => _ExtensionsSelectionPageState();
}

class _ExtensionsSelectionPageState extends State<ExtensionsSelectionPage>
    with TickerProviderStateMixin {
  late AgentConfig _currentConfig;
  List<Extension> _allExtensions = [];
  List<ExtensionCategory> _categories = [];
  List<Extension> _filteredExtensions = [];
  String? _selectedCategory;
  String _searchQuery = '';
  ExtensionComplexity? _maxComplexity;
  ConnectionType? _connectionTypeFilter;
  PricingTier? _pricingFilter;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.initialConfig;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final extensions = await ExtensionService.loadExtensions();
      final categories = await ExtensionService.loadCategories();
      
      setState(() {
        _allExtensions = extensions;
        _categories = categories;
        _isLoading = false;
        _tabController = TabController(length: _categories.length + 1, vsync: this);
      });
      
      _applyFilters();
      
      // Load recommended extensions for the role
      if (_currentConfig.extensions.isEmpty) {
        _loadRecommendedExtensions();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadRecommendedExtensions() {
    final recommended = ExtensionService.getRecommendedExtensionsForRole(
      _allExtensions,
      _currentConfig.role,
    );
    
    final updatedExtensions = List<Extension>.from(_currentConfig.extensions);
    for (final rec in recommended) {
      if (!updatedExtensions.any((ext) => ext.id == rec.id)) {
        updatedExtensions.add(rec.copyWith(enabled: true));
      }
    }
    
    _updateConfig(_currentConfig.copyWith(extensions: updatedExtensions));
  }

  void _applyFilters() {
    _filteredExtensions = ExtensionService.filterExtensions(
      _allExtensions,
      category: _selectedCategory,
      maxComplexity: _maxComplexity,
      connectionType: _connectionTypeFilter,
      pricing: _pricingFilter,
      searchQuery: _searchQuery,
    );
    setState(() {});
  }

  void _updateConfig(AgentConfig newConfig) {
    setState(() {
      _currentConfig = newConfig;
    });
    widget.onConfigChanged(newConfig);
  }

  void _toggleExtension(Extension extension) {
    final updatedExtensions = List<Extension>.from(_currentConfig.extensions);
    final existingIndex = updatedExtensions.indexWhere((ext) => ext.id == extension.id);
    
    if (existingIndex != -1) {
      // Toggle existing extension
      updatedExtensions[existingIndex] = updatedExtensions[existingIndex].copyWith(
        enabled: !updatedExtensions[existingIndex].enabled,
      );
    } else {
      // Add new extension
      updatedExtensions.add(extension.copyWith(enabled: true));
    }
    
    _updateConfig(_currentConfig.copyWith(extensions: updatedExtensions));
  }

  bool _isExtensionSelected(Extension extension) {
    return _currentConfig.extensions.any((ext) => ext.id == extension.id && ext.enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extensions')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading extensions: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Extensions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search extensions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'All'),
                  ..._categories.map((category) => Tab(text: category.name)),
                ],
                onTap: (index) {
                  setState(() {
                    _selectedCategory = index == 0 ? null : _categories[index - 1].name;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Complexity',
                    _maxComplexity?.name ?? 'Any',
                    () => _showComplexityFilter(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Connection',
                    _connectionTypeFilter?.name ?? 'Any',
                    () => _showConnectionTypeFilter(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Pricing',
                    _pricingFilter?.name ?? 'Any',
                    () => _showPricingFilter(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear filters',
                  ),
                ],
              ),
            ),
          ),
          
          // Selected count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_currentConfig.extensions.where((ext) => ext.enabled).length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _currentConfig.extensions.where((ext) => ext.enabled).isNotEmpty
                      ? _clearAllSelections
                      : null,
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          
          // Extensions grid
          Expanded(
            child: _filteredExtensions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No extensions found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredExtensions.length,
                    itemBuilder: (context, index) {
                      final extension = _filteredExtensions[index];
                      return ExtensionCard(
                        extension: extension,
                        isSelected: _isExtensionSelected(extension),
                        onToggle: () => _toggleExtension(extension),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _currentConfig.extensions.where((ext) => ext.enabled).isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              label: Text('Continue (${_currentConfig.extensions.where((ext) => ext.enabled).length})'),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return FilterChip(
      label: Text('$label: $value'),
      onSelected: (_) => onTap(),
      selected: value != 'Any',
    );
  }

  void _showComplexityFilter() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Maximum Complexity'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _maxComplexity = null);
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Any'),
          ),
          ...ExtensionComplexity.values.map((complexity) => SimpleDialogOption(
            onPressed: () {
              setState(() => _maxComplexity = complexity);
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text(complexity.name.toUpperCase()),
          )),
        ],
      ),
    );
  }

  void _showConnectionTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Connection Type'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _connectionTypeFilter = null);
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Any'),
          ),
          ...ConnectionType.values.map((type) => SimpleDialogOption(
            onPressed: () {
              setState(() => _connectionTypeFilter = type);
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text(type.name.toUpperCase()),
          )),
        ],
      ),
    );
  }

  void _showPricingFilter() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pricing'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _pricingFilter = null);
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Any'),
          ),
          ...PricingTier.values.map((pricing) => SimpleDialogOption(
            onPressed: () {
              setState(() => _pricingFilter = pricing);
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text(pricing.name.toUpperCase()),
          )),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _maxComplexity = null;
      _connectionTypeFilter = null;
      _pricingFilter = null;
      _searchQuery = '';
      _selectedCategory = null;
    });
    _applyFilters();
  }

  void _clearAllSelections() {
    final clearedExtensions = _currentConfig.extensions
        .map((ext) => ext.copyWith(enabled: false))
        .toList();
    _updateConfig(_currentConfig.copyWith(extensions: clearedExtensions));
  }
}