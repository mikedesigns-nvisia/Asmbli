import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import 'dart:convert';

class JsonSyntaxHighlighter extends StatelessWidget {
  final String jsonText;
  final TextStyle? baseStyle;

  const JsonSyntaxHighlighter({
    super.key,
    required this.jsonText,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final style = baseStyle ?? TextStyles.bodySmall.copyWith(fontFamily: 'monospace');
    
    try {
      if (jsonText.trim().isEmpty) {
        return Text(
          jsonText,
          style: style.copyWith(color: colors.onSurfaceVariant.withOpacity(0.6)),
        );
      }

      // Try to parse JSON to validate it's properly formatted
      final json = jsonDecode(jsonText);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(json);
      
      return RichText(
        text: TextSpan(
          style: style.copyWith(color: colors.onSurface),
          children: _buildHighlightedSpans(prettyJson, colors),
        ),
      );
    } catch (e) {
      // If it's not valid JSON, just show plain text with error color
      return Text(
        jsonText,
        style: style.copyWith(color: colors.error.withOpacity(0.8)),
      );
    }
  }

  List<TextSpan> _buildHighlightedSpans(String json, ThemeColors colors) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'("(?:[^"\\]|\\.)*")|(\btrue\b|\bfalse\b|\bnull\b)|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|([{}[\],:])',
    );

    int lastEnd = 0;

    for (final match in regex.allMatches(json)) {
      // Add text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: json.substring(lastEnd, match.start),
          style: TextStyle(color: colors.onSurface),
        ));
      }

      final matchedText = match.group(0)!;
      
      if (match.group(1) != null) {
        // String literal
        final isKey = _isJsonKey(json, match.start);
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: isKey ? colors.primary : colors.success,
            fontWeight: isKey ? FontWeight.w600 : FontWeight.normal,
          ),
        ));
      } else if (match.group(2) != null) {
        // Boolean or null
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: colors.accent,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (match.group(3) != null) {
        // Number
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: colors.info,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (match.group(4) != null) {
        // Punctuation
        spans.add(TextSpan(
          text: matchedText,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < json.length) {
      spans.add(TextSpan(
        text: json.substring(lastEnd),
        style: TextStyle(color: colors.onSurface),
      ));
    }

    return spans;
  }

  bool _isJsonKey(String json, int position) {
    // Check if this string is followed by a colon (making it a key)
    final afterString = json.indexOf(':', position);
    final nextString = json.indexOf('"', position + 1);
    
    if (afterString == -1) return false;
    if (nextString != -1 && nextString < afterString) return false;
    
    // Make sure there's nothing but whitespace between the string and colon
    final between = json.substring(position + json.substring(position).indexOf('"') + 1, afterString);
    return between.trim().isEmpty;
  }
}