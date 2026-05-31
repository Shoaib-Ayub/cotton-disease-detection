import 'package:hive/hive.dart';

part 'history_item_model.g.dart';

@HiveType(typeId: 1)
class HistoryItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String diseaseName;

  @HiveField(3)
  final double confidence;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String shortDescription;

  @HiveField(6)
  final List<String> recommendedMedicines;

  @HiveField(7)
  final String dosageGuide;

  @HiveField(8)
  final List<String> precautions;

  @HiveField(9)
  final List<String> preventionTips;

  @HiveField(10)
  final double boxLeft;

  @HiveField(11)
  final double boxTop;

  @HiveField(12)
  final double boxRight;

  @HiveField(13)
  final double boxBottom;

  HistoryItemModel({
    required this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.createdAt,
    required this.shortDescription,
    required this.recommendedMedicines,
    required this.dosageGuide,
    required this.precautions,
    required this.preventionTips,
    required this.boxLeft,
    required this.boxTop,
    required this.boxRight,
    required this.boxBottom,
  });
}
