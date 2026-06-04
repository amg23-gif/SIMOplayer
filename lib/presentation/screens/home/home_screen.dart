import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../providers/channels_provider.dart';
  import '../../../domain/entities/channel.dart';

  const _cats = [
    {'icon': Icons.live_tv,       'label': 'بث مباشر'},
    {'icon': Icons.movie,         'label': 'أفلام'},
    {'icon': Icons.video_library, 'label': 'مسلسلات'},
    {'icon': Icons.star,          'label': 'المفضلة'},
    {'icon': Icons.history,       'label': 'السجل'},
    {'icon': Icons.search,        'label': 'بحث'},
    {'icon': Icons.settings,      'label': 'إعدادات'},
  ];

  final _selCatProvider = StateProvider<int>((ref) => 0);

  class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final sel = ref.watch(_selCatProvider);
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Row(
          children: [
            _Sidebar(sel: sel, onSelect: (i) {
              ref.read(_selCatProvider.notifier).state = i;
              if (i == 5) context.go('${AppConstants.routeHome}/search');
              if (i == 6) context.go(AppConstants.routeSettings);
            }),
            Expanded(
              child: Column(
                children: [
                  _TopBar(sel: sel),
                  Expanded(child: sel == 3 ? const _FavoritesView() : const _ChannelGridView()),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────────────────
  class _Sidebar extends StatelessWidget {
    final int sel;
    final void Function(int) onSelect;
    const _Sidebar({required this.sel, required this.onSelect});

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 72,
        color: const Color(0xFF161B22),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 44, height: 44,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            ...List.generate(_cats.length, (i) {
              final c = _cats[i];
              final active = sel == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF1565C0).withOpacity(0.22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.5)) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c['icon'] as IconData,
                        color: active ? const Color(0xFF2196F3) : const Color(0xFF8B949E), size: 22),
                      const SizedBox(height: 4),
                      Text(c['label'] as String,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 9,
                          color: active ? const Color(0xFF2196F3) : const Color(0xFF8B949E),
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal),
                        textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('${AppConstants.routeHome}/add-source'),
              child: Container(
                width: 44, height: 44,
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

  // ─── TOP BAR ─────────────────────────────────────────────────────────────────
  class _TopBar extends StatelessWidget {
    final int sel;
    const _TopBar({required this.sel});

    @override
    Widget build(BuildContext context) {
      const titles = ['البث المباشر','الأفلام','المسلسلات','المفضلة','السجل','بحث','إعدادات'];
      return Container(
        height: 60, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
        ),
        child: Row(
          children: [
            Text(titles[sel], style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            _Btn(icon: Icons.calendar_today_rounded, label: 'EPG', onTap: () => context.go('${AppConstants.routeHome}/epg')),
            const SizedBox(width: 8),
            _Btn(icon: Icons.search_rounded, label: '', onTap: () => context.go('${AppConstants.routeHome}/search')),
          ],
        ),
      );
    }
  }

  class _Btn extends StatelessWidget {
    final IconData icon; final String label; final VoidCallback onTap;
    const _Btn({required this.icon, required this.label, required this.onTap});
    @override
    Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF8B949E), size: 16),
          if (label.isNotEmpty) ...[const SizedBox(width: 4), Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF8B949E)))],
        ]),
      ),
    );
  }

  // ─── CHANNEL GRID ─────────────────────────────────────────────────────────────
  class _ChannelGridView extends ConsumerWidget {
    const _ChannelGridView();
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final async = ref.watch(channelsProvider);
      return async.when(
        loading: () => const _ShimmerGrid(),
        error: (_, __) => const _Empty(),
        data: (channels) => channels.isEmpty
            ? const _Empty()
            : GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: channels.length,
                itemBuilder: (ctx, i) => _Card(ch: channels[i]),
              ),
      );
    }
  }

  // ─── FAVORITES ────────────────────────────────────────────────────────────────
  class _FavoritesView extends ConsumerWidget {
    const _FavoritesView();
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final async = ref.watch(favoritesProvider);
      return async.when(
        loading: () => const _ShimmerGrid(),
        error: (_, __) => const _Empty(),
        data: (favs) => favs.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.star_border_rounded, color: Color(0xFF30363D), size: 60),
                SizedBox(height: 16),
                Text('لا توجد قنوات مفضلة', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E))),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: favs.length,
                itemBuilder: (ctx, i) => _Card(ch: favs[i]),
              ),
      );
    }
  }

  // ─── CHANNEL CARD ─────────────────────────────────────────────────────────────
  class _Card extends StatelessWidget {
    final Channel ch;
    const _Card({required this.ch});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () => context.go(AppConstants.routePlayer, extra: {
          'channelId': ch.id,
          'streamUrl': ch.currentStreamUrl ?? '',
          'channelName': ch.name,
          'channelLogo': ch.logoUrl,
        }),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: ch.logoUrl!, fit: BoxFit.contain,
                          placeholder: (_, __) => const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 26),
                          errorWidget: (_, __, ___) => const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 26))
                      : const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 26),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                child: Text(ch.name,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────
  class _ShimmerGrid extends StatelessWidget {
    const _ShimmerGrid();
    @override
    Widget build(BuildContext context) => GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10))),
    );
  }

  class _Empty extends StatelessWidget {
    const _Empty();
    @override
    Widget build(BuildContext context) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
      ]),
    );
  }
  