import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import '../../providers/channels_provider.dart';
  import '../../../domain/entities/source.dart';

  class AddSourceScreen extends ConsumerStatefulWidget {
    const AddSourceScreen({super.key});
    @override
    ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
  }

  class _AddSourceScreenState extends ConsumerState<AddSourceScreen>
      with SingleTickerProviderStateMixin {

    late TabController _tabs;
    bool _loading = false;
    String _status = '';

    // M3U controllers
    final _m3uNameCtrl = TextEditingController();
    final _m3uUrlCtrl  = TextEditingController();

    // Xtream controllers
    final _xNameCtrl   = TextEditingController();
    final _xServerCtrl = TextEditingController();
    final _xUserCtrl   = TextEditingController();
    final _xPassCtrl   = TextEditingController();

    @override
    void initState() {
      super.initState();
      _tabs = TabController(length: 2, vsync: this);
    }

    @override
    void dispose() {
      _tabs.dispose();
      _m3uNameCtrl.dispose(); _m3uUrlCtrl.dispose();
      _xNameCtrl.dispose(); _xServerCtrl.dispose();
      _xUserCtrl.dispose(); _xPassCtrl.dispose();
      super.dispose();
    }

    Future<void> _addM3U() async {
      final url  = _m3uUrlCtrl.text.trim();
      final name = _m3uNameCtrl.text.trim();
      if (url.isEmpty) { _showError('أدخل رابط M3U أولاً'); return; }
      setState(() { _loading = true; _status = 'جاري تحميل القائمة...'; });
      try {
        final source = Source(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.isNotEmpty ? name : 'قائمة M3U',
          type: SourceType.m3u,
          m3uUrl: url,
        );
        await ref.read(channelsNotifierProvider.notifier).addSource(source);
        if (mounted) {
          setState(() { _status = '✅ تمت الإضافة بنجاح!'; });
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() { _loading = false; _status = ''; });
          _showError('فشل التحميل: ${e.toString().split(":").last.trim()}');
        }
      }
    }

    Future<void> _addXtream() async {
      final server = _xServerCtrl.text.trim();
      final user   = _xUserCtrl.text.trim();
      final pass   = _xPassCtrl.text.trim();
      final name   = _xNameCtrl.text.trim();
      if (server.isEmpty || user.isEmpty || pass.isEmpty) {
        _showError('أدخل بيانات السيرفر والمستخدم وكلمة المرور'); return;
      }
      setState(() { _loading = true; _status = 'جاري الاتصال بالسيرفر...'; });
      try {
        final source = Source(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.isNotEmpty ? name : user,
          type: SourceType.xtreamCodes,
          serverUrl: server,
          username: user,
          password: pass,
        );
        await ref.read(channelsNotifierProvider.notifier).addSource(source);
        if (mounted) {
          setState(() { _status = '✅ تمت الإضافة بنجاح!'; });
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() { _loading = false; _status = ''; });
          _showError('فشل الاتصال: ${e.toString().split(":").last.trim()}');
        }
      }
    }

    void _showError(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF090D18),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1526),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => context.pop()),
          title: const Text('إضافة قائمة تشغيل',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w700)),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF1E6CF5),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            labelColor: const Color(0xFF4D8EFF),
            unselectedLabelColor: const Color(0xFF4A5568),
            tabs: const [
              Tab(icon: Icon(Icons.link_rounded, size: 18), text: 'M3U / رابط'),
              Tab(icon: Icon(Icons.dns_rounded, size: 18), text: 'Xtream Codes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _M3UTab(
              nameCtrl: _m3uNameCtrl, urlCtrl: _m3uUrlCtrl,
              loading: _loading, status: _status, onSubmit: _addM3U),
            _XtreamTab(
              nameCtrl: _xNameCtrl, serverCtrl: _xServerCtrl,
              userCtrl: _xUserCtrl, passCtrl: _xPassCtrl,
              loading: _loading, status: _status, onSubmit: _addXtream),
          ],
        ),
      );
    }
  }

  // ─── M3U Tab ─────────────────────────────────────────────────────
  class _M3UTab extends StatelessWidget {
    final TextEditingController nameCtrl, urlCtrl;
    final bool loading;
    final String status;
    final VoidCallback onSubmit;
    const _M3UTab({required this.nameCtrl, required this.urlCtrl,
      required this.loading, required this.status, required this.onSubmit});

    @override
    Widget build(BuildContext context) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.info_outline_rounded,
            text: 'أدخل رابط M3U أو M3U8 من مزود IPTV الخاص بك مباشرة',
          ),
          const SizedBox(height: 24),
          _Field(ctrl: nameCtrl, label: 'اسم القائمة (اختياري)',
            hint: 'مثال: قنوات السعودية',
            icon: Icons.label_outline_rounded),
          const SizedBox(height: 14),
          _Field(ctrl: urlCtrl, label: 'رابط M3U *',
            hint: 'http://example.com/playlist.m3u',
            icon: Icons.link_rounded, keyboardType: TextInputType.url),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: const [
            _ExampleChip('http://... /playlist.m3u'),
            _ExampleChip('http://... /get.php?...'),
            _ExampleChip('http://... /stream.m3u8'),
          ]),
          const SizedBox(height: 32),
          _SubmitBtn(loading: loading, status: status,
            label: 'تحميل القائمة', onTap: onSubmit),
        ]),
      );
    }
  }

  // ─── Xtream Tab ──────────────────────────────────────────────────
  class _XtreamTab extends StatelessWidget {
    final TextEditingController nameCtrl, serverCtrl, userCtrl, passCtrl;
    final bool loading;
    final String status;
    final VoidCallback onSubmit;
    const _XtreamTab({
      required this.nameCtrl, required this.serverCtrl,
      required this.userCtrl, required this.passCtrl,
      required this.loading, required this.status, required this.onSubmit});

    @override
    Widget build(BuildContext context) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.security_rounded,
            text: 'سجّل الدخول بحساب Xtream Codes من مزود IPTV الخاص بك',
          ),
          const SizedBox(height: 24),
          _Field(ctrl: nameCtrl, label: 'اسم الاشتراك (اختياري)',
            hint: 'مثال: اشتراكي',
            icon: Icons.label_outline_rounded),
          const SizedBox(height: 14),
          _Field(ctrl: serverCtrl, label: 'عنوان السيرفر *',
            hint: 'http://server.com:8080',
            icon: Icons.dns_rounded, keyboardType: TextInputType.url),
          const SizedBox(height: 14),
          _Field(ctrl: userCtrl, label: 'اسم المستخدم *',
            hint: 'username',
            icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _Field(ctrl: passCtrl, label: 'كلمة المرور *',
            hint: 'password',
            icon: Icons.lock_outline_rounded, obscure: true),
          const SizedBox(height: 32),
          _SubmitBtn(loading: loading, status: status,
            label: 'الاتصال بالسيرفر', onTap: onSubmit),
        ]),
      );
    }
  }

  // ─── Shared Widgets ──────────────────────────────────────────────
  class _InfoCard extends StatelessWidget {
    final IconData icon;
    final String text;
    const _InfoCard({required this.icon, required this.text});

    @override
    Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E6CF5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E6CF5).withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF4D8EFF), size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
          style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4D8EFF), fontSize: 12))),
      ]),
    );
  }

  class _Field extends StatelessWidget {
    final TextEditingController ctrl;
    final String label, hint;
    final IconData icon;
    final TextInputType? keyboardType;
    final bool obscure;
    const _Field({required this.ctrl, required this.label, required this.hint,
      required this.icon, this.keyboardType, this.obscure = false});

    @override
    Widget build(BuildContext context) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
          fontFamily: 'Cairo', color: Color(0xFFB0BEC5), fontSize: 12,
          fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1526),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1C2540)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 12),
              prefixIcon: Icon(icon, color: const Color(0xFF4A5568), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ]);
    }
  }

  class _ExampleChip extends StatelessWidget {
    final String text;
    const _ExampleChip(this.text);

    @override
    Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161E36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1C2540)),
      ),
      child: Text(text, style: const TextStyle(
        fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 10)),
    );
  }

  class _SubmitBtn extends StatelessWidget {
    final bool loading;
    final String status;
    final String label;
    final VoidCallback onTap;
    const _SubmitBtn({required this.loading, required this.status,
      required this.label, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return Column(children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: loading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: loading ? null : const LinearGradient(
                  colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)]),
                color: loading ? const Color(0xFF1C2540) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? Column(children: [
                      const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Color(0xFF4D8EFF), strokeWidth: 2)),
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(status, style: const TextStyle(
                          fontFamily: 'Cairo', color: Color(0xFF4D8EFF), fontSize: 12)),
                      ],
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(label, style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
            ),
          ),
        ),
      ]);
    }
  }
  