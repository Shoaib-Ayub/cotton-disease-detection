import 'dart:ui';

// Is file me ek model banayenge jo har detected object ka data rakhega:
class DetectionBoxModel {
  final String className;
  final double confidence;
  final Rect rect;

  DetectionBoxModel({
    required this.className,
    required this.confidence,
    required this.rect,
  });
}

// Iska kaam:
// className → disease/pest ka naam
// confidence → model kitna sure hai
// rect → bounding box ka area
