// ثوابت التطبيق الرئيسية
class AppConstants {
  AppConstants._();

  // معلومات التطبيق
  static const String appName = 'SIMO Player';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // مفاتيح التخزين الآمن
  static const String kEncryptionKey = 'simo_player_encryption_key';
  static const String kUserIdKey = 'user_id';
  static const String kAuthTokenKey = 'auth_token';
  static const String kSelectedProfileKey = 'selected_profile';

  // مفاتيح SharedPreferences / Drift
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'locale';
  static const String kAutoPlay = 'auto_play';
  static const String kHardwareAcceleration = 'hardware_acceleration';
  static const String kSubtitleSize = 'subtitle_size';
  static const String kBufferSize = 'buffer_size_mb';

  // إعدادات الفيديو
  static const int defaultBufferSizeMB = 64;
  static const int sourceRetryDelaySeconds = 3;
  static const int channelCheckIntervalHours = 24;
  static const int channelCheckTimeoutSeconds = 5;
  static const int watchPartyMaxParticipants = 10;

  // إعدادات EPG
  static const int epgRefreshIntervalHours = 6;
  static const int epgCacheDays = 3;

  // إعدادات M3U
  static const int m3uParseChunkSize = 100;

  // إعدادات QR
  static const int qrCodeExpiryMinutes = 10;
  static const int qrCodeLength = 8;

  // روابط افتراضية
  static const String defaultEpgUrl = 'http://www.xmltv.co.uk/feed/9209';
  static const String channelLogoFallback =
      'https://via.placeholder.com/100x100?text=TV';

  // أسماء مسارات التوجيه
  static const String routeSplash = '/';
  static const String routeProfileSelect = '/profiles';
  static const String routeHome = '/home';
  static const String routePlayer = '/player';
  static const String routeChannels = '/channels';
  static const String routeEpg = '/epg';
  static const String routeSearch = '/search';
  static const String routeSettings = '/settings';
  static const String routeRecordings = '/recordings';
  static const String routeWatchParty = '/watch-party';
  static const String routeLogin = '/login';
  static const String routeAddSource = '/add-source';
  static const String routeRemoteSetup = '/remote-setup';

  // Firebase مجموعات Firestore
  static const String fsUsers = 'users';
  static const String fsProfiles = 'profiles';
  static const String fsFavorites = 'favorites';
  static const String fsHistory = 'watch_history';
  static const String fsSources = 'sources';
  static const String fsSettings = 'settings';
  static const String fsWatchParties = 'watch_parties';
  static const String fsRemoteSetup = 'remote_setup_codes';

  // Firebase Storage مسارات
  static const String storageRecordings = 'recordings';
  static const String storageProfilePics = 'profile_pictures';

  // Firebase Realtime Database مسارات
  static const String rtdbWatchParties = 'watch_parties';
  static const String rtdbRemoteSetup = 'remote_setup';

  // الصور الافتراضية
  static const String assetLogoPath = 'assets/images/logo.png';
  static const String assetSplashBg = 'assets/images/splash_bg.png';
  static const String assetDefaultThumb = 'assets/images/default_thumb.png';

  // ملف إعادة التسمية
  static const String rebrandConfigPath = 'assets/config/rebrand.json';
}
