import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/source.dart';
import '../../providers/channels_provider.dart';

class AddSourceScreen extends ConsumerStatefulWidget {
  const AddSourceScreen({super.key});

  @override
  ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends ConsumerState<AddSourceScreen> {
  final _formKey = GlobalKey<FormState>();
  SourceType _selectedType = SourceType.m3uUrl;
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _epgCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int? _channelCount;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _epgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _channelCount = null;
    });

    try {
      final source = Source(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        m3uUrl: _selectedType == SourceType.m3uUrl ? _urlCtrl.text.trim() : null,
        serverUrl: _selectedType == SourceType.xtreamCodes ? _serverCtrl.text.trim() : null,
        username: _selectedType == SourceType.xtreamCodes ? _userCtrl.text.trim() : null,
        password: _selectedType == SourceType.xtreamCodes ? _passCtrl.text.trim() : null,
        epgUrl: _epgCtrl.text.trim().isNotEmpty ? _epgCtrl.text.trim() : null,
      );

      await ref.read(channelsNotifierProvider.notifier).addSource(source);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المصدر بنجاح!',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'فشل تحميل القائمة: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('إضافة مصدر',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // نوع المصدر
              const Text('نوع المصدر',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
              const SizedBox(height: 8),
              SegmentedButton<SourceType>(
                selected: {_selectedType},
                onSelectionChanged: (sel) =>
                    setState(() => _selectedType = sel.first),
                segments: const [
                  ButtonSegment(
                      value: SourceType.m3uUrl,
                      label: Text('M3U رابط', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                  ButtonSegment(
                      value: SourceType.xtreamCodes,
                      label: Text('Xtream', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                ],
              ),
              const SizedBox(height: 16),

              // اسم المصدر
              _FormField(
                controller: _nameCtrl,
                label: 'اسم المصدر',
                hint: 'مثال: قنوات عربية',
                validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 12),

              // حقول M3U
              if (_selectedType == SourceType.m3uUrl) ...[
                _FormField(
                  controller: _urlCtrl,
                  label: 'رابط M3U',
                  hint: 'http://example.com/playlist.m3u',
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'هذا الحقل مطلوب';
                    if (!v.startsWith('http')) return 'رابط غير صالح';
                    return null;
                  },
                ),
              ],

              // حقول Xtream Codes
              if (_selectedType == SourceType.xtreamCodes) ...[
                _FormField(
                  controller: _serverCtrl,
                  label: 'رابط الخادم',
                  hint: 'http://server.com:8080',
                  keyboardType: TextInputType.url,
                  validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _userCtrl,
                  label: 'اسم المستخدم',
                  hint: 'username',
                  validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _passCtrl,
                  label: 'كلمة المرور',
                  hint: 'password',
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
              ],

              const SizedBox(height: 12),

              // رابط EPG (اختياري)
              _FormField(
                controller: _epgCtrl,
                label: 'رابط دليل البرامج EPG (اختياري)',
                hint: 'http://example.com/epg.xml',
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),

              // رسالة خطأ
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              fontFamily: 'Cairo', color: Colors.redAccent, fontSize: 12),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) const SizedBox(height: 16),

              // زر التحميل
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('جاري تحميل القائمة...',
                                style: TextStyle(fontFamily: 'Cairo')),
                          ],
                        )
                      : const Text('إضافة وتحميل القائمة',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(fontFamily: 'Cairo'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
