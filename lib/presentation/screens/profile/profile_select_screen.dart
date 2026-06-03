import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/local/database.dart';
import '../../../domain/entities/profile.dart';

// مزود قائمة الملفات الشخصية
final profilesProvider = StreamProvider<List<Profile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchProfiles().map((rows) => rows
      .map((r) => Profile(
            id: r.id,
            name: r.name,
            avatarUrl: r.avatarUrl,
            avatarEmoji: r.avatarEmoji ?? '😊',
            isDefault: r.isDefault,
            createdAt: r.createdAt,
          ))
      .toList());
});

// الملف الشخصي المحدد حالياً
final selectedProfileProvider = StateProvider<String?>((ref) => null);

// أيقونات الملفات الشخصية
const _avatarEmojis = [
  '😊', '😎', '🎬', '📺', '🎮', '👦', '👧', '👨', '👩', '🧑',
  '🦁', '🐯', '🐻', '🦊', '🐼', '🎭', '🎯', '🏆', '⭐', '🌙',
];

class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  ConsumerState<ProfileSelectScreen> createState() =>
      _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  bool _showManage = false;

  void _selectProfile(String profileId) {
    ref.read(selectedProfileProvider.notifier).state = profileId;
    context.go(AppConstants.routeHome);
  }

  Future<void> _addProfile() async {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '😊';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'ملف شخصي جديد',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            textAlign: TextAlign.right,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار الأيقونة
              Text(selectedEmoji,
                  style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _avatarEmojis
                    .map((emoji) => GestureDetector(
                          onTap: () =>
                              setDlgState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selectedEmoji == emoji
                                  ? const Color(0xFF00E5FF).withOpacity(0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: selectedEmoji == emoji
                                  ? Border.all(
                                      color: const Color(0xFF00E5FF))
                                  : null,
                            ),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اسم الملف الشخصي',
                  hintStyle: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final db = ref.read(databaseProvider);
                await db.insertProfile(ProfilesTableCompanion.insert(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  avatarEmoji: Value(selectedEmoji),
                  createdAt: DateTime.now(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
              child: const Text('حفظ',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'من يشاهد؟',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: profilesAsync.when(
                data: (profiles) => GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: profiles.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == profiles.length) {
                      return _ProfileCard(
                        emoji: '+',
                        name: 'إضافة',
                        onTap: _addProfile,
                        isAdd: true,
                      );
                    }
                    final p = profiles[i];
                    return _ProfileCard(
                      emoji: p.avatarEmoji ?? '😊',
                      name: p.name,
                      onTap: () => _selectProfile(p.id),
                    );
                  },
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00E5FF))),
                error: (e, _) => Center(
                    child: Text('خطأ: $e',
                        style: const TextStyle(
                            fontFamily: 'Cairo', color: Colors.red))),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;
  final bool isAdd;

  const _ProfileCard({
    required this.emoji,
    required this.name,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isAdd
                  ? Colors.white10
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: isAdd
                  ? Border.all(
                      color: Colors.white30, style: BorderStyle.solid)
                  : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: isAdd ? 36 : 48,
                  color: isAdd ? Colors.white54 : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
