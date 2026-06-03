import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/app_constants.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/profile/profile_select_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/player/player_screen.dart';
import '../../presentation/screens/channels/channels_screen.dart';
import '../../presentation/screens/epg/epg_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/recordings/recordings_screen.dart';
import '../../presentation/screens/watch_party/watch_party_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/channels/add_source_screen.dart';
import '../../presentation/screens/settings/remote_setup_screen.dart';
import '../../presentation/providers/auth_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // التحقق من حالة المصادقة
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == AppConstants.routeLogin;
      final isSplashRoute = state.matchedLocation == AppConstants.routeSplash;
      final isProfileRoute =
          state.matchedLocation == AppConstants.routeProfileSelect;

      if (isSplashRoute) return null;

      if (!isLoggedIn && !isLoginRoute) {
        return AppConstants.routeLogin;
      }

      return null;
    },
    routes: [
      // شاشة البداية
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // شاشة اختيار الملف الشخصي
      GoRoute(
        path: AppConstants.routeProfileSelect,
        name: 'profiles',
        builder: (context, state) => const ProfileSelectScreen(),
      ),

      // شاشة تسجيل الدخول
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // الشاشة الرئيسية
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // قائمة القنوات
          GoRoute(
            path: 'channels',
            name: 'channels',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return ChannelsScreen(categoryFilter: category);
            },
          ),

          // إضافة مصدر جديد
          GoRoute(
            path: 'add-source',
            name: 'add-source',
            builder: (context, state) => const AddSourceScreen(),
          ),

          // البحث
          GoRoute(
            path: 'search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),

          // دليل البرامج EPG
          GoRoute(
            path: 'epg',
            name: 'epg',
            builder: (context, state) {
              final channelId = state.uri.queryParameters['channelId'] ?? '';
              return EpgScreen(channelId: channelId);
            },
          ),
        ],
      ),

      // شاشة المشغل
      GoRoute(
        path: AppConstants.routePlayer,
        name: 'player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlayerScreen(
            channelId: extra?['channelId'] ?? '',
            streamUrl: extra?['streamUrl'] ?? '',
            channelName: extra?['channelName'] ?? '',
            channelLogo: extra?['channelLogo'],
          );
        },
      ),

      // الإعدادات
      GoRoute(
        path: AppConstants.routeSettings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'remote-setup',
            name: 'remote-setup',
            builder: (context, state) => const RemoteSetupScreen(),
          ),
        ],
      ),

      // التسجيلات
      GoRoute(
        path: AppConstants.routeRecordings,
        name: 'recordings',
        builder: (context, state) => const RecordingsScreen(),
      ),

      // غرفة المشاهدة الجماعية
      GoRoute(
        path: AppConstants.routeWatchParty,
        name: 'watch-party',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WatchPartyScreen(
            roomCode: extra?['roomCode'],
            streamUrl: extra?['streamUrl'],
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'صفحة غير موجودة: ${state.error}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    ),
  );
}
