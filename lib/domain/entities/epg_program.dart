import 'package:equatable/equatable.dart';

// كيان برنامج دليل البرامج EPG
class EpgProgram extends Equatable {
  final String id;
  final String channelId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? category;
  final String? imageUrl;
  final String? rating;

  const EpgProgram({
    required this.id,
    required this.channelId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.category,
    this.imageUrl,
    this.rating,
  });

  // هل البرنامج يُعرض الآن
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // نسبة التقدم (0.0 - 1.0)
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0.0;
    if (now.isAfter(endTime)) return 1.0;
    final total = endTime.difference(startTime).inSeconds;
    final elapsed = now.difference(startTime).inSeconds;
    return elapsed / total;
  }

  // مدة البرنامج
  Duration get duration => endTime.difference(startTime);

  @override
  List<Object?> get props => [id, channelId, title, startTime, endTime];
}
