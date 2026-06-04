import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../providers/timer_provider.dart';
import 'timer_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Check and request notifications, exact alarm, and battery exemption permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TimerProvider.instance.checkAndRequestPermissions(context);
    });
  }

  final List<Widget> _pages = const [
    TimerPage(),
    StatsPage(),
    SettingsPage(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = TimerProvider.instance;

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final currentTimerState = provider.state;

        // Break and Work phase checks
        final bool isBreak = currentTimerState == AppTimerState.breakTime ||
            (currentTimerState == AppTimerState.paused && provider.pausedState == AppTimerState.breakTime);

        // Dynamic Material 3 Expressive colors derived from system settings
        final Color modePrimaryColor = isBreak ? theme.colorScheme.tertiary : theme.colorScheme.primary;

        final Color baseColor = Color.alphaBlend(
          modePrimaryColor.withOpacity(isDark ? 0.08 : 0.05),
          theme.colorScheme.surface,
        );

        return Scaffold(
          backgroundColor: baseColor,
          extendBody: true, // Content flows behind navigation bar
          body: Stack(
            children: [
              // Dynamic solid flat background
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                color: baseColor,
              ),

              // Main Pages View
              SafeArea(
                bottom: false,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _pages,
                ),
              ),
            ],
          ),
          // Floating Solid Material 3 Bottom Navigation Bar
          bottomNavigationBar: NavigationBarM3E(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0),
            destinations: const [
              NavigationDestinationM3E(
                icon: Icon(Icons.hourglass_empty_rounded),
                selectedIcon: Icon(Icons.hourglass_full_rounded),
                label: "Timer",
              ),
              NavigationDestinationM3E(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: "Stats",
              ),
              NavigationDestinationM3E(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: "Settings",
              ),
            ],
          ),
        );
      },
    );
  }
}
