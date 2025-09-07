import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_catalog_integration_test.dart';
import '../../../../core/services/mcp_catalog_service.dart';
import '../../../../core/services/secure_credentials_service.dart';

/// Debug panel for testing MCP catalog functionality
/// This widget provides debugging and testing tools for the MCP system
class MCPDebugPanel extends ConsumerStatefulWidget {
  const MCPDebugPanel({super.key});

  @override
  ConsumerState<MCPDebugPanel> createState() => _MCPDebugPanelState();
}

class _MCPDebugPanelState extends ConsumerState<MCPDebugPanel> {
  bool _isRunningTest = false;
  MCPIntegrationTestResult? _lastTestResult;
  String? _debugOutput;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bug_report, color: colors.accent, size: 20),
                SizedBox(width: SpacingTokens.sm),
                Text(
                  'MCP Debug Panel',
                  style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
                ),
                const Spacer(),
                if (_isRunningTest)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: SpacingTokens.md),
            
            // Test controls
            _buildTestControls(colors),
            
            if (_lastTestResult != null) ...[
              SizedBox(height: SpacingTokens.lg),
              _buildTestResults(colors),
            ],
            
            if (_debugOutput != null) ...[
              SizedBox(height: SpacingTokens.lg),
              _buildDebugOutput(colors),
            ],
            
            SizedBox(height: SpacingTokens.lg),
            _buildSystemInfo(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControls(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Testing Controls',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        SizedBox(height: SpacingTokens.sm),
        
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: [
            AsmblButton.secondary(
              text: 'Run Smoke Test',
              onPressed: _isRunningTest ? null : _runSmokeTest,
              icon: Icons.speed,
            ),
            AsmblButton.primary(
              text: 'Run Full Integration Test',
              onPressed: _isRunningTest ? null : _runFullTest,
              icon: Icons.play_arrow,
            ),
            AsmblButton.secondary(
              text: 'Clear Results',
              onPressed: _clearResults,
              icon: Icons.clear,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestResults(ThemeColors colors) {
    final result = _lastTestResult!;
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: result.success 
            ? colors.primary.withOpacity(0.05) 
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: result.success 
              ? colors.primary.withOpacity(0.2) 
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? colors.primary : Colors.red,
                size: 16,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Test Results: ${result.success ? "PASSED" : "FAILED"}',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: result.success ? colors.primary : Colors.red,
                ),
              ),
              const Spacer(),
              Text(
                'Success Rate: ${(result.successRate * 100).toStringAsFixed(1)}%',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          
          if (result.successes.isNotEmpty) ...[
            _buildResultSection('Successes', result.successes, colors.primary, colors),
            SizedBox(height: SpacingTokens.sm),
          ],
          
          if (result.warnings.isNotEmpty) ...[
            _buildResultSection('Warnings', result.warnings, Colors.orange, colors),
            SizedBox(height: SpacingTokens.sm),
          ],
          
          if (result.errors.isNotEmpty) ...[
            _buildResultSection('Errors', result.errors, Colors.red, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, List<String> items, Color color, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length}):',
          style: TextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: SpacingTokens.xs),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: SpacingTokens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 6),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  item,
                  style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDebugOutput(ThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Output',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                _debugOutput!,
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(ThemeColors colors) {
    final catalogService = ref.read(mcpCatalogServiceProvider);
    final catalogEntries = catalogService.getAllCatalogEntries();
    
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Information',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          _buildInfoRow('Catalog Entries Loaded', '${catalogEntries.length}', colors),
          _buildInfoRow('Featured Entries', '${catalogService.getFeaturedEntries().length}', colors),
          _buildInfoRow('MCP System Status', 'Initialized', colors),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeColors colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyles.caption.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSmokeTest() async {
    setState(() {
      _isRunningTest = true;
      _debugOutput = 'Running smoke test...\n';
    });

    try {
      final testService = ref.read(mcpIntegrationTestProvider);
      final success = await testService.runSmokeTest();
      
      setState(() {
        _lastTestResult = MCPIntegrationTestResult();
        if (success) {
          _lastTestResult!.successes.add('Smoke test passed - core functionality working');
          _lastTestResult!.success = true;
        } else {
          _lastTestResult!.errors.add('Smoke test failed - check debug output');
        }
        _debugOutput = _debugOutput! + '\nSmoke test completed: ${success ? "PASSED" : "FAILED"}';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = MCPIntegrationTestResult();
        _lastTestResult!.errors.add('Smoke test exception: $e');
        _debugOutput = _debugOutput! + '\nException: $e';
      });
    } finally {
      setState(() => _isRunningTest = false);
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isRunningTest = true;
      _debugOutput = 'Running full integration test...\n';
    });

    try {
      final testResult = await ref.read(mcpIntegrationTestResultProvider.future);
      setState(() {
        _lastTestResult = testResult;
        _debugOutput = _debugOutput! + '\nFull integration test completed';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = MCPIntegrationTestResult();
        _lastTestResult!.errors.add('Integration test exception: $e');
        _debugOutput = _debugOutput! + '\nException: $e';
      });
    } finally {
      setState(() => _isRunningTest = false);
    }
  }

  void _clearResults() {
    setState(() {
      _lastTestResult = null;
      _debugOutput = null;
    });
  }
}