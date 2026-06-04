import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';

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
  int _participantCount = 1;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode != null) {
      setState(() => _activeRoomCode = widget.roomCode);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _createRoom() {
    final code = _generateCode();
    setState(() {
      _activeRoomCode = code;
      _participantCount = 1;
    });
  }

  void _joinRoom(String code) {
    setState(() {
      _activeRoomCode = code.toUpperCase().trim();
      _participantCount = 2;
    });
  }

  void _shareCode() {
    if (_activeRoomCode == null) return;
    Share.share('انضم إلى غرفة مشاهدتي على SIMO Player\nالرمز: $_activeRoomCode');
  }

  void _leaveRoom() {
    setState(() {
      _activeRoomCode = null;
      _participantCount = 1;
      _codeCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1526),
        title: const Text('غرفة المشاهدة الجماعية',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _activeRoomCode != null
          ? _ActiveRoom(
              code: _activeRoomCode!,
              participants: _participantCount,
              onShare: _shareCode,
              onLeave: _leaveRoom,
            )
          : _JoinOrCreate(
              ctrl: _codeCtrl,
              onCreateRoom: _createRoom,
              onJoinRoom: () {
                if (_codeCtrl.text.trim().length >= 4) {
                  _joinRoom(_codeCtrl.text);
                }
              },
            ),
    );
  }
}

class _JoinOrCreate extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  const _JoinOrCreate({required this.ctrl, required this.onCreateRoom, required this.onJoinRoom});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E6CF5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E6CF5).withOpacity(0.3)),
          ),
          child: const Column(children: [
            Icon(Icons.groups_rounded, color: Color(0xFF4D8EFF), size: 48),
            SizedBox(height: 12),
            Text('شاهد مع أصدقائك', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('أنشئ غرفة أو انضم لغرفة موجودة لمشاهدة IPTV معاً',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCreateRoom,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('إنشاء غرفة جديدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6CF5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(children: [
          Expanded(child: Divider(color: Color(0xFF1C2540))),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('أو', style: TextStyle(fontFamily: 'Cairo', color: Colors.white38))),
          Expanded(child: Divider(color: Color(0xFF1C2540))),
        ]),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1526),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1C2540)),
          ),
          child: TextField(
            controller: ctrl,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 22, letterSpacing: 4),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'أدخل رمز الغرفة',
              hintStyle: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 14, letterSpacing: 0),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onJoinRoom,
            icon: const Icon(Icons.login_rounded),
            label: const Text('الانضمام للغرفة', style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4D8EFF),
              side: const BorderSide(color: Color(0xFF1E6CF5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ActiveRoom extends StatelessWidget {
  final String code;
  final int participants;
  final VoidCallback onShare;
  final VoidCallback onLeave;
  const _ActiveRoom({required this.code, required this.participants, required this.onShare, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1526),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E6CF5).withOpacity(0.4)),
            ),
            child: Column(children: [
              const Text('رمز الغرفة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 12),
              Text(code, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 6)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.people_rounded, color: Color(0xFF4D8EFF), size: 18),
                const SizedBox(width: 6),
                Text('$participants مشارك', style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4D8EFF))),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم نسخ الرمز!', style: TextStyle(fontFamily: 'Cairo')),
                    duration: Duration(seconds: 2),
                  ));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ الرمز', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6CF5), foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('مشاركة', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C2540), foregroundColor: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 18),
            label: const Text('مغادرة الغرفة', style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
          ),
        ]),
      ),
    );
  }
}
