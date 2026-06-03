import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/local/database.dart';

// مزود قائمة التسجيلات
final recordingsProvider = StreamProvider<List<RecordingsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecordings();
});

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(recordingsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('التسجيلات',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      ),
      body: recordingsAsync.when(
        data: (recordings) {
          if (recordings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 64, color: Colors.white12),
                  SizedBox(height: 16),
                  Text('لا توجد تسجيلات',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white54,
                          fontSize: 15)),
                  SizedBox(height: 8),
                  Text(
                    'ابدأ التسجيل من شاشة المشغل',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white38,
                        fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: recordings.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white10),
            itemBuilder: (ctx, i) =>
                _RecordingItem(recording: recordings[i], ref: ref),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (e, _) => Center(
            child: Text('خطأ: $e',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.red))),
      ),
    );
  }
}

class _RecordingItem extends StatelessWidget {
  final RecordingsTableData recording;
  final WidgetRef ref;
  const _RecordingItem({required this.recording, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final isCompleted = recording.status == 'completed';
    final isRecording = recording.status == 'recording';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.red.withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecording
              ? Icons.fiber_manual_record
              : isCompleted
                  ? Icons.check_circle
                  : Icons.schedule,
          color: isRecording
              ? Colors.red
              : isCompleted
                  ? Colors.green
                  : Colors.orange,
          size: 24,
        ),
      ),
      title: Text(
        recording.channelName,
        style: const TextStyle(
            fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w600),
        textDirection: TextDirection.rtl,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateFormat.format(recording.startTime),
            style: const TextStyle(
                fontFamily: 'Cairo', color: Colors.white54, fontSize: 12),
          ),
          if (isCompleted && recording.sizeBytes > 0)
            Text(
              _formatSize(recording.sizeBytes),
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Colors.white38, fontSize: 11),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: Color(0xFF00E5FF), size: 28),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('حذف التسجيل',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            textAlign: TextAlign.right),
        content: const Text('هل تريد حذف هذا التسجيل نهائياً؟',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white70),
            textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteRecording(recording.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
