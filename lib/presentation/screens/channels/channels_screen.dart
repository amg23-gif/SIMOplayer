import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import '../../../core/constants/app_constants.dart';
  import '../../../domain/entities/channel.dart';
  import '../../providers/channels_provider.dart';

  enum _ViewMode { grid, list }
  final _viewModeProvider = StateProvider<_ViewMode>((ref) => _ViewMode.grid);
  final _searchQueryProvider = StateProvider<String>((ref) => '');

  class ChannelsScreen extends ConsumerWidget {
    final String? categoryFilter;
    const ChannelsScreen({super.key, this.categoryFilter});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final channelsAsync = ref.watch(channelsByCategoryProvider(categoryFilter));
      final viewMode = ref.watch(_viewModeProvider);
      final query = ref.watch(_searchQueryProvider);

      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Column(
          children: [
            // Top bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFF161B22),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'بحث في ${categoryFilter ?? 'القنوات'}...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 13),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B949E), size: 20),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      viewMode == _ViewMode.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: const Color(0xFF8B949E),
                    ),
                    onPressed: () => ref.read(_viewModeProvider.notifier).state =
                        viewMode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid,
                  ),
                ],
              ),
            ),
            // Channel list
            Expanded(
              child: channelsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
                error: (_, __) => const Center(child: Text('خطأ في تحميل القنوات', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E)))),
                data: (channels) {
                  final filtered = query.isEmpty
                      ? channels
                      : channels.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Color(0xFF30363D), size: 50),
                        const SizedBox(height: 12),
                        Text('لا نتائج لـ "$query"', style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E))),
                      ],
                    ));
                  }
                  return viewMode == _ViewMode.grid
                      ? _GridView(channels: filtered)
                      : _ListView(channels: filtered);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  class _GridView extends StatelessWidget {
    final List<Channel> channels;
    const _GridView({required this.channels});
    @override
    Widget build(BuildContext context) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemCount: channels.length,
        itemBuilder: (ctx, i) => _ChannelTile(channel: channels[i], isGrid: true),
      );
    }
  }

  class _ListView extends StatelessWidget {
    final List<Channel> channels;
    const _ListView({required this.channels});
    @override
    Widget build(BuildContext context) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: channels.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFF21262D), height: 1),
        itemBuilder: (ctx, i) => _ChannelTile(channel: channels[i], isGrid: false),
      );
    }
  }

  class _ChannelTile extends StatelessWidget {
    final Channel channel;
    final bool isGrid;
    const _ChannelTile({required this.channel, required this.isGrid});

    void _open(BuildContext context) {
      context.go(AppConstants.routePlayer, extra: {
        'channelId': channel.id,
        'streamUrl': channel.streamUrl,
        'channelName': channel.name,
        'channelLogo': channel.logoUrl,
      });
    }

    @override
    Widget build(BuildContext context) {
      if (isGrid) {
        return GestureDetector(
          onTap: () => _open(context),
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
                    child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: channel.logoUrl!, fit: BoxFit.contain,
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
                  child: Text(channel.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      }
      // List view
      return ListTile(
        onTap: () => _open(context),
        leading: Container(
          width: 48, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(6)),
          child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(imageUrl: channel.logoUrl!, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 20)))
              : const Icon(Icons.live_tv, color: Color(0xFF30363D), size: 20),
        ),
        title: Text(channel.name, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: channel.category != null
            ? Text(channel.category!, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF8B949E), fontSize: 11))
            : null,
        trailing: const Icon(Icons.play_circle_rounded, color: Color(0xFF1565C0), size: 28),
        tileColor: Colors.transparent,
      );
    }
  }
  