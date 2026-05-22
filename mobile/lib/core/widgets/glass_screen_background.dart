import 'package:flutter/material.dart';

/// Full-screen gradient background with soft glow orbs (auth / governance glass UI).
class GlassScreenBackground extends StatelessWidget {
  const GlassScreenBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF81C784), Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: -70, right: -30, child: _GlowOrb(size: 170, alpha: 0.11)),
          const Positioned(bottom: 40, left: -50, child: _GlowOrb(size: 210, alpha: 0.1)),
          ?child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}
