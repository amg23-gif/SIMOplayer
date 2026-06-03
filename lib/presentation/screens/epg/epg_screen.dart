import 'package:flutter/material.dart';
import 'dart:ui' show TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/local/database.dart';
import '../../../domain/entities/epg_program.dart';
import '../../../core/utils/epg_parser.dart';

// مزود برامج قناة محددة
final epgProgramsProvider =
    FutureProvider.family<List<EpgProgram>, String>((ref, channelId) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getProgramsForChannel(channelId);
  return rows
      .map((r) => EpgProgram(
            id: r.id,
            channelId: r.channelId,
            title: r.title,
            description: r.description,
            startTime: r.startTime,
            endTime: r.endTime,
            category: r.category,
            imageUrl: r.imageUrl,
            rating: r.rating,
          ))
      .toList();
});

class EpgScreen extends ConsumerWidget {
  final String channelId;
  const EpgScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(epgProgramsProvider(channelId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('دليل البرامج',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
      ),
      body: programsAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tv_off, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد بيانات برامج لهذه القناة',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white54,
                        fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف رابط EPG من إعدادات المصدر',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white38,
                        fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: programs.length,
            itemBuilder: (ctx, i) => _EpgProgramItem(program: programs[i]),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        error: (e, _) => Center(
            child: Text('خطأ في تحميل البرامج: $e',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.red))),
      ),
    );
  }
}

class _EpgProgramItem extends StatelessWidget {
  final EpgProgram program;
  const _EpgProgramItem({required this.program});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isLive = program.isLive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? const Color(0xFF1565C0).withOpacity(0.2)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: isLive
            ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProgramDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // مدة البرنامج ومؤشر مباشر
                  Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'مباشر',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${_formatDuration(program.duration)}',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white38,
                            fontSize: 11),
                      ),
                    ],
                  ),
                  // وقت البداية والنهاية
                  Text(
                    '${timeFormat.format(program.startTime)} - ${timeFormat.format(program.endTime)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isLive ? const Color(0xFF00E5FF) : Colors.white54,
                      fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // اسم البرنامج
              Text(
                program.title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: isLive ? Colors.white : Colors.white70,
                  fontWeight:
                      isLive ? FontWeight.bold : FontWeight.normal,
                ),
                textDirection: TextDirection.rtl,
              ),
              // وصف البرنامج
              if (program.description != null && program.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  program.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white38,
                      fontSize: 11),
                  textDirection: TextDirection.rtl,
                ),
              ],
              // شريط التقدم للبرنامج الحالي
              if (isLive) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: program.progress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5FF)),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              program.title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('yyyy/MM/dd HH:mm').format(program.startTime)} - ${DateFormat('HH:mm').format(program.endTime)}',
              style: const TextStyle(
                  fontFamily: 'Cairo', color: Color(0xFF00E5FF), fontSize: 13),
            ),
            if (program.description != null) ...[
              const SizedBox(height: 12),
              Text(
                program.description!,
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.white70, fontSize: 13),
                textDirection: TextDirection.rtl,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}س ${d.inMinutes % 60}د';
    return '${d.inMinutes}د';
  }
}
