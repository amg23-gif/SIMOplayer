import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/source.dart';

// إنشاء Dio مع دعم SSL الكامل (بما في ذلك الشهادات الموقّعة ذاتياً)
Dio _buildDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 20),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11) SIMO-Player/1.0',
      'Accept': '*/*',
    },
  ));

  // تجاوز التحقق من شهادات SSL لدعم خوادم IPTV
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  };

  return dio;
}

// محلل ملفات M3U
class M3uParser {
  // التحقق من بيانات Xtream Codes أولاً ثم تحميل القنوات
  static Future<List<Channel>> parseFromUrl(Source source) async {
    if (source.type == SourceType.xtreamCodes) {
      return _parseXtream(source);
    }
    return _parseM3uUrl(source);
  }

  // تحليل مصدر Xtream Codes
  static Future<List<Channel>> _parseXtream(Source source) async {
    final apiUrl = source.xtreamApiUrl;
    final m3uUrl = source.xtreamM3uUrl;

    if (apiUrl == null || m3uUrl == null) {
      throw Exception('بيانات الاتصال غير مكتملة — تحقق من عنوان السيرفر والمستخدم وكلمة المرور');
    }

    final dio = _buildDio();

    // الخطوة 1: التحقق من بيانات الدخول عبر Xtream API
    try {
      final apiResp = await dio.get<String>(
        apiUrl,
        options: Options(responseType: ResponseType.plain),
      );

      if (apiResp.statusCode != 200) {
        throw Exception('السيرفر رفض الاتصال (${apiResp.statusCode}) — تحقق من بيانات الدخول');
      }

      final body = apiResp.data ?? '';
      if (body.contains('"user_info"')) {
        // تحقق من صلاحية الحساب
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final userInfo = json['user_info'] as Map<String, dynamic>?;
          if (userInfo != null) {
            final status = userInfo['status']?.toString() ?? '';
            if (status == 'Banned' || status == 'banned') {
              throw Exception('الحساب محظور — تواصل مع مزود الخدمة');
            }
            final expDate = userInfo['exp_date'];
            if (expDate != null) {
              final exp = int.tryParse(expDate.toString()) ?? 0;
              if (exp > 0 && exp < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
                throw Exception('انتهت صلاحية الاشتراك — تواصل مع مزود الخدمة');
              }
            }
          }
        } catch (e) {
          if (e.toString().contains('انتهت') || e.toString().contains('محظور')) {
            rethrow;
          }
          // الاستمرار إذا كانت مشكلة في تحليل JSON فقط
        }
      } else if (body.contains('"Wrong credentials"') ||
          body.contains('"wrong_credentials"') ||
          body.toLowerCase().contains('wrong') ||
          body.contains('"error"')) {
        throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e, source.serverUrl ?? ''));
    }

    // الخطوة 2: تحميل قائمة القنوات M3U
    try {
      final m3uResp = await dio.get<String>(
        m3uUrl,
        options: Options(responseType: ResponseType.plain),
      );

      if (m3uResp.data == null || m3uResp.data!.isEmpty) {
        throw Exception('القائمة فارغة — لا توجد قنوات في هذا الاشتراك');
      }

      final content = m3uResp.data!;
      if (!content.trimLeft().startsWith('#EXTM3U') &&
          !content.contains('#EXTINF')) {
        throw Exception('بيانات القائمة غير صالحة — تأكد من نوع المصدر');
      }

      return _parseInIsolate(content, source.id);
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e, source.serverUrl ?? ''));
    }
  }

  // تحليل M3U من رابط عادي
  static Future<List<Channel>> _parseM3uUrl(Source source) async {
    final url = source.effectiveUrl;
    if (url == null || url.isEmpty) {
      throw Exception('لا يوجد رابط للمصدر');
    }

    final dio = _buildDio();

    try {
      final response = await dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('الملف فارغ أو لا يوجد محتوى');
      }

      return _parseInIsolate(response.data!, source.id);
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e, url));
    }
  }

  // تحويل أخطاء Dio إلى رسائل عربية واضحة
  static String _friendlyDioError(DioException e, String url) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مدة الاتصال — تأكد من عنوان السيرفر والاتصال بالإنترنت';
      case DioExceptionType.receiveTimeout:
        return 'السيرفر لا يستجيب — حاول مجدداً لاحقاً';
      case DioExceptionType.connectionError:
        final msg = e.message ?? '';
        if (msg.contains('ECONNREFUSED') || msg.contains('refused')) {
          return 'السيرفر يرفض الاتصال — تحقق من المنفذ وعنوان السيرفر';
        }
        if (msg.contains('ENOTFOUND') || msg.contains('lookup')) {
          return 'لم يتم العثور على السيرفر — تحقق من عنوان السيرفر';
        }
        if (msg.contains('ECONNRESET') || msg.contains('reset')) {
          return 'انقطع الاتصال بالسيرفر — تحقق من اتصالك بالإنترنت';
        }
        return 'فشل الاتصال بالسيرفر — تحقق من عنوان السيرفر والاتصال بالإنترنت';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          return 'بيانات الدخول غير صحيحة (خطأ $code)';
        }
        if (code == 404) {
          return 'الصفحة غير موجودة (404) — تحقق من عنوان السيرفر';
        }
        if (code >= 500) {
          return 'خطأ في السيرفر ($code) — حاول مجدداً لاحقاً';
        }
        return 'استجابة غير متوقعة من السيرفر ($code)';
      case DioExceptionType.badCertificate:
        return 'شهادة SSL غير صالحة — جرّب HTTP بدلاً من HTTPS';
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';
      default:
        final msg = e.message ?? '';
        if (msg.isNotEmpty) return msg;
        return 'فشل الاتصال — تحقق من اتصالك بالإنترنت';
    }
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

  static String? _extractAttribute(String line, String attribute) {
    final regex = RegExp('$attribute="([^"]*)"', caseSensitive: false);
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  static String? _extractDisplayName(String line) {
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex == -1) return null;
    return line.substring(commaIndex + 1).trim();
  }
}
