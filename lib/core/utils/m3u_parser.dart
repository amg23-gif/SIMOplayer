import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/source.dart';

// محلل ملفات M3U
class M3uParser {
  // تحليل M3U من رابط
  static Future<List<Channel>> parseFromUrl(Source source) async {
    final url = source.effectiveUrl;
    if (url == null) throw Exception('لا يوجد رابط للمصدر');

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    final response = await dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );

    if (response.data == null) throw Exception('البيانات فارغة');
    return _parseInIsolate(response.data!, source.id);
  }

  // تحليل M3U من نص
  static Future<List<Channel>> parseFromString(
      String content, String sourceId) async {
    return _parseInIsolate(content, sourceId);
  }

  // تشغيل التحليل في Isolate منفصل لتفادي تجميد الواجهة
  static Future<List<Channel>> _parseInIsolate(
      String content, String sourceId) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _parseM3uContent,
      [receivePort.sendPort, content, sourceId],
    );
    return await receivePort.first as List<Channel>;
  }

  // دالة التحليل الفعلية (تعمل في Isolate)
  static void _parseM3uContent(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final content = args[1] as String;
    final sourceId = args[2] as String;

    final channels = <Channel>[];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;
    String? currentLanguage;
    String? currentCountry;
    int channelIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        // استخراج معلومات القناة من السطر
        currentName = _extractAttribute(line, 'tvg-name') ??
            _extractDisplayName(line);
        currentLogo = _extractAttribute(line, 'tvg-logo');
        currentGroup = _extractAttribute(line, 'group-title') ?? 'عام';
        currentTvgId = _extractAttribute(line, 'tvg-id');
        currentTvgName = _extractAttribute(line, 'tvg-name');
        currentLanguage = _extractAttribute(line, 'tvg-language');
        currentCountry = _extractAttribute(line, 'tvg-country');
      } else if (line.isNotEmpty &&
          !line.startsWith('#') &&
          currentName != null) {
        // سطر الرابط
        channelIndex++;
        final channelId = '${sourceId}_$channelIndex';

        channels.add(Channel(
          id: channelId,
          name: currentName,
          logoUrl: currentLogo,
          category: currentGroup ?? 'عام',
          group: currentGroup,
          language: currentLanguage,
          country: currentCountry,
          tvgId: currentTvgId,
          tvgName: currentTvgName,
          streamUrls: [line],
        ));

        // إعادة تعيين المتغيرات
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
        currentLanguage = null;
        currentCountry = null;
      }
    }

    sendPort.send(channels);
  }

  // استخراج قيمة صفة معينة من سطر #EXTINF
  static String? _extractAttribute(String line, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"', caseSensitive: false);
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  // استخراج اسم القناة من نهاية السطر
  static String? _extractDisplayName(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex == -1) return null;
    return line.substring(commaIndex + 1).trim();
  }
}
