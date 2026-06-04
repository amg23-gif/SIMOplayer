import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(AppConstants.qrCodeLength,
        (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _generateCode() {
    final code = _generateRandomCode();
    setState(() {
      _setupCode = code;
      _remainingSeconds = AppConstants.qrCodeExpiryMinutes * 60;
      _transferComplete = false;
    });

    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _generateCode();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('الإعداد عن بُعد',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
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
                  _InstructionStep(number: '3', text: 'أدخل الرمز الظاهر أدناه أو امسح QR Code'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_setupCode != null) ...[
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
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _setupCode!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم نسخ الرمز!',
                        style: TextStyle(fontFamily: 'Cairo')),
                    duration: Duration(seconds: 2),
                  ));
                },
                child: Text(
                  _setupCode!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('اضغط للنسخ',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer,
                      size: 16,
                      color: _remainingSeconds < 60
                          ? Colors.orange
                          : Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    'ينتهي بعد $_formattedTime',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: _remainingSeconds < 60
                          ? Colors.orange
                          : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _generateCode,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تجديد الرمز',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E6CF5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1E6CF5).withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF4D8EFF), size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ميزة النقل التلقائي عبر QR ستكون متاحة في إصدار قادم بعد ربط Firebase',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFF4D8EFF),
                        fontSize: 11),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ]),
            ),
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
        Text(text,
            style: const TextStyle(
                fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF00E5FF)),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
