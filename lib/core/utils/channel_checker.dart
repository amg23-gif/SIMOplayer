import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database.dart';

// خدمة فحص توفر القنوات (تعمل في الخلفية بدون إزعاج المستخدم)
class ChannelChecker {
  final AppDatabase _db;
  Timer? _periodicTimer;

  ChannelChecker(this._db);

  // بدء الفحص الدوري كل 24 ساعة
  void startPeriodicCheck() {
    // فحص فوري عند البدء
    _runCheck();

    // جدولة الفحص كل 24 ساعة
    _periodicTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _runCheck(),
    );
  }

  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // تشغيل الفحص
  Future<void> _runCheck() async {
    final channels = await _db.getAllChannels();

    // تحليل القنوات في Isolate منفصل
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _checkChannelsInIsolate,
      [
        receivePort.sendPort,
        channels
            .map((c) => {
                  'id': c.id,
                  'url': c.streamUrlsJson,
                })
            .toList(),
      ],
    );

    final results = await receivePort.first as Map<String, bool>;

    // تحديث حالة كل قناة في قاعدة البيانات
    for (final entry in results.entries) {
      await _db.updateChannelAvailability(entry.key, entry.value);
    }
  }

  // فحص قناة واحدة
  static Future<bool> checkSingleChannel(String url) async {
    try {
      final uri = Uri.parse(url);
      final socket = await Socket.connect(
        uri.host,
        uri.port > 0 ? uri.port : 80,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // فحص جماعي في Isolate
  static void _checkChannelsInIsolate(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final channels = args[1] as List<Map<String, dynamic>>;

    final results = <String, bool>{};

    for (final channel in channels) {
      final id = channel['id'] as String;
      final urlsJson = channel['url'] as String;

      try {
        // محاولة الاتصال بأول رابط فقط (للسرعة)
        final urls = urlsJson.split(',');
        if (urls.isNotEmpty) {
          final url = urls.first.trim();
          results[id] = await _pingUrl(url);
        } else {
          results[id] = false;
        }
      } catch (_) {
        results[id] = false;
      }
    }

    sendPort.send(results);
  }

  static Future<bool> _pingUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final port = uri.port > 0
          ? uri.port
          : (uri.scheme == 'https' ? 443 : 80);

      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// مزود فاحص القنوات
final channelCheckerProvider = Provider<ChannelChecker>((ref) {
  final db = ref.watch(databaseProvider);
  return ChannelChecker(db);
});
