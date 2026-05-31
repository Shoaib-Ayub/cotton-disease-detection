import 'package:flutter/material.dart';

import '../../../detection/data/models/disease_recommendation_model.dart';

class RecommendationCard extends StatelessWidget {
  final DiseaseRecommendationModel recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recommendation.diseaseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _SectionTitle(title: "Short Description"),
            const SizedBox(height: 6),
            Text(
              recommendation.shortDescription,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: "Recommended Medicines"),
            const SizedBox(height: 6),
            ...recommendation.recommendedMedicines.map(
              (medicine) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        medicine,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: "Dosage Guide"),
            const SizedBox(height: 6),
            Text(
              recommendation.dosageGuide,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: "Precautions"),
            const SizedBox(height: 6),
            ...recommendation.precautions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: "Prevention Tips"),
            const SizedBox(height: 6),
            ...recommendation.preventionTips.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}
