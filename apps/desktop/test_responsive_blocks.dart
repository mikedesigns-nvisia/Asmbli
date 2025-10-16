import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/core/design_system/design_system.dart';
import 'lib/features/orchestration/models/logic_block.dart';
import 'lib/features/orchestration/presentation/widgets/logic_block_widget.dart';

void main() {
  runApp(const ProviderScope(child: ResponsiveBlockTestApp()));
}

class ResponsiveBlockTestApp extends StatelessWidget {
  const ResponsiveBlockTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Logic Block Test',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ResponsiveBlockTestScreen(),
    );
  }
}

class ResponsiveBlockTestScreen extends StatelessWidget {
  const ResponsiveBlockTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    // Create test blocks with different content lengths
    final testBlocks = [
      LogicBlock(
        id: 'short',
        type: LogicBlockType.goal,
        label: 'Short',
        position: const Position(x: 50, y: 50),
      ),
      LogicBlock(
        id: 'medium',
        type: LogicBlockType.reasoning,
        label: 'Medium Length Text',
        position: const Position(x: 250, y: 50),
      ),
      LogicBlock(
        id: 'long',
        type: LogicBlockType.gateway,
        label: 'Very Long Text That Should Wrap to Multiple Lines',
        position: const Position(x: 50, y: 200),
      ),
      LogicBlock(
        id: 'complex',
        type: LogicBlockType.reasoning,
        label: 'Complex Reasoning Block with Extended Content and Multiple Lines of Text',
        position: const Position(x: 250, y: 200),
      ),
    ];
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Responsive Logic Blocks Test'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Test different block types with varying content lengths:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...testBlocks.map((block) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${block.type.name.toUpperCase()}: "${block.label}"',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LogicBlockWidget(
                      block: block,
                      isSelected: false,
                      isActive: false,
                      isHovered: false,
                      onTap: () {},
                      onDoubleTap: () {},
                      onPanStart: (_) {},
                      onPanUpdate: (_) {},
                      onPanEnd: (_) {},
                      onConnectionStart: (_, __) {},
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}