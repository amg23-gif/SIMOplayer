import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: const Color(0xFF0A0A0A),
      indicatorColor: const Color(0xFF00E5FF).withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => _navigate(context, i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.home, color: Color(0xFF00E5FF)),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.live_tv_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.live_tv, color: Color(0xFF00E5FF)),
          label: 'القنوات',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.search, color: Color(0xFF00E5FF)),
          label: 'بحث',
        ),
        NavigationDestination(
          icon: Icon(Icons.videocam_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.videocam, color: Color(0xFF00E5FF)),
          label: 'التسجيلات',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.settings, color: Color(0xFF00E5FF)),
          label: 'إعدادات',
        ),
      ],
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppConstants.routeHome);
        break;
      case 1:
        context.push('/home/channels');
        break;
      case 2:
        context.push('/home/search');
        break;
      case 3:
        context.push(AppConstants.routeRecordings);
        break;
      case 4:
        context.push(AppConstants.routeSettings);
        break;
    }
  }
}
