import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AnimatedOrbsBackground extends StatefulWidget {
  const AnimatedOrbsBackground({super.key});

  @override
  State<AnimatedOrbsBackground> createState() => _AnimatedOrbsBackgroundState();
}

class _AnimatedOrbsBackgroundState extends State<AnimatedOrbsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        final size = MediaQuery.of(context).size;
        
        return Stack(
          children: [
            // Base background
            Container(color: context.rrBg),
            
            // Orb 1: Indigo (moves in an infinity loop)
            Positioned(
              left: size.width * 0.5 + sin(t) * size.width * 0.4 - 150,
              top: size.height * 0.4 + sin(t * 2) * size.height * 0.2 - 150,
              child: _buildOrb(AppColors.indigo, 300),
            ),
            
            // Orb 2: Score5 (Teal) (moves in a circle)
            Positioned(
              left: size.width * 0.5 + cos(t * 1.5) * size.width * 0.3 - 120,
              top: size.height * 0.6 + sin(t * 1.5) * size.height * 0.3 - 120,
              child: _buildOrb(AppColors.score5, 240),
            ),
            
            // Orb 3: Accent Blue (moves up and down)
            Positioned(
              left: size.width * 0.2 + cos(t * 0.8) * size.width * 0.2 - 100,
              top: size.height * 0.2 + sin(t * 1.2) * size.height * 0.2 - 100,
              child: _buildOrb(AppColors.score3, 200),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          )
        ],
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
