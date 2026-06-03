import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channels_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('الإعدادات',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // الحساب
          if (user != null && !user.isAnonymous)
            _SettingsSection(
              title: 'الحساب',
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF1565C0),
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.substring(0, 1) ?? 'م',
                            style: const TextStyle(
                                fontFamily: 'Cairo', color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    user.displayName ?? 'مستخدم',
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    user.email ?? '',
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
                    textDirection: TextDirection.rtl,
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go(AppConstants.routeLogin);
                    },
                    child: const Text('تسجيل الخروج',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                  ),
                ),
              ],
            ),

          // المظهر
          _SettingsSection(
            title: 'المظهر',
            children: [
              // الثيم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الثيم',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
                    const SizedBox(height: 8),
                    SegmentedButton<AppThemeMode>(
                      selected: {settings.appThemeMode},
                      onSelectionChanged: (sel) => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(sel.first),
                      segments: const [
                        ButtonSegment(
                            value: AppThemeMode.dark,
                            label: Text('داكن', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            icon: Icon(Icons.dark_mode, size: 16)),
                        ButtonSegment(
                            value: AppThemeMode.light,
                            label: Text('فاتح', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            icon: Icon(Icons.light_mode, size: 16)),
                        ButtonSegment(
                            value: AppThemeMode.oled,
                            label: Text('OLED', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            icon: Icon(Icons.brightness_1, size: 16)),
                      ],
                    ),
                  ],
                ),
              ),

              // اللغة
              ListTile(
                title: const Text('اللغة',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                trailing: DropdownButton<String>(
                  value: settings.locale.languageCode,
                  dropdownColor: const Color(0xFF1A1A1A),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: 'ar',
                        child: Text('العربية',
                            style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
                    DropdownMenuItem(
                        value: 'en',
                        child: Text('English',
                            style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).setLocale(val);
                    }
                  },
                ),
              ),
            ],
          ),

          // إعدادات المشغل
          _SettingsSection(
            title: 'إعدادات المشغل',
            children: [
              SwitchListTile(
                title: const Text('تسريع الجهاز',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                subtitle: const Text('استخدام وحدة معالجة GPU',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
                    textDirection: TextDirection.rtl),
                value: settings.hardwareAcceleration,
                onChanged: (val) => ref
                    .read(settingsProvider.notifier)
                    .setHardwareAcceleration(val),
                activeColor: const Color(0xFF00E5FF),
              ),
              // حجم المخزن المؤقت
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${settings.bufferSizeMB} ميغابايت',
                            style: const TextStyle(
                                fontFamily: 'Cairo', color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                        const Text('حجم المخزن المؤقت',
                            style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
                      ],
                    ),
                    Slider(
                      value: settings.bufferSizeMB.toDouble(),
                      min: 16,
                      max: 256,
                      divisions: 15,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (val) => ref
                          .read(settingsProvider.notifier)
                          .setBufferSize(val.toInt()),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // المصادر
          _SettingsSection(
            title: 'المصادر',
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF)),
                title: const Text('إضافة مصدر جديد',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                onTap: () => context.push('/home/add-source'),
                trailing: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.orange),
                title: const Text('فحص توفر القنوات',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري بدء فحص القنوات في الخلفية...',
                          style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Color(0xFF1A1A1A),
                    ),
                  );
                },
                trailing: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
            ],
          ),

          // الإعداد عن بُعد
          _SettingsSection(
            title: 'الإعداد عن بُعد',
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Color(0xFF00E5FF)),
                title: const Text('إعداد التلفزيون عن بُعد',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                subtitle: const Text('امسح QR Code لنقل الإعدادات',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
                    textDirection: TextDirection.rtl),
                onTap: () => context.push('/settings/remote-setup'),
                trailing: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
            ],
          ),

          // الخصوصية والأمان
          _SettingsSection(
            title: 'الخصوصية والأمان',
            children: [
              ListTile(
                leading: const Icon(Icons.shield, color: Colors.green),
                title: const Text('حماية الاتصال (VPN)',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                subtitle: const Text('يُنصح باستخدام VPN لحماية خصوصيتك',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
                    textDirection: TextDirection.rtl),
                onTap: () async {
                  final vpnUri = Uri.parse('https://play.google.com/store/search?q=vpn');
                  if (await canLaunchUrl(vpnUri)) {
                    await launchUrl(vpnUri, mode: LaunchMode.externalApplication);
                  }
                },
                trailing: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
            ],
          ),

          // عن التطبيق
          _SettingsSection(
            title: 'عن التطبيق',
            children: [
              ListTile(
                title: const Text('الإصدار',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                trailing: const Text('${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white54)),
              ),
              ListTile(
                title: const Text('سياسة الخصوصية',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    textDirection: TextDirection.rtl),
                trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E5FF),
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(color: Colors.white10),
              bottom: BorderSide(color: Colors.white10),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
