import 'dart:convert';

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Masa Başı (Hareketsiz)';
      case ActivityLevel.light:
        return 'Az Hareketli (Haftada 1-2 gün spor)';
      case ActivityLevel.moderate:
        return 'Orta Derece (Haftada 3-5 gün spor)';
      case ActivityLevel.active:
        return 'Çok Hareketli (Haftada 6-7 gün spor)';
      case ActivityLevel.veryActive:
        return 'Profesyonel Sporcu / Ağır İş';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
}

class UserProfile {
  final String name;
  final int age;
  final String gender; // 'Erkek' veya 'Kadın'
  final double height; // cm cinsinden
  final double weight; // kg cinsinden
  final double targetWeight; // kg cinsinden
  final ActivityLevel activityLevel;
  final int avatarIndex;
  final int waterIntakeMl;
  final int waterGoalMl;
  final int streakDays;

  UserProfile({
    this.name = '',
    this.age = 0,
    this.gender = '',
    this.height = 0.0,
    this.weight = 0.0,
    this.targetWeight = 0.0,
    this.activityLevel = ActivityLevel.sedentary,
    this.avatarIndex = 0,
    this.waterIntakeMl = 0,
    this.waterGoalMl = 0,
    this.streakDays = 0,
  });

  /// Vücut Kitle İndeksi (VKİ / BMI)
  double get bmi {
    if (height <= 0) return 0.0;
    final heightInMeters = height / 100.0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// VKİ Durum Açıklaması
  String get bmiStatus {
    final b = bmi;
    if (b < 18.5) return 'Zayıf';
    if (b < 25.0) return 'Normal Kilo';
    if (b < 30.0) return 'Fazla Kilolu';
    return 'Obezite';
  }

  /// Bazal Metabolizma Hızı (BMR - Harris-Benedict Formülü)
  int get bmr {
    if (gender == 'Kadın') {
      return (447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age)).round();
    } else {
      return (88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age)).round();
    }
  }

  /// Toplam Günlük Enerji Harcaması (TDEE)
  int get tdee {
    return (bmr * activityLevel.multiplier).round();
  }

  /// Hedefe göre önerilen kalori (Kilo verme için -400, koruma için aynı, alma için +400)
  int get recommendedCalories {
    if (weight > targetWeight + 1) {
      return tdee - 450; // Sağlıklı kilo verme açığı
    } else if (weight < targetWeight - 1) {
      return tdee + 350; // Kilo alma
    } else {
      return tdee; // Kilo koruma
    }
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    ActivityLevel? activityLevel,
    int? avatarIndex,
    int? waterIntakeMl,
    int? waterGoalMl,
    int? streakDays,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      waterIntakeMl: waterIntakeMl ?? this.waterIntakeMl,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel.index,
      'avatarIndex': avatarIndex,
      'waterIntakeMl': waterIntakeMl,
      'waterGoalMl': waterGoalMl,
      'streakDays': streakDays,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      targetWeight: (map['targetWeight'] as num?)?.toDouble() ?? 0.0,
      activityLevel: ActivityLevel.values[(map['activityLevel'] as int?) ?? 0],
      avatarIndex: map['avatarIndex'] ?? 0,
      waterIntakeMl: map['waterIntakeMl'] ?? 0,
      waterGoalMl: map['waterGoalMl'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}
