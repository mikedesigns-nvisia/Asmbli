import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/ui/button.dart';

/// Navigation component that matches the web app's header design
/// Includes the Asmbli brand, navigation links, and CTA button
class AsmblNavigation extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? backHref;
  final String? backLabel;

  const AsmblNavigation({
    super.key,
    this.showBackButton = false,
    this.backHref,
    this.backLabel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }

  bool _isActive(BuildContext context, String path) {
    return _getCurrentRoute(context) == path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute = _getCurrentRoute(context);
    
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Back button if needed
          if (showBackButton) ...[
            AsmblGhostButton(
              text: '← ${backLabel ?? 'Home'}',
              onPressed: () => context.go(backHref ?? '/'),
              size: AsmblButtonSize.small,
            ),
            const SizedBox(width: 16),
          ],
          
          // Brand logo
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(4),
              hoverColor: theme.colorScheme.primary.withOpacity(0.08),
              splashColor: theme.colorScheme.primary.withOpacity(0.16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  'Asmbli',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Space Grotesk',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Navigation actions
      actions: [
        // Desktop navigation links
        _NavLink(
          text: 'Templates',
          path: '/templates',
          isActive: _isActive(context, '/templates'),
          onTap: () => context.go('/templates'),
        ),
        const SizedBox(width: 24),
        
        _NavLink(
          text: 'Library',
          path: '/library',
          isActive: _isActive(context, '/library') || _isActive(context, '/agents'),
          onTap: () => context.go('/agents'),
        ),
        const SizedBox(width: 24),
        
        _NavLink(
          text: 'Dashboard',
          path: '/dashboard',
          isActive: _isActive(context, '/dashboard') || _isActive(context, '/settings'),
          onTap: () => context.go('/settings'),
        ),
        const SizedBox(width: 32),
        
        // CTA Button
        AsmblPrimaryButton(
          text: 'Start Building',
          onPressed: () => context.go('/wizard'),
          size: AsmblButtonSize.medium,
        ),
        const SizedBox(width: 16),
      ],
      
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.colorScheme.background.withOpacity(0.95),
      foregroundColor: theme.colorScheme.onSurface,
    );
  }
}

/// Navigation link component
class _NavLink extends StatelessWidget {
  final String text;
  final String path;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.text,
    required this.path,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: theme.colorScheme.primary.withOpacity(0.08),
        splashColor: theme.colorScheme.primary.withOpacity(0.16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive 
                    ? theme.colorScheme.primary 
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Space Grotesk',
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive 
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile navigation drawer (for smaller screens)
class AsmblMobileNavigation extends StatelessWidget {
  const AsmblMobileNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with brand
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Asmbli',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ),
            
            const Divider(),
            
            // Navigation items
            _MobileNavItem(
              title: 'Templates',
              icon: Icons.library_books,
              onTap: () {
                Navigator.pop(context);
                context.go('/templates');
              },
            ),
            _MobileNavItem(
              title: 'Library',
              icon: Icons.extension,
              onTap: () {
                Navigator.pop(context);
                context.go('/agents');
              },
            ),
            _MobileNavItem(
              title: 'Dashboard',
              icon: Icons.dashboard,
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            
            const Spacer(),
            
            // CTA Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: AsmblPrimaryButton(
                text: 'Start Building',
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/wizard');
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile navigation item
class _MobileNavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}