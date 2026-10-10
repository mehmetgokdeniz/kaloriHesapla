import 'package:flutter/material.dart';
import '../models/meal_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onMealChanged;

  const HistoryScreen({super.key, this.onMealChanged});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MealItem> _allMeals = [];
  MealType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  void _loadMeals() {
    setState(() {
      _allMeals = StorageService.getMeals();
    });
  }

  Future<void> _deleteMeal(String id) async {
    await StorageService.deleteMeal(id);
    _loadMeals();
    widget.onMealChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öğün silindi.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showMealDetails(MealItem meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    meal.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${meal.calories} kcal',
                  style: const TextStyle(color: AppTheme.primaryLight, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${meal.mealType.displayName} • ${meal.portion}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.darkBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroCol('Protein', '${meal.protein}g', AppTheme.proteinColor),
                _buildMacroCol('Karb.', '${meal.carbs}g', AppTheme.carbsColor),
                _buildMacroCol('Yağ', '${meal.fat}g', AppTheme.fatColor),
                _buildMacroCol('Lif', '${meal.fiber}g', AppTheme.fiberColor),
              ],
            ),
            if (meal.healthTip.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  meal.healthTip,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
              ),
            ],
            if (meal.ingredients.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meal.ingredients.map((ing) {
                  return Chip(
                    label: Text(ing, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    backgroundColor: AppTheme.darkCardElevated,
                    side: const BorderSide(color: AppTheme.darkBorder),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMeals = _filterType == null
        ? _allMeals
        : _allMeals.where((m) => m.mealType == _filterType).toList();

    final totalCalories = filteredMeals.fold<int>(0, (sum, m) => sum + m.calories);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Öğün Geçmişi'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tümü'),
                  selected: _filterType == null,
                  selectedColor: AppTheme.primaryEmerald,
                  backgroundColor: AppTheme.darkCard,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                ...MealType.values.map((type) {
                  final isSelected = _filterType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${type.iconAssetOrEmoji} ${type.displayName}'),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryEmerald,
                      backgroundColor: AppTheme.darkCard,
                      onSelected: (val) {
                        setState(() => _filterType = val ? type : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Total Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredMeals.length} Öğün Listelendi',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                Text(
                  'Toplam: $totalCalories kcal',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Meal List
          Expanded(
            child: filteredMeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_meals_rounded, size: 54, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        const Text(
                          'Kayıtlı öğün bulunamadı',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = filteredMeals[index];
                      return MealCard(
                        meal: meal,
                        onTap: () => _showMealDetails(meal),
                        onDelete: () => _deleteMeal(meal.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
