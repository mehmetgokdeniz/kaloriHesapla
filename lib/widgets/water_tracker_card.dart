import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'glass.dart';

class WaterTrackerCard extends StatefulWidget {
  final VoidCallback? onWaterChanged;

  const WaterTrackerCard({super.key, this.onWaterChanged});

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = StorageService.getProfile();
  }

  void _addWater(int deltaMl) async {
    await StorageService.updateWaterIntake(deltaMl);
    setState(() {
      _profile = StorageService.getProfile();
    });
    widget.onWaterChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    _profile = StorageService.getProfile();
    final effectiveGoal = _profile.waterGoalMl > 0 ? _profile.waterGoalMl : 2500;
    final progress = (_profile.waterIntakeMl / effectiveGoal).clamp(0.0, 1.0);
    final isCompleted = _profile.waterIntakeMl >= effectiveGoal;

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.all(18),
      borderColor: isCompleted ? const Color(0xFF06B6D4).withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF06B6D4), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GÜNLÜK SU TAKİBİ',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Hidrasyon Seviyesi',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  text: '${_profile.waterIntakeMl}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: ' / $effectiveGoal ml',
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
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addWater(250),
                  icon: const Icon(Icons.local_cafe_rounded, size: 16, color: Color(0xFF38BDF8)),
                  label: const Text('+250 ml'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.45)),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addWater(500),
                  icon: const Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFF06B6D4)),
                  label: const Text('+500 ml'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.45)),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _profile.waterIntakeMl >= 250 ? () => _addWater(-250) : null,
                icon: const Icon(Icons.remove_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  foregroundColor: Colors.white70,
                ),
                tooltip: '-250 ml Eksilt',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
