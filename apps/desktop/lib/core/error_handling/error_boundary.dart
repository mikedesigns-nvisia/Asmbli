import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/design_system.dart';
import 'global_error_handler.dart';

class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorContext;
  final bool reportErrors;
  final VoidCallback? onError;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorContext,
    this.reportErrors = true,
    this.onError,
  });
  
  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    // Error zone is set up at the app level in main.dart
  }
  
  void _handleError(Object error, StackTrace stackTrace) {
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
      
      // Report to global error handler
      if (widget.reportErrors) {
        final errorHandler = ref.read(globalErrorHandlerProvider.notifier);
        errorHandler.reportError(
          error,
          stackTrace,
          context: widget.errorContext,
          level: ErrorLevel.error,
        );
      }
      
      // Call custom error callback
      widget.onError?.call();
    }
  }
  
  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _DefaultErrorWidget(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: _retry,
        context: widget.errorContext,
      );
    }
    
    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;
  final String? context;
  
  const _DefaultErrorWidget({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
    this.context,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isDevelopment = kDebugMode;
    
    return AsmblCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.error.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: colors.error,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Error title
          Text(
            'Something went wrong',
            style: TextStyles.cardTitle.copyWith(
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          // Context information
          if (this.context != null) ...[
            Text(
              'Error in: ${this.context}',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
          
          // Error message (simplified for users)
          Text(
            _getSimplifiedErrorMessage(error),
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Development mode: show technical details
          if (isDevelopment) ...[
            const SizedBox(height: SpacingTokens.lg),
            ExpansionTile(
              title: Text(
                'Technical Details',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  margin: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error:',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        error.toString(),
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (stackTrace != null) ...[
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'Stack Trace:',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          stackTrace.toString(),
                          style: TextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AsmblButton.secondary(
                text: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
              const SizedBox(width: SpacingTokens.md),
              AsmblButton.secondary(
                text: 'Report Issue',
                icon: Icons.bug_report,
                onPressed: () => _reportError(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getSimplifiedErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'Storage error. Please check available disk space.';
    } else if (errorString.contains('memory')) {
      return 'Memory issue. Try closing other applications.';
    } else if (errorString.contains('invalid') || errorString.contains('format')) {
      return 'Invalid data format. Please try refreshing.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
  
  void _reportError(BuildContext context) {
    // Show dialog for error reporting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Error'),
        content: const Text(
          'Error details have been logged. If this problem persists, '
          'please contact support or file an issue on GitHub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Specialized error boundaries for different app sections
class NavigationErrorBoundary extends ErrorBoundary {
  NavigationErrorBoundary({
    super.key,
    required super.child,
  }) : super(
          errorContext: 'Navigation',
          fallback: const _NavigationErrorFallback(),
        );
}

class ChatErrorBoundary extends ErrorBoundary {
  ChatErrorBoundary({
    super.key,
    required super.child,
  }) : super(
          errorContext: 'Chat',
          fallback: const _ChatErrorFallback(),
        );
}

class SettingsErrorBoundary extends ErrorBoundary {
  SettingsErrorBoundary({
    super.key,
    required super.child,
  }) : super(
          errorContext: 'Settings',
          fallback: const _SettingsErrorFallback(),
        );
}

class StorageErrorBoundary extends ErrorBoundary {
  StorageErrorBoundary({
    super.key,
    required super.child,
  }) : super(
          errorContext: 'Storage',
          fallback: const _StorageErrorFallback(),
        );
}

// Specialized fallback widgets
class _NavigationErrorFallback extends StatelessWidget {
  const _NavigationErrorFallback();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.navigation,
              size: 64,
              color: ThemeColors(context).error,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Navigation Error',
              style: TextStyles.pageTitle.copyWith(
                color: ThemeColors(context).onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Unable to navigate to the requested page',
              style: TextStyles.bodyMedium.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            AsmblButton.primary(
              text: 'Go Home',
              icon: Icons.home,
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatErrorFallback extends StatelessWidget {
  const _ChatErrorFallback();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: ThemeColors(context).error,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Chat Unavailable',
            style: TextStyles.cardTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'There was an error loading the chat interface',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsErrorFallback extends StatelessWidget {
  const _SettingsErrorFallback();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: ThemeColors(context).error,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Settings Error',
            style: TextStyles.cardTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Unable to load settings. Your preferences may be temporarily unavailable.',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StorageErrorFallback extends StatelessWidget {
  const _StorageErrorFallback();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 48,
            color: ThemeColors(context).error,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Storage Error',
            style: TextStyles.cardTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Unable to access local storage. Please check available disk space.',
            style: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}