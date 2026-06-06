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
  late final AnimationController _leftClickController;
  late final AnimationController _centerClickController;
  late final AnimationController _rightClickController;
  late final AnimationController _stateTransitionController;
  late final AnimationController _leftPressedController;
  late final AnimationController _centerPressedController;
  late final AnimationController _rightPressedController;
  late final AnimationController _addClickController;
  late final AnimationController _subtractClickController;
  late final AnimationController _addPressedController;
  late final AnimationController _subtractPressedController;
  late final AnimationController _classicPressedController;
  late final AnimationController _dynamicPressedController;

  @override
  void initState() {
    super.initState();
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
    final state = TimerProvider.instance.state;
    _stateTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: (state == AppTimerState.idle || state == AppTimerState.paused) ? 0.0 : 1.0,
    );
    _leftPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _centerPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _rightPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _addClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _subtractClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _addPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _subtractPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _classicPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _dynamicPressedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    TimerProvider.instance.addListener(_onTimerStateChanged);
  }

  @override
  void dispose() {
    _leftClickController.dispose();
    _centerClickController.dispose();
    _rightClickController.dispose();
    _stateTransitionController.dispose();
    _leftPressedController.dispose();
    _centerPressedController.dispose();
    _rightPressedController.dispose();
    _addClickController.dispose();
    _subtractClickController.dispose();
    _addPressedController.dispose();
    _subtractPressedController.dispose();
    _classicPressedController.dispose();
    _dynamicPressedController.dispose();
    TimerProvider.instance.removeListener(_onTimerStateChanged);
    super.dispose();
  }

  void _onTimerStateChanged() {
    if (!mounted) return;
    final state = TimerProvider.instance.state;
    final shouldBeCircle = state == AppTimerState.idle || state == AppTimerState.paused;
    if (shouldBeCircle) {
      if (_stateTransitionController.value > 0.0 && !_stateTransitionController.isDismissed) {
        _stateTransitionController.reverse();
      }
    } else {
      if (_stateTransitionController.value < 1.0 && !_stateTransitionController.isCompleted) {
        _stateTransitionController.forward();
      }
    }
  }

  double _getBounceValue(AnimationController controller) {
    if (!controller.isAnimating) return 0.0;
    final t = controller.value;
    return math.sin(t * math.pi);
  }

  double _leftButtonScaleX(double pLeft, double pCenter) {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_leftClickController);
    scale -= 0.15 * _getBounceValue(_centerClickController);
    scale += 0.20 * pLeft;
    scale -= 0.15 * pCenter;
    return scale;
  }

  double _rightButtonScaleX(double pRight, double pCenter) {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_rightClickController);
    scale -= 0.15 * _getBounceValue(_centerClickController);
    scale += 0.20 * pRight;
    scale -= 0.15 * pCenter;
    return scale;
  }

  double _centerButtonScaleX(double pCenter, double pLeft, double pRight) {
    double scale = 1.0;
    scale += 0.22 * _getBounceValue(_centerClickController);
    scale -= 0.15 * _getBounceValue(_leftClickController);
    scale -= 0.15 * _getBounceValue(_rightClickController);
    scale += 0.22 * pCenter;
    scale -= 0.15 * pLeft;
    scale -= 0.15 * pRight;
    return scale;
  }

  double _addButtonScaleX(double pAdd) {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_addClickController);
    scale += 0.20 * pAdd;
    return scale;
  }

  double _subtractButtonScaleX(double pSubtract) {
    double scale = 1.0;
    scale += 0.20 * _getBounceValue(_subtractClickController);
    scale += 0.20 * pSubtract;
    return scale;
  }

  void _onAddButtonPressed(VoidCallback action) {
    _addClickController.forward(from: 0.0).then((_) {
      _addClickController.reset();
    });
    action();
  }

  void _onSubtractButtonPressed(VoidCallback action) {
    _subtractClickController.forward(from: 0.0).then((_) {
      _subtractClickController.reset();
    });
    action();
  }

  Alignment _getCenterButtonAlignment({
    required double scaleL,
    required double scaleR,
    required double scaleC,
  }) {
    final double wl = 64.0 * scaleL;
    final double wr = 64.0 * scaleR;
    final double wc = 96.0 * scaleC;
    final double diff = 96.0 - wc;
    if (diff.abs() < 1e-3) {
      return Alignment.center;
    }
    final double alignmentX = (wl - wr) / diff;
    return Alignment(alignmentX.clamp(-5.0, 5.0), 0.0);
  }

  void _onLeftButtonPressed(VoidCallback action) {
    _leftClickController.forward(from: 0.0).then((_) {
      _leftClickController.reset();
    });
    action();
  }

  void _onCenterButtonPressed(VoidCallback action) {
    _centerClickController.forward(from: 0.0).then((_) {
      _centerClickController.reset();
    });
    action();
  }

  void _onRightButtonPressed(VoidCallback action) {
    _rightClickController.forward(from: 0.0).then((_) {
      _rightClickController.reset();
    });
    action();
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
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _addClickController,
                          _addPressedController,
                          _subtractClickController,
                          _subtractPressedController,
                        ]),
                        builder: (context, _) {
                          final pAdd = _addPressedController.value;
                          final pSubtract = _subtractPressedController.value;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showAdjustButtons) ...[
                                _buildExpressiveButton(
                                  onPressed: () => _onAddButtonPressed(() => provider.addMinute()),
                                  iconData: Icons.add_rounded,
                                  isFilled: false,
                                  scaleX: _addButtonScaleX(pAdd),
                                  baseWidth: 40.0,
                                  baseHeight: 40.0,
                                  shape: IconButtonM3EShapeVariant.round,
                                  alignment: Alignment.center,
                                  position: 'add',
                                  theme: theme,
                                  pressedValue: pAdd,
                                  pressedController: _addPressedController,
                                  iconSize: 20.0,
                                  pressedRadius: 8.0,
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
                                _buildExpressiveButton(
                                  onPressed: () => _onSubtractButtonPressed(() => provider.subtractMinute()),
                                  iconData: Icons.remove_rounded,
                                  isFilled: false,
                                  scaleX: _subtractButtonScaleX(pSubtract),
                                  baseWidth: 40.0,
                                  baseHeight: 40.0,
                                  shape: IconButtonM3EShapeVariant.round,
                                  alignment: Alignment.center,
                                  position: 'subtract',
                                  theme: theme,
                                  pressedValue: pSubtract,
                                  pressedController: _subtractPressedController,
                                  iconSize: 20.0,
                                  pressedRadius: 8.0,
                                ),
                              ],
                            ],
                          );
                        },
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
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _classicPressedController,
          _dynamicPressedController,
        ]),
        builder: (context, _) {
          return Row(
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
                _classicPressedController,
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
                _dynamicPressedController,
              ),
            ],
          );
        },
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
    AnimationController pressedController,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final double p = pressedController.value;

    final double innerRadius = isSelected
        ? 28.0 - (28.0 - 4.0) * p
        : 8.0 - (8.0 - 4.0) * p;

    final BorderRadius borderRadius = isLeft
        ? BorderRadius.only(
            topLeft: const Radius.circular(28.0),
            bottomLeft: const Radius.circular(28.0),
            topRight: Radius.circular(innerRadius),
            bottomRight: Radius.circular(innerRadius),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(innerRadius),
            bottomLeft: Radius.circular(innerRadius),
            topRight: const Radius.circular(28.0),
            bottomRight: const Radius.circular(28.0),
          );

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

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: bgColor,
        child: InkWell(
          onTapDown: isIdle ? (_) => pressedController.forward() : null,
          onTapCancel: isIdle ? () => pressedController.reverse() : null,
          onTap: isIdle
              ? () {
                  pressedController.reverse();
                  provider.setMode(targetMode);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
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
        ),
      ),
    );
  }

  Widget _buildExpressiveButton({
    required VoidCallback onPressed,
    required IconData iconData,
    required bool isFilled,
    required double scaleX,
    required double baseWidth,
    required double baseHeight,
    required IconButtonM3EShapeVariant shape,
    required Alignment alignment,
    required String position,
    required ThemeData theme,
    double transitionValue = 1.0,
    double widthMultiplier = 1.0,
    bool enabled = true,
    double pressedValue = 0.0,
    required AnimationController pressedController,
    double centerPressedValue = 0.0,
    double iconSize = 32.0,
    double pressedRadius = 16.0,
  }) {
    final double width = baseWidth * scaleX * widthMultiplier;
    final double height = baseHeight;

    final Color bgColor = isFilled
        ? theme.colorScheme.primary
        : theme.colorScheme.secondaryContainer;

    final Color iconColor = isFilled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSecondaryContainer;

    final childWidget = SizedBox(
      width: baseWidth * widthMultiplier,
      height: baseHeight,
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
              transitionValue: transitionValue,
              pressedValue: pressedValue,
              centerPressedValue: centerPressedValue,
              pressedRadius: pressedRadius,
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
                transitionValue: transitionValue,
                pressedValue: pressedValue,
                centerPressedValue: centerPressedValue,
                pressedRadius: pressedRadius,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: enabled ? (_) => pressedController.forward() : null,
                  onTapCancel: enabled ? () => pressedController.reverse() : null,
                  onTap: enabled
                      ? () {
                          pressedController.reverse();
                          onPressed();
                        }
                      : null,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        iconData,
                        key: ValueKey(iconData),
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      return Opacity(
        opacity: 0.35,
        child: childWidget,
      );
    }
    return childWidget;
  }

  // M3 Expressive Control Board
  Widget _buildControlBoard(TimerProvider provider, ThemeData theme, bool isIdle, bool isWork, bool isBreak, Color primaryColor) {
    final state = provider.state;

    final bool isClassic = provider.mode == AppTimerMode.classic;
    final IconData rightIcon;
    final VoidCallback rightAction;
    final bool rightEnabled;

    if (isClassic) {
      final bool onBreak = state == AppTimerState.breakTime || (state == AppTimerState.paused && provider.pausedState == AppTimerState.breakTime);
      rightIcon = onBreak ? Icons.local_fire_department_rounded : Icons.skip_next_rounded;
      rightAction = onBreak
          ? () => provider.resumeWorkEarly()
          : () => provider.skipToClassicBreak();
      rightEnabled = state != AppTimerState.idle;
    } else {
      // Dynamic Mode
      final bool onBreak = state == AppTimerState.breakTime || (state == AppTimerState.paused && provider.pausedState == AppTimerState.breakTime);
      rightIcon = onBreak ? Icons.local_fire_department_rounded : Icons.coffee_rounded;
      rightAction = onBreak
          ? () => provider.resumeWorkEarly()
          : () => provider.triggerDynamicBreak();
      rightEnabled = state != AppTimerState.idle && (onBreak || provider.elapsedSeconds > 0);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _leftClickController,
        _centerClickController,
        _rightClickController,
        _stateTransitionController,
        _leftPressedController,
        _centerPressedController,
        _rightPressedController,
      ]),
      builder: (context, child) {
        final t = _stateTransitionController.value;
        final pLeft = _leftPressedController.value;
        final pCenter = _centerPressedController.value;
        final pRight = _rightPressedController.value;
        return Container(
          key: const ValueKey('control_board'),
          margin: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. LEFT Button: Reset (M3E Tonal, round shape)
              _buildExpressiveButton(
                onPressed: () => _onLeftButtonPressed(() => provider.stopTimer()),
                iconData: Icons.replay_rounded,
                isFilled: false,
                scaleX: _leftButtonScaleX(pLeft, pCenter),
                baseWidth: 64.0,
                baseHeight: 64.0,
                shape: IconButtonM3EShapeVariant.round,
                alignment: Alignment.centerLeft,
                position: 'left',
                theme: theme,
                pressedValue: pLeft,
                pressedController: _leftPressedController,
                centerPressedValue: pCenter,
              ),
              const SizedBox(width: 12),

              // 2. CENTER Button: Play/Pause/Resume (M3E Filled, square shape morphing corner radius)
              _buildExpressiveButton(
                onPressed: () => _onCenterButtonPressed(() {
                  if (provider.state == AppTimerState.idle) {
                    provider.startTimer();
                  } else {
                    if (provider.state == AppTimerState.paused) {
                      provider.resumeTimer();
                    } else {
                      provider.pauseTimer();
                    }
                  }
                }),
                iconData: (provider.state == AppTimerState.idle || provider.state == AppTimerState.paused)
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                isFilled: true,
                scaleX: _centerButtonScaleX(pCenter, pLeft, pRight),
                baseWidth: 96.0,
                baseHeight: 64.0,
                shape: IconButtonM3EShapeVariant.square,
                alignment: _getCenterButtonAlignment(
                  scaleL: _leftButtonScaleX(pLeft, pCenter),
                  scaleR: _rightButtonScaleX(pRight, pCenter),
                  scaleC: _centerButtonScaleX(pCenter, pLeft, pRight),
                ),
                position: 'center',
                theme: theme,
                transitionValue: t,
                pressedValue: pCenter,
                pressedController: _centerPressedController,
              ),
              const SizedBox(width: 12),

              // 3. RIGHT Button: Action/Skip/Break (M3E Tonal, round shape)
              _buildExpressiveButton(
                onPressed: () => _onRightButtonPressed(rightAction),
                iconData: rightIcon,
                isFilled: false,
                scaleX: _rightButtonScaleX(pRight, pCenter),
                baseWidth: 64.0,
                baseHeight: 64.0,
                shape: IconButtonM3EShapeVariant.round,
                alignment: Alignment.centerRight,
                position: 'right',
                theme: theme,
                enabled: rightEnabled,
                pressedValue: pRight,
                pressedController: _rightPressedController,
                centerPressedValue: pCenter,
              ),
            ],
          ),
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
  required double transitionValue,
  required double pressedValue,
  required Size size,
  double centerPressedValue = 0.0,
  double pressedRadius = 16.0,
}) {
  final path = Path();

  if (shape == IconButtonM3EShapeVariant.round) {
    // Round shape (Left/Right buttons, and Center button when idle/paused in stadium shape)
    // Base radius is height / 2 (32.0). Under pressed state, it morphs to pressedRadius.
    final double rBase = height / 2; // 32.0
    final double rBaseCur = rBase - (rBase - pressedRadius) * pressedValue;

    if (position == 'left' || position == 'right') {
      if (width >= height) {
        path.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(rBaseCur),
        ));
      } else {
        // Squishing: corner radius decreases vertically to create flat sides, while matching width horizontally to keep top/bottom normally curved
        final double rx = width / 2;
        final double centerSquish = (centerValue + centerPressedValue).clamp(0.0, 1.0);
        final double ry = rBaseCur - (rBaseCur - 20.0) * centerSquish;
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
        Radius.circular(rBaseCur),
      ));
    }
  } else {
    // Center button (Square shape):
    // Unpressed active shape has a radius of 16.0.
    // When transitionValue is 0.0 (idle/paused), unpressed is 32.0.
    // When transitionValue is 1.0 (active), unpressed is 16.0.
    // Pressed radius is pressedRadius (defaults to 16.0).
    final double rUnpressed = 32.0 - (32.0 - 16.0) * transitionValue;
    final double rPressed = pressedRadius;
    final double rCur = rUnpressed - (rUnpressed - rPressed) * pressedValue;

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(rCur),
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
  final double transitionValue;
  final double pressedValue;
  final double centerPressedValue;
  final double pressedRadius;

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
    required this.transitionValue,
    required this.pressedValue,
    this.centerPressedValue = 0.0,
    this.pressedRadius = 16.0,
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
      transitionValue: transitionValue,
      pressedValue: pressedValue,
      size: size,
      centerPressedValue: centerPressedValue,
      pressedRadius: pressedRadius,
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
        oldDelegate.rightValue != rightValue ||
        oldDelegate.transitionValue != transitionValue ||
        oldDelegate.pressedValue != pressedValue ||
        oldDelegate.centerPressedValue != centerPressedValue ||
        oldDelegate.pressedRadius != pressedRadius;
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
  final double transitionValue;
  final double pressedValue;
  final double centerPressedValue;
  final double pressedRadius;

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
    required this.transitionValue,
    required this.pressedValue,
    this.centerPressedValue = 0.0,
    this.pressedRadius = 16.0,
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
      transitionValue: transitionValue,
      pressedValue: pressedValue,
      size: size,
      centerPressedValue: centerPressedValue,
      pressedRadius: pressedRadius,
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
        oldClipper.rightValue != rightValue ||
        oldClipper.transitionValue != transitionValue ||
        oldClipper.pressedValue != pressedValue ||
        oldClipper.centerPressedValue != centerPressedValue ||
        oldClipper.pressedRadius != pressedRadius;
  }
}
