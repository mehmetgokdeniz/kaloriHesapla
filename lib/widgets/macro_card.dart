import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class MacroCard extends StatelessWidget {
  final double currentProtein;
  final double currentCarbs;
  final double currentFat;
  final int dailyCalorieGoal;

  const MacroCard({
    super.key,
    required this.currentProtein,
    required this.currentCarbs,
    required this.currentFat,
    required this.dailyCalorieGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Standart dengeli dağılım hedefleri
    final targetProtein = (dailyCalorieGoal * 0.25 / 4).round();
    final targetCarbs = (dailyCalorieGoal * 0.50 / 4).round();
    final targetFat = (dailyCalorieGoal * 0.25 / 9).round();

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MAKRO BESİN DEĞERLERİ',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroProgressItem(
                  title: 'Protein',
                  current: currentProtein,
                  target: targetProtein.toDouble(),
                  color: AppTheme.proteinColor,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgressItem(
                  title: 'Karbonhidrat',
                  current: currentCarbs,
                  target: targetCarbs.toDouble(),
                  color: AppTheme.carbsColor,
                  icon: Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgressItem(
                  title: 'Yağ',
                  current: currentFat,
                  target: targetFat.toDouble(),
                  color: AppTheme.fatColor,
                  icon: Icons.water_drop_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String title;
  final double current;
  final double target;
  final Color color;
  final IconData icon;

  const _MacroProgressItem({
    required this.title,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                '${(current).toStringAsFixed(0)}g',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '/${target.toInt()}g',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
