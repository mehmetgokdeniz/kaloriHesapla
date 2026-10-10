import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_item.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _mealsKey = 'user_meals_data';
  static const String _goalKey = 'daily_calorie_goal';
  static const String _apiKeyKey = 'user_gemini_api_key';
  static const String _groqKeyKey = 'user_groq_api_key';
  static const String _profileKey = 'user_profile_data';
  static const String _firstRunKey = 'is_first_run_completed';
  static const String _streakStartKey = 'daily_streak_start_at';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _checkFirstRun();
  }

  // --- Profile Management ---
  static UserProfile getProfile() {
    final raw = _prefs?.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      return UserProfile();
    }
    try {
      return UserProfile.fromJson(raw);
    } catch (_) {
      return UserProfile();
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await _prefs?.setString(_profileKey, profile.toJson());
  }

  static Future<void> updateWaterIntake(int deltaMl) async {
    final profile = getProfile();
    final newIntake = (profile.waterIntakeMl + deltaMl).clamp(0, 8000);
    await saveProfile(profile.copyWith(waterIntakeMl: newIntake));
  }

  // --- API Key Management ---
  static String getApiKey() {
    return _prefs?.getString(_apiKeyKey) ?? '';
  }

  static Future<void> saveApiKey(String key) async {
    await _prefs?.setString(_apiKeyKey, key.trim());
  }

  static String getGroqApiKey() {
    return _prefs?.getString(_groqKeyKey) ?? '';
  }

  static Future<void> saveGroqApiKey(String key) async {
    await _prefs?.setString(_groqKeyKey, key.trim());
  }

  // --- Daily Streak ---
  static int getStreakDays() {
    return _prefs?.getInt('daily_streak_days') ?? 0;
  }

  static Future<int> updateDailyStreak() async {
    final now = DateTime.now();
    var startMillis = _prefs?.getInt(_streakStartKey);

    if (startMillis == null) {
      startMillis = now.millisecondsSinceEpoch;
      await _prefs?.setInt(_streakStartKey, startMillis);
    }

    final elapsed = now.millisecondsSinceEpoch - startMillis;
    final streakDays = 1 + (elapsed ~/ Duration.millisecondsPerDay);
    await _prefs?.setInt('daily_streak_days', streakDays);

    final profile = getProfile();
    if (profile.streakDays != streakDays) {
      await saveProfile(profile.copyWith(streakDays: streakDays));
    }
    return streakDays;
  }

  // --- Daily Calorie Goal ---
  static int getDailyCalorieGoal() {
    return _prefs?.getInt(_goalKey) ?? 2000;
  }

  static Future<void> saveDailyCalorieGoal(int goal) async {
    await _prefs?.setInt(_goalKey, goal);
  }

  // --- Meals Persistence ---
  static List<MealItem> getMeals() {
    final rawList = _prefs?.getStringList(_mealsKey) ?? [];
    try {
      return rawList.map((itemStr) => MealItem.fromJson(itemStr)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMeals(List<MealItem> meals) async {
    final rawList = meals.map((m) => m.toJson()).toList();
    await _prefs?.setStringList(_mealsKey, rawList);
  }

  static Future<void> addMeal(MealItem meal) async {
    final meals = getMeals();
    meals.insert(0, meal);
    await saveMeals(meals);
  }

  static Future<void> deleteMeal(String mealId) async {
    final meals = getMeals();
    meals.removeWhere((item) => item.id == mealId);
    await saveMeals(meals);
  }

  static Future<void> clearAllMeals() async {
    await _prefs?.remove(_mealsKey);
  }

  // --- İlk Çalışma Kontrolü ---
  static Future<void> _checkFirstRun() async {
    final hasRun = _prefs?.getBool(_firstRunKey) ?? false;
    if (!hasRun) {
      // İlk açılışta hiçbir örnek veri eklemiyoruz;
      // kullanıcı onboarding akışından kendi profilini oluşturur.
      await _prefs?.setBool(_firstRunKey, true);
      await _prefs?.setInt(_streakStartKey, DateTime.now().millisecondsSinceEpoch);
      await _prefs?.setInt('daily_streak_days', 1);
    } else if (_prefs?.getInt(_streakStartKey) == null) {
      // Upgrade existing installs without a streak timestamp.
      await _prefs?.setInt(_streakStartKey, DateTime.now().millisecondsSinceEpoch);
      await _prefs?.setInt('daily_streak_days', 1);
    }
  }
}
