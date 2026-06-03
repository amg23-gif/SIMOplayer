import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/channel.dart';
import '../../core/constants/app_constants.dart';

// حالة المشغل
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
  }) {
    return PlayerState(
      currentChannel: currentChannel ?? this.currentChannel,
      controller: controller ?? this.controller,
      status: status ?? this.status,
      errorMessage: errorMessage,
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
  Timer? _sourceRetryTimer;

  @override
  PlayerState build() => const PlayerState();

  // تشغيل قناة
  Future<void> playChannel(Channel channel) async {
    // إيقاف المشغل الحالي
    await _dispose();

    state = state.copyWith(
      currentChannel: channel,
      status: PlayerStatus.loading,
      currentSourceIndex: 0,
      errorMessage: null,
    );

    await _loadSource(channel, 0);
  }

  // تحميل مصدر محدد
  Future<void> _loadSource(Channel channel, int sourceIndex) async {
    if (sourceIndex >= channel.streamUrls.length) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'لا توجد مصادر متاحة',
      );
      return;
    }

    final url = channel.streamUrls[sourceIndex];
    state = state.copyWith(
      status: PlayerStatus.loading,
      currentSourceIndex: sourceIndex,
    );

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // جدولة التبديل التلقائي إذا فشل التحميل
      _sourceRetryTimer = Timer(
        const Duration(seconds: AppConstants.sourceRetryDelaySeconds),
        () => _tryNextSource(channel, sourceIndex),
      );

      await controller.initialize();

      // إلغاء مؤقت التبديل لأن التحميل نجح
      _sourceRetryTimer?.cancel();

      controller.addListener(_onPlayerValueChanged);
      await controller.play();

      state = state.copyWith(
        controller: controller,
        status: PlayerStatus.playing,
        duration: controller.value.duration,
      );

      _startPositionTimer();
    } catch (e) {
      _sourceRetryTimer?.cancel();
      await _tryNextSource(channel, sourceIndex);
    }
  }

  // تجربة المصدر التالي
  Future<void> _tryNextSource(Channel channel, int currentIndex) async {
    final nextIndex = currentIndex + 1;
    if (nextIndex < channel.streamUrls.length) {
      state = state.copyWith(
        status: PlayerStatus.switching,
        errorMessage: 'جاري تجربة المصدر التالي...',
      );
      await _loadSource(channel, nextIndex);
    } else {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'فشل تحميل جميع المصادر',
      );
    }
  }

  void _onPlayerValueChanged() {
    final ctrl = state.controller;
    if (ctrl == null) return;

    if (ctrl.value.hasError) {
      _tryNextSource(
        state.currentChannel!,
        state.currentSourceIndex,
      );
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

  // تشغيل / إيقاف مؤقت
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

  // ترجيع / تقديم (للـ TimeShift)
  Future<void> seekBy(Duration offset) async {
    final ctrl = state.controller;
    if (ctrl == null) return;
    final newPos = ctrl.value.position + offset;
    await ctrl.seekTo(newPos);
  }

  // تغيير السرعة
  Future<void> setSpeed(double speed) async {
    await state.controller?.setPlaybackSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  // تبديل ملء الشاشة
  Future<void> toggleFullscreen() async {
    if (!state.isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  // إظهار / إخفاء أدوات التحكم
  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      state = state.copyWith(showControls: false);
    });
  }

  // تحرير الموارد
  Future<void> _dispose() async {
    _positionTimer?.cancel();
    _controlsTimer?.cancel();
    _sourceRetryTimer?.cancel();
    await state.controller?.dispose();
  }

  @override
  void dispose() {
    _dispose();
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
