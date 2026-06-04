import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:uuid/uuid.dart';
  import '../../../domain/entities/source.dart';
  import '../../providers/channels_provider.dart';

  class AddSourceScreen extends ConsumerStatefulWidget {
    const AddSourceScreen({super.key});
    @override
    ConsumerState<AddSourceScreen> createState() => _St();
  }

  class _St extends ConsumerState<AddSourceScreen> {
    final _urlCtrl  = TextEditingController();
    final _nameCtrl = TextEditingController();
    bool _loading = false;
    String? _err;

    @override
    void dispose() { _urlCtrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

    Future<void> _add() async {
      final url = _urlCtrl.text.trim();
      if (url.isEmpty) { setState(() => _err = 'أدخل رابط M3U'); return; }
      setState(() { _loading = true; _err = null; });
      try {
        final source = Source(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim().isEmpty ? 'مصدر جديد' : _nameCtrl.text.trim(),
          type: SourceType.m3uUrl,
          m3uUrl: url,
        );
        await ref.read(channelsNotifierProvider.notifier).addSource(source);
        if (mounted) context.pop();
      } catch (e) {
        setState(() => _err = 'فشل إضافة المصدر. تحقق من الرابط.');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22), elevation: 0,
          title: const Text('إضافة مصدر M3U',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('رابط M3U / M3U8'),
              const SizedBox(height: 8),
              _fld(_urlCtrl, 'http://example.com/playlist.m3u', Icons.link_rounded),
              const SizedBox(height: 16),
              _lbl('الاسم (اختياري)'),
              const SizedBox(height: 8),
              _fld(_nameCtrl, 'اسم المصدر', Icons.label_rounded),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, style: const TextStyle(fontFamily: 'Cairo', color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إضافة', style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF30363D))),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF1565C0), size: 18),
                    SizedBox(width: 8),
                    Text('أمثلة على الروابط',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  SizedBox(height: 8),
                  Text('• http://example.com/playlist.m3u',
                    style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 12)),
                  Text('• http://iptv.example.com/get.php?type=m3u',
                    style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 12)),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    Widget _lbl(String t) => Text(t, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 13));

    Widget _fld(TextEditingController c, String hint, IconData icon) => TextField(
      controller: c,
      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFF8B949E)),
        filled: true, fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF30363D))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF30363D))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0))),
        prefixIcon: Icon(icon, color: const Color(0xFF8B949E))),
    );
  }
  