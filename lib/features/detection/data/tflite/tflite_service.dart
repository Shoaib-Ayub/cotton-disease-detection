import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection_box_model.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  static const int inputSize = 896;

  Future<void> load() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/models/best_float32.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    final raw = await rootBundle.loadString('assets/labels/labels.txt');
    _labels = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    debugPrint('LABELS COUNT: ${_labels.length}');
    debugPrint('LABELS: $_labels');
  }

  Future<List<DetectionBoxModel>> detectObjects(File imageFile) async {
    debugPrint('STEP A: detectObjects started');

    await load();

    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception('TFLite interpreter not loaded');
    }

    debugPrint('STEP B: interpreter loaded');

    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Image decode failed');
    }

    debugPrint('STEP C: image decoded');

    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    debugPrint('Original image size: $originalWidth x $originalHeight');

    final letterbox = _letterboxImage(originalImage);

    debugPrint(
      'STEP D: image letterboxed to $inputSize x $inputSize, '
      'scale=${letterbox.scale}, padX=${letterbox.padX}, padY=${letterbox.padY}',
    );

    final input = _imageToTensor(letterbox.image);

    debugPrint('STEP E: input tensor created');

    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputType = outputTensor.type;

    debugPrint('YOLO Output Shape: $outputShape');
    debugPrint('YOLO Output Type: $outputType');

    final output = _createOutputBuffer(outputShape);

    debugPrint('STEP F: output buffer created');

    interpreter.run(input, output);

    debugPrint('STEP G: interpreter.run completed');

    final detections = _parseYoloOutput(
      output: output,
      originalWidth: originalWidth.toDouble(),
      originalHeight: originalHeight.toDouble(),
      resizeScale: letterbox.scale,
      padX: letterbox.padX.toDouble(),
      padY: letterbox.padY.toDouble(),
      confidenceThreshold: 0.70,
      maxAreaRatio: 0.35,
      minAreaRatio: 0.00002,
    );

    debugPrint('STEP H: parsing completed');
    debugPrint('Total parsed detections: ${detections.length}');

    return detections;
  }

  _LetterboxResult _letterboxImage(img.Image originalImage) {
    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    final scale = min(inputSize / originalWidth, inputSize / originalHeight);

    final newWidth = (originalWidth * scale).round();
    final newHeight = (originalHeight * scale).round();

    final resized = img.copyResize(
      originalImage,
      width: newWidth,
      height: newHeight,
    );

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));

    final padX = ((inputSize - newWidth) / 2).round();
    final padY = ((inputSize - newHeight) / 2).round();

    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    return _LetterboxResult(
      image: canvas,
      scale: scale,
      padX: padX,
      padY: padY,
    );
  }

  List<List<List<List<double>>>> _imageToTensor(img.Image image) {
    return [
      List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);

          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;

          return [r, g, b];
        }),
      ),
    ];
  }

  dynamic _createOutputBuffer(List<int> shape) {
    if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)),
      );
    }

    if (shape.length == 2) {
      return List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
    }

    throw Exception('Unsupported output tensor shape: $shape');
  }

  List<DetectionBoxModel> _parseYoloOutput({
    required dynamic output,
    required double originalWidth,
    required double originalHeight,
    required double resizeScale,
    required double padX,
    required double padY,
    double confidenceThreshold = 0.40,
    double maxAreaRatio = 0.35,
    double minAreaRatio = 0.00002,
  }) {
    final List<DetectionBoxModel> results = [];

    final data = output[0];

    if (data.isEmpty) return [];

    final rows = data.length;
    final cols = data[0].length;

    debugPrint('Rows: $rows, Cols: $cols');

    if (rows == 11) {
      final int numClasses = rows - 4;
      double highestScoreFound = 0.0;

      for (int i = 0; i < cols; i++) {
        final double x = (data[0][i] as num).toDouble();
        final double y = (data[1][i] as num).toDouble();
        final double w = (data[2][i] as num).toDouble();
        final double h = (data[3][i] as num).toDouble();

        double maxScore = 0.0;
        int classIndex = -1;

        for (int c = 0; c < numClasses; c++) {
          final score = (data[c + 4][i] as num).toDouble();

          if (score > maxScore) {
            maxScore = score;
            classIndex = c;
          }
        }

        if (maxScore > highestScoreFound) {
          highestScoreFound = maxScore;
        }

        if (maxScore < confidenceThreshold) continue;
        if (classIndex < 0 || classIndex >= _labels.length) continue;

        final rect = _scaleBoxToOriginal(
          xCenter: x,
          yCenter: y,
          width: w,
          height: h,
          originalWidth: originalWidth,
          originalHeight: originalHeight,
          resizeScale: resizeScale,
          padX: padX,
          padY: padY,
        );

        if (rect.width <= 1 || rect.height <= 1) continue;

        final areaRatio =
            (rect.width * rect.height) / (originalWidth * originalHeight);

        if (areaRatio > maxAreaRatio) continue;
        if (areaRatio < minAreaRatio) continue;

        results.add(
          DetectionBoxModel(
            className: _labels[classIndex],
            confidence: maxScore,
            rect: rect,
          ),
        );
      }

      debugPrint('Highest score found: $highestScoreFound');
    } else {
      debugPrint('Unsupported YOLO format for now: rows=$rows cols=$cols');
    }

    debugPrint('Total parsed detections before NMS: ${results.length}');

    final filtered = _applyNms(results, iouThreshold: 0.45);

    debugPrint('Total parsed detections after NMS: ${filtered.length}');

    return filtered;
  }

  Rect _scaleBoxToOriginal({
    required double xCenter,
    required double yCenter,
    required double width,
    required double height,
    required double originalWidth,
    required double originalHeight,
    required double resizeScale,
    required double padX,
    required double padY,
  }) {
    final bool isNormalized =
        xCenter <= 1.5 && yCenter <= 1.5 && width <= 1.5 && height <= 1.5;

    double x = xCenter;
    double y = yCenter;
    double w = width;
    double h = height;

    if (isNormalized) {
      x *= inputSize;
      y *= inputSize;
      w *= inputSize;
      h *= inputSize;
    }

    final double leftOnInput = x - w / 2;
    final double topOnInput = y - h / 2;
    final double rightOnInput = x + w / 2;
    final double bottomOnInput = y + h / 2;

    final double left = (leftOnInput - padX) / resizeScale;
    final double top = (topOnInput - padY) / resizeScale;
    final double right = (rightOnInput - padX) / resizeScale;
    final double bottom = (bottomOnInput - padY) / resizeScale;

    return Rect.fromLTRB(
      left.clamp(0.0, originalWidth),
      top.clamp(0.0, originalHeight),
      right.clamp(0.0, originalWidth),
      bottom.clamp(0.0, originalHeight),
    );
  }

  List<DetectionBoxModel> _applyNms(
    List<DetectionBoxModel> boxes, {
    double iouThreshold = 0.45,
  }) {
    if (boxes.isEmpty) return [];

    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionBoxModel> selected = [];

    while (boxes.isNotEmpty) {
      final current = boxes.removeAt(0);
      selected.add(current);

      boxes.removeWhere(
        (box) =>
            box.className == current.className &&
            _calculateIoU(current.rect, box.rect) > iouThreshold,
      );
    }

    return selected;
  }

  double _calculateIoU(Rect a, Rect b) {
    final intersectionLeft = max(a.left, b.left);
    final intersectionTop = max(a.top, b.top);
    final intersectionRight = min(a.right, b.right);
    final intersectionBottom = min(a.bottom, b.bottom);

    final intersectionWidth = max(0.0, intersectionRight - intersectionLeft);
    final intersectionHeight = max(0.0, intersectionBottom - intersectionTop);
    final intersectionArea = intersectionWidth * intersectionHeight;

    final areaA = a.width * a.height;
    final areaB = b.width * b.height;

    final unionArea = areaA + areaB - intersectionArea;

    if (unionArea <= 0) return 0.0;

    return intersectionArea / unionArea;
  }
}

class _LetterboxResult {
  final img.Image image;
  final double scale;
  final int padX;
  final int padY;

  _LetterboxResult({
    required this.image,
    required this.scale,
    required this.padX,
    required this.padY,
  });
}
