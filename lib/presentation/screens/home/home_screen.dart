import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/channels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/continue_watching_section.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar مخصص
          SliverAppBar(
            pinned: true,
            expandedHeight: 60,
            backgroundColor: const Color(0xFF0A0A0A),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF00E5FF)],
                    ),
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SIMO Player',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => context.push('/home/search'),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => context.push(AppConstants.routeSettings),
              ),
            ],
          ),

          // قسم متابعة المشاهدة
          const SliverToBoxAdapter(child: ContinueWatchingSection()),

          // قسم المفضلة
          SliverToBoxAdapter(
            child: favoritesAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SectionHeader(
                      title: 'المفضلة',
                      icon: Icons.favorite,
                      iconColor: Colors.red,
                      onMore: () =>
                          context.push('/home/channels?category=favorites'),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: favorites.take(10).length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: ChannelCard(
                            channel: favorites[i],
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
              loading: () => const ShimmerRow(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // قسم القنوات حسب التصنيف
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: categories.take(5).map((cat) {
                  return _CategorySection(category: cat, ref: ref);
                }).toList(),
              ),
              loading: () => const ShimmerLoading(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          // زر إضافة مصدر إذا لم تكن هناك قنوات
          SliverToBoxAdapter(
            child: channelsAsync.when(
              data: (channels) {
                if (channels.isNotEmpty) return const SizedBox.shrink();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.tv_off,
                            size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد قنوات. أضف مصدراً للبدء.',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white54,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/home/add-source'),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'إضافة مصدر',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String category;
  final WidgetRef ref;

  const _CategorySection({required this.category, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsByCategoryProvider(category));
    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SectionHeader(
              title: category,
              icon: Icons.tv,
              onMore: () =>
                  context.push('/home/channels?category=$category'),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: channels.take(10).length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: ChannelCard(channel: channels[i], compact: true),
                ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onMore;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.iconColor = const Color(0xFF00E5FF),
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                ),
              ),
            ),
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
