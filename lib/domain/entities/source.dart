import 'package:equatable/equatable.dart';

// أنواع مصادر القنوات
enum SourceType { m3uUrl, m3uFile, xtreamCodes }

// كيان مصدر القنوات
class Source extends Equatable {
  final String id;
  final String name;
  final SourceType type;
  final String? m3uUrl;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? localFilePath;
  final String? epgUrl;
  final int channelCount;
  final DateTime? lastRefreshed;
  final bool isActive;

  const Source({
    required this.id,
    required this.name,
    required this.type,
    this.m3uUrl,
    this.serverUrl,
    this.username,
    this.password,
    this.localFilePath,
    this.epgUrl,
    this.channelCount = 0,
    this.lastRefreshed,
    this.isActive = true,
  });

  // تنظيف رابط السيرفر (إزالة الشرطة المائلة الزائدة في النهاية)
  String? get _cleanServerUrl {
    if (serverUrl == null) return null;
    return serverUrl!.trimRight().replaceAll(RegExp(r'/+$'), '');
  }

  // بناء رابط Xtream Codes M3U
  String? get xtreamM3uUrl {
    if (type != SourceType.xtreamCodes) return null;
    final srv = _cleanServerUrl;
    if (srv == null || username == null || password == null) return null;
    return '$srv/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
  }

  // بناء رابط Xtream Codes API للتحقق من بيانات الدخول
  String? get xtreamApiUrl {
    if (type != SourceType.xtreamCodes) return null;
    final srv = _cleanServerUrl;
    if (srv == null || username == null || password == null) return null;
    return '$srv/player_api.php?username=$username&password=$password';
  }

  // الرابط الفعلي للتحميل
  String? get effectiveUrl {
    switch (type) {
      case SourceType.m3uUrl:
        return m3uUrl;
      case SourceType.xtreamCodes:
        return xtreamM3uUrl;
      case SourceType.m3uFile:
        return localFilePath;
    }
  }

  Source copyWith({
    String? id,
    String? name,
    SourceType? type,
    String? m3uUrl,
    String? serverUrl,
    String? username,
    String? password,
    String? localFilePath,
    String? epgUrl,
    int? channelCount,
    DateTime? lastRefreshed,
    bool? isActive,
  }) {
    return Source(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      localFilePath: localFilePath ?? this.localFilePath,
      epgUrl: epgUrl ?? this.epgUrl,
      channelCount: channelCount ?? this.channelCount,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, type, m3uUrl, serverUrl, username];
}
