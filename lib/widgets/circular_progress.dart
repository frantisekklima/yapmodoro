import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularTimerProgress extends StatefulWidget {
  final double progress;
  final List<Color> gradientColors;
  final double strokeWidth;
  final Widget? child;
  final bool isWavy; // Whether to render wavy squiggles (M3 Expressive)
  final DateTime? targetTime;
  final int totalDurationSeconds;
  final bool isRunning;
  final bool isDynamicFocus;

  const CircularTimerProgress({
    super.key,
    required this.progress,
    required this.gradientColors,
    this.strokeWidth = 12.0,
    this.child,
    this.isWavy = false,
    this.targetTime,
    this.totalDurationSeconds = 0,
    this.isRunning = false,
    this.isDynamicFocus = false,
  });

  @override
  State<CircularTimerProgress> createState() => _CircularTimerProgressState();
}

class _CircularTimerProgressState extends State<CircularTimerProgress> with SingleTickerProviderStateMixin {
  late AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    
    // Controller for continuous flowing wave phase shift and high-resolution redraws
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (widget.isRunning) {
      _phaseController.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularTimerProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _phaseController.repeat();
      } else {
        _phaseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _phaseController,
      builder: (context, child) {
        final double phase = widget.isWavy ? _phaseController.value * 2 * math.pi : 0.0;

        // Calculate smooth high-resolution progress in real-time
        double smoothProgress = widget.progress;
        if (widget.isRunning && widget.targetTime != null && widget.totalDurationSeconds > 0) {
          final remainingMs = widget.targetTime!.difference(DateTime.now()).inMilliseconds;
          if (remainingMs > 0) {
            final totalMs = widget.totalDurationSeconds * 1000;
            smoothProgress = ((totalMs - remainingMs) / totalMs).clamp(0.0, 1.0);
          } else {
            smoothProgress = 1.0;
          }
        }

        return AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _CircularTimerExpressivePainter(
                  progress: smoothProgress,
                  gradientColors: widget.gradientColors,
                  strokeWidth: widget.strokeWidth,
                  isWavy: widget.isWavy,
                  phase: phase,
                  theme: theme,
                  isDynamicFocus: widget.isDynamicFocus,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _CircularTimerExpressivePainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final double strokeWidth;
  final bool isWavy;
  final double phase;
  final ThemeData theme;
  final bool isDynamicFocus;

  _CircularTimerExpressivePainter({
    required this.progress,
    required this.gradientColors,
    required this.strokeWidth,
    required this.isWavy,
    required this.phase,
    required this.theme,
    required this.isDynamicFocus,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final center = s.center(Offset.zero);
    final baseRadius = (math.min(s.width, s.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: baseRadius);

    final trackColor = theme.colorScheme.onSurface.withOpacity(0.08);
    final Color activeColor = gradientColors.isNotEmpty ? gradientColors.first : theme.colorScheme.primary;

    // Static completely closed track ring when resting at zero progress
    if (progress <= 0.0 && !isWavy) {
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true
        ..color = trackColor;
      canvas.drawCircle(center, baseRadius, trackPaint);
      return;
    }

    final double activeSweep = progress.clamp(0.0, 1.0) * math.pi * 2;
    
    // Wave activates at 10% progress and stops at 90% progress (except for continuous Dynamic Focus at 1.0)
    double waveFactor = 0.0;
    if (isDynamicFocus) {
      waveFactor = 1.0;
    } else {
      if (progress >= 0.10 && progress <= 0.90) {
        waveFactor = 1.0;
      }
    }
    
    // Smooth circle opening track factors (0.0 to 0.05 progress window)
    double openingFactor = (progress / 0.05).clamp(0.0, 1.0);
    double closingFactor = ((1.0 - progress) / 0.05).clamp(0.0, 1.0);
    double globalGapFactor = math.min(openingFactor, closingFactor);
    
    final start = -math.pi / 2; // Fixed 12 o'clock position
    final end = start + activeSweep;

    final gapDp = strokeWidth * 1.2; // Halved gap size
    final gapAngle = gapDp / baseRadius; 
    final currentGapAngle = gapAngle * globalGapFactor;

    // Angle displacement of a single rounded stroke cap
    final capAngle = (strokeWidth / 2) / baseRadius;

    // 1. Draw Broken Background Track with cap compensation for smooth opening
    if (progress < 1.0) {
      final double trackSweep = (math.pi * 2) - activeSweep - (4 * capAngle) - (currentGapAngle * 2);
      
      if (trackSweep > 0) {
        final trackPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = trackColor;
        
        final trackStart = end + (2 * capAngle) + currentGapAngle;
        canvas.drawArc(rect, trackStart, trackSweep, false, trackPaint);
      }
    }

    // 2. Draw Active Progress Path
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = activeColor;

    if (isWavy && waveFactor > 0.0) {
      final amp = 5.0 * waveFactor; 
      final scallopLen = 46.0; 

      final double arcLength = baseRadius * activeSweep;
      final int steps = math.max(360, (arcLength * 3.0).round());
      final path = Path();

      final double totalArcLen = baseRadius * activeSweep;
      final bool isClosedCircle = progress >= 1.0;

      double effectiveScallopLen = scallopLen;
      if (isClosedCircle) {
        final double numWaves = (totalArcLen / scallopLen).roundToDouble();
        if (numWaves > 0) {
          effectiveScallopLen = totalArcLen / numWaves;
        }
      }

      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final ang = start + (end - start) * t;
        final arcLen = baseRadius * (ang - start);
        
        // Uniform swinging endpoints
        final r = baseRadius + amp * math.sin(arcLen / effectiveScallopLen * 2 * math.pi + phase);
        final p = Offset(center.dx + r * math.cos(ang), center.dy + r * math.sin(ang));

        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }

      if (isClosedCircle) {
        path.close();
      }

      canvas.drawPath(path, activePaint);
    } else {
      // Draw flat expressive rounded arc when outside the active wave windows
      canvas.drawArc(rect, start, activeSweep, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerExpressivePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isWavy != isWavy ||
        oldDelegate.phase != phase ||
        oldDelegate.theme != theme ||
        oldDelegate.isDynamicFocus != isDynamicFocus;
  }
}
