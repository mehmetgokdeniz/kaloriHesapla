class AiAnalysisResult {
  final String foodName;
  final String portion;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int healthScore; // 1 to 10
  final String advice;
  final List<String> ingredients;
  final bool isSuccess;
  final String? errorMessage;

  AiAnalysisResult({
    required this.foodName,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    required this.healthScore,
    required this.advice,
    this.ingredients = const [],
    this.isSuccess = true,
    this.errorMessage,
  });

  factory AiAnalysisResult.fromGeminiJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      foodName: json['yemek_adi']?.toString() ?? 'Bilinmeyen Yemek',
      portion: json['tahmini_porsiyon']?.toString() ?? '1 Porsiyon',
      calories: (json['toplam_kalori'] as num?)?.toInt() ?? 0,
      protein: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['karbonhidrat_g'] as num?)?.toDouble() ?? 0.0,
      fat: (json['yag_g'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['lif_g'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['saglik_puani'] as num?)?.toInt() ?? 7,
      advice: json['besin_degerlendirmesi']?.toString() ?? 'Sağlıklı ve dengeli beslenmeye özen gösterin.',
      ingredients: (json['icindekiler'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isSuccess: true,
    );
  }

  factory AiAnalysisResult.error(String message) {
    return AiAnalysisResult(
      foodName: 'Analiz Edilemedi',
      portion: '-',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
      healthScore: 0,
      advice: message,
      ingredients: [],
      isSuccess: false,
      errorMessage: message,
    );
  }
}
