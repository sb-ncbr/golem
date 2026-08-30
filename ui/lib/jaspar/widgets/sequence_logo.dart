// sequence_logo.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../motif_logic.dart';
import '../nucleotide_colors.dart';

class SequenceLogo extends StatelessWidget {
  const SequenceLogo({
    super.key,
    required this.motif,
    this.maxHeight = 160,
    this.colWidth =
        76.0, // Odpovídá šířce sloupce v PfmTableEditor (72 + 4px margin)
    this.startX = 40.0, // Odpovídá šířce popisků A, C, G, T (32 + 8px margin)
  });

  final JasparMotif motif;
  final double maxHeight;
  final double colWidth;
  final double startX;

  List<double> get _icValues => [
        for (var col = 0; col < motif.length; col++)
          calculateInformationContent(motif, col),
      ];

  @override
  Widget build(BuildContext context) {
    final width = math.max(350.0, startX + motif.length * colWidth);
    return SizedBox(
      height: maxHeight + 30,
      width: width,
      child: CustomPaint(
        painter: _VectorSequenceLogoPainter(
          ppm: motif.ppm,
          icValues: _icValues,
          colWidth: colWidth,
          startX: startX,
        ),
      ),
    );
  }
}

class _VectorSequenceLogoPainter extends CustomPainter {
  _VectorSequenceLogoPainter({
    required this.ppm,
    required this.icValues,
    required this.colWidth,
    required this.startX,
  });

  final Ppm ppm;
  final List<double> icValues;
  final double colWidth;
  final double startX;

  Path _letterPath(String letter) {
    final path = Path();
    switch (letter) {
      case 'A':
        path.fillType = PathFillType.evenOdd;
        path.moveTo(38, 0);
        path.lineTo(62, 0);
        path.lineTo(86, 100);
        path.lineTo(66, 100);
        path.lineTo(58, 62);
        path.lineTo(42, 62);
        path.lineTo(34, 100);
        path.lineTo(14, 100);
        path.close();
        path.moveTo(50, 18);
        path.lineTo(56, 48);
        path.lineTo(44, 48);
        path.close();
        break;

      case 'C':
        path.moveTo(85, 18);
        path.cubicTo(72, 2, 62, 0, 50, 0);
        path.cubicTo(35, 0, 12, 20, 12, 50);
        path.cubicTo(12, 80, 35, 100, 50, 100);
        path.cubicTo(62, 100, 75, 98, 85, 82);
        path.lineTo(72, 72);
        path.cubicTo(62, 84, 56, 85, 50, 85);
        path.cubicTo(36, 85, 27, 72, 27, 50);
        path.cubicTo(27, 28, 36, 15, 50, 15);
        path.cubicTo(56, 15, 62, 16, 72, 28);
        path.close();
        break;

      case 'G':
        path.moveTo(85, 18);
        path.cubicTo(72, 2, 62, 0, 50, 0);
        path.cubicTo(35, 0, 12, 20, 12, 50);
        path.cubicTo(12, 80, 35, 100, 50, 100);
        path.cubicTo(62, 100, 75, 96, 85, 82);
        path.lineTo(85, 48);
        path.lineTo(52, 48);
        path.lineTo(52, 62);
        path.lineTo(70, 62);
        path.lineTo(70, 72);
        path.cubicTo(62, 84, 56, 85, 50, 85);
        path.cubicTo(36, 85, 27, 72, 27, 50);
        path.cubicTo(27, 28, 36, 15, 50, 15);
        path.cubicTo(56, 15, 62, 16, 72, 28);
        path.close();
        break;

      case 'T':
        path.moveTo(5, 0);
        path.lineTo(95, 0);
        path.lineTo(95, 18);
        path.lineTo(59, 18);
        path.lineTo(59, 100);
        path.lineTo(41, 100);
        path.lineTo(41, 18);
        path.lineTo(5, 18);
        path.close();
        break;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ppm.isEmpty || ppm[0].isEmpty) return;

    final logoHeight = size.height - 30;

    final axisPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(startX - 3, 10),
      Offset(startX - 3, logoHeight + 10),
      axisPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var bits = 0.0; bits <= 2.0; bits += 0.5) {
      final y = logoHeight + 10 - (bits / 2.0) * logoHeight;
      canvas.drawLine(Offset(startX - 8, y), Offset(startX - 3, y), axisPaint);
      textPainter.text = TextSpan(
        text: bits.toStringAsFixed(1),
        style: const TextStyle(color: Colors.black87, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX - 30, y - 6));
    }

    for (var col = 0; col < ppm[0].length; col++) {
      final ic = icValues[col];
      final colBases = [
        for (var r = 0; r < 4; r++) BaseFreq(bases[r], ppm[r][col]),
      ]..sort((a, b) => a.freq.compareTo(b.freq));

      var currentY = logoHeight + 10;
      final xPos = startX + col * colWidth + 2;

      for (final base in colBases) {
        if (base.freq <= 0 || ic <= 0) continue;
        final letterHeight = (base.freq * ic / 2.0) * logoHeight;
        if (letterHeight < 0.5) continue;

        final fillPaint = Paint()
          ..color = baseColor(base.name)
          ..style = PaintingStyle.fill;

        final matrix = Matrix4.identity()
          ..translate(xPos, currentY - letterHeight)
          ..scale((colWidth - 4) / 100.0, letterHeight / 100.0);

        final letterPath = _letterPath(base.name).transform(matrix.storage);
        canvas.drawPath(letterPath, fillPaint);

        currentY -= letterHeight;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VectorSequenceLogoPainter oldDelegate) {
    return true;
  }
}
