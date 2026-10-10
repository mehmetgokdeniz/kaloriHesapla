import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/meal_item.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/calorie_progress_card.dart';
import '../widgets/glass.dart';
import '../widgets/macro_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/water_tracker_card.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<MealItem> _todayMeals = [];
  int _dailyGoal = 2000;
  UserProfile _profile = UserProfile();

  @override
  void initState() {
    super.initState();
    _initializeDailyStreak();
  }

  Future<void> _initializeDailyStreak() async {
    await StorageService.updateDailyStreak();
    if (!mounted) return;

    _refreshData();
    // Profil boşsa onboarding başlat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_profile.name.isEmpty ||
          _profile.age == 0 ||
          _profile.height == 0.0) {
        await _startOnboarding();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VERİ
  // ──────────────────────────────────────────────────────────────────────────
  void _refreshData() {
    final allMeals = StorageService.getMeals();
    final now = DateTime.now();
    final today = allMeals.where((m) {
      return m.dateTime.year == now.year &&
          m.dateTime.month == now.month &&
          m.dateTime.day == now.day;
    }).toList();
    setState(() {
      _todayMeals = today;
      _dailyGoal = StorageService.getDailyCalorieGoal();
      _profile = StorageService.getProfile();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ONBOARDING — ADIM ADIM PROFİL TOPLAMA
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _startOnboarding() async {
    if (!mounted) return;

    // Gemini'den örnek profil dene (timeout'ta null dönerse manuel ekrana düş)
    final geminiResult = await _tryGeminiProfile();

    // Gemini bilgisi gelse bile kullanıcıya onaylat / düzenleme imkânı ver
    await _showOnboardingSheet(prefilled: geminiResult);
  }

  Future<Map<String, dynamic>?> _tryGeminiProfile() async {
    if (!GeminiService.hasApiKey()) return null;
    try {
      return await GeminiService.requestUserProfile().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showOnboardingSheet({Map<String, dynamic>? prefilled}) async {
    if (!mounted) return;

    final nameCtrl = TextEditingController(
      text: prefilled?['name']?.toString() ?? '',
    );
    final ageCtrl = TextEditingController(
      text: (prefilled?['age'] as int?)?.toString() ?? '',
    );
    final heightCtrl = TextEditingController(
      text: (prefilled?['height'] as num?)?.toStringAsFixed(0) ?? '',
    );
    final weightCtrl = TextEditingController(
      text: (prefilled?['weight'] as num?)?.toStringAsFixed(1) ?? '',
    );
    final targetWeightCtrl = TextEditingController(
      text: (prefilled?['targetWeight'] as num?)?.toStringAsFixed(1) ?? '',
    );
    final waterGoalCtrl = TextEditingController(
      text: (prefilled?['waterGoalMl'] as int?)?.toString() ?? '2500',
    );
    final rawGender = prefilled?['gender']?.toString() ?? '';
    String gender = (rawGender == 'Erkek' || rawGender == 'Kadın')
        ? rawGender
        : 'Erkek';
    ActivityLevel activity =
        ActivityLevel.values.elementAtOrNull(
          prefilled?['activityLevel'] as int? ?? 0,
        ) ??
        ActivityLevel.sedentary;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tutamaç
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20, top: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.primaryEmerald,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profilinizi Oluşturun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kişiselleştirilmiş hedefler için',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // İsim
                  _buildField(
                    nameCtrl,
                    'Adınız Soyadınız',
                    Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lütfen adınızı girin'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Yaş + Cinsiyet yan yana
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          ageCtrl,
                          'Yaş',
                          Icons.cake_outlined,
                          isNumber: true,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 10 || n > 100)
                              return 'Geçerli yaş girin';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          dropdownColor: AppTheme.darkCardElevated,
                          decoration: InputDecoration(
                            labelText: 'Cinsiyet',
                            prefixIcon: const Icon(
                              Icons.wc_outlined,
                              color: AppTheme.primaryEmerald,
                              size: 18,
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: AppTheme.darkCardElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: ['Erkek', 'Kadın']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setSheet(() => gender = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Boy + Kilo yan yana
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          heightCtrl,
                          'Boy (cm)',
                          Icons.height_rounded,
                          suffix: 'cm',
                          isNumber: true,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 100 || n > 250)
                              return '100-250 arası';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          weightCtrl,
                          'Kilo (kg)',
                          Icons.monitor_weight_outlined,
                          suffix: 'kg',
                          isDecimal: true,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n < 20 || n > 300)
                              return '20-300 arası';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hedef Kilo
                  _buildField(
                    targetWeightCtrl,
                    'Hedef Kilo (kg)',
                    Icons.flag_outlined,
                    suffix: 'kg',
                    isDecimal: true,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 20 || n > 300) return '20-300 arası';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Günlük su hedefi
                  _buildField(
                    waterGoalCtrl,
                    'Günlük Su Hedefi (ml)',
                    Icons.water_drop_outlined,
                    suffix: 'ml',
                    isNumber: true,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 500 || n > 8000)
                        return '500-8000 arası';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Aktivite seviyesi
                  DropdownButtonFormField<ActivityLevel>(
                    value: activity,
                    dropdownColor: AppTheme.darkCardElevated,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Fiziksel Aktivite Düzeyi',
                      prefixIcon: const Icon(
                        Icons.directions_run_rounded,
                        color: AppTheme.primaryEmerald,
                        size: 18,
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: AppTheme.darkCardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: ActivityLevel.values
                        .map(
                          (lvl) => DropdownMenuItem(
                            value: lvl,
                            child: Text(lvl.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => activity = v);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Kaydet
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Profili Kaydet & Başla',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final profile = UserProfile(
                          name: nameCtrl.text.trim(),
                          age: int.tryParse(ageCtrl.text) ?? 0,
                          gender: gender,
                          height: double.tryParse(heightCtrl.text) ?? 0.0,
                          weight: double.tryParse(weightCtrl.text) ?? 0.0,
                          targetWeight:
                              double.tryParse(targetWeightCtrl.text) ?? 0.0,
                          activityLevel: activity,
                          avatarIndex: 0,
                          waterIntakeMl: 0,
                          waterGoalMl: int.tryParse(waterGoalCtrl.text) ?? 2500,
                          streakDays: StorageService.getStreakDays(),
                        );

                        await StorageService.saveProfile(profile);
                        // Profil bazlı kalori hedefi öner
                        await StorageService.saveDailyCalorieGoal(
                          profile.recommendedCalories,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        _refreshData();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Form alanı builder yardımcısı
  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? suffix,
    bool isNumber = false,
    bool isDecimal = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
          ? TextInputType.number
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: AppTheme.primaryEmerald, size: 18),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: AppTheme.darkCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontSize: 10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TARAYICI & AYARLAR
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerScreen(onMealAdded: _refreshData),
      ),
    );
    _refreshData();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _refreshData();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MANUEL ÖĞÜN EKLEMESİ
  // ──────────────────────────────────────────────────────────────────────────
  void _showManualAddDialog() {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    MealType selectedType = MealType.ogle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Manuel Öğün Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Yemek Adı (Örn: Tost & Çay)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: calCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalori (kcal)',
                  suffixText: 'kcal',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Karb (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Yağ (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: MealType.values.map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text('${type.iconAssetOrEmoji} ${type.displayName}'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryEmerald,
                    backgroundColor: AppTheme.darkCardElevated,
                    onSelected: (val) {
                      if (val) setModalState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final cal = int.tryParse(calCtrl.text) ?? 0;
                  if (name.isEmpty || cal <= 0) return;

                  final meal = MealItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    calories: cal,
                    protein: double.tryParse(proteinCtrl.text) ?? 0.0,
                    carbs: double.tryParse(carbsCtrl.text) ?? 0.0,
                    fat: double.tryParse(fatCtrl.text) ?? 0.0,
                    portion: '1 Porsiyon',
                    mealType: selectedType,
                    dateTime: DateTime.now(),
                  );

                  await StorageService.addMeal(meal);
                  _refreshData();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentIndex) {
      case 0:
        currentBody = _buildDashboard();
        break;
      case 1:
        currentBody = const StatsScreen();
        break;
      case 2:
        currentBody = HistoryScreen(onMealChanged: _refreshData);
        break;
      case 3:
        currentBody = ProfileScreen(onProfileUpdated: _refreshData);
        break;
      default:
        currentBody = _buildDashboard();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: currentBody,
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: AppTheme.primaryEmerald,
        elevation: 0,
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        tooltip: 'Yemek Tara',
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: BottomAppBar(
            color: Colors.white.withValues(alpha: 0.07),
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavTab(0, Icons.home_rounded, 'Bugün'),
                _buildNavTab(1, Icons.bar_chart_rounded, 'Analiz'),
                const SizedBox(width: 48),
                _buildNavTab(2, Icons.history_rounded, 'Geçmiş'),
                _buildNavTab(3, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppTheme.primaryEmerald
        : const Color(0xFF64748B);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DASHBOARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final consumedCalories = _todayMeals.fold<int>(
      0,
      (sum, m) => sum + m.calories,
    );
    final totalProtein = _todayMeals.fold<double>(
      0.0,
      (sum, m) => sum + m.protein,
    );
    final totalCarbs = _todayMeals.fold<double>(0.0, (sum, m) => sum + m.carbs);
    final totalFat = _todayMeals.fold<double>(0.0, (sum, m) => sum + m.fat);

    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(now);
    final displayName = _profile.name.isNotEmpty
        ? _profile.name.split(' ').first
        : 'Hoş Geldiniz';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: AppTheme.primaryEmerald,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // Üst bar: avatar + selamlama + butonlar
            Row(
              children: [
                UserAvatarWidget(
                  avatarIndex: _profile.avatarIndex,
                  size: 48,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Merhaba, $displayName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_profile.streakDays > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.carbsColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppTheme.carbsColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_profile.streakDays}g',
                                    style: const TextStyle(
                                      color: AppTheme.carbsColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _showManualAddDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Manuel Ekle',
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Ayarlar',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Profil tamamlanmamışsa uyarı banner'ı
            if (_profile.name.isEmpty || _profile.height == 0.0)
              GestureDetector(
                onTap: () => _startOnboarding(),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Profilinizi tamamlayın — kişiselleştirilmiş kalori hedefi için dokunun.',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

            // Yemek tarama banner — cam panel
            GestureDetector(
              onTap: _openScanner,
              child: GlassPanel(
                radius: 24,
                padding: const EdgeInsets.all(18),
                tint: AppTheme.primaryEmerald,
                tintAlpha: 0.18,
                borderColor: AppTheme.primaryEmerald.withValues(alpha: 0.45),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yemek Fotoğrafı Çek / Seç',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kalori ve besinleri anında hesapla',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Kalori progress kartı
            CalorieProgressCard(
              consumedCalories: consumedCalories,
              goalCalories: _dailyGoal,
              onAdjustGoal: _openSettings,
            ),

            const SizedBox(height: 16),

            // Makro kart
            MacroCard(
              currentProtein: totalProtein,
              currentCarbs: totalCarbs,
              currentFat: totalFat,
              dailyCalorieGoal: _dailyGoal,
            ),

            const SizedBox(height: 16),

            // Su takip kartı
            WaterTrackerCard(onWaterChanged: _refreshData),

            const SizedBox(height: 22),

            // Bugünkü öğünler başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BUGÜNKÜ ÖĞÜNLER',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${_todayMeals.length} Öğün',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Öğünler
            if (_todayMeals.isEmpty)
              GlassPanel(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bugün henüz bir öğün eklenmedi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fotoğraf çekerek veya manuel ekleyerek başlayın.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._todayMeals.map((meal) {
                return MealCard(
                  meal: meal,
                  onDelete: () async {
                    await StorageService.deleteMeal(meal.id);
                    _refreshData();
                  },
                );
              }),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
