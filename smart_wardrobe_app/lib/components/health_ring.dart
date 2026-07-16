import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Animated health score ring with color coding.
class HealthRing extends StatefulWidget {
  final int score;
  final double size;

  const HealthRing({super.key, required this.score, this.size = 160});

  @override
  State<HealthRing> createState() => _HealthRingState();
}

class _HealthRingState extends State<HealthRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: 0, end: widget.score.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 90) return AppColors.green;
    if (score >= 60) return AppColors.gold;
    if (score >= 40) return AppColors.amber;
    return AppColors.red;
  }

  String _scoreLabel(int score) {
    if (score >= 90) return '✦ Exceptional';
    if (score >= 75) return '◈ Great';
    if (score >= 60) return '▲ Good';
    if (score >= 40) return '◇ Fair';
    return '○ Low';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final score = _animation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              score: score,
              color: _scoreColor(score),
              strokeWidth: 8,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toInt().toString(),
                    style: AppTheme.metricValue.copyWith(
                      color: _scoreColor(score),
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    _scoreLabel(widget.score),
                    style: AppTheme.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final Color color;
  final double strokeWidth;

  _RingPainter({required this.score, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.bgSurface2
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score ring
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.score != score;
}
