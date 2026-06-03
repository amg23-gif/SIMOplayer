import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/channels_provider.dart';

class RemoteSetupScreen extends ConsumerStatefulWidget {
  const RemoteSetupScreen({super.key});

  @override
  ConsumerState<RemoteSetupScreen> createState() => _RemoteSetupScreenState();
}

class _RemoteSetupScreenState extends ConsumerState<RemoteSetupScreen> {
  String? _setupCode;
  Timer? _expiryTimer;
  int _remainingSeconds = AppConstants.qrCodeExpiryMinutes * 60;
  bool _transferComplete = false;
  DatabaseReference? _codeRef;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(AppConstants.qrCodeLength, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _generateCode() async {
    final code = _generateRandomCode();
    setState(() {
      _setupCode = code;
      _remainingSeconds = AppConstants.qrCodeExpiryMinutes * 60;
      _transferComplete = false;
    });

    // حفظ الرمز في Firebase مع البيانات للنقل
    _codeRef = FirebaseDatabase.instance.ref('${AppConstants.rtdbRemoteSetup}/$code');
    await _codeRef!.set({
      'code': code,
      'status': 'waiting',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'expiresAt': DateTime.now().add(Duration(minutes: AppConstants.qrCodeExpiryMinutes)).millisecondsSinceEpoch,
    });

    // مراقبة حالة النقل
    _codeRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['status'] == 'transfer_initiated') {
        _performTransfer(code, data);
      }
    });

    // مؤقت الانتهاء
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _generateCode(); // تجديد تلقائي
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _performTransfer(String code, Map data) async {
    // نقل المصادر والإعدادات للتلفزيون
    final sourcesAsync = ref.read(sourcesProvider);
    sourcesAsync.whenData((sources) async {
      final sourcesData = sources.map((s) => {
        'id': s.id,
        'name': s.name,
        'type': s.type.name,
        'm3uUrl': s.m3uUrl,
        'serverUrl': s.serverUrl,
        'username': s.username,
        'password': s.password,
        'epgUrl': s.epgUrl,
      }).toList();

      await _codeRef!.update({
        'status': 'transfer_complete',
        'sources': sourcesData,
      });

      if (mounted) {
        setState(() => _transferComplete = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نقل الإعدادات للتلفزيون بنجاح!',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _codeRef?.remove();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('الإعداد عن بُعد',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // تعليمات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _InstructionStep(number: '1', text: 'افتح SIMO Player على التلفزيون'),
                  SizedBox(height: 8),
                  _InstructionStep(number: '2', text: 'اذهب للإعدادات > الإعداد عن بُعد'),
                  SizedBox(height: 8),
                  _InstructionStep(number: '3', text: 'امسح رمز QR الظاهر أدناه بكاميرا هاتفك'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (_setupCode != null) ...[
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'simo_player://setup?code=$_setupCode',
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1565C0),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // الرمز النصي
              Text(
                _setupCode!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),

              // مؤقت الانتهاء
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _remainingSeconds < 60 ? Colors.orange : Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ينتهي بعد $_formattedTime',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: _remainingSeconds < 60 ? Colors.orange : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // تجديد الرمز
            OutlinedButton.icon(
              onPressed: _generateCode,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تجديد الرمز',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            if (_transferComplete) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('تم نقل الإعدادات بنجاح!',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.green)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00E5FF),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
