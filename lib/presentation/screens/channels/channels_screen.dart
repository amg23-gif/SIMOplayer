import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/channels_provider.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/app_bottom_nav.dart';

// أوضاع العرض
enum ChannelViewMode { grid, list, poster }

final _viewModeProvider = StateProvider<ChannelViewMode>((ref) => ChannelViewMode.grid);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          categoryFilter ?? 'جميع القنوات',
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        actions: [
          // تبديل وضع العرض
          PopupMenuButton<ChannelViewMode>(
            icon: const Icon(Icons.view_module, color: Colors.white),
            color: const Color(0xFF1A1A1A),
            onSelected: (mode) =>
                ref.read(_viewModeProvider.notifier).state = mode,
            itemBuilder: (_) => [
              _viewMenuItem(ChannelViewMode.grid, Icons.grid_view, 'عرض شبكي'),
              _viewMenuItem(ChannelViewMode.list, Icons.list, 'عرض قائمة'),
              _viewMenuItem(
                  ChannelViewMode.poster, Icons.movie, 'عرض بوسترات'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              textDirection: TextDirection.rtl,
              style:
                  const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث في القنوات...',
                hintStyle: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white54),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (val) =>
                  ref.read(_searchQueryProvider.notifier).state = val,
            ),
          ),

          // قائمة القنوات
          Expanded(
            child: channelsAsync.when(
              data: (channels) {
                final filtered = query.isEmpty
                    ? channels
                    : channels
                        .where((c) => c.name
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد قنوات',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white54,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                switch (viewMode) {
                  case ChannelViewMode.grid:
                    return _GridView(channels: filtered);
                  case ChannelViewMode.list:
                    return _ListView(channels: filtered);
                  case ChannelViewMode.poster:
                    return _PosterView(channels: filtered);
                }
              },
              loading: () => const ShimmerLoading(),
              error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  PopupMenuItem<ChannelViewMode> _viewMenuItem(
      ChannelViewMode mode, IconData icon, String label) {
    return PopupMenuItem<ChannelViewMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Colors.white)),
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
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: channels.length,
      itemBuilder: (ctx, i) => ChannelCard(channel: channels[i]),
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
      separatorBuilder: (_, __) => const Divider(
          height: 1, color: Colors.white10),
      itemBuilder: (ctx, i) => _ChannelListItem(channel: channels[i]),
    );
  }
}

class _PosterView extends StatelessWidget {
  final List<Channel> channels;
  const _PosterView({required this.channels});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: channels.length,
      itemBuilder: (ctx, i) =>
          ChannelCard(channel: channels[i], posterMode: true),
    );
  }
}

class _ChannelListItem extends ConsumerWidget {
  final Channel channel;
  const _ChannelListItem({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: channel.logoUrl != null
            ? Image.network(
                channel.logoUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.tv,
                    color: Colors.white54, size: 44),
              )
            : const Icon(Icons.tv, color: Colors.white54, size: 44),
      ),
      title: Text(
        channel.name,
        style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.w600),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        channel.category,
        style: const TextStyle(
            fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
        textDirection: TextDirection.rtl,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!channel.isAvailable)
            const Icon(Icons.block, color: Colors.red, size: 16),
          IconButton(
            icon: Icon(
              channel.isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  channel.isFavorite ? Colors.red : Colors.white54,
              size: 20,
            ),
            onPressed: () => ref
                .read(channelsNotifierProvider.notifier)
                .toggleFavorite(channel.id, !channel.isFavorite),
          ),
        ],
      ),
      onTap: () => context.push(
        AppConstants.routePlayer,
        extra: {
          'channelId': channel.id,
          'streamUrl': channel.currentStreamUrl ?? '',
          'channelName': channel.name,
          'channelLogo': channel.logoUrl,
        },
      ),
    );
  }
}
