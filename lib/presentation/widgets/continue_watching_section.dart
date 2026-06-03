import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/database.dart';
import '../providers/settings_provider.dart';
import 'shimmer_loading.dart';

// مزود سجل المشاهدة
final watchHistoryProvider = StreamProvider<List<WatchHistoryTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final profile = ref.watch(selectedProfileIdProvider);
  return db.watchHistory(profileId: profile, limit: 10);
});

// معرف الملف الشخصي المحدد
final selectedProfileIdProvider = StateProvider<String>((ref) => 'default');

class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('عرض الكل',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF00E5FF),
                            fontSize: 13)),
                  ),
                  const Row(
                    children: [
                      Text('متابعة المشاهدة',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.play_circle, color: Color(0xFF00E5FF), size: 20),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (ctx, i) => _ContinueWatchingCard(item: history[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const ShimmerRow(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final WatchHistoryTableData item;
  const _ContinueWatchingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppConstants.routePlayer,
        extra: {
          'channelId': item.channelId,
          'streamUrl': item.streamUrl ?? '',
          'channelName': item.channelName,
          'channelLogo': item.channelLogo,
        },
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            // شعار القناة
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.channelLogo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.channelLogo!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.tv,
                                color: Colors.white24,
                                size: 48),
                          ),
                        )
                      : const Icon(Icons.tv, color: Colors.white24, size: 48),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.channelName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white70,
                          fontSize: 11),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
            // زر التشغيل
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF).withOpacity(0.9),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.black, size: 18),
              ),
            ),
            // شريط تقدم المشاهدة
            if (item.stopPositionSeconds != null && item.stopPositionSeconds! > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: LinearProgressIndicator(
                    value: (item.stopPositionSeconds! / 3600.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    minHeight: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
