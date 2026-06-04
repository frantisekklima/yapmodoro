import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../providers/timer_provider.dart';
import '../widgets/circular_progress.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  late final AnimationController _startClickController;
  late final AnimationController _leftClickController;
  late final AnimationController _centerClickController;
  late final AnimationController _rightClickController;

  @override
  void initState() {
    super.initState();
    _startClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _leftClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _centerClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rightClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _startClickController.dispose();
    _leftClickController.dispose();
    _centerClickController.dispose();
    _rightClickController.dispose();
    super.dispose();
  }

  double _getBounceValue(AnimationController controller) {
    if (!controller.isAnimating) return 0.0;
    final t = controller.value;
    return math.sin(t * math.pi);
  }

  double get _startButtonScaleX {
    return 1.0 + 0.15 * _getBounceValue(_startClickController);
  }

  double get _leftButtonScaleX {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_leftClickController);
    scale -= 0.15 * _getBounceValue(_centerClickController);
    return scale;
  }

  double get _rightButtonScaleX {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_rightClickController);
    scale -= 0.15 * _getBounceValue(_centerClickController);
    return scale;
  }

  double get _centerButtonScaleX {
    double scale = 1.0;
    scale += 0.22 * _getBounceValue(_centerClickController);
    scale -= 0.15 * _getBounceValue(_leftClickController);
    scale -= 0.15 * _getBounceValue(_rightClickController);
    return scale;
  }

  Alignment get _centerButtonAlignment {
    if (_leftClickController.isAnimating) {
      return Alignment.centerRight;
    }
    if (_rightClickController.isAnimating) {
      return Alignment.centerLeft;
    }
    return Alignment.center;
  }

  void _onLeftButtonPressed(VoidCallback action) {
    if (_leftClickController.isAnimating) return;
    _leftClickController.forward(from: 0.0).then((_) {
      _leftClickController.reset();
      action();
    });
  }

  void _onCenterButtonPressed(VoidCallback action) {
    if (_centerClickController.isAnimating) return;
    _centerClickController.forward(from: 0.0).then((_) {
      _centerClickController.reset();
      action();
    });
  }

  void _onRightButtonPressed(VoidCallback action) {
    if (_rightClickController.isAnimating) return;
    _rightClickController.forward(from: 0.0).then((_) {
      _rightClickController.reset();
      action();
    });
  }

  void _onStartButtonPressed(VoidCallback action) {
    if (_startClickController.isAnimating) return;
    _startClickController.forward(from: 0.0).then((_) {
      _startClickController.reset();
      action();
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  // Helper to determine the ordinal suffix (1st, 2nd, 3rd, 4th, etc.)
  String _getOrdinal(int number) {
    if (number <= 0) return "1st";
    if (number % 100 >= 11 && number % 100 <= 13) {
      return "${number}th";
    }
    switch (number % 10) {
      case 1:
        return "${number}st";
      case 2:
        return "${number}nd";
      case 3:
        return "${number}rd";
      default:
        return "${number}th";
    }
  }

  // Material 3 Expressive helper to guarantee high contrast between focus and break colors
  Color _getBreakColor(ThemeData theme) {
    return theme.colorScheme.tertiary;
  }

  @override
  Widget build(BuildContext context) {
    final provider = TimerProvider.instance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final currentTimerState = provider.state;
        final currentTimerMode = provider.mode;

        // Break and Work phase checks
        final bool isBreak = currentTimerState == AppTimerState.breakTime ||
            (currentTimerState == AppTimerState.paused && provider.pausedState == AppTimerState.breakTime);

        final bool isWork = currentTimerState == AppTimerState.working ||
            (currentTimerState == AppTimerState.paused && provider.pausedState == AppTimerState.working);

        final bool isIdle = currentTimerState == AppTimerState.idle;

        final bool isDynamicFocus = currentTimerMode == AppTimerMode.dynamicMode && isWork;

        // Expressive Material 3 Dynamic Colors derived entirely from system settings
        final Color modePrimaryColor = isBreak ? _getBreakColor(theme) : theme.colorScheme.primary;

        final themeColors = [modePrimaryColor, modePrimaryColor.withOpacity(0.85)];

        final bool showAdjustButtons = currentTimerMode == AppTimerMode.classic ||
            (currentTimerMode == AppTimerMode.dynamicMode && isBreak);

        final Color adjustButtonBg = theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceVariant
            : modePrimaryColor.withOpacity(0.08);

        // Calculate today's completed focus sessions count
        final today = DateTime.now();
        final int todayFocusCount = provider.sessions
            .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day)
            .length;

        // Compute session indicators (Ordinal Flow and Daily Total)
        String sessionIndicator = "";
        String dailyIndicator = "";
        
        if (isBreak) {
          sessionIndicator = "${_getOrdinal(provider.currentFlowSessionIndex)} Break";
          dailyIndicator = "${_getOrdinal(todayFocusCount)} Break of the day";
        } else {
          sessionIndicator = "${_getOrdinal(provider.currentFlowSessionIndex + 1)} Focus";
          dailyIndicator = "${_getOrdinal(todayFocusCount + 1)} Focus of the day";
        }

        // Split sessionIndicator to style the ordinal part in italic & larger size
        final parts = sessionIndicator.split(' ');
        final String ordinalPart = parts.isNotEmpty ? parts[0] : '';
        final String phasePart = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        // Timer string
        String timerString = "00:00";
        if (isIdle) {
          timerString = currentTimerMode == AppTimerMode.classic
              ? '${(provider.classicWorkMinutes + (provider.classicWorkAdjustmentSeconds ~/ 60)).toString().padLeft(2, '0')}:00'
              : '00:00';
        } else if (isWork) {
          timerString = currentTimerMode == AppTimerMode.dynamicMode
              ? _formatDuration(provider.elapsedSeconds)
              : _formatDuration(provider.remainingSeconds);
        } else if (isBreak) {
          timerString = _formatDuration(provider.remainingSeconds);
        }

        // 1. Running: progress bar is beautifully squiggly and animated
        // 2. Stopped/Paused: progress bar freezes instantly into a solid rounded M3E broken arc
        // 3. Dynamic Focus: 1.0 (completely filled) progress ring
        double progress = 0.0;
        bool isWavy = false;

        if (currentTimerState == AppTimerState.idle) {
          progress = 0.0;
          isWavy = false;
        } else if (currentTimerState == AppTimerState.working) {
          isWavy = true; // Wavy when running
          progress = currentTimerMode == AppTimerMode.dynamicMode ? 1.0 : provider.progressPercentage;
        } else if (currentTimerState == AppTimerState.breakTime) {
          isWavy = true; // Wavy when running
          progress = provider.progressPercentage;
        } else if (currentTimerState == AppTimerState.paused) {
          isWavy = false; // Freeze and solidify instantly when paused
          if (provider.pausedState == AppTimerState.working) {
            progress = currentTimerMode == AppTimerMode.dynamicMode ? 1.0 : provider.progressPercentage;
          } else if (provider.pausedState == AppTimerState.breakTime) {
            progress = provider.progressPercentage;
          }
        }



        final modifiedTheme = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: modePrimaryColor,
            secondary: modePrimaryColor,
            primaryContainer: isBreak ? theme.colorScheme.tertiaryContainer : theme.colorScheme.primaryContainer,
            onPrimaryContainer: isBreak ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onPrimaryContainer,
            secondaryContainer: isBreak ? theme.colorScheme.tertiaryContainer : theme.colorScheme.secondaryContainer,
            onSecondaryContainer: isBreak ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onSecondaryContainer,
          ),
        );

        return Theme(
          data: modifiedTheme,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const SizedBox(height: 10),
                // Ordinal Session Indicator - fun typography
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: "$ordinalPart ",
                        style: TextStyle(
                          color: modePrimaryColor,
                          fontSize: 32.0,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: phasePart,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.8),
                          fontSize: 24.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Daily Session Indicator
                Text(
                  dailyIndicator,
                  style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.45),
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
 
                // Circular Timer Display
                Center(
                  child: SizedBox(
                    width: (MediaQuery.of(context).size.width * 0.72).clamp(200.0, 300.0),
                    height: (MediaQuery.of(context).size.width * 0.72).clamp(200.0, 300.0),
                    child: CircularTimerProgress(
                      progress: progress,
                      gradientColors: themeColors,
                      isWavy: isWavy,
                      strokeWidth: 12.0,
                      targetTime: provider.segmentTargetTime,
                      totalDurationSeconds: provider.totalDurationForCurrentSegment,
                      isRunning: currentTimerState == AppTimerState.working || currentTimerState == AppTimerState.breakTime,
                      isDynamicFocus: isDynamicFocus,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showAdjustButtons) ...[
                            IconButtonM3E(
                              onPressed: () => provider.addMinute(),
                              icon: const Icon(Icons.add_rounded, size: 20.0),
                              variant: IconButtonM3EVariant.tonal,
                              size: IconButtonM3ESize.sm,
                              shape: IconButtonM3EShapeVariant.round,
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            timerString,
                            style: TextStyle(
                              color: theme.colorScheme.onBackground,
                              fontSize: 54.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                          if (showAdjustButtons) ...[
                            const SizedBox(height: 6),
                            IconButtonM3E(
                              onPressed: () => provider.subtractMinute(),
                              icon: const Icon(Icons.remove_rounded, size: 20.0),
                              variant: IconButtonM3EVariant.tonal,
                              size: IconButtonM3ESize.sm,
                              shape: IconButtonM3EShapeVariant.round,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                if (provider.enableBreakRollover && provider.carryOverBreakSeconds > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14.0,
                        color: modePrimaryColor.withOpacity(0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "+${provider.carryOverBreakSeconds ~/ 60}:${(provider.carryOverBreakSeconds % 60).toString().padLeft(2, '0')} overflow will be added to next break",
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.65),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Mode Switcher (Classic vs Dynamic)
                _buildModeSwitcher(provider, isIdle, modifiedTheme, modePrimaryColor),

                const SizedBox(height: 24),

                // Action Buttons Control Board
                _buildControlBoard(provider, modifiedTheme, isIdle, isWork, isBreak, modePrimaryColor),

                const SizedBox(height: 40), // Balanced space for bottom nav
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  // Pill Mode Switcher Widget (No glassmorphism, solid M3 surfaces, no border)
  Widget _buildModeSwitcher(TimerProvider provider, bool isIdle, ThemeData theme, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            provider,
            AppTimerMode.classic,
            "Classic",
            isIdle,
            provider.mode == AppTimerMode.classic,
            true, // isLeft = true
            theme,
            primaryColor,
          ),
          const SizedBox(width: 2),
          _buildModeButton(
            provider,
            AppTimerMode.dynamicMode,
            "Dynamic",
            isIdle,
            provider.mode == AppTimerMode.dynamicMode,
            false, // isLeft = false
            theme,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    TimerProvider provider,
    AppTimerMode targetMode,
    String text,
    bool isIdle,
    bool isSelected,
    bool isLeft,
    ThemeData theme,
    Color primaryColor,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    // Morphing BorderRadius:
    // Selected button: fully rounded pill (28.0)
    // Unselected left button: fully rounded outer (left) edge, partially rounded inner (right) edge
    // Unselected right button: partially rounded inner (left) edge, fully rounded outer (right) edge
    final BorderRadius borderRadius = isSelected
        ? BorderRadius.circular(28.0)
        : (isLeft
            ? const BorderRadius.only(
                topLeft: Radius.circular(28.0),
                bottomLeft: Radius.circular(28.0),
                topRight: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                bottomLeft: Radius.circular(12.0),
                topRight: Radius.circular(28.0),
                bottomRight: Radius.circular(28.0),
              ));

    // Dynamic backgrounds
    final Color bgColor = isSelected
        ? primaryColor
        : (isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.35)
            : primaryColor.withOpacity(0.08));

    // Dynamic text and icon colors
    final Color contentColor = isSelected
        ? Colors.white
        : (isIdle
            ? primaryColor.withOpacity(0.85)
            : primaryColor.withOpacity(0.35));

    return GestureDetector(
      onTap: isIdle ? () => provider.setMode(targetMode) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_rounded,
                  color: contentColor,
                  size: 16.0,
                ),
                const SizedBox(width: 8.0),
              ],
              Text(
                text,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 13.0,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpressiveButton({
    required VoidCallback onPressed,
    required IconData iconData,
    required bool isFilled,
    required double scaleX,
    required double baseSize,
    required IconButtonM3EShapeVariant shape,
    required Alignment alignment,
    required String position,
    required ThemeData theme,
  }) {
    final double width = baseSize * scaleX;
    final double height = baseSize;

    final Color bgColor = isFilled
        ? theme.colorScheme.primary
        : theme.colorScheme.secondaryContainer;

    final Color iconColor = isFilled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSecondaryContainer;

    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: OverflowBox(
        alignment: alignment,
        minWidth: 0.0,
        maxWidth: double.infinity,
        minHeight: 0.0,
        maxHeight: double.infinity,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: ExpressiveButtonPainter(
              width: width,
              height: height,
              color: bgColor,
              shape: shape,
              position: position,
              isLeftAnimating: _leftClickController.isAnimating,
              isCenterAnimating: _centerClickController.isAnimating,
              isRightAnimating: _rightClickController.isAnimating,
              leftValue: _getBounceValue(_leftClickController),
              centerValue: _getBounceValue(_centerClickController),
              rightValue: _getBounceValue(_rightClickController),
            ),
            child: ClipPath(
              clipper: ExpressiveButtonClipper(
                width: width,
                height: height,
                shape: shape,
                position: position,
                isLeftAnimating: _leftClickController.isAnimating,
                isCenterAnimating: _centerClickController.isAnimating,
                isRightAnimating: _rightClickController.isAnimating,
                leftValue: _getBounceValue(_leftClickController),
                centerValue: _getBounceValue(_centerClickController),
                rightValue: _getBounceValue(_rightClickController),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  child: Center(
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: baseSize == 64.0 ? 36.0 : 28.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // M3 Expressive Symmetric Control Board (Left: circle Stop | Center: rectangular Action | Right: circle Pause)
  Widget _buildControlBoard(TimerProvider provider, ThemeData theme, bool isIdle, bool isWork, bool isBreak, Color primaryColor) {
    if (isIdle) {
      return Column(
        children: [
          _buildStartButton(provider, theme, primaryColor),
          const SizedBox(height: 12),
        ],
      );
    }

    final state = provider.state;
    final isPaused = state == AppTimerState.paused;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _leftClickController,
        _centerClickController,
        _rightClickController,
      ]),
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. LEFT Button: Stop (M3E Tonal, round shape)
              _buildExpressiveButton(
                onPressed: () => _onLeftButtonPressed(() => provider.stopTimer()),
                iconData: Icons.stop_rounded,
                isFilled: false,
                scaleX: _leftButtonScaleX,
                baseSize: 56.0,
                shape: IconButtonM3EShapeVariant.round,
                alignment: Alignment.centerLeft,
                position: 'left',
                theme: theme,
              ),
              const SizedBox(width: 8),

              // 2. CENTER Button: Primary Action (M3E Filled, square shape)
              _buildExpressiveButton(
                onPressed: () => _onCenterButtonPressed(() {
                  if (isWork) {
                    if (provider.mode == AppTimerMode.dynamicMode) {
                      provider.triggerDynamicBreak();
                    } else {
                      provider.skipToClassicBreak();
                    }
                  } else if (isBreak) {
                    provider.resumeWorkEarly();
                  }
                }),
                iconData: isWork
                    ? (provider.mode == AppTimerMode.dynamicMode
                        ? Icons.coffee_rounded
                        : Icons.skip_next_rounded)
                    : Icons.local_fire_department_rounded,
                isFilled: true,
                scaleX: _centerButtonScaleX,
                baseSize: 56.0,
                shape: IconButtonM3EShapeVariant.square,
                alignment: _centerButtonAlignment,
                position: 'center',
                theme: theme,
              ),
              const SizedBox(width: 8),

              // 3. RIGHT Button: Pause/Resume Toggle (M3E Tonal, round shape)
              _buildExpressiveButton(
                onPressed: () => _onRightButtonPressed(
                  isPaused ? () => provider.resumeTimer() : () => provider.pauseTimer(),
                ),
                iconData: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                isFilled: false,
                scaleX: _rightButtonScaleX,
                baseSize: 56.0,
                shape: IconButtonM3EShapeVariant.round,
                alignment: Alignment.centerRight,
                position: 'right',
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartButton(TimerProvider provider, ThemeData theme, Color primaryColor) {
    return AnimatedBuilder(
      animation: _startClickController,
      builder: (context, child) {
        return _buildExpressiveButton(
          onPressed: () => _onStartButtonPressed(() => provider.startTimer()),
          iconData: Icons.play_arrow_rounded,
          isFilled: true,
          scaleX: _startButtonScaleX,
          baseSize: 64.0,
          shape: IconButtonM3EShapeVariant.round,
          alignment: Alignment.center,
          position: 'start',
          theme: theme,
        );
      },
    );
  }
}

// HELPER CLASSES AND CUSTOM PAINTERS FOR EXPRESSIVE ANCHORED BUTTON ANIMATIONS

Path getExpressiveButtonPath({
  required double width,
  required double height,
  required IconButtonM3EShapeVariant shape,
  required String position,
  required bool isLeftAnimating,
  required bool isCenterAnimating,
  required bool isRightAnimating,
  required double leftValue,
  required double centerValue,
  required double rightValue,
  required Size size,
}) {
  final path = Path();

  if (shape == IconButtonM3EShapeVariant.round) {
    final double rBase = height / 2; // 28.0

    if (position == 'left' || position == 'right') {
      if (width >= height) {
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(rBase),
        ));
      } else {
        // Squishing: corner radius decreases vertically to create flat sides, while matching width horizontally to keep top/bottom normally curved
        final double rx = width / 2;
        final double ry = rBase - (rBase - 20.0) * centerValue;
        path.addRRect(RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, width, height),
          topLeft: Radius.elliptical(rx, ry),
          bottomLeft: Radius.elliptical(rx, ry),
          topRight: Radius.elliptical(rx, ry),
          bottomRight: Radius.elliptical(rx, ry),
        ));
      }
    } else {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(rBase),
      ));
    }
  } else {
    final double rBase = 16.0;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(rBase),
    ));
  }

  return path;
}

class ExpressiveButtonPainter extends CustomPainter {
  final double width;
  final double height;
  final Color color;
  final IconButtonM3EShapeVariant shape;
  final String position;
  final bool isLeftAnimating;
  final bool isCenterAnimating;
  final bool isRightAnimating;
  final double leftValue;
  final double centerValue;
  final double rightValue;

  ExpressiveButtonPainter({
    required this.width,
    required this.height,
    required this.color,
    required this.shape,
    required this.position,
    required this.isLeftAnimating,
    required this.isCenterAnimating,
    required this.isRightAnimating,
    required this.leftValue,
    required this.centerValue,
    required this.rightValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = getExpressiveButtonPath(
      width: width,
      height: height,
      shape: shape,
      position: position,
      isLeftAnimating: isLeftAnimating,
      isCenterAnimating: isCenterAnimating,
      isRightAnimating: isRightAnimating,
      leftValue: leftValue,
      centerValue: centerValue,
      rightValue: rightValue,
      size: size,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ExpressiveButtonPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.color != color ||
        oldDelegate.shape != shape ||
        oldDelegate.position != position ||
        oldDelegate.isLeftAnimating != isLeftAnimating ||
        oldDelegate.isCenterAnimating != isCenterAnimating ||
        oldDelegate.isRightAnimating != isRightAnimating ||
        oldDelegate.leftValue != leftValue ||
        oldDelegate.centerValue != centerValue ||
        oldDelegate.rightValue != rightValue;
  }
}

class ExpressiveButtonClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final IconButtonM3EShapeVariant shape;
  final String position;
  final bool isLeftAnimating;
  final bool isCenterAnimating;
  final bool isRightAnimating;
  final double leftValue;
  final double centerValue;
  final double rightValue;

  ExpressiveButtonClipper({
    required this.width,
    required this.height,
    required this.shape,
    required this.position,
    required this.isLeftAnimating,
    required this.isCenterAnimating,
    required this.isRightAnimating,
    required this.leftValue,
    required this.centerValue,
    required this.rightValue,
  });

  @override
  Path getClip(Size size) {
    return getExpressiveButtonPath(
      width: width,
      height: height,
      shape: shape,
      position: position,
      isLeftAnimating: isLeftAnimating,
      isCenterAnimating: isCenterAnimating,
      isRightAnimating: isRightAnimating,
      leftValue: leftValue,
      centerValue: centerValue,
      rightValue: rightValue,
      size: size,
    );
  }

  @override
  bool shouldReclip(covariant ExpressiveButtonClipper oldClipper) {
    return oldClipper.width != width ||
        oldClipper.height != height ||
        oldClipper.shape != shape ||
        oldClipper.position != position ||
        oldClipper.isLeftAnimating != isLeftAnimating ||
        oldClipper.isCenterAnimating != isCenterAnimating ||
        oldClipper.isRightAnimating != isRightAnimating ||
        oldClipper.leftValue != leftValue ||
        oldClipper.centerValue != centerValue ||
        oldClipper.rightValue != rightValue;
  }
}
