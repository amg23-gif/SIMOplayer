import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';

// بيانات الغرفة
class WatchPartyRoom {
  final String code;
  final String hostUserId;
  final String? streamUrl;
  final Duration position;
  final bool isPlaying;
  final List<String> participants;

  const WatchPartyRoom({
    required this.code,
    required this.hostUserId,
    this.streamUrl,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.participants = const [],
  });
}

class WatchPartyScreen extends ConsumerStatefulWidget {
  final String? roomCode;
  final String? streamUrl;

  const WatchPartyScreen({super.key, this.roomCode, this.streamUrl});

  @override
  ConsumerState<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends ConsumerState<WatchPartyScreen> {
  final _codeCtrl = TextEditingController();
  String? _activeRoomCode;
  bool _isHost = false;
  bool _isSyncing = false;
  int _participantCount = 1;
  DatabaseReference? _roomRef;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode != null) {
      _joinRoom(widget.roomCode!);
    }
  }

  // إنشاء غرفة جديدة
  Future<void> _createRoom() async {
    final code = _generateCode();
    final db = FirebaseDatabase.instance;
    _roomRef = db.ref('${AppConstants.rtdbWatchParties}/$code');

    await _roomRef!.set({
      'code': code,
      'streamUrl': widget.streamUrl ?? '',
      'position': 0,
      'isPlaying': false,
      'participants': ['host'],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    _roomRef!.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _participantCount =
              (data['participants'] as List?)?.length ?? 1;
        });
      }
    });

    setState(() {
      _activeRoomCode = code;
      _isHost = true;
    });
  }

  // الانضمام لغرفة موجودة
  Future<void> _joinRoom(String code) async {
    setState(() => _isSyncing = true);
    final db = FirebaseDatabase.instance;
    _roomRef = db.ref('${AppConstants.rtdbWatchParties}/$code');

    final snapshot = await _roomRef!.get();
    if (!snapshot.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('غرفة غير موجودة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSyncing = false);
      return;
    }

    _roomRef!.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _participantCount = (data['participants'] as List?)?.length ?? 1;
          _isSyncing = false;
        });
      }
    });

    setState(() {
      _activeRoomCode = code;
      _isHost = false;
      _isSyncing = false;
    });
  }

  // مغادرة الغرفة
  Future<void> _leaveRoom() async {
    if (_isHost && _activeRoomCode != null) {
      await _roomRef?.remove();
    }
    setState(() {
      _activeRoomCode = null;
      _isHost = false;
    });
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    if (_isHost) _roomRef?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('غرفة مشاهدة جماعية',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _activeRoomCode == null
            ? _buildJoinOrCreate()
            : _buildActiveRoom(),
      ),
    );
  }

  Widget _buildJoinOrCreate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // أيقونة
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          ),
          child: const Icon(Icons.people, color: Color(0xFF00E5FF), size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'شاهد مع أصدقائك',
          style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'أنشئ غرفة وشارك الرمز مع صديقك لمزامنة المشاهدة',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // إنشاء غرفة
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _createRoom,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('إنشاء غرفة جديدة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // فاصل
        const Row(
          children: [
            Expanded(child: Divider(color: Colors.white24)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('أو', style: TextStyle(fontFamily: 'Cairo', color: Colors.white38)),
            ),
            Expanded(child: Divider(color: Colors.white24)),
          ],
        ),
        const SizedBox(height: 20),

        // الانضمام لغرفة
        TextField(
          controller: _codeCtrl,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
              fontFamily: 'Cairo', color: Colors.white, fontSize: 20, letterSpacing: 4),
          decoration: InputDecoration(
            hintText: 'أدخل رمز الغرفة',
            hintStyle: const TextStyle(
                fontFamily: 'Cairo', color: Colors.white38, fontSize: 16),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              if (_codeCtrl.text.length >= 4) {
                _joinRoom(_codeCtrl.text.trim().toUpperCase());
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00E5FF),
              side: const BorderSide(color: Color(0xFF00E5FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('الانضمام للغرفة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRoom() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // حالة المزامنة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                _isSyncing ? 'جاري المزامنة...' : 'متزامن',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.green, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // رمز الغرفة
        const Text('رمز الغرفة',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
          ),
          child: Text(
            _activeRoomCode ?? '',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E5FF),
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // عدد المشاركين
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              '$_participantCount مشاركون',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // أزرار المشاركة
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _activeRoomCode ?? ''));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم نسخ الرمز',
                              style: TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: Color(0xFF1A1A1A)),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ', style: TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                    'انضم إلى غرفة المشاهدة في SIMO Player بالرمز: $_activeRoomCode'),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('مشاركة', style: TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00E5FF),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // مغادرة الغرفة
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text('مغادرة الغرفة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
