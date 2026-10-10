import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarItem {
  final String label;
  final String emoji;
  final List<Color> gradientColors;
  final IconData icon;

  const AvatarItem({
    required this.label,
    required this.emoji,
    required this.gradientColors,
    required this.icon,
  });
}

class AppAvatars {
  static const List<AvatarItem> presets = [
    AvatarItem(
      label: 'Fit & Atletik',
      emoji: '🏃‍♂️',
      gradientColors: [Color(0xFF10B981), Color(0xFF06B6D4)],
      icon: Icons.directions_run_rounded,
    ),
    AvatarItem(
      label: 'Sağlıklı Yaşam',
      emoji: '🥑',
      gradientColors: [Color(0xFF059669), Color(0xFF84CC16)],
      icon: Icons.eco_rounded,
    ),
    AvatarItem(
      label: 'Enerjik & Hızlı',
      emoji: '⚡',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      icon: Icons.bolt_rounded,
    ),
    AvatarItem(
      label: 'Güç & Kas',
      emoji: '🏋️‍♂️',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
      icon: Icons.fitness_center_rounded,
    ),
    AvatarItem(
      label: 'Gurme & Diyet',
      emoji: '🥗',
      gradientColors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      icon: Icons.favorite_rounded,
    ),
    AvatarItem(
      label: 'Elit Şampiyon',
      emoji: '👑',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  static AvatarItem get(int index) {
    if (index < 0 || index >= presets.length) return presets[0];
    return presets[index];
  }
}

class UserAvatarWidget extends StatelessWidget {
  final int avatarIndex;
  final double size;
  final bool showBadge;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    required this.avatarIndex,
    this.size = 56,
    this.showBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatars.get(avatarIndex);

    final content = Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow Ring
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: avatar.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: avatar.gradientColors[0].withValues(alpha: 0.35),
                blurRadius: size * 0.25,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Center(
            child: Text(
              avatar.emoji,
              style: TextStyle(fontSize: size * 0.46),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 14,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
