import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/glass.dart';
import '../widgets/water_tracker_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profile = StorageService.getProfile();
    });
  }

  Future<void> _updateProfile(UserProfile newProfile) async {
    await StorageService.saveProfile(newProfile);
    _loadProfile();
    widget.onProfileUpdated?.call();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Karakterini Seç',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tarzına en uygun avatarı belirle',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: AppAvatars.presets.length,
              itemBuilder: (context, index) {
                final preset = AppAvatars.presets[index];
                final isSelected = _profile.avatarIndex == index;

                return GestureDetector(
                  onTap: () {
                    _updateProfile(_profile.copyWith(avatarIndex: index));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                          : AppTheme.darkCardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryEmerald : AppTheme.darkBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UserAvatarWidget(avatarIndex: index, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          preset.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile.name);
    final ageCtrl = TextEditingController(text: _profile.age > 0 ? _profile.age.toString() : '');
    final heightCtrl = TextEditingController(text: _profile.height > 0 ? _profile.height.toStringAsFixed(0) : '');
    final weightCtrl = TextEditingController(text: _profile.weight > 0 ? _profile.weight.toStringAsFixed(1) : '');
    final targetWeightCtrl = TextEditingController(text: _profile.targetWeight > 0 ? _profile.targetWeight.toStringAsFixed(1) : '');
    final waterGoalCtrl = TextEditingController(
        text: _profile.waterGoalMl > 0 ? _profile.waterGoalMl.toString() : '2500');
    String gender = _profile.gender.isNotEmpty ? _profile.gender : 'Erkek';
    ActivityLevel activity = _profile.activityLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tutamaç
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Text('Profil & Vücut Bilgileri',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // İsim
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Adınız Soyadınız',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryEmerald, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Yaş + Cinsiyet
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Yaş',
                          prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.primaryEmerald, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: gender,
                        dropdownColor: AppTheme.darkCardElevated,
                        decoration: const InputDecoration(labelText: 'Cinsiyet',
                            prefixIcon: Icon(Icons.wc_outlined, color: AppTheme.primaryEmerald, size: 18)),
                        style: const TextStyle(color: Colors.white),
                        items: ['Erkek', 'Kadın']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) { if (val != null) setDialogState(() => gender = val); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Boy + Kilo
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm)',
                          suffixText: 'cm',
                          prefixIcon: Icon(Icons.height_rounded, color: AppTheme.primaryEmerald, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg)',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryEmerald, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hedef Kilo
                TextField(
                  controller: targetWeightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Hedef Kilo (kg)',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.flag_outlined, color: AppTheme.primaryEmerald, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Günlük Su Hedefi
                TextField(
                  controller: waterGoalCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Günlük Su Hedefi (ml)',
                    suffixText: 'ml',
                    prefixIcon: Icon(Icons.water_drop_outlined, color: Color(0xFF06B6D4), size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Aktivite
                DropdownButtonFormField<ActivityLevel>(
                  value: activity,
                  dropdownColor: AppTheme.darkCardElevated,
                  decoration: const InputDecoration(
                    labelText: 'Fiziksel Aktivite Düzeyi',
                    prefixIcon: Icon(Icons.directions_run_rounded, color: AppTheme.primaryEmerald, size: 18),
                  ),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: ActivityLevel.values
                      .map((lvl) => DropdownMenuItem(
                            value: lvl,
                            child: Text(lvl.displayName, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) { if (val != null) setDialogState(() => activity = val); },
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Değişiklikleri Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final newProf = _profile.copyWith(
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _profile.name,
                        age: int.tryParse(ageCtrl.text) ?? _profile.age,
                        gender: gender,
                        height: double.tryParse(heightCtrl.text) ?? _profile.height,
                        weight: double.tryParse(weightCtrl.text) ?? _profile.weight,
                        targetWeight: double.tryParse(targetWeightCtrl.text) ?? _profile.targetWeight,
                        waterGoalMl: int.tryParse(waterGoalCtrl.text) ?? _profile.waterGoalMl,
                        activityLevel: activity,
                      );
                      await _updateProfile(newProf);
                      // Kalori hedefini de otomatik güncelle
                      await StorageService.saveDailyCalorieGoal(newProf.recommendedCalories);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyRecommendedCalories() async {
    final rec = _profile.recommendedCalories;
    await StorageService.saveDailyCalorieGoal(rec);
    widget.onProfileUpdated?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Günlük hedef $rec kcal olarak uygulandı!'),
            ],
          ),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profil & Sağlık'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Bilgileri Düzenle',
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Sistem Ayarları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // User Card
          _buildUserHeroCard(),
          const SizedBox(height: 18),

          // BMI / VKİ Card
          _buildBmiCard(),
          const SizedBox(height: 18),

          // BMR & TDEE Metabolism Recommendation Card
          _buildMetabolismCard(),
          const SizedBox(height: 18),

          // Water Tracker
          WaterTrackerCard(onWaterChanged: widget.onProfileUpdated),
          const SizedBox(height: 18),

          // Badges / Achievements
          _buildBadgesCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserHeroCard() {
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          UserAvatarWidget(
            avatarIndex: _profile.avatarIndex,
            size: 68,
            showBadge: true,
            onTap: _showAvatarPicker,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.carbsColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: AppTheme.carbsColor, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${_profile.streakDays} Gün',
                            style: const TextStyle(
                              color: AppTheme.carbsColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile.gender} • ${_profile.age} Yaş • ${_profile.height.toInt()} cm',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profile.activityLevel.displayName,
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard() {
    final bmi = _profile.bmi;
    final bmiStatus = _profile.bmiStatus;

    Color statusColor;
    if (bmi < 18.5) {
      statusColor = const Color(0xFF38BDF8);
    } else if (bmi < 25.0) {
      statusColor = AppTheme.primaryEmerald;
    } else if (bmi < 30.0) {
      statusColor = AppTheme.carbsColor;
    } else {
      statusColor = const Color(0xFFEF4444);
    }

    // Weight progress
    final diff = (_profile.weight - _profile.targetWeight).abs();
    final isLosing = _profile.weight > _profile.targetWeight;

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_weight_rounded, color: AppTheme.primaryEmerald, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'VÜCUT KİTLE İNDEKSİ (VKİ)',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  bmiStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Text('kg/m²', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_profile.weight.toStringAsFixed(1)} kg → ${_profile.targetWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    isLosing ? '$diff kg verilecek' : '$diff kg alınacak',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(flex: 18, child: Container(height: 7, color: const Color(0xFF38BDF8))),
                const SizedBox(width: 2),
                Expanded(flex: 25, child: Container(height: 7, color: AppTheme.primaryEmerald)),
                const SizedBox(width: 2),
                Expanded(flex: 20, child: Container(height: 7, color: AppTheme.carbsColor)),
                const SizedBox(width: 2),
                Expanded(flex: 15, child: Container(height: 7, color: const Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Zayıf (<18.5)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              Text('Normal (18.5-24.9)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              Text('Kilolu (25+)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolismCard() {
    final bmr = _profile.bmr;
    final tdee = _profile.tdee;
    final recommended = _profile.recommendedCalories;

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.carbsColor, size: 20),
              SizedBox(width: 8),
              Text(
                'BİLİMSEL METABOLİZMA HESABI',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bazal Hız (BMR)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$bmr kcal',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('Dinlenirken yakılan', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toplam Yakım (TDEE)',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$tdee kcal',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('Günlük hareketle', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hedefine Göre Önerilen Kalori:',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    Text(
                      '$recommended kcal / gün',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _applyRecommendedCalories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Hedef Yap', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard() {
    final badges = [
      {'emoji': '🥑', 'title': 'AI Kaşifi', 'desc': 'Yemek taraması yapıldı'},
      {'emoji': '💧', 'title': 'Hidrasyon', 'desc': 'Su takibi aktif'},
      {'emoji': '🔥', 'title': 'Seri Ustası', 'desc': '5 gün düzenli kayıt'},
      {'emoji': '🎯', 'title': 'Hedef Odaklı', 'desc': 'Günlük kalori dengelendi'},
    ];

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'BAŞARI ROZETLERİ',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: badges.map((b) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardElevated,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(b['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        b['title']!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b['desc']!,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
