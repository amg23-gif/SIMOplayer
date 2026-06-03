import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

// --- جداول قاعدة البيانات ---

// جدول القنوات
class ChannelsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get group => text().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get tvgId => text().nullable()();
  TextColumn get tvgName => text().nullable()();
  TextColumn get streamUrlsJson => text()(); // JSON array of URLs
  TextColumn get sourceId => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastChecked => dateTime().nullable()();
  IntColumn get currentSourceIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول المصادر
class SourcesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // m3uUrl, m3uFile, xtreamCodes
  TextColumn get m3uUrl => text().nullable()();
  TextColumn get serverUrl => text().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  TextColumn get localFilePath => text().nullable()();
  TextColumn get epgUrl => text().nullable()();
  IntColumn get channelCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRefreshed => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول الملفات الشخصية
class ProfilesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get avatarEmoji => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول سجل المشاهدة
class WatchHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get channelName => text()();
  TextColumn get channelLogo => text().nullable()();
  TextColumn get streamUrl => text().nullable()();
  TextColumn get profileId => text()();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get stopPositionSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول بيانات EPG
class EpgProgramsTable extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get rating => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول التسجيلات
class RecordingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get channelName => text()();
  TextColumn get title => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get cloudUrl => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  BoolColumn get isScheduled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول الإعدادات
class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get profileId => text().withDefault(const Constant('default'))();

  @override
  Set<Column> get primaryKey => {key, profileId};
}

// --- قاعدة البيانات الرئيسية ---
@DriftDatabase(tables: [
  ChannelsTable,
  SourcesTable,
  ProfilesTable,
  WatchHistoryTable,
  EpgProgramsTable,
  RecordingsTable,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // إنشاء ملف شخصي افتراضي
          await into(profilesTable).insert(ProfilesTableCompanion.insert(
            id: const Value('default'),
            name: const Value('الملف الافتراضي'),
            avatarEmoji: const Value('😊'),
            isDefault: const Value(true),
            createdAt: Value(DateTime.now()),
          ));
        },
      );

  // --- عمليات القنوات ---

  Future<List<ChannelsTableData>> getAllChannels({String? profileId}) {
    return select(channelsTable).get();
  }

  Stream<List<ChannelsTableData>> watchChannels({String? category}) {
    if (category != null) {
      return (select(channelsTable)
            ..where((t) => t.category.equals(category)))
          .watch();
    }
    return select(channelsTable).watch();
  }

  Stream<List<ChannelsTableData>> watchFavorites() {
    return (select(channelsTable)
          ..where((t) => t.isFavorite.equals(true)))
        .watch();
  }

  Future<void> insertChannels(List<ChannelsTableCompanion> channels) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(channelsTable, channels);
    });
  }

  Future<void> toggleFavorite(String channelId, bool isFavorite) async {
    await (update(channelsTable)
          ..where((t) => t.id.equals(channelId)))
        .write(ChannelsTableCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> updateChannelAvailability(
      String channelId, bool isAvailable) async {
    await (update(channelsTable)
          ..where((t) => t.id.equals(channelId)))
        .write(ChannelsTableCompanion(
      isAvailable: Value(isAvailable),
      lastChecked: Value(DateTime.now()),
    ));
  }

  Future<void> deleteChannelsBySource(String sourceId) async {
    await (delete(channelsTable)
          ..where((t) => t.sourceId.equals(sourceId)))
        .go();
  }

  // --- عمليات المصادر ---

  Stream<List<SourcesTableData>> watchSources() {
    return select(sourcesTable).watch();
  }

  Future<void> insertSource(SourcesTableCompanion source) async {
    await into(sourcesTable).insertOnConflictUpdate(source);
  }

  Future<void> deleteSource(String sourceId) async {
    await (delete(sourcesTable)..where((t) => t.id.equals(sourceId))).go();
  }

  Future<void> updateSourceChannelCount(
      String sourceId, int count, DateTime refreshed) async {
    await (update(sourcesTable)..where((t) => t.id.equals(sourceId))).write(
      SourcesTableCompanion(
        channelCount: Value(count),
        lastRefreshed: Value(refreshed),
      ),
    );
  }

  // --- عمليات الملفات الشخصية ---

  Stream<List<ProfilesTableData>> watchProfiles() {
    return select(profilesTable).watch();
  }

  Future<void> insertProfile(ProfilesTableCompanion profile) async {
    await into(profilesTable).insertOnConflictUpdate(profile);
  }

  Future<void> deleteProfile(String profileId) async {
    await (delete(profilesTable)..where((t) => t.id.equals(profileId))).go();
  }

  // --- عمليات سجل المشاهدة ---

  Stream<List<WatchHistoryTableData>> watchHistory(
      {required String profileId, int limit = 20}) {
    return (select(watchHistoryTable)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.watchedAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> addToHistory(WatchHistoryTableCompanion entry) async {
    // حذف الإدخال القديم لنفس القناة ثم إعادة الإدراج
    await (delete(watchHistoryTable)
          ..where((t) =>
              t.channelId.equals(entry.channelId.value) &
              t.profileId.equals(entry.profileId.value)))
        .go();
    await into(watchHistoryTable).insert(entry);
  }

  Future<void> updateStopPosition(String historyId, int positionSeconds) async {
    await (update(watchHistoryTable)
          ..where((t) => t.id.equals(historyId)))
        .write(WatchHistoryTableCompanion(
            stopPositionSeconds: Value(positionSeconds)));
  }

  Future<void> clearHistory(String profileId) async {
    await (delete(watchHistoryTable)
          ..where((t) => t.profileId.equals(profileId)))
        .go();
  }

  // --- عمليات EPG ---

  Future<List<EpgProgramsTableData>> getProgramsForChannel(
      String channelId) async {
    return (select(epgProgramsTable)
          ..where((t) => t.channelId.equals(channelId))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Future<EpgProgramsTableData?> getCurrentProgram(String channelId) async {
    final now = DateTime.now();
    return (select(epgProgramsTable)
          ..where((t) =>
              t.channelId.equals(channelId) &
              t.startTime.isSmallerOrEqualValue(now) &
              t.endTime.isBiggerOrEqualValue(now)))
        .getSingleOrNull();
  }

  Future<void> insertEpgPrograms(
      List<EpgProgramsTableCompanion> programs) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(epgProgramsTable, programs);
    });
  }

  Future<void> clearOldEpgData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    await (delete(epgProgramsTable)
          ..where((t) => t.endTime.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  // --- عمليات التسجيلات ---

  Stream<List<RecordingsTableData>> watchRecordings() {
    return (select(recordingsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }

  Future<void> insertRecording(RecordingsTableCompanion recording) async {
    await into(recordingsTable).insert(recording);
  }

  Future<void> updateRecordingStatus(String id, String status,
      {String? filePath, int? sizeBytes, DateTime? endTime}) async {
    await (update(recordingsTable)..where((t) => t.id.equals(id))).write(
      RecordingsTableCompanion(
        status: Value(status),
        filePath: filePath != null ? Value(filePath) : const Value.absent(),
        sizeBytes: sizeBytes != null ? Value(sizeBytes) : const Value.absent(),
        endTime: endTime != null ? Value(endTime) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteRecording(String id) async {
    await (delete(recordingsTable)..where((t) => t.id.equals(id))).go();
  }

  // --- عمليات الإعدادات ---

  Future<String?> getSetting(String key,
      {String profileId = 'default'}) async {
    final result = await (select(settingsTable)
          ..where(
              (t) => t.key.equals(key) & t.profileId.equals(profileId)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value,
      {String profileId = 'default'}) async {
    await into(settingsTable).insertOnConflictUpdate(
      SettingsTableCompanion.insert(
        key: key,
        value: value,
        profileId: Value(profileId),
      ),
    );
  }
}

// فتح اتصال قاعدة البيانات
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'simo_player.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// مزود قاعدة البيانات
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('يجب توفير قاعدة البيانات في main()');
});
