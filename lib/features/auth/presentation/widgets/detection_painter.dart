import 'package:flutter/material.dart';

import '../../../detection/data/models/detection_box_model.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectionBoxModel> detections;
  final Size imageOriginalSize;
  final BoxFit boxFit;

  DetectionPainter({
    required this.detections,
    required this.imageOriginalSize,
    this.boxFit = BoxFit.contain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;
    if (imageOriginalSize.width <= 0 || imageOriginalSize.height <= 0) return;

    final fittedSizes = applyBoxFit(boxFit, imageOriginalSize, size);
    final sourceSize = fittedSizes.source;
    final destinationSize = fittedSizes.destination;

    final dx = (size.width - destinationSize.width) / 2;
    final dy = (size.height - destinationSize.height) / 2;

    final scaleX = destinationSize.width / sourceSize.width;
    final scaleY = destinationSize.height / sourceSize.height;

    final boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final labelBgPaint = Paint()..color = Colors.black;

    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        dx + detection.rect.left * scaleX,
        dy + detection.rect.top * scaleY,
        dx + detection.rect.right * scaleX,
        dy + detection.rect.bottom * scaleY,
      );

      canvas.drawRect(rect, boxPaint);

      final label =
          '${detection.className} ${(detection.confidence * 100).toStringAsFixed(1)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final labelTop = rect.top - 24 < 0 ? rect.top : rect.top - 24;

      final labelRect = Rect.fromLTWH(
        rect.left,
        labelTop,
        textPainter.width + 10,
        22,
      );

      canvas.drawRect(labelRect, labelBgPaint);
      textPainter.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return true;
  }
}
