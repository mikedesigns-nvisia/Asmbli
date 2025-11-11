import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/design_system.dart';

/// Modern command palette (Cmd+K) for keyboard-first navigation
class CommandPalette extends StatefulWidget {
  final Function(CommandAction) onActionSelected;
  final List<CommandAction> availableActions;
  
  const CommandPalette({
    super.key,
    required this.onActionSelected,
    required this.availableActions,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommandAction> _filteredActions = [];
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _filteredActions = widget.availableActions;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    // Auto-focus search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    _searchController.addListener(_filterActions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterActions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredActions = widget.availableActions;
      } else {
        _filteredActions = widget.availableActions
            .where((action) =>
                action.title.toLowerCase().contains(query) ||
                action.description.toLowerCase().contains(query) ||
                action.keywords.any((keyword) => keyword.toLowerCase().contains(query)))
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  void _executeSelectedAction() {
    if (_filteredActions.isNotEmpty && _selectedIndex < _filteredActions.length) {
      widget.onActionSelected(_filteredActions[_selectedIndex]);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 500),
              child: Card(
                elevation: 20,
                shadowColor: colors.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search input
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.border),
                        ),
                      ),
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                            setState(() {
                              _selectedIndex = (_selectedIndex + 1).clamp(0, _filteredActions.length - 1);
                            });
                          },
                          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                            setState(() {
                              _selectedIndex = (_selectedIndex - 1).clamp(0, _filteredActions.length - 1);
                            });
                          },
                          const SingleActivator(LogicalKeyboardKey.enter): _executeSelectedAction,
                          const SingleActivator(LogicalKeyboardKey.escape): () {
                            Navigator.of(context).pop();
                          },
                        },
                        child: Focus(
                          autofocus: true,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type a command or search...',
                              hintStyle: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: colors.primary,
                                size: 20,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ESC',
                                      style: TextStyles.bodySmall.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Results
                    if (_filteredActions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              color: colors.onSurfaceVariant,
                              size: 32,
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            Text(
                              'No results found',
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                          itemCount: _filteredActions.length,
                          itemBuilder: (context, index) {
                            final action = _filteredActions[index];
                            final isSelected = index == _selectedIndex;
                            
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedIndex = index);
                                  _executeSelectedAction();
                                },
                                onHover: (hovering) {
                                  if (hovering) {
                                    setState(() => _selectedIndex = index);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: SpacingTokens.lg,
                                    vertical: SpacingTokens.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? Border(
                                            left: BorderSide(
                                              color: colors.primary,
                                              width: 3,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: action.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          action.icon,
                                          color: action.color,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: SpacingTokens.md),
                                      
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              action.title,
                                              style: TextStyles.bodyMedium.copyWith(
                                                color: isSelected
                                                    ? colors.primary
                                                    : colors.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (action.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                action.description,
                                                style: TextStyles.bodySmall.copyWith(
                                                  color: colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      if (action.shortcut != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            action.shortcut!,
                                            style: TextStyles.bodySmall.copyWith(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Command action data model
class CommandAction {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final String? shortcut;
  final VoidCallback? action;

  const CommandAction({
    required this.id,
    required this.title,
    this.description = '',
    required this.icon,
    required this.color,
    this.keywords = const [],
    this.shortcut,
    this.action,
  });
}

/// Utility to show command palette
class CommandPaletteOverlay {
  static OverlayEntry? _overlayEntry;
  
  static void show(
    BuildContext context, {
    required List<CommandAction> actions,
    required Function(CommandAction) onActionSelected,
  }) {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () => hide(),
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 100),
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping palette
              child: CommandPalette(
                availableActions: actions,
                onActionSelected: (action) {
                  hide();
                  onActionSelected(action);
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}