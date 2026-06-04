import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../domain/entities/channel.dart';

enum PlayerStatus { idle, loading, playing, paused, error, switching }

class PlayerState {
  final Channel? currentChannel;
  final Player? player;
  final VideoController? videoController;
  final PlayerStatus status;
  final String? errorMessage;
  final bool isFullscreen;
  final bool showControls;
  final Duration position;
  final int currentSourceIndex;

  const PlayerState({
    this.currentChannel,
    this.player,
    this.videoController,
    this.status = PlayerStatus.idle,
    this.errorMessage,
    this.isFullscreen = false,
    this.showControls = true,
    this.position = Duration.zero,
    this.currentSourceIndex = 0,
  });

  PlayerState copyWith({
    Channel? currentChannel,
    Player? player,
    VideoController? videoController,
    PlayerStatus? status,
    String? errorMessage,
    bool? isFullscreen,
    bool? showControls,
    Duration? position,
    int? currentSourceIndex,
    bool clearError = false,
  }) {
    return PlayerState(
      currentChannel: currentChannel ?? this.currentChannel,
      player: player ?? this.player,
      videoController: videoController ?? this.videoController,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isFullscreen: isFullscreen ?? this.isFullscreen,
      showControls: showControls ?? this.showControls,
      position: position ?? this.position,
      currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  Player? _player;
  VideoController? _videoController;
  Timer? _positionTimer;
  Timer? _controlsTimer;
  StreamSubscription? _errorSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _playingSub;

  @override
  PlayerState build() => const PlayerState();

  // ─── HTTP Headers لروابط IPTV ──────────────────────────────────
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 11; Mobile) VLC/3.6.0',
    'Connection': 'keep-alive',
    'Accept': '*/*',
  };

  // ─── تشغيل قناة ────────────────────────────────────────────────
  Future<void> playChannel(Channel channel) async {
    // إنشاء player جديد إذا لزم
    if (_player == null) {
      _player = Player();
      _videoController = VideoController(_player!);
      _subscribeToPlayerEvents();
    }

    state = state.copyWith(
      currentChannel: channel,
      player: _player,
      videoController: _videoController,
      status: PlayerStatus.loading,
      currentSourceIndex: 0,
      clearError: true,
    );

    await _loadSource(channel, 0);
  }

  void _subscribeToPlayerEvents() {
    _errorSub?.cancel();
    _playingSub?.cancel();

    _playingSub = _player!.stream.playing.listen((playing) {
      if (state.status == PlayerStatus.loading && playing) {
        state = state.copyWith(status: PlayerStatus.playing, clearError: true);
        _startPositionTimer();
        showControlsTemporarily();
      } else if (!playing && state.status == PlayerStatus.playing) {
        state = state.copyWith(status: PlayerStatus.paused);
      }
    });

    _errorSub = _player!.stream.error.listen((error) {
      if (error.isNotEmpty) {
        final ch = state.currentChannel;
        if (ch != null && state.currentSourceIndex + 1 < ch.streamUrls.length) {
          _tryNextSource(ch, state.currentSourceIndex);
        } else {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: 'تعذّر تشغيل القناة — تحقق من الرابط',
          );
        }
      }
    });
  }

  Future<void> _loadSource(Channel channel, int sourceIndex) async {
    if (sourceIndex >= channel.streamUrls.length) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'لا توجد روابط متاحة لهذه القناة',
      );
      return;
    }

    final url = channel.streamUrls[sourceIndex].trim();
    if (url.isEmpty) {
      await _tryNextSource(channel, sourceIndex);
      return;
    }

    state = state.copyWith(
      status: PlayerStatus.loading,
      currentSourceIndex: sourceIndex,
    );

    try {
      // media_kit يدعم HLS/MPEG-TS/RTSP تلقائياً مثل VLC
      await _player!.open(
        Media(url, httpHeaders: _headers),
        play: true,
      );

      // انتظار بدء التشغيل أو الخطأ (30 ثانية)
      bool resolved = false;
      await Future.any([
        _player!.stream.playing.firstWhere((p) => p).then((_) {
          resolved = true;
        }),
        _player!.stream.error.firstWhere((e) => e.isNotEmpty).then((_) {
          resolved = true;
        }),
        Future.delayed(const Duration(seconds: 30)),
      ]);

      if (!resolved) {
        // Timeout
        if (channel.streamUrls.length > sourceIndex + 1) {
          await _tryNextSource(channel, sourceIndex);
        } else {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: 'انتهت مهلة التحميل — السيرفر لا يستجيب',
          );
        }
      }
    } catch (e) {
      if (channel.streamUrls.length > sourceIndex + 1) {
        await _tryNextSource(channel, sourceIndex);
      } else {
        state = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: 'تعذّر تشغيل القناة — ${e.toString().split(":").last.trim()}',
        );
      }
    }
  }

  Future<void> _tryNextSource(Channel channel, int currentIndex) async {
    final next = currentIndex + 1;
    if (next < channel.streamUrls.length) {
      state = state.copyWith(status: PlayerStatus.switching);
      await _loadSource(channel, next);
    } else {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'لا يمكن تشغيل هذه القناة — جرب مصدراً آخر',
      );
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_player != null) {
        state = state.copyWith(position: _player!.state.position);
      }
    });
  }

  // ─── تشغيل / إيقاف ───────────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (_player == null) return;
    await _player!.playOrPause();
  }

  // ─── تقديم / ترجيع ───────────────────────────────────────────────
  Future<void> seekBy(Duration offset) async {
    if (_player == null) return;
    final pos = _player!.state.position + offset;
    await _player!.seek(pos);
  }

  // ─── إعادة المحاولة ──────────────────────────────────────────────
  Future<void> retry() async {
    final ch = state.currentChannel;
    if (ch != null) await playChannel(ch);
  }

  // ─── ملء الشاشة ──────────────────────────────────────────────────
  Future<void> toggleFullscreen() async {
    if (!state.isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _resetOrientation();
    }
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  Future<void> _resetOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (state.status == PlayerStatus.playing) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  void toggleControls() {
    if (state.showControls) {
      _controlsTimer?.cancel();
      state = state.copyWith(showControls: false);
    } else {
      showControlsTemporarily();
    }
  }

  // ─── تنظيف ───────────────────────────────────────────────────────
  Future<void> stopAndReset() async {
    _positionTimer?.cancel();
    _controlsTimer?.cancel();
    _errorSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    await _resetOrientation();
    state = const PlayerState();
  }

  @override
  void dispose() {
    stopAndReset();
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
