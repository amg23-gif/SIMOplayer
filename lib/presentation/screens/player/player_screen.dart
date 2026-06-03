import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../domain/entities/channel.dart';
import '../../providers/player_provider.dart';
import '../../providers/channels_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String streamUrl;
  final String channelName;
  final String? channelLogo;

  const PlayerScreen({
    super.key,
    required this.channelId,
    required this.streamUrl,
    required this.channelName,
    this.channelLogo,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChannel();
    });
  }

  Future<void> _loadChannel() async {
    final channelsAsync = ref.read(channelsProvider);
    channelsAsync.whenData((channels) {
      final channel = channels.where((c) => c.id == widget.channelId).firstOrNull;
      if (channel != null) {
        ref.read(playerProvider.notifier).playChannel(channel);
      } else {
        // تحميل من URL مباشرة إذا لم توجد القناة
        final tempChannel = Channel(
          id: widget.channelId,
          name: widget.channelName,
          logoUrl: widget.channelLogo,
          category: '',
          streamUrls: [widget.streamUrl],
        );
        ref.read(playerProvider.notifier).playChannel(tempChannel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isFullscreen = playerState.isFullscreen;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => ref.read(playerProvider.notifier).showControlsTemporarily(),
        child: Stack(
          children: [
            // عرض الفيديو
            Center(
              child: _VideoView(playerState: playerState),
            ),

            // أدوات التحكم
            if (playerState.showControls)
              _PlayerControls(
                playerState: playerState,
                channelName: widget.channelName,
                channelLogo: widget.channelLogo,
                onBack: () {
                  if (isFullscreen) {
                    ref.read(playerProvider.notifier).toggleFullscreen();
                  } else {
                    context.pop();
                  }
                },
              ),

            // مؤشر التبديل التلقائي للمصدر
            if (playerState.status == PlayerStatus.switching)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'جاري تجربة المصدر التالي...',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // رسالة خطأ
            if (playerState.status == PlayerStatus.error)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      playerState.errorMessage ?? 'خطأ في تحميل البث',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadChannel,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black),
                      child: const Text('إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),

            // مؤشر التحميل
            if (playerState.status == PlayerStatus.loading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    SizedBox(height: 12),
                    Text(
                      'جاري التحميل...',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white54,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoView extends StatelessWidget {
  final PlayerState playerState;
  const _VideoView({required this.playerState});

  @override
  Widget build(BuildContext context) {
    final ctrl = playerState.controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: ctrl.value.aspectRatio,
      child: VideoPlayer(ctrl),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final PlayerState playerState;
  final String channelName;
  final String? channelLogo;
  final VoidCallback onBack;

  const _PlayerControls({
    required this.playerState,
    required this.channelName,
    this.channelLogo,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent, Colors.black87],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 8),
                    if (channelLogo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          channelLogo!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.tv,
                              color: Colors.white54,
                              size: 32),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      channelName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // زر PiP
                    IconButton(
                      icon: const Icon(Icons.picture_in_picture_alt,
                          color: Colors.white),
                      onPressed: () {},
                      tooltip: 'صورة داخل صورة',
                    ),
                    // زر التسجيل
                    IconButton(
                      icon: Icon(
                        playerState.isRecording
                            ? Icons.stop_circle
                            : Icons.fiber_manual_record,
                        color: playerState.isRecording
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () {},
                      tooltip: 'تسجيل',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // أزرار التحكم المركزية
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ترجيع 10 ثوانٍ
                  IconButton(
                    icon: const Icon(Icons.replay_10,
                        color: Colors.white, size: 36),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .seekBy(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 24),
                  // زر تشغيل / إيقاف
                  GestureDetector(
                    onTap: () =>
                        ref.read(playerProvider.notifier).togglePlayPause(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: Icon(
                        playerState.status == PlayerStatus.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // تقديم 10 ثوانٍ
                  IconButton(
                    icon: const Icon(Icons.forward_10,
                        color: Colors.white, size: 36),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .seekBy(const Duration(seconds: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // شريط التقدم (للـ TimeShift)
              if (playerState.duration != null &&
                  playerState.duration != Duration.zero)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00E5FF),
                      thumbColor: const Color(0xFF00E5FF),
                      inactiveTrackColor: Colors.white24,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: playerState.position.inSeconds.toDouble(),
                      min: 0,
                      max: playerState.duration!.inSeconds.toDouble(),
                      onChanged: (val) => ref
                          .read(playerProvider.notifier)
                          .seekBy(Duration(
                              seconds: val.toInt() -
                                  playerState.position.inSeconds)),
                    ),
                  ),
                ),
              // الشريط السفلي
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(playerState.position),
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white70,
                          fontSize: 12),
                    ),
                    const Spacer(),
                    // ملء الشاشة
                    IconButton(
                      icon: Icon(
                        playerState.isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => ref
                          .read(playerProvider.notifier)
                          .toggleFullscreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
