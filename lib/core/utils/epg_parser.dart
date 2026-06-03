import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../../domain/entities/epg_program.dart';

// محلل ملفات EPG بصيغة XMLTV
class EpgParser {
  // تحميل وتحليل EPG من رابط
  static Future<List<EpgProgram>> parseFromUrl(String url) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));

    final response = await dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );

    if (response.data == null) throw Exception('بيانات EPG فارغة');
    return parseFromString(response.data!);
  }

  // تحليل من نص XML
  static Future<List<EpgProgram>> parseFromString(String xmlContent) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_parseXmltv, [receivePort.sendPort, xmlContent]);
    return await receivePort.first as List<EpgProgram>;
  }

  // دالة التحليل الفعلية في Isolate
  static void _parseXmltv(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    final xmlContent = args[1] as String;

    try {
      final programs = <EpgProgram>[];
      final document = XmlDocument.parse(xmlContent);

      // تحليل كل برنامج <programme>
      final programElements = document.findAllElements('programme');

      for (final element in programElements) {
        try {
          final channelId = element.getAttribute('channel') ?? '';
          final startStr = element.getAttribute('start') ?? '';
          final stopStr = element.getAttribute('stop') ?? '';

          if (channelId.isEmpty || startStr.isEmpty || stopStr.isEmpty) {
            continue;
          }

          final start = _parseXmltvDate(startStr);
          final stop = _parseXmltvDate(stopStr);

          if (start == null || stop == null) continue;

          final titleEl = element.findElements('title').firstOrNull;
          final descEl = element.findElements('desc').firstOrNull;
          final categoryEl = element.findElements('category').firstOrNull;
          final iconEl = element.findElements('icon').firstOrNull;
          final ratingEl = element.findElements('rating').firstOrNull;

          final title = titleEl?.innerText ?? 'برنامج غير معروف';
          final description = descEl?.innerText;
          final category = categoryEl?.innerText;
          final imageUrl = iconEl?.getAttribute('src');
          final rating =
              ratingEl?.findElements('value').firstOrNull?.innerText;

          // إنشاء معرف فريد
          final id =
              '${channelId}_${start.millisecondsSinceEpoch}';

          programs.add(EpgProgram(
            id: id,
            channelId: channelId,
            title: title,
            description: description,
            startTime: start,
            endTime: stop,
            category: category,
            imageUrl: imageUrl,
            rating: rating,
          ));
        } catch (_) {
          // تجاهل الإدخالات الخاطئة
        }
      }

      sendPort.send(programs);
    } catch (e) {
      sendPort.send(<EpgProgram>[]);
    }
  }

  // تحليل تاريخ XMLTV (مثال: 20240115143000 +0200)
  static DateTime? _parseXmltvDate(String dateStr) {
    try {
      // إزالة المسافة والمنطقة الزمنية
      final clean = dateStr.replaceAll(RegExp(r'\s.*'), '').trim();
      if (clean.length < 14) return null;

      final year = int.parse(clean.substring(0, 4));
      final month = int.parse(clean.substring(4, 6));
      final day = int.parse(clean.substring(6, 8));
      final hour = int.parse(clean.substring(8, 10));
      final minute = int.parse(clean.substring(10, 12));
      final second = int.parse(clean.substring(12, 14));

      // استخراج منطقة زمنية إذا وجدت
      int tzOffset = 0;
      if (dateStr.contains(' ')) {
        final tzStr = dateStr.split(' ').last.trim();
        if (tzStr.length >= 5) {
          final sign = tzStr[0] == '-' ? -1 : 1;
          final tzHour = int.parse(tzStr.substring(1, 3));
          final tzMin = int.parse(tzStr.substring(3, 5));
          tzOffset = sign * (tzHour * 60 + tzMin);
        }
      }

      return DateTime.utc(year, month, day, hour, minute, second)
          .subtract(Duration(minutes: tzOffset));
    } catch (_) {
      return null;
    }
  }
}
