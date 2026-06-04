import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/constants/app_constants.dart';
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

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {

  late AnimationController _panelCtrl;
  late Animation<Offset> _panelSlide;
  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
    _panelSlide = Tween<Offset>(
      begin: const Offset(-1.05, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannel());
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    ref.read(playerProvider.notifier).stopAndReset();
    super.dispose();
  }

  Future<void> _loadChannel({Channel? channel}) async {
    Channel? ch = channel;
    if (ch == null) {
      final channelsAsync = ref.read(channelsProvider);
      channelsAsync.whenData((channels) {
        ch = channels.where((c) => c.id == widget.channelId).firstOrNull;
      });
      ch ??= Channel(
        id: widget.channelId.isNotEmpty ? widget.channelId : 'temp',
        name: widget.channelName,
        logoUrl: widget.channelLogo,
        category: '',
        streamUrls: widget.streamUrl.isNotEmpty ? [widget.streamUrl] : [],
      );
    }
    await ref.read(playerProvider.notifier).playChannel(ch!);
  }

  void _goBack() {
    ref.read(playerProvider.notifier).stopAndReset();
    if (context.canPop()) context.pop();
    else context.go('/home');
  }

  void _handleBack() {
    if (_panelOpen) { _closePanel(); return; }
    final s = ref.read(playerProvider);
    if (s.isFullscreen) {
      ref.read(playerProvider.notifier).toggleFullscreen();
    } else {
      _goBack();
    }
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    if (_panelOpen) _panelCtrl.forward();
    else _panelCtrl.reverse();
  }

  void _closePanel() {
    setState(() => _panelOpen = false);
    _panelCtrl.reverse();
  }

  void _switchChannel(Channel ch) {
    _closePanel();
    _loadChannel(channel: ch);
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(playerProvider);
    final size = MediaQuery.of(context).size;
    final panelWidth = size.width * 0.62;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) _handleBack(); },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_panelOpen) { _closePanel(); return; }
            ref.read(playerProvider.notifier).toggleControls();
          },
          child: Stack(children: [

            // ── Video (media_kit) ─────────────────────────────────
            Positioned.fill(
              child: ps.videoController != null
                  ? Video(
                      controller: ps.videoController!,
                      controls: NoVideoControls,
                      fill: Colors.black,
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Back button + title ───────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(children: [
                    _RoundBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: _handleBack),
                    if (ps.showControls) ...[
                      const SizedBox(width: 10),
                      if (widget.channelLogo != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: widget.channelLogo!,
                            width: 30, height: 30, fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const SizedBox.shrink()),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ps.currentChannel?.name ?? widget.channelName,
                          style: const TextStyle(
                            fontFamily: 'Cairo', color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700,
                            shadows: [Shadow(blurRadius: 12, color: Colors.black)]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ),
              ),
            ),

            // ── Controls ──────────────────────────────────────────
            if (ps.showControls &&
                ps.status != PlayerStatus.loading &&
                ps.status != PlayerStatus.switching &&
                ps.status != PlayerStatus.error)
              Positioned.fill(
                child: _ControlsOverlay(state: ps, onChannelList: _togglePanel),
              ),

            // ── Loading ───────────────────────────────────────────
            if (ps.status == PlayerStatus.loading || ps.status == PlayerStatus.switching)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(
                    width: 48, height: 48,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E6CF5), strokeWidth: 2.5)),
                  const SizedBox(height: 16),
                  Text(
                    ps.status == PlayerStatus.switching
                        ? 'تغيير المصدر...' : 'جاري التحميل...',
                    style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white70, fontSize: 13)),
                ]),
              ),

            // ── Error ─────────────────────────────────────────────
            if (ps.status == PlayerStatus.error)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(28),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1526).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1C2540)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.wifi_off_rounded,
                        color: Colors.redAccent, size: 32)),
                    const SizedBox(height: 14),
                    Text(ps.errorMessage ?? 'تعذّر تشغيل القناة',
                      style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _ActionBtn(
                        label: 'إعادة المحاولة',
                        icon: Icons.refresh_rounded,
                        onTap: () => ref.read(playerProvider.notifier).retry(),
                        primary: true),
                      const SizedBox(width: 10),
                      _ActionBtn(
                        label: 'رجوع',
                        icon: Icons.arrow_back_rounded,
                        onTap: _goBack,
                        primary: false),
                    ]),
                  ]),
                ),
              ),

            // ── Channel Panel ─────────────────────────────────────
            if (_panelOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePanel,
                  child: Container(color: Colors.black54)),
              ),

            SlideTransition(
              position: _panelSlide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: panelWidth,
                  child: _ChannelPanel(
                    currentChannelId: ps.currentChannel?.id ?? widget.channelId,
                    currentCategory: ps.currentChannel?.category ?? '',
                    onSelect: _switchChannel,
                    onClose: _closePanel,
                  ),
                ),
              ),
            ),

          ]),
        ),
      ),
    );
  }
}

// ─── Controls ────────────────────────────────────────────────────
class _ControlsOverlay extends ConsumerWidget {
  final PlayerState state;
  final VoidCallback onChannelList;
  const _ControlsOverlay({required this.state, required this.onChannelList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = state.status == PlayerStatus.playing;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
          stops: [0, 0.35, 0.65, 1],
        ),
      ),
      child: Column(children: [
        const SizedBox(height: 70),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CtrlBtn(Icons.replay_10_rounded, 34,
            () => ref.read(playerProvider.notifier).seekBy(const Duration(seconds: -10))),
          const SizedBox(width: 36),
          _CtrlBtn(
            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, 70,
            () => ref.read(playerProvider.notifier).togglePlayPause()),
          const SizedBox(width: 36),
          _CtrlBtn(Icons.forward_10_rounded, 34,
            () => ref.read(playerProvider.notifier).seekBy(const Duration(seconds: 10))),
        ]),
        const Spacer(),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              Text(_fmt(state.position),
                style: const TextStyle(
                  fontFamily: 'Cairo', color: Colors.white70, fontSize: 11)),
              const Spacer(),
              GestureDetector(
                onTap: onChannelList,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6CF5).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E6CF5).withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.format_list_bulleted_rounded,
                      color: Color(0xFF4D8EFF), size: 14),
                    SizedBox(width: 4),
                    Text('القنوات', style: TextStyle(
                      fontFamily: 'Cairo', color: Color(0xFF4D8EFF), fontSize: 11)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              _CtrlBtn(
                state.isFullscreen
                    ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                22,
                () => ref.read(playerProvider.notifier).toggleFullscreen()),
            ]),
          ),
        ),
      ]),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }
}

// ─── Channel Panel ────────────────────────────────────────────────
class _ChannelPanel extends ConsumerStatefulWidget {
  final String currentChannelId;
  final String currentCategory;
  final void Function(Channel) onSelect;
  final VoidCallback onClose;
  const _ChannelPanel({
    required this.currentChannelId,
    required this.currentCategory,
    required this.onSelect,
    required this.onClose,
  });

  @override
  ConsumerState<_ChannelPanel> createState() => _ChannelPanelState();
}

class _ChannelPanelState extends ConsumerState<_ChannelPanel> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF090D18).withOpacity(0.97),
          border: const Border(right: BorderSide(color: Color(0xFF1C2540))),
        ),
        child: Column(children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                const Icon(Icons.format_list_bulleted_rounded,
                  color: Color(0xFF4D8EFF), size: 16),
                const SizedBox(width: 8),
                const Text('القنوات', style: TextStyle(
                  fontFamily: 'Cairo', color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF161E36),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1C2540)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'ابحث...',
                  hintStyle: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 11),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4A5568), size: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const Divider(color: Color(0xFF1C2540), height: 1),
          Expanded(
            child: channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(
                color: Color(0xFF1E6CF5), strokeWidth: 2)),
              error: (_, __) => const Center(child: Text('خطأ',
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568)))),
              data: (all) {
                var channels = widget.currentCategory.isNotEmpty
                    ? all.where((c) => c.category == widget.currentCategory).toList()
                    : all;
                if (_search.isNotEmpty) {
                  channels = channels
                      .where((c) => c.name.toLowerCase().contains(_search))
                      .toList();
                }
                if (channels.isEmpty) {
                  return const Center(child: Text('لا توجد قنوات',
                    style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF4A5568), fontSize: 12)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: channels.length,
                  itemBuilder: (ctx, i) {
                    final ch = channels[i];
                    final isCurrent = ch.id == widget.currentChannelId;
                    return GestureDetector(
                      onTap: isCurrent ? null : () => widget.onSelect(ch),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF1E6CF5).withOpacity(0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(color: const Color(0xFF1E6CF5).withOpacity(0.4)) : null,
                        ),
                        child: Row(children: [
                          SizedBox(
                            width: 28, height: 28,
                            child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ch.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.live_tv_rounded,
                                      color: Color(0xFF1C2540), size: 16))
                                : const Icon(Icons.live_tv_rounded,
                                    color: Color(0xFF1C2540), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ch.name,
                              style: TextStyle(
                                fontFamily: 'Cairo', fontSize: 11,
                                color: isCurrent ? Colors.white : const Color(0xFFB0BEC5),
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (isCurrent)
                            const Icon(Icons.play_arrow_rounded,
                              color: Color(0xFF4D8EFF), size: 14),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────
class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(9),
        child: Icon(icon, color: Colors.white, size: 20))),
  );
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _CtrlBtn(this.icon, this.size, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: Colors.white, size: size,
      shadows: const [Shadow(blurRadius: 12, color: Colors.black)]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const _ActionBtn({required this.label, required this.icon,
    required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: primary
            ? const LinearGradient(colors: [Color(0xFF1E6CF5), Color(0xFF0D47C8)])
            : null,
        color: primary ? null : const Color(0xFF1C2540),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontFamily: 'Cairo', color: Colors.white, fontSize: 12)),
      ]),
    ),
  );
}
