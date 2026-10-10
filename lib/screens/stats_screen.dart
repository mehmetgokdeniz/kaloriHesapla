import 'package:flutter/material.dart';
import '../models/meal_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<MealItem> _allMeals = [];
  int _dailyGoal = 2000;

  @override
  void initState() {
    super.initState();
    _allMeals = StorageService.getMeals();
    _dailyGoal = StorageService.getDailyCalorieGoal();
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _allMeals.fold<int>(0, (sum, m) => sum + m.calories);
    final totalProtein = _allMeals.fold<double>(0.0, (sum, m) => sum + m.protein);
    final totalCarbs = _allMeals.fold<double>(0.0, (sum, m) => sum + m.carbs);
    final totalFat = _allMeals.fold<double>(0.0, (sum, m) => sum + m.fat);

    final totalMacros = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9);
    final proteinPercent = totalMacros > 0 ? (totalProtein * 4 / totalMacros * 100).round() : 25;
    final carbsPercent = totalMacros > 0 ? (totalCarbs * 4 / totalMacros * 100).round() : 50;
    final fatPercent = totalMacros > 0 ? (totalFat * 9 / totalMacros * 100).round() : 25;

    // Son 7 günün temsili barları
    final weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final weekValues = [1850, 1920, 2100, 1780, 2200, 1950, totalCalories > 0 ? totalCalories : 1800];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('İstatistik & Analiz'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Weekly Calorie Bar Chart Card
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, color: AppTheme.primaryEmerald, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'HAFTALIK KALORİ DAĞILIMI',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Hedef: $_dailyGoal',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Custom Bar Chart
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final val = weekValues[index];
                      final isToday = index == 6;
                      final ratio = (val / 2800).clamp(0.1, 1.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$val',
                            style: TextStyle(
                              color: isToday ? AppTheme.primaryLight : const Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 22,
                            height: 100 * ratio,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isToday
                                    ? [AppTheme.primaryEmerald, const Color(0xFF06B6D4)]
                                    : [const Color(0xFF2E3D66), const Color(0xFF1F2F57)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weekDays[index],
                            style: TextStyle(
                              color: isToday ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Macro Ratio Distribution Card
          GlassPanel(
            radius: 26,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, color: AppTheme.carbsColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'MAKRO KALORİ ORANLARI',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stacked Ratio Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Expanded(flex: proteinPercent, child: Container(color: AppTheme.proteinColor)),
                        const SizedBox(width: 2),
                        Expanded(flex: carbsPercent, child: Container(color: AppTheme.carbsColor)),
                        const SizedBox(width: 2),
                        Expanded(flex: fatPercent, child: Container(color: AppTheme.fatColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Protein', '%$proteinPercent', '${totalProtein.toInt()}g', AppTheme.proteinColor),
                    _buildLegendItem('Karb.', '%$carbsPercent', '${totalCarbs.toInt()}g', AppTheme.carbsColor),
                    _buildLegendItem('Yağ', '%$fatPercent', '${totalFat.toInt()}g', AppTheme.fatColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Haftalık beslenme içgörüsü
          GlassPanel(
            radius: 24,
            padding: const EdgeInsets.all(18),
            tint: AppTheme.primaryEmerald,
            tintAlpha: 0.14,
            borderColor: AppTheme.primaryEmerald.withValues(alpha: 0.4),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xE610B981),
                  radius: 18,
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beslenme Değerlendirmesi',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Haftalık protein alımın gayet dengeli seviyede! Akşam öğünlerinde lif ve su tüketimini biraz daha artırarak sindirimini ve tokluk süreni maksimize edebilirsin.',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String percent, String grams, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title $percent',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              grams,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
