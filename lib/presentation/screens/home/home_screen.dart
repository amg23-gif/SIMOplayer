import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../providers/channels_provider.dart';
  import '../../../domain/entities/channel.dart';
  import '../../../domain/entities/source.dart';

  // ─── State Providers ─────────────────────────────────────────────
  enum _Nav { live, movies, series, favorites, playlists }

  final _navProvider      = StateProvider<_Nav>((ref) => _Nav.live);
  final _categoryProvider = StateProvider<String?>((ref) => null); // null = الكل

  // ─── Keywords for smart content detection ────────────────────────
  const _movieKw  = ['movie','film','vod','cinema','أفلام','فيلم','سينما'];
  const _seriesKw = ['series','show','episode','مسلسل','مسلسلات','serial'];

  bool _isMovie(Channel c)  => _movieKw.any((k) => c.category.toLowerCase().contains(k));
  bool _isSeries(Channel c) => _seriesKw.any((k) => c.category.toLowerCase().contains(k));
  bool _isLive(Channel c)   => !_isMovie(c) && !_isSeries(c);

  // ─── HOME SCREEN ─────────────────────────────────────────────────
  class HomeScreen extends ConsumerWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final nav = ref.watch(_navProvider);
      return Scaffold(
        backgroundColor: const Color(0xFF090D18),
        body: SafeArea(
          child: Row(
            children: [
              // ── Sidebar ─────────────────────────────────────────
              _Sidebar(
                nav: nav,
                onNav: (n, ctx) {
                  ref.read(_navProvider.notifier).state = n;
                  ref.read(_categoryProvider.notifier).state = null;
                },
                onAddPlaylist: () => context.push('${AppConstants.routeHome}/add-source'),
                onSettings:    () => context.push(AppConstants.routeSettings),
              ),
              // ── Main ────────────────────────────────────────────
              Expanded(
                child: _MainArea(nav: nav),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ─── SIDEBAR ─────────────────────────────────────────────────────
  class _Sidebar extends StatelessWidget {
    final _Nav nav;
    final void Function(_Nav, BuildContext) onNav;
    final VoidCallback onAddPlaylist;
    final VoidCallback onSettings;
    const _Sidebar({
      required this.nav,
      required this.onNav,
      required this.onAddPlaylist,
      required this.onSettings,
    });

    static const _items = <_NavItem>[
      _NavItem(_Nav.live,      Icons.live_tv_rounded,      'Live'),
      _NavItem(_Nav.movies,    Icons.movie_filter_rounded,  'VOD'),
      _NavItem(_Nav.series,    Icons.video_library_rounded, 'Series'),
      _NavItem(_Nav.favorites, Icons.favorite_rounded,      'Favs'),
      _NavItem(_Nav.playlists, Icons.playlist_play_rounded, 'Lists'),
    ];

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 68,
        decoration: const BoxDecoration(
          color: Color(0xFF0E1526),
          border: Border(right: BorderSide(color: Color(0xFF1C2540), width: 1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Logo
            GestureDetector(
              onTap: () => onNav(_Nav.live, context),
              child: Container(
                width: 42, height: 42,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)],
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF1E6CF5).withOpacity(0.4),
                    blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              ),
            ),
            // Nav items
            ...(_items.map((item) => _SideItem(
              item: item,
              active: nav == item.nav,
              onTap: () => onNav(item.nav, context),
            ))),
            const Spacer(),
            // Settings
            _IconOnly(
              icon: Icons.settings_rounded,
              tooltip: 'الإعدادات',
              onTap: onSettings,
            ),
            const SizedBox(height: 8),
            // Add Playlist
            _IconOnly(
              icon: Icons.add_circle_outline_rounded,
              tooltip: 'إضافة قائمة',
              color: const Color(0xFF1E6CF5),
              onTap: onAddPlaylist,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }

  class _NavItem {
    final _Nav nav;
    final IconData icon;
    final String label;
    const _NavItem(this.nav, this.icon, this.label);
  }

  class _SideItem extends StatelessWidget {
    final _NavItem item;
    final bool active;
    final VoidCallback onTap;
    const _SideItem({required this.item, required this.active, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? const Color(0xFF1E6CF5).withOpacity(0.18)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active bar on top
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: active ? 24 : 0,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6CF5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(item.icon,
                color: active ? const Color(0xFF4D8EFF) : const Color(0xFF4A5568),
                size: 22),
              const SizedBox(height: 4),
              Text(item.label,
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 9,
                  color: active ? const Color(0xFF4D8EFF) : const Color(0xFF4A5568),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                )),
            ],
          ),
        ),
      );
    }
  }

  class _IconOnly extends StatelessWidget {
    final IconData icon;
    final String tooltip;
    final Color color;
    final VoidCallback onTap;
    const _IconOnly({
      required this.icon, required this.tooltip,
      this.color = const Color(0xFF4A5568), required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color == const Color(0xFF1E6CF5)
                  ? const Color(0xFF1E6CF5).withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      );
    }
  }

  // ─── MAIN AREA ────────────────────────────────────────────────────
  class _MainArea extends ConsumerWidget {
    final _Nav nav;
    const _MainArea({required this.nav});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      switch (nav) {
        case _Nav.live:      return const _LiveSection();
        case _Nav.movies:    return const _FilteredSection(title: 'الأفلام',    icon: Icons.movie_filter_rounded,  mode: 'movies');
        case _Nav.series:    return const _FilteredSection(title: 'المسلسلات', icon: Icons.video_library_rounded, mode: 'series');
        case _Nav.favorites: return const _FavSection();
        case _Nav.playlists: return const _PlaylistSection();
      }
    }
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────
  class _TopBar extends StatelessWidget {
    final String title;
    final IconData icon;
    final Widget? trailing;
    const _TopBar({required this.title, required this.icon, this.trailing});

    @override
    Widget build(BuildContext context) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF0E1526),
          border: Border(bottom: BorderSide(color: Color(0xFF1C2540))),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4D8EFF), size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 17,
              fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            if (trailing != null) trailing!,
            GestureDetector(
              onTap: () => context.push('${AppConstants.routeHome}/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161E36),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1C2540)),
                ),
                child: const Row(children: [
                  Icon(Icons.search_rounded, color: Color(0xFF4A5568), size: 15),
                  SizedBox(width: 5),
                  Text('بحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF4A5568))),
                ]),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─── LIVE TV SECTION ──────────────────────────────────────────────
  class _LiveSection extends ConsumerWidget {
    const _LiveSection();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final selectedCat = ref.watch(_categoryProvider);
      final channelsAsync = ref.watch(channelsProvider);
      final categoriesAV  = ref.watch(categoriesProvider);

      return Column(
        children: [
          _TopBar(title: 'البث المباشر', icon: Icons.live_tv_rounded),
          // Category chips
          SizedBox(
            height: 46,
            child: categoriesAV.when(
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _Chip(label: 'الكل', active: selectedCat == null,
                    onTap: () => ref.read(_categoryProvider.notifier).state = null),
                  ...cats.map((c) => _Chip(label: c,
                    active: selectedCat == c,
                    onTap: () => ref.read(_categoryProvider.notifier).state = c)),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
          Expanded(
            child: channelsAsync.when(
              loading: () => const _ShimmerGrid(),
              error: (_, __) => _EmptyState(
                icon: Icons.signal_wifi_off_rounded,
                title: 'لا يمكن تحميل القنوات',
                sub: 'تحقق من اتصالك بالإنترنت',
                onAdd: () => context.push('${AppConstants.routeHome}/add-source'),
              ),
              data: (all) {
                final live = all.where(_isLive).toList();
                final filtered = selectedCat == null
                    ? live
                    : live.where((c) => c.category == selectedCat).toList();
                if (filtered.isEmpty) {
                  return _EmptyState(
                    icon: Icons.live_tv_rounded,
                    title: 'لا توجد قنوات',
                    sub: 'أضف قائمة M3U للبدء',
                    onAdd: () => context.push('${AppConstants.routeHome}/add-source'),
                  );
                }
                return _ChannelGrid(channels: filtered);
              },
            ),
          ),
        ],
      );
    }
  }

  // ─── FILTERED SECTION (Movies / Series) ──────────────────────────
  class _FilteredSection extends ConsumerWidget {
    final String title;
    final IconData icon;
    final String mode; // 'movies' | 'series'
    const _FilteredSection({required this.title, required this.icon, required this.mode});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final channelsAsync = ref.watch(channelsProvider);
      return Column(
        children: [
          _TopBar(title: title, icon: icon),
          Expanded(
            child: channelsAsync.when(
              loading: () => const _ShimmerGrid(),
              error: (_, __) => _EmptyState(icon: Icons.error_outline_rounded,
                title: 'خطأ في التحميل', sub: '', onAdd: () {}),
              data: (all) {
                final filtered = mode == 'movies'
                    ? all.where(_isMovie).toList()
                    : all.where(_isSeries).toList();
                if (filtered.isEmpty) {
                  return _EmptyState(
                    icon: mode == 'movies' ? Icons.movie_filter_rounded : Icons.video_library_rounded,
                    title: 'لا يوجد محتوى في هذا القسم',
                    sub: 'قائمتك لا تحتوي على $title\nتأكد أن تصنيفات M3U تحتوي على كلمات Movie / Series',
                    onAdd: () => context.push('${AppConstants.routeHome}/add-source'),
                  );
                }
                return _ChannelGrid(channels: filtered);
              },
            ),
          ),
        ],
      );
    }
  }

  // ─── FAVORITES ────────────────────────────────────────────────────
  class _FavSection extends ConsumerWidget {
    const _FavSection();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final favAsync = ref.watch(favoritesProvider);
      return Column(
        children: [
          const _TopBar(title: 'المفضلة', icon: Icons.favorite_rounded),
          Expanded(
            child: favAsync.when(
              loading: () => const _ShimmerGrid(),
              error: (_, __) => const Center(child: Text('خطأ',
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568)))),
              data: (favs) => favs.isEmpty
                  ? _EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'لا توجد مفضلة بعد',
                      sub: 'اضغط طويلاً على أي قناة لإضافتها للمفضلة',
                      onAdd: null,
                    )
                  : _ChannelGrid(channels: favs),
            ),
          ),
        ],
      );
    }
  }

  // ─── PLAYLISTS SECTION ────────────────────────────────────────────
  class _PlaylistSection extends ConsumerWidget {
    const _PlaylistSection();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final sourcesAsync = ref.watch(sourcesProvider);
      return Column(
        children: [
          _TopBar(
            title: 'قوائم التشغيل',
            icon: Icons.playlist_play_rounded,
            trailing: GestureDetector(
              onTap: () => context.push('${AppConstants.routeHome}/add-source'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('إضافة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ),
          Expanded(
            child: sourcesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E6CF5))),
              error: (_, __) => const Center(child: Text('خطأ', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568)))),
              data: (sources) => sources.isEmpty
                  ? _EmptyState(
                      icon: Icons.playlist_add_rounded,
                      title: 'لا توجد قوائم تشغيل',
                      sub: 'أضف رابط M3U أو بيانات Xtream Codes',
                      onAdd: () => context.push('${AppConstants.routeHome}/add-source'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: sources.length,
                      itemBuilder: (ctx, i) => _SourceCard(source: sources[i]),
                    ),
            ),
          ),
        ],
      );
    }
  }

  class _SourceCard extends ConsumerWidget {
    final Source source;
    const _SourceCard({required this.source});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1526),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C2540)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1E6CF5).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                source.type == SourceType.xtreamCodes
                    ? Icons.dns_rounded
                    : Icons.link_rounded,
                color: const Color(0xFF1E6CF5), size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.name,
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.tv_rounded, size: 11, color: const Color(0xFF4A5568)),
                    const SizedBox(width: 4),
                    Text('${source.channelCount} قناة',
                      style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 11)),
                    if (source.lastRefreshed != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.update_rounded, size: 11, color: const Color(0xFF4A5568)),
                      const SizedBox(width: 4),
                      Text(_fmtDate(source.lastRefreshed!),
                        style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 11)),
                    ],
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF4A5568), size: 20),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      );
    }

    String _fmtDate(DateTime d) {
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inDays == 0) return 'اليوم';
      if (diff.inDays == 1) return 'أمس';
      return '${diff.inDays} أيام';
    }

    void _confirmDelete(BuildContext context, WidgetRef ref) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF0E1526),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف القائمة؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          content: Text('سيتم حذف "${source.name}" وجميع قنواتها',
            style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568)))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(channelsNotifierProvider.notifier).deleteSource(source.id);
              },
              child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }
  }

  // ─── CHANNEL GRID ─────────────────────────────────────────────────
  class _ChannelGrid extends StatelessWidget {
    final List<Channel> channels;
    const _ChannelGrid({required this.channels});

    @override
    Widget build(BuildContext context) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: channels.length,
        itemBuilder: (ctx, i) => _ChannelCard(channel: channels[i]),
      );
    }
  }

  // ─── CHANNEL CARD ─────────────────────────────────────────────────
  class _ChannelCard extends ConsumerWidget {
    final Channel channel;
    const _ChannelCard({required this.channel});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return GestureDetector(
        onTap: () => context.push(AppConstants.routePlayer, extra: {
          'channelId': channel.id,
          'streamUrl': channel.currentStreamUrl ?? '',
          'channelName': channel.name,
          'channelLogo': channel.logoUrl,
        }),
        onLongPress: () => ref.read(channelsNotifierProvider.notifier)
            .toggleFavorite(channel.id, !channel.isFavorite),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1526),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: channel.isFavorite
                  ? const Color(0xFF1E6CF5).withOpacity(0.5)
                  : const Color(0xFF1C2540),
            ),
            boxShadow: channel.isFavorite ? [
              BoxShadow(color: const Color(0xFF1E6CF5).withOpacity(0.15),
                blurRadius: 8, offset: const Offset(0, 2)),
            ] : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: channel.logoUrl!,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Icon(
                                  Icons.live_tv_rounded,
                                  color: Color(0xFF1C2540), size: 28),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.live_tv_rounded,
                                  color: Color(0xFF1C2540), size: 28),
                              )
                            : const Icon(Icons.live_tv_rounded,
                                color: Color(0xFF1C2540), size: 28),
                      ),
                    ),
                    if (channel.isFavorite)
                      Positioned(top: 6, right: 6,
                        child: Icon(Icons.favorite_rounded,
                          color: const Color(0xFF1E6CF5), size: 12)),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF090D18),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  channel.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 10,
                    color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ─── CHIP ─────────────────────────────────────────────────────────
  class _Chip extends StatelessWidget {
    final String label;
    final bool active;
    final VoidCallback onTap;
    const _Chip({required this.label, required this.active, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)])
                : null,
            color: active ? null : const Color(0xFF161E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Colors.transparent : const Color(0xFF1C2540)),
          ),
          child: Text(label,
            style: TextStyle(
              fontFamily: 'Cairo', fontSize: 12,
              color: active ? Colors.white : const Color(0xFF4A5568),
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            )),
        ),
      );
    }
  }

  // ─── SHIMMER GRID ────────────────────────────────────────────────
  class _ShimmerGrid extends StatelessWidget {
    const _ShimmerGrid();
    @override
    Widget build(BuildContext context) => GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.35,
        crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1526),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  class _EmptyState extends StatelessWidget {
    final IconData icon;
    final String title;
    final String sub;
    final VoidCallback? onAdd;
    const _EmptyState({required this.icon, required this.title, required this.sub, required this.onAdd});

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E6CF5).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1E6CF5).withOpacity(0.5), size: 36),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 16,
              color: Colors.white, fontWeight: FontWeight.w700)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sub,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF4A5568)),
                textAlign: TextAlign.center),
            ],
            if (onAdd != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('إضافة قائمة M3U', style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      );
    }
  }
  