import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:video_player/video_player.dart';
  import 'package:cached_network_image/cached_network_image.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannel());
    }

    @override
    void dispose() {
      ref.read(playerProvider.notifier).stopAndReset();
      super.dispose();
    }

    Future<void> _loadChannel() async {
      final channelsAsync = ref.read(channelsProvider);
      Channel? channel;
      channelsAsync.whenData((channels) {
        channel = channels.where((c) => c.id == widget.channelId).firstOrNull;
      });

      channel ??= Channel(
        id: widget.channelId.isNotEmpty ? widget.channelId : 'temp',
        name: widget.channelName,
        logoUrl: widget.channelLogo,
        category: '',
        streamUrls: widget.streamUrl.isNotEmpty ? [widget.streamUrl] : [],
      );

      await ref.read(playerProvider.notifier).playChannel(channel!);
    }

    void _goBack() {
      ref.read(playerProvider.notifier).stopAndReset();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    void _handleBack() {
      final playerState = ref.read(playerProvider);
      if (playerState.isFullscreen) {
        ref.read(playerProvider.notifier).toggleFullscreen();
      } else {
        _goBack();
      }
    }

    @override
    Widget build(BuildContext context) {
      final playerState = ref.watch(playerProvider);

      // Flutter 3.22: use onPopInvoked (onPopInvokedWithResult needs Flutter 3.24+)
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(playerProvider.notifier).toggleControls(),
            child: Stack(
              children: [
                // ─── الفيديو ──────────────────────────────────────
                Positioned.fill(child: _VideoView(playerState: playerState)),

                // ─── زر الرجوع — يظهر دائماً ─────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _handleBack,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                          if (playerState.showControls) ...[
                            const SizedBox(width: 8),
                            if (widget.channelLogo != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: widget.channelLogo!,
                                  width: 32, height: 32, fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const SizedBox.shrink()),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(widget.channelName,
                                style: const TextStyle(
                                  fontFamily: 'Cairo', color: Colors.white, fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── أدوات التحكم (عند اللمس) ────────────────────
                if (playerState.showControls &&
                    playerState.status != PlayerStatus.loading &&
                    playerState.status != PlayerStatus.error)
                  Positioned.fill(
                    child: _ControlsOverlay(playerState: playerState),
                  ),

                // ─── التحميل ─────────────────────────────────────
                if (playerState.status == PlayerStatus.loading ||
                    playerState.status == PlayerStatus.switching)
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF1565C0), strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(
                        playerState.status == PlayerStatus.switching
                            ? 'جاري تجربة مصدر آخر...'
                            : 'جاري التحميل...',
                        style: const TextStyle(
                          fontFamily: 'Cairo', color: Colors.white70, fontSize: 14)),
                    ]),
                  ),

                // ─── خطأ ─────────────────────────────────────────
                if (playerState.status == PlayerStatus.error)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_rounded,
                          color: Colors.redAccent, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          playerState.errorMessage ?? 'تعذّر تشغيل القناة',
                          style: const TextStyle(
                            fontFamily: 'Cairo', color: Colors.white, fontSize: 15),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          ElevatedButton.icon(
                            onPressed: _loadChannel,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Cairo')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white)),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30)),
                            child: const Text('رجوع',
                              style: TextStyle(fontFamily: 'Cairo'))),
                        ]),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ─── عرض الفيديو ──────────────────────────────────────────────────
  class _VideoView extends StatelessWidget {
    final PlayerState playerState;
    const _VideoView({required this.playerState});

    @override
    Widget build(BuildContext context) {
      final ctrl = playerState.controller;
      if (ctrl == null || !ctrl.value.isInitialized) {
        return const SizedBox.shrink();
      }
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      );
    }
  }

  // ─── أدوات التحكم ─────────────────────────────────────────────────
  class _ControlsOverlay extends ConsumerWidget {
    final PlayerState playerState;
    const _ControlsOverlay({required this.playerState});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final isPlaying = playerState.status == PlayerStatus.playing;

      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
            stops: [0, 0.3, 0.7, 1],
          ),
        ),
        child: Column(children: [
          const SizedBox(height: 60),
          const Spacer(),
          // أزرار التشغيل
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CtrlBtn(
              icon: Icons.replay_10_rounded, size: 36,
              onTap: () => ref.read(playerProvider.notifier)
                  .seekBy(const Duration(seconds: -10))),
            const SizedBox(width: 32),
            _CtrlBtn(
              icon: isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 64,
              onTap: () => ref.read(playerProvider.notifier).togglePlayPause()),
            const SizedBox(width: 32),
            _CtrlBtn(
              icon: Icons.forward_10_rounded, size: 36,
              onTap: () => ref.read(playerProvider.notifier)
                  .seekBy(const Duration(seconds: 10))),
          ]),
          const Spacer(),
          // الشريط السفلي
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Text(_fmt(playerState.position),
                  style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
                const Spacer(),
                _CtrlBtn(
                  icon: playerState.isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  size: 26,
                  onTap: () => ref.read(playerProvider.notifier).toggleFullscreen()),
              ]),
            ),
          ),
        ]),
      );
    }

    String _fmt(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }
  }

  class _CtrlBtn extends StatelessWidget {
    final IconData icon;
    final double size;
    final VoidCallback onTap;
    const _CtrlBtn({required this.icon, required this.size, required this.onTap});

    @override
    Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size,
        shadows: const [Shadow(blurRadius: 10, color: Colors.black)]),
    );
  }
  