import 'dart:async';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:video_player/video_player.dart';
  import '../../domain/entities/channel.dart';
  import '../../core/constants/app_constants.dart';

  enum PlayerStatus { idle, loading, playing, paused, error, switching }

  class PlayerState {
    final Channel? currentChannel;
    final VideoPlayerController? controller;
    final PlayerStatus status;
    final String? errorMessage;
    final bool isFullscreen;
    final bool isPipActive;
    final bool isRecording;
    final Duration position;
    final Duration? duration;
    final double speed;
    final bool showControls;
    final int currentSourceIndex;

    const PlayerState({
      this.currentChannel,
      this.controller,
      this.status = PlayerStatus.idle,
      this.errorMessage,
      this.isFullscreen = false,
      this.isPipActive = false,
      this.isRecording = false,
      this.position = Duration.zero,
      this.duration,
      this.speed = 1.0,
      this.showControls = true,
      this.currentSourceIndex = 0,
    });

    PlayerState copyWith({
      Channel? currentChannel,
      VideoPlayerController? controller,
      PlayerStatus? status,
      String? errorMessage,
      bool? isFullscreen,
      bool? isPipActive,
      bool? isRecording,
      Duration? position,
      Duration? duration,
      double? speed,
      bool? showControls,
      int? currentSourceIndex,
      bool clearController = false,
      bool clearError = false,
    }) {
      return PlayerState(
        currentChannel: currentChannel ?? this.currentChannel,
        controller: clearController ? null : (controller ?? this.controller),
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isFullscreen: isFullscreen ?? this.isFullscreen,
        isPipActive: isPipActive ?? this.isPipActive,
        isRecording: isRecording ?? this.isRecording,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        speed: speed ?? this.speed,
        showControls: showControls ?? this.showControls,
        currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
      );
    }
  }

  class PlayerNotifier extends Notifier<PlayerState> {
    Timer? _positionTimer;
    Timer? _controlsTimer;

    @override
    PlayerState build() => const PlayerState();

    // ─── تشغيل قناة ────────────────────────────────────────────────
    Future<void> playChannel(Channel channel) async {
      await _disposeController();

      state = state.copyWith(
        currentChannel: channel,
        status: PlayerStatus.loading,
        currentSourceIndex: 0,
        clearError: true,
        clearController: true,
      );

      await _loadSource(channel, 0);
    }

    // ─── تحميل مصدر بعينه ──────────────────────────────────────────
    Future<void> _loadSource(Channel channel, int sourceIndex) async {
      if (sourceIndex >= channel.streamUrls.length) {
        state = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: 'فشل تحميل القناة — تحقق من الرابط أو اتصالك',
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
        clearController: true,
      );

      VideoPlayerController? ctrl;
      try {
        ctrl = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );

        // ⚠️ FIX: استخدام timeout بدل مؤقت منفصل لتفادي race condition
        // روابط IPTV المباشرة قد تحتاج 10-30 ثانية للتحميل
        await ctrl.initialize().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('انتهت مهلة التحميل', const Duration(seconds: 30));
          },
        );

        ctrl.addListener(_onPlayerValueChanged);
        await ctrl.play();

        state = state.copyWith(
          controller: ctrl,
          status: PlayerStatus.playing,
          duration: ctrl.value.duration,
          clearError: true,
        );

        _startPositionTimer();
        showControlsTemporarily();
      } on TimeoutException {
        await ctrl?.dispose();
        // إذا كان هناك مصدر آخر جربه، وإلا أظهر خطأ واضح
        if (channel.streamUrls.length > 1 && sourceIndex + 1 < channel.streamUrls.length) {
          await _tryNextSource(channel, sourceIndex);
        } else {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: 'البث بطيء أو غير متاح — جرب مرة أخرى',
            clearController: true,
          );
        }
      } catch (e) {
        await ctrl?.dispose();
        if (channel.streamUrls.length > 1 && sourceIndex + 1 < channel.streamUrls.length) {
          await _tryNextSource(channel, sourceIndex);
        } else {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: 'تعذّر تشغيل القناة — تحقق من الرابط',
            clearController: true,
          );
        }
      }
    }

    // ─── تجربة المصدر التالي ────────────────────────────────────────
    Future<void> _tryNextSource(Channel channel, int currentIndex) async {
      final nextIndex = currentIndex + 1;
      if (nextIndex < channel.streamUrls.length) {
        state = state.copyWith(
          status: PlayerStatus.switching,
          errorMessage: 'جاري تجربة مصدر آخر...',
        );
        await _loadSource(channel, nextIndex);
      } else {
        state = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: 'لا يمكن تشغيل هذه القناة — تحقق من رابط M3U',
          clearController: true,
        );
      }
    }

    void _onPlayerValueChanged() {
      final ctrl = state.controller;
      if (ctrl == null) return;
      if (ctrl.value.hasError && state.status == PlayerStatus.playing) {
        final ch = state.currentChannel;
        if (ch != null) {
          _tryNextSource(ch, state.currentSourceIndex);
        }
      }
    }

    void _startPositionTimer() {
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final ctrl = state.controller;
        if (ctrl != null && ctrl.value.isInitialized) {
          state = state.copyWith(position: ctrl.value.position);
        }
      });
    }

    // ─── تشغيل / إيقاف مؤقت ─────────────────────────────────────────
    Future<void> togglePlayPause() async {
      final ctrl = state.controller;
      if (ctrl == null) return;
      if (ctrl.value.isPlaying) {
        await ctrl.pause();
        state = state.copyWith(status: PlayerStatus.paused);
      } else {
        await ctrl.play();
        state = state.copyWith(status: PlayerStatus.playing);
      }
    }

    // ─── تقديم / ترجيع ───────────────────────────────────────────────
    Future<void> seekBy(Duration offset) async {
      final ctrl = state.controller;
      if (ctrl == null) return;
      final newPos = ctrl.value.position + offset;
      await ctrl.seekTo(newPos);
    }

    // ─── السرعة ──────────────────────────────────────────────────────
    Future<void> setSpeed(double speed) async {
      await state.controller?.setPlaybackSpeed(speed);
      state = state.copyWith(speed: speed);
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

    // ─── إعادة ضبط الاتجاه (مهم عند الخروج) ──────────────────────────
    Future<void> _resetOrientation() async {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // ─── التحكم في ظهور أدوات التحكم ─────────────────────────────────
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

    // ─── تنظيف وإعادة ضبط عند الخروج من المشغل ─────────────────────
    Future<void> stopAndReset() async {
      await _disposeController();
      await _resetOrientation();
      state = const PlayerState();
    }

    Future<void> _disposeController() async {
      _positionTimer?.cancel();
      _controlsTimer?.cancel();
      final ctrl = state.controller;
      if (ctrl != null) {
        ctrl.removeListener(_onPlayerValueChanged);
        await ctrl.dispose();
      }
    }

    @override
    void dispose() {
      _disposeController();
      _resetOrientation();
    }
  }

  final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
    PlayerNotifier.new,
  );
  