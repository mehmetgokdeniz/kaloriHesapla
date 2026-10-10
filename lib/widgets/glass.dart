import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Uygulama genelinde cam zemini: koyu gradyan + yumuşak renk küreleri.
/// MaterialApp.builder ile tüm route'ların arkasına yerleştirilir.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF060A16), Color(0xFF0A1122), Color(0xFF070B18)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        _orb(Alignment(-1.15, -0.85), 330, const Color(0xFF10B981), 0.34),
        _orb(const Alignment(1.25, -0.15), 310, const Color(0xFF22D3EE), 0.18),
        _orb(const Alignment(-1.05, 0.65), 300, const Color(0xFF7C3AED), 0.24),
        _orb(const Alignment(0.95, 1.15), 270, const Color(0xFFF59E0B), 0.12),
        Positioned.fill(child: child),
      ],
    );
  }

  static Widget _orb(Alignment alignment, double size, Color color, double alpha) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

/// Liquid glass kart: bulanık arka plan + yarı saydam dolgu + parlak üst kenar.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Vurgu rengi (varsayılan beyaz cam).
  final Color? tint;
  final double tintAlpha;
  final Color? borderColor;
  final double borderWidth;
  final bool showSheen;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.blur = 18,
    this.tint,
    this.tintAlpha = 0.10,
    this.borderColor,
    this.borderWidth = 1,
    this.showSheen = true,
  });

  @override
  Widget build(BuildContext context) {
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular(radius > borderWidth ? radius - borderWidth : 0);

    final fill = tint != null
        ? [tint!.withValues(alpha: tintAlpha), Colors.white.withValues(alpha: 0.03)]
        : [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.035)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: outer,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.16),
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: inner,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: fill,
                    ),
                  ),
                ),
              ),
              if (showSheen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
