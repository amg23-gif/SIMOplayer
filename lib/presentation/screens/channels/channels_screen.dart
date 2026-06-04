import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../../domain/entities/channel.dart';
  import '../../providers/channels_provider.dart';

  enum _VM { grid, list }
  final _vmProv = StateProvider<_VM>((ref) => _VM.grid);
  final _qProv  = StateProvider<String>((ref) => '');

  class ChannelsScreen extends ConsumerWidget {
    final String? categoryFilter;
    const ChannelsScreen({super.key, this.categoryFilter});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final chAsync = ref.watch(channelsByCategoryProvider(categoryFilter));
      final vm = ref.watch(_vmProv);
      final q  = ref.watch(_qProv);

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Column(
          children: [
            // شريط البحث والتبديل
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF161B22),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.pop()),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => ref.read(_qProv.notifier).state = v,
                        style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'بحث في ${categoryFilter ?? 'القنوات'}...',
                          hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 13),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B949E), size: 20)),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        vm == _VM.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        color: const Color(0xFF8B949E)),
                      onPressed: () => ref.read(_vmProv.notifier).state =
                          vm == _VM.grid ? _VM.list : _VM.grid),
                  ],
                ),
              ),
            ),
            // القنوات
            Expanded(
              child: chAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
                error: (_, __) => const Center(
                  child: Text('خطأ في التحميل',
                    style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E)))),
                data: (channels) {
                  final list = q.isEmpty
                      ? channels
                      : channels.where((c) =>
                          c.name.toLowerCase().contains(q.toLowerCase())).toList();
                  if (list.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search_off_rounded, color: Color(0xFF21262D), size: 50),
                      const SizedBox(height: 12),
                      Text('لا نتائج لـ "$q"',
                        style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E))),
                    ]));
                  }
                  return vm == _VM.grid
                      ? _GridV(channels: list)
                      : _ListV(channels: list);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  class _GridV extends StatelessWidget {
    final List<Channel> channels;
    const _GridV({required this.channels});
    @override
    Widget build(BuildContext context) => GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.4,
        crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: channels.length,
      itemBuilder: (ctx, i) => _Tile(ch: channels[i], isGrid: true),
    );
  }

  class _ListV extends StatelessWidget {
    final List<Channel> channels;
    const _ListV({required this.channels});
    @override
    Widget build(BuildContext context) => ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF21262D), height: 1),
      itemBuilder: (ctx, i) => _Tile(ch: channels[i], isGrid: false),
    );
  }

  class _Tile extends StatelessWidget {
    final Channel ch;
    final bool isGrid;
    const _Tile({required this.ch, required this.isGrid});

    void _open(BuildContext context) => context.push(AppConstants.routePlayer, extra: {
      'channelId': ch.id,
      'streamUrl': ch.currentStreamUrl ?? '',
      'channelName': ch.name,
      'channelLogo': ch.logoUrl,
    });

    @override
    Widget build(BuildContext context) {
      final logoWidget = ch.logoUrl != null && ch.logoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: ch.logoUrl!, fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(Icons.live_tv, color: Color(0xFF21262D), size: 24))
          : const Icon(Icons.live_tv, color: Color(0xFF21262D), size: 24);

      if (isGrid) {
        return GestureDetector(
          onTap: () => _open(context),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF21262D))),
            child: Column(children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(8), child: logoWidget)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                child: Text(ch.name,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 10,
                    color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      }
      // عرض قائمة
      return ListTile(
        onTap: () => _open(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 52, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(6)),
          child: ClipRRect(borderRadius: BorderRadius.circular(6), child: logoWidget),
        ),
        title: Text(ch.name,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white,
            fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: ch.category.isNotEmpty
            ? Text(ch.category, style: const TextStyle(
                fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 11))
            : null,
        trailing: const Icon(Icons.play_circle_rounded, color: Color(0xFF1565C0), size: 30),
      );
    }
  }
  