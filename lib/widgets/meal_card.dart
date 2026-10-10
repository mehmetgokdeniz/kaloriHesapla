import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_item.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class MealCard extends StatelessWidget {
  final MealItem meal;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MealCard({
    super.key,
    required this.meal,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(meal.dateTime);

    Color scoreColor;
    if (meal.healthScore >= 8) {
      scoreColor = AppTheme.scoreHigh;
    } else if (meal.healthScore >= 5) {
      scoreColor = AppTheme.scoreMid;
    } else {
      scoreColor = AppTheme.scoreLow;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        radius: 20,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal Type Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Text(
                        meal.mealType.iconAssetOrEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Time/Portion
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${meal.mealType.displayName} • $timeStr • ${meal.portion}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Calorie Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${meal.calories} kcal',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Health Score Chip
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 12, color: scoreColor),
                            const SizedBox(width: 2),
                            Text(
                              '${meal.healthScore}/10',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Macro Pills
                Row(
                  children: [
                    _MacroPill(label: 'P', value: '${meal.protein.toStringAsFixed(1)}g', color: AppTheme.proteinColor),
                    const SizedBox(width: 8),
                    _MacroPill(label: 'K', value: '${meal.carbs.toStringAsFixed(1)}g', color: AppTheme.carbsColor),
                    const SizedBox(width: 8),
                    _MacroPill(label: 'Y', value: '${meal.fat.toStringAsFixed(1)}g', color: AppTheme.fatColor),
                    if (meal.fiber > 0) ...[
                      const SizedBox(width: 8),
                      _MacroPill(label: 'Lif', value: '${meal.fiber.toStringAsFixed(1)}g', color: AppTheme.fiberColor),
                    ],
                    const Spacer(),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF64748B), size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Sil',
                        onPressed: onDelete,
                      ),
                  ],
                ),
                // Health Tip preview if available
                if (meal.healthTip.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCardElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meal.healthTip,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
