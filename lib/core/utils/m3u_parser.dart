import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/source.dart';

// إنشاء Dio مع دعم SSL الكامل
Dio _buildDio() {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11) SIMO-Player/2.0',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    },
  ));
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  };
  return dio;
}

class M3uParser {
  static Future<List<Channel>> parseFromUrl(Source source) async {
    if (source.type == SourceType.xtreamCodes) {
      return _parseXtream(source);
    }
    return _parseM3uUrl(source);
  }

  // بناء جميع احتمالات الرابط تلقائياً
  static List<String> _buildUrlVariations(String raw) {
    final clean = raw.trim().replaceAll(RegExp(r'/+$'), '');
    final variations = <String>[];

    // الرابط كما هو أولاً
    variations.add(clean);

    final isHttps = clean.startsWith('https://');
    final isHttp = clean.startsWith('http://');
    final hasPort = RegExp(r':\d+$').hasMatch(clean);

    if (isHttps) {
      // جرب HTTP بدل HTTPS
      final httpVersion = clean.replaceFirst('https://', 'http://');
      variations.add(httpVersion);
      // جرب HTTP:80
      if (!hasPort) {
        variations.add('$httpVersion:80');
        variations.add('$httpVersion:8080');
        variations.add('$httpVersion:25461');
      }
    } else if (isHttp) {
      if (!hasPort) {
        // جرب مع المنافذ الشائعة
        variations.add('$clean:80');
        variations.add('$clean:8080');
        variations.add('$clean:25461');
      }
      // جرب HTTPS
      final httpsVersion = clean.replaceFirst('http://', 'https://');
      variations.add(httpsVersion);
    } else {
      // بدون بروتوكول — أضف http
      variations.add('http://$clean');
      variations.add('http://$clean:80');
      variations.add('https://$clean');
    }

    return variations.toSet().toList();
  }

  // Xtream Codes مع محاولة تلقائية لجميع احتمالات الرابط
  static Future<List<Channel>> _parseXtream(Source source) async {
    final user = source.username ?? '';
    final pass = source.password ?? '';
    final rawServer = source.serverUrl ?? '';

    if (rawServer.isEmpty || user.isEmpty || pass.isEmpty) {
      throw Exception('أدخل عنوان السيرفر واسم المستخدم وكلمة المرور');
    }

    final dio = _buildDio();
    final variations = _buildUrlVariations(rawServer);
    String? workingBase;
    String? lastError;

    // جرّب كل احتمال للرابط حتى ينجح واحد
    for (final base in variations) {
      try {
        final apiUrl = '$base/player_api.php?username=$user&password=$pass';
        final resp = await dio.get<String>(
          apiUrl,
          options: Options(
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 600,
          ),
        );

        final body = resp.data ?? '';
        final code = resp.statusCode ?? 0;

        if (code == 200 && body.isNotEmpty) {
          // تحقق من رسالة "خطأ في البيانات"
          if (body.contains('"Wrong credentials"') ||
              body.toLowerCase().contains('wrong') ||
              body.contains('"error"') && !body.contains('"user_info"')) {
            throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
          }

          // التحقق من صلاحية الحساب
          if (body.contains('"user_info"')) {
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
                  if (exp > 0 &&
                      exp < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
                    throw Exception('انتهت صلاحية الاشتراك — تواصل مع مزود الخدمة');
                  }
                }
              }
            } catch (e) {
              if (e.toString().contains('انتهت') ||
                  e.toString().contains('محظور') ||
                  e.toString().contains('غير صحيحة')) {
                rethrow;
              }
            }
          }

          workingBase = base;
          break;
        }
      } on DioException catch (e) {
        lastError = _friendlyDioError(e, base);
        continue;
      } on Exception catch (e) {
        final msg = e.toString();
        if (msg.contains('محظور') ||
            msg.contains('انتهت') ||
            msg.contains('غير صحيحة')) {
          rethrow;
        }
        lastError = msg;
        continue;
      }
    }

    if (workingBase == null) {
      throw Exception(lastError ??
          'تعذّر الاتصال بالسيرفر — تحقق من العنوان واتصالك بالإنترنت');
    }

    // تحميل قائمة القنوات باستخدام الرابط الصحيح الذي نجح
    final m3uUrl =
        '$workingBase/get.php?username=$user&password=$pass&type=m3u_plus&output=ts';

    try {
      final m3uResp = await dio.get<String>(
        m3uUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      final content = m3uResp.data ?? '';
      if (content.isEmpty) {
        throw Exception('القائمة فارغة — لا توجد قنوات في هذا الاشتراك');
      }
      if (!content.trimLeft().startsWith('#EXTM3U') &&
          !content.contains('#EXTINF')) {
        throw Exception('بيانات القائمة غير صالحة — تأكد من نوع المصدر');
      }

      return _parseInIsolate(content, source.id);
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e, workingBase));
    }
  }

  // تحليل M3U من رابط عادي
  static Future<List<Channel>> _parseM3uUrl(Source source) async {
    final url = source.effectiveUrl;
    if (url == null || url.isEmpty) throw Exception('لا يوجد رابط للمصدر');

    final dio = _buildDio();
    try {
      final resp = await dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(minutes: 3),
        ),
      );

      final content = resp.data ?? '';
      if (content.isEmpty) throw Exception('الملف فارغ أو لا يوجد محتوى');
      return _parseInIsolate(content, source.id);
    } on DioException catch (e) {
      throw Exception(_friendlyDioError(e, url));
    }
  }

  static String _friendlyDioError(DioException e, String url) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'انتهت مدة الاتصال — السيرفر لا يستجيب ($url)';
      case DioExceptionType.receiveTimeout:
        return 'السيرفر لا يرسل بيانات — حاول مجدداً';
      case DioExceptionType.connectionError:
        final msg = e.message ?? '';
        if (msg.contains('refused')) return 'السيرفر يرفض الاتصال — تحقق من المنفذ';
        if (msg.contains('ENOTFOUND') || msg.contains('lookup'))
          return 'لم يتم العثور على السيرفر — تحقق من العنوان';
        return 'فشل الاتصال — تحقق من العنوان والإنترنت';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) return 'بيانات الدخول غير صحيحة ($code)';
        if (code == 404) return 'الصفحة غير موجودة (404)';
        if (code >= 500) return 'خطأ في السيرفر ($code)';
        return 'استجابة غير متوقعة ($code)';
      case DioExceptionType.badCertificate:
        return 'خطأ SSL — جرّب http:// بدل https://';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'فشل الاتصال — تحقق من اتصالك بالإنترنت';
    }
  }

  static Future<List<Channel>> parseFromString(
      String content, String sourceId) async {
    return _parseInIsolate(content, sourceId);
  }

  static Future<List<Channel>> _parseInIsolate(
      String content, String sourceId) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _parseM3uContent,
      [receivePort.sendPort, content, sourceId],
    );
    return await receivePort.first as List<Channel>;
  }

  static void _parseM3uContent(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final content = args[1] as String;
    final sourceId = args[2] as String;

    final channels = <Channel>[];
    final lines = content.split('\n');
    String? name, logo, group, tvgId, tvgName, language, country;
    int idx = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        name = _attr(line, 'tvg-name') ?? _displayName(line);
        logo = _attr(line, 'tvg-logo');
        group = _attr(line, 'group-title') ?? 'عام';
        tvgId = _attr(line, 'tvg-id');
        tvgName = _attr(line, 'tvg-name');
        language = _attr(line, 'tvg-language');
        country = _attr(line, 'tvg-country');
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null) {
        idx++;
        channels.add(Channel(
          id: '${sourceId}_$idx',
          name: name,
          logoUrl: logo,
          category: group ?? 'عام',
          group: group,
          language: language,
          country: country,
          tvgId: tvgId,
          tvgName: tvgName,
          streamUrls: [line],
        ));
        name = logo = group = tvgId = tvgName = language = country = null;
      }
    }
    sendPort.send(channels);
  }

  static String? _attr(String line, String attr) {
    final m = RegExp('$attr="([^"]*)"', caseSensitive: false).firstMatch(line);
    return m?.group(1);
  }

  static String? _displayName(String line) {
    final i = line.lastIndexOf(',');
    return i == -1 ? null : line.substring(i + 1).trim();
  }
}
