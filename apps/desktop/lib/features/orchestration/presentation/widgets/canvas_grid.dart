import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// Canvas grid painter for visual alignment and spatial reference
class CanvasGridPainter extends CustomPainter {
  final ThemeColors colors;
  final double zoom;
  final double gridSize;

  CanvasGridPainter({
    required this.colors,
    required this.zoom,
    this.gridSize = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.border.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Adjust grid density based on zoom level
    final effectiveGridSize = gridSize * zoom;
    
    // Don't draw grid if too dense or too sparse
    if (effectiveGridSize < 5 || effectiveGridSize > 100) return;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += effectiveGridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += effectiveGridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw origin indicator (slightly thicker lines at 0,0)
    if (size.width > 0 && size.height > 0) {
      final originPaint = Paint()
        ..color = colors.border.withOpacity(0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Find the origin position (accounting for pan/zoom)
      const origin = Offset(2500, 2500); // Center of our 5000x5000 canvas
      
      if (origin.dx >= 0 && origin.dx <= size.width) {
        canvas.drawLine(
          Offset(origin.dx, 0),
          Offset(origin.dx, size.height),
          originPaint,
        );
      }
      
      if (origin.dy >= 0 && origin.dy <= size.height) {
        canvas.drawLine(
          Offset(0, origin.dy),
          Offset(size.width, origin.dy),
          originPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CanvasGridPainter oldDelegate) {
    return colors != oldDelegate.colors || 
           zoom != oldDelegate.zoom ||
           gridSize != oldDelegate.gridSize;
  }
}