import 'package:equatable/equatable.dart';

// كيان سجل المشاهدة
class WatchHistory extends Equatable {
  final String id;
  final String channelId;
  final String channelName;
  final String? channelLogo;
  final String? streamUrl;
  final String profileId;
  final DateTime watchedAt;
  final Duration? stopPosition; // نقطة التوقف للاستئناف

  const WatchHistory({
    required this.id,
    required this.channelId,
    required this.channelName,
    this.channelLogo,
    this.streamUrl,
    required this.profileId,
    required this.watchedAt,
    this.stopPosition,
  });

  @override
  List<Object?> get props => [id, channelId, profileId, watchedAt];
}
