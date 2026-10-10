import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class CalorieProgressCard extends StatelessWidget {
  final int consumedCalories;
  final int goalCalories;
  final VoidCallback? onAdjustGoal;

  const CalorieProgressCard({
    super.key,
    required this.consumedCalories,
    required this.goalCalories,
    this.onAdjustGoal,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = goalCalories - consumedCalories;
    final progress = goalCalories > 0 ? (consumedCalories / goalCalories).clamp(0.0, 1.0) : 0.0;
    final isExceeded = remaining < 0;

    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GÜNLÜK KALORİ DURUMU',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isExceeded
                        ? '${remaining.abs()} kcal aşıldı'
                        : '$remaining kcal kaldı',
                    style: TextStyle(
                      color: isExceeded ? const Color(0xFFEF4444) : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: onAdjustGoal,
                icon: const Icon(Icons.tune_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.darkCardElevated,
                  foregroundColor: Colors.white70,
                ),
                tooltip: 'Hedefi Değiştir',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Custom Circular Progress Ring
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Ring Stack
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExceeded ? const Color(0xFFEF4444) : AppTheme.primaryEmerald,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExceeded ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
                            color: isExceeded ? const Color(0xFFEF4444) : AppTheme.primaryEmerald,
                            size: 26,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '%${(progress * 100).toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatItem(
                    label: 'Alınan Kalori',
                    value: '$consumedCalories',
                    unit: 'kcal',
                    color: AppTheme.primaryEmerald,
                    icon: Icons.restaurant_rounded,
                  ),
                  const SizedBox(height: 12),
                  _StatItem(
                    label: 'Hedef Kalori',
                    value: '$goalCalories',
                    unit: 'kcal',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.flag_rounded,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
            RichText(
              text: TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
