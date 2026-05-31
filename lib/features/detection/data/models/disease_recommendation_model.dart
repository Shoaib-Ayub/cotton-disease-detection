class DiseaseRecommendationModel {
  final String diseaseName;
  final String shortDescription;
  final List<String> recommendedMedicines;
  final String dosageGuide;
  final List<String> precautions;
  final List<String> preventionTips;

  const DiseaseRecommendationModel({
    required this.diseaseName,
    required this.shortDescription,
    required this.recommendedMedicines,
    required this.dosageGuide,
    required this.precautions,
    required this.preventionTips,
  });
}
