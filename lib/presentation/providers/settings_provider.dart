import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/database.dart';

// نموذج إعدادات التطبيق
class AppSettings {
  final ThemeMode themeMode;
  final AppThemeMode appThemeMode;
  final Color? customThemeColor;
  final Locale locale;
  final bool hardwareAcceleration;
  final int bufferSizeMB;
  final bool autoPlay;
  final bool showUnavailableChannels;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.appThemeMode = AppThemeMode.dark,
    this.customThemeColor,
    this.locale = const Locale('ar', 'SA'),
    this.hardwareAcceleration = true,
    this.bufferSizeMB = AppConstants.defaultBufferSizeMB,
    this.autoPlay = false,
    this.showUnavailableChannels = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppThemeMode? appThemeMode,
    Color? customThemeColor,
    Locale? locale,
    bool? hardwareAcceleration,
    int? bufferSizeMB,
    bool? autoPlay,
    bool? showUnavailableChannels,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      appThemeMode: appThemeMode ?? this.appThemeMode,
      customThemeColor: customThemeColor ?? this.customThemeColor,
      locale: locale ?? this.locale,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      bufferSizeMB: bufferSizeMB ?? this.bufferSizeMB,
      autoPlay: autoPlay ?? this.autoPlay,
      showUnavailableChannels:
          showUnavailableChannels ?? this.showUnavailableChannels,
    );
  }
}

// مزود الإعدادات
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _loadSettings() async {
    final themeStr =
        await _db.getSetting(AppConstants.kThemeMode) ?? 'dark';
    final localeStr =
        await _db.getSetting(AppConstants.kLocale) ?? 'ar';
    final hwAccel =
        await _db.getSetting(AppConstants.kHardwareAcceleration) ?? 'true';
    final bufferStr =
        await _db.getSetting(AppConstants.kBufferSize) ??
            AppConstants.defaultBufferSizeMB.toString();

    AppThemeMode appThemeMode;
    ThemeMode themeMode;
    switch (themeStr) {
      case 'light':
        appThemeMode = AppThemeMode.light;
        themeMode = ThemeMode.light;
        break;
      case 'oled':
        appThemeMode = AppThemeMode.oled;
        themeMode = ThemeMode.dark;
        break;
      default:
        appThemeMode = AppThemeMode.dark;
        themeMode = ThemeMode.dark;
    }

    state = AppSettings(
      themeMode: themeMode,
      appThemeMode: appThemeMode,
      locale: Locale(localeStr),
      hardwareAcceleration: hwAccel == 'true',
      bufferSizeMB: int.tryParse(bufferStr) ?? AppConstants.defaultBufferSizeMB,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    String themeStr;
    ThemeMode themeMode;
    switch (mode) {
      case AppThemeMode.light:
        themeStr = 'light';
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.oled:
        themeStr = 'oled';
        themeMode = ThemeMode.dark;
        break;
      default:
        themeStr = 'dark';
        themeMode = ThemeMode.dark;
    }
    await _db.setSetting(AppConstants.kThemeMode, themeStr);
    state = state.copyWith(themeMode: themeMode, appThemeMode: mode);
  }

  Future<void> setLocale(String languageCode) async {
    await _db.setSetting(AppConstants.kLocale, languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }

  Future<void> setHardwareAcceleration(bool value) async {
    await _db.setSetting(AppConstants.kHardwareAcceleration, value.toString());
    state = state.copyWith(hardwareAcceleration: value);
  }

  Future<void> setBufferSize(int mb) async {
    await _db.setSetting(AppConstants.kBufferSize, mb.toString());
    state = state.copyWith(bufferSizeMB: mb);
  }

  Future<void> setShowUnavailableChannels(bool value) async {
    state = state.copyWith(showUnavailableChannels: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
