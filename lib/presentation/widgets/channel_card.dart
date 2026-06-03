import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/channel.dart';
import '../providers/channels_provider.dart';

// بطاقة القناة - تدعم عدة أوضاع عرض
class ChannelCard extends ConsumerWidget {
  final Channel channel;
  final bool compact;
  final bool posterMode;

  const ChannelCard({
    super.key,
    required this.channel,
    this.compact = false,
    this.posterMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posterMode) return _buildPosterCard(context, ref);
    if (compact) return _buildCompactCard(context, ref);
    return _buildGridCard(context, ref);
  }

  // وضع الشبكة العادي
  Widget _buildGridCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openPlayer(context),
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: channel.isFavorite
                ? Colors.red.withOpacity(0.5)
                : Colors.white10,
          ),
        ),
        child: Stack(
          children: [
            // شعار القناة
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _ChannelLogo(logoUrl: channel.logoUrl, size: 64),
              ),
            ),
            // اسم القناة
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Text(
                  channel.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            // مؤشر عدم التوفر
            if (!channel.isAvailable)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'غير متاح',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            // أيقونة المفضلة
            if (channel.isFavorite)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.favorite, color: Colors.red, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  // وضع مدمج (أصغر)
  Widget _buildCompactCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openPlayer(context),
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: _ChannelLogo(logoUrl: channel.logoUrl, size: 50),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              channel.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.white70,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  // وضع البوستر (Netflix-style)
  Widget _buildPosterCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openPlayer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // صورة القناة (poster)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: channel.logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: channel.logoUrl!,
                    fit: BoxFit.cover,
                    color: Colors.black38,
                    colorBlendMode: BlendMode.darken,
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Center(
                        child: Icon(Icons.tv, color: Colors.white24, size: 40),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tv, color: Colors.white24, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            channel.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.tv, color: Colors.white24, size: 48),
                    ),
                  ),
          ),
          // اسم القناة في الأسفل
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                channel.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    if (channel.currentStreamUrl == null) return;
    context.push(
      AppConstants.routePlayer,
      extra: {
        'channelId': channel.id,
        'streamUrl': channel.currentStreamUrl!,
        'channelName': channel.name,
        'channelLogo': channel.logoUrl,
      },
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              channel.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: channel.isFavorite ? Colors.red : Colors.white54,
            ),
            title: Text(
              channel.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
            onTap: () {
              ref.read(channelsNotifierProvider.notifier)
                  .toggleFavorite(channel.id, !channel.isFavorite);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tv, color: Colors.white54),
            title: const Text('دليل البرامج',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              context.push('/home/epg?channelId=${channel.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle, color: Color(0xFF00E5FF)),
            title: const Text('تشغيل',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _openPlayer(context);
            },
          ),
        ],
      ),
    );
  }
}

// ودجت شعار القناة مع التخزين المؤقت
class _ChannelLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _ChannelLogo({this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return Icon(Icons.tv, color: Colors.white24, size: size * 0.7);
    }

    return CachedNetworkImage(
      imageUrl: logoUrl!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white24,
          ),
        ),
      ),
      errorWidget: (_, __, ___) =>
          Icon(Icons.tv, color: Colors.white24, size: size * 0.7),
    );
  }
}
