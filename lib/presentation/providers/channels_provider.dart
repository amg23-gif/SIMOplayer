import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/source.dart';
import '../../data/datasources/local/database.dart';
import '../../core/utils/m3u_parser.dart';

// مزود قائمة المصادر
final sourcesProvider = StreamProvider<List<Source>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchSources().map((rows) => rows.map(_rowToSource).toList());
});

// مزود قائمة القنوات (كاملة)
final channelsProvider = StreamProvider<List<Channel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchChannels().map((rows) => rows.map(_rowToChannel).toList());
});

// مزود القنوات المفضلة
final favoritesProvider = StreamProvider<List<Channel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFavorites().map((rows) => rows.map(_rowToChannel).toList());
});

// مزود قائمة التصنيفات
final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(channelsProvider).whenData(
        (channels) => channels.map((c) => c.category).toSet().toList()..sort(),
      );
});

// مزود القنوات حسب تصنيف
final channelsByCategoryProvider =
    Provider.family<AsyncValue<List<Channel>>, String?>((ref, category) {
  return ref.watch(channelsProvider).whenData(
        (channels) => category == null
            ? channels
            : channels.where((c) => c.category == category).toList(),
      );
});

// منطق إدارة القنوات والمصادر
class ChannelsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => ref.read(databaseProvider);

  // إضافة مصدر جديد وتحميل قنواته
  Future<void> addSource(Source source) async {
    state = const AsyncLoading();
    try {
      // حفظ المصدر في قاعدة البيانات
      await _db.insertSource(_sourceToCompanion(source));

      // تحميل وتحليل القنوات
      final channels = await M3uParser.parseFromUrl(source);

      // تحويل القنوات لصف قاعدة البيانات وحفظها
      final companions = channels
          .map((ch) => _channelToCompanion(ch, source.id))
          .toList();
      await _db.insertChannels(companions);

      // تحديث عدد القنوات
      await _db.updateSourceChannelCount(
          source.id, channels.length, DateTime.now());

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // حذف مصدر وقنواته
  Future<void> deleteSource(String sourceId) async {
    await _db.deleteChannelsBySource(sourceId);
    await _db.deleteSource(sourceId);
  }

  // تبديل المفضلة
  Future<void> toggleFavorite(String channelId, bool isFavorite) async {
    await _db.toggleFavorite(channelId, isFavorite);
  }

  // إضافة رابط إضافي لقناة موجودة
  Future<void> addStreamUrlToChannel(
      String channelId, String newUrl) async {
    final channels = await _db.getAllChannels();
    final channel = channels.where((c) => c.id == channelId).firstOrNull;
    if (channel == null) return;

    final urls = channel.streamUrlsJson.split(',').toList();
    urls.add(newUrl);
    // تحديث القناة (سيتم تنفيذه لاحقاً بعمليات update)
  }
}

final channelsNotifierProvider =
    AsyncNotifierProvider<ChannelsNotifier, void>(ChannelsNotifier.new);

// --- دوال تحويل نماذج البيانات ---

Channel _rowToChannel(ChannelsTableData row) {
  List<String> urls;
  try {
    urls = (jsonDecode(row.streamUrlsJson) as List).cast<String>();
  } catch (_) {
    urls = row.streamUrlsJson.split(',').where((u) => u.isNotEmpty).toList();
  }

  return Channel(
    id: row.id,
    name: row.name,
    logoUrl: row.logoUrl,
    category: row.category,
    group: row.group,
    language: row.language,
    country: row.country,
    tvgId: row.tvgId,
    tvgName: row.tvgName,
    streamUrls: urls,
    isFavorite: row.isFavorite,
    isAvailable: row.isAvailable,
    lastChecked: row.lastChecked,
    currentSourceIndex: row.currentSourceIndex,
  );
}

Source _rowToSource(SourcesTableData row) {
  return Source(
    id: row.id,
    name: row.name,
    type: SourceType.values.firstWhere(
      (t) => t.name == row.type,
      orElse: () => SourceType.m3uUrl,
    ),
    m3uUrl: row.m3uUrl,
    serverUrl: row.serverUrl,
    username: row.username,
    password: row.password,
    localFilePath: row.localFilePath,
    epgUrl: row.epgUrl,
    channelCount: row.channelCount,
    lastRefreshed: row.lastRefreshed,
    isActive: row.isActive,
  );
}

ChannelsTableCompanion _channelToCompanion(Channel ch, String sourceId) {
  return ChannelsTableCompanion.insert(
    id: ch.id,
    name: ch.name,
    logoUrl: Value(ch.logoUrl),
    category: Value(ch.category),
    group: Value(ch.group),
    language: Value(ch.language),
    country: Value(ch.country),
    tvgId: Value(ch.tvgId),
    tvgName: Value(ch.tvgName),
    streamUrlsJson: jsonEncode(ch.streamUrls),
    sourceId: sourceId,
  );
}

SourcesTableCompanion _sourceToCompanion(Source s) {
  return SourcesTableCompanion.insert(
    id: s.id,
    name: s.name,
    type: s.type.name,
    m3uUrl: Value(s.m3uUrl),
    serverUrl: Value(s.serverUrl),
    username: Value(s.username),
    password: Value(s.password),
    localFilePath: Value(s.localFilePath),
    epgUrl: Value(s.epgUrl),
    channelCount: Value(s.channelCount),
    lastRefreshed: Value(s.lastRefreshed),
    isActive: Value(s.isActive),
  );
}
