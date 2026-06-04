import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../providers/channels_provider.dart';
  import '../../../domain/entities/channel.dart';

  // Category sidebar items
  const _categories = [
    {'icon': Icons.live_tv, 'label': 'بث مباشر'},
    {'icon': Icons.movie, 'label': 'أفلام'},
    {'icon': Icons.video_library, 'label': 'مسلسلات'},
    {'icon': Icons.star, 'label': 'المفضلة'},
    {'icon': Icons.history, 'label': 'السجل'},
    {'icon': Icons.search, 'label': 'بحث'},
    {'icon': Icons.settings, 'label': 'إعدادات'},
  ];

  final _selectedCatProvider = StateProvider<int>((ref) => 0);

  class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final selectedCat = ref.watch(_selectedCatProvider);

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Row(
          children: [
            // ─── Sidebar ───────────────────────────────────────
            _Sidebar(selectedCat: selectedCat, onSelect: (i) {
              ref.read(_selectedCatProvider.notifier).state = i;
              if (i == 5) context.go('${AppConstants.routeHome}/search');
              if (i == 6) context.go(AppConstants.routeSettings);
            }),

            // ─── Main Content ───────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _TopBar(selectedCat: selectedCat),
                  Expanded(
                    child: selectedCat == 3
                        ? const _FavoritesView()
                        : const _ChannelGridView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────
  // SIDEBAR
  // ───────────────────────────────────────────────────
  class _Sidebar extends StatelessWidget {
    final int selectedCat;
    final void Function(int) onSelect;
    const _Sidebar({required this.selectedCat, required this.onSelect});

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 72,
        color: const Color(0xFF161B22),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Logo
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            // Nav items
            ...List.generate(_categories.length, (i) {
              final cat = _categories[i];
              final isSelected = selectedCat == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1565C0).withOpacity(0.25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.6), width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF8B949E),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF8B949E),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            // Add source button
            GestureDetector(
              onTap: () => context.go('${AppConstants.routeHome}/add-source'),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF21262D),
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF8B949E), size: 24),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────
  // TOP BAR
  // ───────────────────────────────────────────────────
  class _TopBar extends StatelessWidget {
    final int selectedCat;
    const _TopBar({required this.selectedCat});

    @override
    Widget build(BuildContext context) {
      final titles = ['البث المباشر', 'الأفلام', 'المسلسلات', 'المفضلة', 'السجل', 'بحث', 'إعدادات'];
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 1)),
        ),
        child: Row(
          children: [
            Text(
              titles[selectedCat],
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // EPG button
            _NavBtn(
              icon: Icons.calendar_today_rounded,
              label: 'EPG',
              onTap: () => context.go('${AppConstants.routeHome}/epg'),
            ),
            const SizedBox(width: 8),
            // Search
            _NavBtn(
              icon: Icons.search_rounded,
              label: '',
              onTap: () => context.go('${AppConstants.routeHome}/search'),
            ),
          ],
        ),
      );
    }
  }

  class _NavBtn extends StatelessWidget {
    final IconData icon;
    final String label;
    final VoidCallback onTap;
    const _NavBtn({required this.icon, required this.label, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8B949E), size: 16),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF8B949E))),
              ]
            ],
          ),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────
  // CHANNEL GRID
  // ───────────────────────────────────────────────────
  class _ChannelGridView extends ConsumerWidget {
    const _ChannelGridView();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final channelsAsync = ref.watch(channelsProvider);

      return channelsAsync.when(
        loading: () => const _LoadingGrid(),
        error: (_, __) => const _EmptyState(),
        data: (channels) {
          if (channels.isEmpty) return const _EmptyState();
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: channels.length,
            itemBuilder: (ctx, i) => _ChannelCard(channel: channels[i]),
          );
        },
      );
    }
  }

  class _ChannelCard extends StatelessWidget {
    final Channel channel;
    const _ChannelCard({required this.channel});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () => context.go(AppConstants.routePlayer, extra: {
          'channelId': channel.id,
          'streamUrl': channel.streamUrl,
          'channelName': channel.name,
          'channelLogo': channel.logoUrl,
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF30363D), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: channel.logoUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 30),
                          errorWidget: (_, __, ___) => const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 30),
                        )
                      : const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 30),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  channel.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────
  // FAVORITES
  // ───────────────────────────────────────────────────
  class _FavoritesView extends ConsumerWidget {
    const _FavoritesView();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final favAsync = ref.watch(favoritesProvider);
      return favAsync.when(
        loading: () => const _LoadingGrid(),
        error: (_, __) => const _EmptyState(),
        data: (favs) {
          if (favs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star_border_rounded, color: Color(0xFF30363D), size: 60),
                  SizedBox(height: 16),
                  Text('لا توجد قنوات مفضلة بعد', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E))),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: favs.length,
            itemBuilder: (ctx, i) => _ChannelCard(channel: favs[i]),
          );
        },
      );
    }
  }

  // ───────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────
  class _LoadingGrid extends StatelessWidget {
    const _LoadingGrid();
    @override
    Widget build(BuildContext context) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  class _EmptyState extends StatelessWidget {
    const _EmptyState();
    @override
    Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_off_rounded, color: Color(0xFF30363D), size: 64),
            const SizedBox(height: 16),
            const Text('لا توجد قنوات', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Color(0xFF8B949E))),
            const SizedBox(height: 8),
            const Text('أضف مصدر M3U للبدء', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF8B949E))),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('${AppConstants.routeHome}/add-source'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('+ إضافة مصدر', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }
  }
  