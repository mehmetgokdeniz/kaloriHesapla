import 'dart:convert';

enum MealType {
  kahvalti,
  ogle,
  aksam,
  araOgun;

  String get displayName {
    switch (this) {
      case MealType.kahvalti:
        return 'Kahvaltı';
      case MealType.ogle:
        return 'Öğle Yemeği';
      case MealType.aksam:
        return 'Akşam Yemeği';
      case MealType.araOgun:
        return 'Ara Öğün';
    }
  }

  String get iconAssetOrEmoji {
    switch (this) {
      case MealType.kahvalti:
        return '🍳';
      case MealType.ogle:
        return '🍲';
      case MealType.aksam:
        return '🍽️';
      case MealType.araOgun:
        return '🍎';
    }
  }
}

class MealItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String portion;
  final MealType mealType;
  final int healthScore; // 1-10
  final String healthTip;
  final List<String> ingredients;
  final String? imagePath;
  final DateTime dateTime;

  MealItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    required this.portion,
    required this.mealType,
    this.healthScore = 8,
    this.healthTip = '',
    this.ingredients = const [],
    this.imagePath,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'portion': portion,
      'mealType': mealType.index,
      'healthScore': healthScore,
      'healthTip': healthTip,
      'ingredients': ingredients,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      portion: map['portion'] ?? '1 Porsiyon',
      mealType: MealType.values[(map['mealType'] as int?) ?? 0],
      healthScore: (map['healthScore'] as num?)?.toInt() ?? 8,
      healthTip: map['healthTip'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      imagePath: map['imagePath'],
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory MealItem.fromJson(String source) => MealItem.fromMap(json.decode(source));
}
