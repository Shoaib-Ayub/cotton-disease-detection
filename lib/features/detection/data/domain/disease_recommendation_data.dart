import '../models/disease_recommendation_model.dart';

class DiseaseRecommendationData {
  static Map<String, DiseaseRecommendationModel> recommendations = {
    'jassid_leafhopper': DiseaseRecommendationModel(
      diseaseName: 'Jassid / Leafhopper',
      shortDescription:
          'Yeh sucking pest hai jo pattiyon ka ras chusta hai. Is se leaf curling aur yellowing ho sakti hai.',
      recommendedMedicines: ['Imidacloprid', 'Acetamiprid', 'Thiamethoxam'],
      dosageGuide:
          'Label instruction ke mutabiq spray karein. Overdose na karein.',
      precautions: [
        'Subah ya shaam spray karein',
        'Protective gloves aur mask use karein',
        'Tez hawa me spray na karein',
      ],
      preventionTips: [
        'Field ki regular monitoring karein',
        'Affected pattiyan check karte rahain',
        'Balanced fertilizer use karein',
      ],
    ),
    'pink_bollworm': DiseaseRecommendationModel(
      diseaseName: 'Pink Bollworm',
      shortDescription:
          'Yeh boll ko damage karta hai aur kapas ki quality aur yield dono ko affect karta hai.',
      recommendedMedicines: [
        'Emamectin Benzoate',
        'Spinosad',
        'Chlorantraniliprole',
      ],
      dosageGuide: 'Recommended agricultural label dose follow karein.',
      precautions: [
        'Protective clothes pehnen',
        'Spray ke baad haath dhoyein',
        'Children se medicines door rakhein',
      ],
      preventionTips: [
        'Pheromone traps use karein',
        'Infested bolls ko remove karein',
        'Crop residue ko destroy karein',
      ],
    ),
    'thrips': DiseaseRecommendationModel(
      diseaseName: 'Thrips',
      shortDescription:
          'Thrips pattiyon aur narm hisson ko damage karte hain, jis se silvery marks aur curling hoti hai.',
      recommendedMedicines: ['Spinetoram', 'Abamectin', 'Fipronil'],
      dosageGuide:
          'Company label aur local agriculture guidance ke mutabiq istemal karein.',
      precautions: [
        'Direct skin contact se bachein',
        'Mask aur goggles use karein',
        'Dopehar ki garmi me spray avoid karein',
      ],
      preventionTips: [
        'Weeds control karein',
        'Field scouting regular rakhein',
        'Early infestation par action lein',
      ],
    ),
    'whitefly_adult': DiseaseRecommendationModel(
      diseaseName: 'Whitefly',
      shortDescription:
          'Whitefly ras chusti hai aur virus spread karne ka bhi sabab ban sakti hai.',
      recommendedMedicines: ['Buprofezin', 'Pyriproxyfen', 'Imidacloprid'],
      dosageGuide:
          'Recommended dose hi use karein aur repeat spray interval maintain karein.',
      precautions: [
        'Bee activity ke time spray avoid karein',
        'Spray ke duran face cover karein',
        'Water source ke qareeb ehtiyat karein',
      ],
      preventionTips: [
        'Yellow sticky traps use karein',
        'Excess nitrogen avoid karein',
        'Early stage monitoring karein',
      ],
    ),
    'american_bollworm': DiseaseRecommendationModel(
      diseaseName: 'American Bollworm',
      shortDescription:
          'Yeh larvae leaves, squares aur bolls ko damage karte hain aur crop loss barha dete hain.',
      recommendedMedicines: ['Indoxacarb', 'Emamectin Benzoate', 'Spinosad'],
      dosageGuide: 'Label dose aur spray interval follow karein.',
      precautions: [
        'Spray ke waqt gloves pehnen',
        'Khali container dubara use na karein',
        'Food items se door rakhein',
      ],
      preventionTips: [
        'Light trap ya pheromone trap use karein',
        'Egg masses aur larvae inspect karein',
        'Timely spray schedule follow karein',
      ],
    ),
    'aphid_colony': DiseaseRecommendationModel(
      diseaseName: 'Aphid Colony',
      shortDescription:
          'Aphids narm hisson ka ras chuste hain aur honeydew ki wajah se fungus bhi develop ho sakti hai.',
      recommendedMedicines: ['Dinotefuran', 'Imidacloprid', 'Acetamiprid'],
      dosageGuide: 'Recommended quantity se zyada use na karein.',
      precautions: [
        'Spray se pehle label zaroor parhein',
        'Windy weather me spray avoid karein',
        'Mask use karein',
      ],
      preventionTips: [
        'Natural predators ko preserve karein',
        'Excessive nitrogen avoid karein',
        'Early colonies ko identify karein',
      ],
    ),
    'mealybug': DiseaseRecommendationModel(
      diseaseName: 'Mealybug',
      shortDescription:
          'Mealybug cotton plant ke hisson par white cottony mass jaisa nazar aata hai aur growth ko affect karta hai.',
      recommendedMedicines: ['Buprofezin', 'Spirotetramat', 'Imidacloprid'],
      dosageGuide: 'Local label recommendation ke mutabiq spray karein.',
      precautions: [
        'Protective kit use karein',
        'Mixing ke waqt ehtiyat karein',
        'Spray ke baad equipment saaf karein',
      ],
      preventionTips: [
        'Infested plants ko jaldi identify karein',
        'Ant control karein',
        'Field sanitation maintain rakhein',
      ],
    ),
  };

  static DiseaseRecommendationModel? getByClassName(String className) {
    return recommendations[className];
  }
}
