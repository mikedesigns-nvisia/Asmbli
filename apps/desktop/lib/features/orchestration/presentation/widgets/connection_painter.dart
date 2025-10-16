import 'package:flutter/material.dart';
import '../../models/logic_block.dart';
import '../../models/canvas_state.dart';
import '../../../../core/design_system/design_system.dart';

/// Custom painter for rendering connections between logic blocks
/// Implements dual-flow architecture with execution (thick) and data (colored) flows
class ConnectionPainter extends CustomPainter {
  final List<BlockConnection> connections;
  final List<LogicBlock> blocks;
  final PendingConnection? pendingConnection;
  final ThemeColors colors;

  ConnectionPainter({
    required this.connections,
    required this.blocks,
    this.pendingConnection,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing connections
    for (final connection in connections) {
      _drawConnection(canvas, connection);
    }
    
    // Draw pending connection being created
    if (pendingConnection != null) {
      _drawPendingConnection(canvas, pendingConnection!);
    }
  }

  void _drawConnection(Canvas canvas, BlockConnection connection) {
    final sourceBlock = blocks.where((b) => b.id == connection.sourceBlockId).firstOrNull;
    final targetBlock = blocks.where((b) => b.id == connection.targetBlockId).firstOrNull;
    
    if (sourceBlock == null || targetBlock == null) return;
    
    final sourcePoint = _getConnectionPoint(sourceBlock, connection.sourcePin, isOutput: true);
    final targetPoint = _getConnectionPoint(targetBlock, connection.targetPin, isOutput: false);
    
    _drawBezierConnection(
      canvas,
      sourcePoint,
      targetPoint,
      connection.type,
    );
  }

  void _drawPendingConnection(Canvas canvas, PendingConnection pending) {
    final sourceBlock = blocks.where((b) => b.id == pending.sourceBlockId).firstOrNull;
    if (sourceBlock == null) return;
    
    final sourcePoint = _getConnectionPoint(sourceBlock, pending.sourcePin, isOutput: true);
    final targetPoint = Offset(pending.currentPosition.x, pending.currentPosition.y);
    
    _drawBezierConnection(
      canvas,
      sourcePoint,
      targetPoint,
      pending.type,
      isPending: true,
    );
  }

  void _drawBezierConnection(
    Canvas canvas,
    Offset start,
    Offset end,
    ConnectionType type, {
    bool isPending = false,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Style based on connection type (research recommendation: thick for execution, thin for data)
    if (type == ConnectionType.execution) {
      paint.color = isPending 
          ? colors.onSurface.withValues(alpha: 0.6) 
          : colors.onSurface;
      paint.strokeWidth = isPending ? 2.5 : 3.0;
    } else {
      paint.color = isPending 
          ? colors.primary.withValues(alpha: 0.6) 
          : colors.primary;
      paint.strokeWidth = isPending ? 1.5 : 2.0;
    }

    // Create curved path for better visual flow
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Control points for smooth curve
    final controlDistance = (end.dx - start.dx).abs() * 0.5;
    final control1 = Offset(start.dx + controlDistance, start.dy);
    final control2 = Offset(end.dx - controlDistance, end.dy);
    
    path.cubicTo(
      control1.dx, control1.dy,
      control2.dx, control2.dy,
      end.dx, end.dy,
    );
    
    // Draw main connection line
    canvas.drawPath(path, paint);
    
    // Draw arrow for execution flow
    if (type == ConnectionType.execution && !isPending) {
      _drawArrowHead(canvas, control2, end, paint);
    }
    
    // Draw data flow animation indicators (small circles)
    if (type == ConnectionType.data && !isPending) {
      _drawDataFlowIndicators(canvas, path, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset control, Offset end, Paint paint) {
    // Calculate arrow direction
    final direction = (end - control).normalized;
    final perpendicular = Offset(-direction.dy, direction.dx);
    
    const arrowSize = 8.0;
    final arrowPoint1 = end - direction * arrowSize + perpendicular * (arrowSize * 0.5);
    final arrowPoint2 = end - direction * arrowSize - perpendicular * (arrowSize * 0.5);
    
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawDataFlowIndicators(Canvas canvas, Path path, Paint paint) {
    // Draw small dots along the path to indicate data flow
    final metrics = path.computeMetrics().first;
    const dotCount = 3;
    const dotSize = 2.0;
    
    for (int i = 1; i <= dotCount; i++) {
      final distance = (metrics.length / (dotCount + 1)) * i;
      final tangent = metrics.getTangentForOffset(distance);
      
      if (tangent != null) {
        final dotPaint = Paint()
          ..color = paint.color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(tangent.position, dotSize, dotPaint);
      }
    }
  }

  Offset _getConnectionPoint(LogicBlock block, String pin, {required bool isOutput}) {
    final baseX = block.position.x;
    final baseY = block.position.y;
    
    // Pin positions based on logic block design
    switch (pin) {
      case 'input':
        return Offset(baseX, baseY + block.defaultHeight / 2 - 6);
      case 'output':
        return Offset(baseX + block.defaultWidth, baseY + block.defaultHeight / 2 - 6);
      case 'data_input':
        return Offset(baseX, baseY + block.defaultHeight / 2 + 4);
      case 'data_output':
        return Offset(baseX + block.defaultWidth, baseY + block.defaultHeight / 2 + 4);
      default:
        // Default to center
        return Offset(
          baseX + (isOutput ? block.defaultWidth : 0),
          baseY + block.defaultHeight / 2,
        );
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return connections != oldDelegate.connections ||
           blocks != oldDelegate.blocks ||
           pendingConnection != oldDelegate.pendingConnection;
  }
}

/// Extension for vector operations
extension OffsetExtensions on Offset {
  Offset get normalized {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return this / magnitude;
  }
}