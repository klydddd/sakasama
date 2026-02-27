import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Formats ML Kit's [RecognizedText] into a spatial layout string that
/// preserves the visual structure of the receipt.
///
/// Both Gemini Nano and GGUF strategies receive this formatted text,
/// which is far more useful than a flat text dump because it retains
/// positional context (top/middle/bottom zones, column alignment).
class SpatialTextFormatter {
  SpatialTextFormatter._();

  /// Format [RecognizedText] into a spatial layout string.
  ///
  /// Output example:
  /// ```
  /// [TOP] Receipt #571
  /// [TOP] Store details
  /// [TOP] Lyka's Clothing
  /// [MID] Item list | Amount | Price per unit | Price
  /// [MID] 1. Wavy Silk Dress - brown (SK1) | 1 | 450.00 PHP
  /// [BOT] Total | 959.00 PHP
  /// [BOT] Date 23/12/2022
  /// ```
  static String format(RecognizedText recognized) {
    final blocks = recognized.blocks;
    if (blocks.isEmpty) return recognized.text;

    // Collect all lines with bounding box positions
    final lines = <_PositionedLine>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        lines.add(
          _PositionedLine(
            text: line.text.trim(),
            top: line.boundingBox.top,
            left: line.boundingBox.left,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
        );
      }
    }

    if (lines.isEmpty) return recognized.text;

    // Sort by vertical position (top-to-bottom)
    lines.sort((a, b) => a.top.compareTo(b.top));

    // Calculate zone boundaries (top 25%, middle 50%, bottom 25%)
    final minY = lines.first.top;
    final maxY = lines.last.bottom;
    final height = maxY - minY;
    final topThreshold = minY + height * 0.25;
    final bottomThreshold = minY + height * 0.75;

    // Group lines on the same row (similar Y position → likely in same row)
    final rows = _groupIntoRows(lines);

    // Build formatted output
    final buffer = StringBuffer();
    for (final row in rows) {
      // Determine zone
      final avgTop = row.map((l) => l.top).reduce((a, b) => a + b) / row.length;
      final zone = avgTop < topThreshold
          ? 'TOP'
          : avgTop > bottomThreshold
          ? 'BOT'
          : 'MID';

      // Sort columns left-to-right within the row
      row.sort((a, b) => a.left.compareTo(b.left));

      // Join columns with ' | '
      final content = row.map((l) => l.text).join(' | ');
      buffer.writeln('[$zone] $content');
    }

    return buffer.toString().trimRight();
  }

  /// Group lines into rows based on vertical overlap.
  ///
  /// Lines whose Y-positions are within a threshold are considered
  /// the same row (e.g., "Amount" and "Price" columns on the same line).
  static List<List<_PositionedLine>> _groupIntoRows(
    List<_PositionedLine> lines,
  ) {
    if (lines.isEmpty) return [];

    final rows = <List<_PositionedLine>>[];
    var currentRow = <_PositionedLine>[lines.first];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final prevLine = currentRow.last;

      // If this line's top is close to the previous line's top,
      // they're on the same row
      final rowHeight = prevLine.bottom - prevLine.top;
      final threshold = rowHeight > 0 ? rowHeight * 0.6 : 15.0;

      if ((line.top - prevLine.top).abs() < threshold) {
        currentRow.add(line);
      } else {
        rows.add(currentRow);
        currentRow = [line];
      }
    }
    rows.add(currentRow);

    return rows;
  }
}

class _PositionedLine {
  const _PositionedLine({
    required this.text,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double top;
  final double left;
  final double right;
  final double bottom;
}
