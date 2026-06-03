// GENERATED CODE - DO NOT MODIFY BY HAND
// يُولَّد هذا الملف تلقائياً عبر: dart run build_runner build
// شغّل: flutter pub run build_runner build --delete-conflicting-outputs

part of 'database.dart';

// **************************************************************************
// DriftDatabaseGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ChannelsTableData extends DataClass implements Insertable<ChannelsTableData> {
  final String id;
  final String name;
  final String? logoUrl;
  final String category;
  final String? group;
  final String? language;
  final String? country;
  final String? tvgId;
  final String? tvgName;
  final String streamUrlsJson;
  final String sourceId;
  final bool isFavorite;
  final bool isAvailable;
  final DateTime? lastChecked;
  final int currentSourceIndex;

  const ChannelsTableData({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.category,
    this.group,
    this.language,
    this.country,
    this.tvgId,
    this.tvgName,
    required this.streamUrlsJson,
    required this.sourceId,
    required this.isFavorite,
    required this.isAvailable,
    this.lastChecked,
    required this.currentSourceIndex,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoUrl != null) map['logo_url'] = Variable<String?>(logoUrl);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || group != null) map['group'] = Variable<String?>(group);
    if (!nullToAbsent || language != null) map['language'] = Variable<String?>(language);
    if (!nullToAbsent || country != null) map['country'] = Variable<String?>(country);
    if (!nullToAbsent || tvgId != null) map['tvg_id'] = Variable<String?>(tvgId);
    if (!nullToAbsent || tvgName != null) map['tvg_name'] = Variable<String?>(tvgName);
    map['stream_urls_json'] = Variable<String>(streamUrlsJson);
    map['source_id'] = Variable<String>(sourceId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || lastChecked != null) map['last_checked'] = Variable<DateTime?>(lastChecked);
    map['current_source_index'] = Variable<int>(currentSourceIndex);
    return map;
  }

  ChannelsTableCompanion toCompanion(bool nullToAbsent) {
    return ChannelsTableCompanion(
      id: Value(id),
      name: Value(name),
      logoUrl: logoUrl == null && nullToAbsent ? const Value.absent() : Value(logoUrl),
      category: Value(category),
      group: group == null && nullToAbsent ? const Value.absent() : Value(group),
      language: language == null && nullToAbsent ? const Value.absent() : Value(language),
      country: country == null && nullToAbsent ? const Value.absent() : Value(country),
      tvgId: tvgId == null && nullToAbsent ? const Value.absent() : Value(tvgId),
      tvgName: tvgName == null && nullToAbsent ? const Value.absent() : Value(tvgName),
      streamUrlsJson: Value(streamUrlsJson),
      sourceId: Value(sourceId),
      isFavorite: Value(isFavorite),
      isAvailable: Value(isAvailable),
      lastChecked: lastChecked == null && nullToAbsent ? const Value.absent() : Value(lastChecked),
      currentSourceIndex: Value(currentSourceIndex),
    );
  }

  factory ChannelsTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelsTableData(
      id: serializer.fromJson<String>(data['id']),
      name: serializer.fromJson<String>(data['name']),
      logoUrl: serializer.fromJson<String?>(data['logo_url']),
      category: serializer.fromJson<String>(data['category']),
      group: serializer.fromJson<String?>(data['group']),
      language: serializer.fromJson<String?>(data['language']),
      country: serializer.fromJson<String?>(data['country']),
      tvgId: serializer.fromJson<String?>(data['tvg_id']),
      tvgName: serializer.fromJson<String?>(data['tvg_name']),
      streamUrlsJson: serializer.fromJson<String>(data['stream_urls_json']),
      sourceId: serializer.fromJson<String>(data['source_id']),
      isFavorite: serializer.fromJson<bool>(data['is_favorite']),
      isAvailable: serializer.fromJson<bool>(data['is_available']),
      lastChecked: serializer.fromJson<DateTime?>(data['last_checked']),
      currentSourceIndex: serializer.fromJson<int>(data['current_source_index']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'logo_url': serializer.toJson<String?>(logoUrl),
      'category': serializer.toJson<String>(category),
      'group': serializer.toJson<String?>(group),
      'language': serializer.toJson<String?>(language),
      'country': serializer.toJson<String?>(country),
      'tvg_id': serializer.toJson<String?>(tvgId),
      'tvg_name': serializer.toJson<String?>(tvgName),
      'stream_urls_json': serializer.toJson<String>(streamUrlsJson),
      'source_id': serializer.toJson<String>(sourceId),
      'is_favorite': serializer.toJson<bool>(isFavorite),
      'is_available': serializer.toJson<bool>(isAvailable),
      'last_checked': serializer.toJson<DateTime?>(lastChecked),
      'current_source_index': serializer.toJson<int>(currentSourceIndex),
    };
  }

  ChannelsTableData copyWith({
    String? id, String? name, Value<String?> logoUrl = const Value.absent(),
    String? category, Value<String?> group = const Value.absent(),
    Value<String?> language = const Value.absent(), Value<String?> country = const Value.absent(),
    Value<String?> tvgId = const Value.absent(), Value<String?> tvgName = const Value.absent(),
    String? streamUrlsJson, String? sourceId, bool? isFavorite, bool? isAvailable,
    Value<DateTime?> lastChecked = const Value.absent(), int? currentSourceIndex,
  }) => ChannelsTableData(
    id: id ?? this.id, name: name ?? this.name,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    category: category ?? this.category,
    group: group.present ? group.value : this.group,
    language: language.present ? language.value : this.language,
    country: country.present ? country.value : this.country,
    tvgId: tvgId.present ? tvgId.value : this.tvgId,
    tvgName: tvgName.present ? tvgName.value : this.tvgName,
    streamUrlsJson: streamUrlsJson ?? this.streamUrlsJson,
    sourceId: sourceId ?? this.sourceId,
    isFavorite: isFavorite ?? this.isFavorite,
    isAvailable: isAvailable ?? this.isAvailable,
    lastChecked: lastChecked.present ? lastChecked.value : this.lastChecked,
    currentSourceIndex: currentSourceIndex ?? this.currentSourceIndex,
  );

  @override
  String toString() => 'Channel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChannelsTableData && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class ChannelsTableCompanion extends UpdateCompanion<ChannelsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> logoUrl;
  final Value<String> category;
  final Value<String?> group;
  final Value<String?> language;
  final Value<String?> country;
  final Value<String?> tvgId;
  final Value<String?> tvgName;
  final Value<String> streamUrlsJson;
  final Value<String> sourceId;
  final Value<bool> isFavorite;
  final Value<bool> isAvailable;
  final Value<DateTime?> lastChecked;
  final Value<int> currentSourceIndex;

  const ChannelsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.group = const Value.absent(),
    this.language = const Value.absent(),
    this.country = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    this.streamUrlsJson = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastChecked = const Value.absent(),
    this.currentSourceIndex = const Value.absent(),
  });

  ChannelsTableCompanion.insert({
    required String id,
    required String name,
    this.logoUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.group = const Value.absent(),
    this.language = const Value.absent(),
    this.country = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    required String streamUrlsJson,
    required String sourceId,
    this.isFavorite = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.lastChecked = const Value.absent(),
    this.currentSourceIndex = const Value.absent(),
  }) : id = Value(id), name = Value(name),
       streamUrlsJson = Value(streamUrlsJson), sourceId = Value(sourceId);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (name.present) map['name'] = Variable<String>(name.value);
    if (logoUrl.present) map['logo_url'] = Variable<String?>(logoUrl.value);
    if (category.present) map['category'] = Variable<String>(category.value);
    if (group.present) map['group'] = Variable<String?>(group.value);
    if (language.present) map['language'] = Variable<String?>(language.value);
    if (country.present) map['country'] = Variable<String?>(country.value);
    if (tvgId.present) map['tvg_id'] = Variable<String?>(tvgId.value);
    if (tvgName.present) map['tvg_name'] = Variable<String?>(tvgName.value);
    if (streamUrlsJson.present) map['stream_urls_json'] = Variable<String>(streamUrlsJson.value);
    if (sourceId.present) map['source_id'] = Variable<String>(sourceId.value);
    if (isFavorite.present) map['is_favorite'] = Variable<bool>(isFavorite.value);
    if (isAvailable.present) map['is_available'] = Variable<bool>(isAvailable.value);
    if (lastChecked.present) map['last_checked'] = Variable<DateTime?>(lastChecked.value);
    if (currentSourceIndex.present) map['current_source_index'] = Variable<int>(currentSourceIndex.value);
    return map;
  }

  @override
  String toString() => 'ChannelsTableCompanion(id: $id, name: $name)';
}

// --- SourcesTableData ---
class SourcesTableData extends DataClass implements Insertable<SourcesTableData> {
  final String id;
  final String name;
  final String type;
  final String? m3uUrl;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? localFilePath;
  final String? epgUrl;
  final int channelCount;
  final DateTime? lastRefreshed;
  final bool isActive;

  const SourcesTableData({
    required this.id, required this.name, required this.type,
    this.m3uUrl, this.serverUrl, this.username, this.password,
    this.localFilePath, this.epgUrl, required this.channelCount,
    this.lastRefreshed, required this.isActive,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {'id': Variable<String>(id)};

  SourcesTableCompanion toCompanion(bool nullToAbsent) => SourcesTableCompanion(id: Value(id));
  factory SourcesTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      SourcesTableData(id: data['id'], name: data['name'], type: data['type'], channelCount: data['channel_count'] ?? 0, isActive: data['is_active'] ?? true);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'id': id, 'name': name};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is SourcesTableData && other.id == id);
  @override
  int get hashCode => id.hashCode;
}

class SourcesTableCompanion extends UpdateCompanion<SourcesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> m3uUrl;
  final Value<String?> serverUrl;
  final Value<String?> username;
  final Value<String?> password;
  final Value<String?> localFilePath;
  final Value<String?> epgUrl;
  final Value<int> channelCount;
  final Value<DateTime?> lastRefreshed;
  final Value<bool> isActive;

  const SourcesTableCompanion({
    this.id = const Value.absent(), this.name = const Value.absent(),
    this.type = const Value.absent(), this.m3uUrl = const Value.absent(),
    this.serverUrl = const Value.absent(), this.username = const Value.absent(),
    this.password = const Value.absent(), this.localFilePath = const Value.absent(),
    this.epgUrl = const Value.absent(), this.channelCount = const Value.absent(),
    this.lastRefreshed = const Value.absent(), this.isActive = const Value.absent(),
  });

  SourcesTableCompanion.insert({
    required String id, required String name, required String type,
    this.m3uUrl = const Value.absent(), this.serverUrl = const Value.absent(),
    this.username = const Value.absent(), this.password = const Value.absent(),
    this.localFilePath = const Value.absent(), this.epgUrl = const Value.absent(),
    this.channelCount = const Value.absent(), this.lastRefreshed = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : id = Value(id), name = Value(name), type = Value(type);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (name.present) map['name'] = Variable<String>(name.value);
    if (type.present) map['type'] = Variable<String>(type.value);
    if (m3uUrl.present) map['m3u_url'] = Variable<String?>(m3uUrl.value);
    if (serverUrl.present) map['server_url'] = Variable<String?>(serverUrl.value);
    if (username.present) map['username'] = Variable<String?>(username.value);
    if (password.present) map['password'] = Variable<String?>(password.value);
    if (localFilePath.present) map['local_file_path'] = Variable<String?>(localFilePath.value);
    if (epgUrl.present) map['epg_url'] = Variable<String?>(epgUrl.value);
    if (channelCount.present) map['channel_count'] = Variable<int>(channelCount.value);
    if (lastRefreshed.present) map['last_refreshed'] = Variable<DateTime?>(lastRefreshed.value);
    if (isActive.present) map['is_active'] = Variable<bool>(isActive.value);
    return map;
  }
}

// --- ProfilesTableData ---
class ProfilesTableData extends DataClass implements Insertable<ProfilesTableData> {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? avatarEmoji;
  final bool isDefault;
  final DateTime createdAt;

  const ProfilesTableData({
    required this.id, required this.name, this.avatarUrl,
    this.avatarEmoji, required this.isDefault, required this.createdAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {'id': Variable<String>(id)};
  ProfilesTableCompanion toCompanion(bool nullToAbsent) => ProfilesTableCompanion(id: Value(id));
  factory ProfilesTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      ProfilesTableData(id: data['id'], name: data['name'], isDefault: data['is_default'] ?? false, createdAt: DateTime.now());
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'id': id, 'name': name};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is ProfilesTableData && other.id == id);
  @override
  int get hashCode => id.hashCode;
}

class ProfilesTableCompanion extends UpdateCompanion<ProfilesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatarUrl;
  final Value<String?> avatarEmoji;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;

  const ProfilesTableCompanion({
    this.id = const Value.absent(), this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(), this.avatarEmoji = const Value.absent(),
    this.isDefault = const Value.absent(), this.createdAt = const Value.absent(),
  });

  ProfilesTableCompanion.insert({
    required String id, required String name,
    this.avatarUrl = const Value.absent(), this.avatarEmoji = const Value.absent(),
    this.isDefault = const Value.absent(), required DateTime createdAt,
  }) : id = Value(id), name = Value(name), createdAt = Value(createdAt);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (name.present) map['name'] = Variable<String>(name.value);
    if (avatarUrl.present) map['avatar_url'] = Variable<String?>(avatarUrl.value);
    if (avatarEmoji.present) map['avatar_emoji'] = Variable<String?>(avatarEmoji.value);
    if (isDefault.present) map['is_default'] = Variable<bool>(isDefault.value);
    if (createdAt.present) map['created_at'] = Variable<DateTime>(createdAt.value);
    return map;
  }
}

// --- WatchHistoryTableData ---
class WatchHistoryTableData extends DataClass implements Insertable<WatchHistoryTableData> {
  final String id;
  final String channelId;
  final String channelName;
  final String? channelLogo;
  final String? streamUrl;
  final String profileId;
  final DateTime watchedAt;
  final int? stopPositionSeconds;

  const WatchHistoryTableData({
    required this.id, required this.channelId, required this.channelName,
    this.channelLogo, this.streamUrl, required this.profileId,
    required this.watchedAt, this.stopPositionSeconds,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {'id': Variable<String>(id)};
  WatchHistoryTableCompanion toCompanion(bool nullToAbsent) => WatchHistoryTableCompanion(id: Value(id));
  factory WatchHistoryTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      WatchHistoryTableData(id: data['id'], channelId: data['channel_id'], channelName: data['channel_name'], profileId: data['profile_id'], watchedAt: DateTime.now());
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'id': id};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is WatchHistoryTableData && other.id == id);
  @override
  int get hashCode => id.hashCode;
}

class WatchHistoryTableCompanion extends UpdateCompanion<WatchHistoryTableData> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> channelName;
  final Value<String?> channelLogo;
  final Value<String?> streamUrl;
  final Value<String> profileId;
  final Value<DateTime> watchedAt;
  final Value<int?> stopPositionSeconds;

  const WatchHistoryTableCompanion({
    this.id = const Value.absent(), this.channelId = const Value.absent(),
    this.channelName = const Value.absent(), this.channelLogo = const Value.absent(),
    this.streamUrl = const Value.absent(), this.profileId = const Value.absent(),
    this.watchedAt = const Value.absent(), this.stopPositionSeconds = const Value.absent(),
  });

  WatchHistoryTableCompanion.insert({
    required String id, required String channelId, required String channelName,
    this.channelLogo = const Value.absent(), this.streamUrl = const Value.absent(),
    required String profileId, required DateTime watchedAt,
    this.stopPositionSeconds = const Value.absent(),
  }) : id = Value(id), channelId = Value(channelId), channelName = Value(channelName),
       profileId = Value(profileId), watchedAt = Value(watchedAt);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (channelId.present) map['channel_id'] = Variable<String>(channelId.value);
    if (channelName.present) map['channel_name'] = Variable<String>(channelName.value);
    if (channelLogo.present) map['channel_logo'] = Variable<String?>(channelLogo.value);
    if (streamUrl.present) map['stream_url'] = Variable<String?>(streamUrl.value);
    if (profileId.present) map['profile_id'] = Variable<String>(profileId.value);
    if (watchedAt.present) map['watched_at'] = Variable<DateTime>(watchedAt.value);
    if (stopPositionSeconds.present) map['stop_position_seconds'] = Variable<int?>(stopPositionSeconds.value);
    return map;
  }
}

// --- EpgProgramsTableData ---
class EpgProgramsTableData extends DataClass implements Insertable<EpgProgramsTableData> {
  final String id;
  final String channelId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? category;
  final String? imageUrl;
  final String? rating;

  const EpgProgramsTableData({
    required this.id, required this.channelId, required this.title,
    this.description, required this.startTime, required this.endTime,
    this.category, this.imageUrl, this.rating,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {'id': Variable<String>(id)};
  EpgProgramsTableCompanion toCompanion(bool nullToAbsent) => EpgProgramsTableCompanion(id: Value(id));
  factory EpgProgramsTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      EpgProgramsTableData(id: data['id'], channelId: data['channel_id'], title: data['title'], startTime: DateTime.now(), endTime: DateTime.now());
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'id': id};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is EpgProgramsTableData && other.id == id);
  @override
  int get hashCode => id.hashCode;
}

class EpgProgramsTableCompanion extends UpdateCompanion<EpgProgramsTableData> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String?> category;
  final Value<String?> imageUrl;
  final Value<String?> rating;

  const EpgProgramsTableCompanion({
    this.id = const Value.absent(), this.channelId = const Value.absent(),
    this.title = const Value.absent(), this.description = const Value.absent(),
    this.startTime = const Value.absent(), this.endTime = const Value.absent(),
    this.category = const Value.absent(), this.imageUrl = const Value.absent(),
    this.rating = const Value.absent(),
  });

  EpgProgramsTableCompanion.insert({
    required String id, required String channelId, required String title,
    this.description = const Value.absent(), required DateTime startTime,
    required DateTime endTime, this.category = const Value.absent(),
    this.imageUrl = const Value.absent(), this.rating = const Value.absent(),
  }) : id = Value(id), channelId = Value(channelId), title = Value(title),
       startTime = Value(startTime), endTime = Value(endTime);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (channelId.present) map['channel_id'] = Variable<String>(channelId.value);
    if (title.present) map['title'] = Variable<String>(title.value);
    if (description.present) map['description'] = Variable<String?>(description.value);
    if (startTime.present) map['start_time'] = Variable<DateTime>(startTime.value);
    if (endTime.present) map['end_time'] = Variable<DateTime>(endTime.value);
    if (category.present) map['category'] = Variable<String?>(category.value);
    if (imageUrl.present) map['image_url'] = Variable<String?>(imageUrl.value);
    if (rating.present) map['rating'] = Variable<String?>(rating.value);
    return map;
  }
}

// --- RecordingsTableData ---
class RecordingsTableData extends DataClass implements Insertable<RecordingsTableData> {
  final String id;
  final String channelId;
  final String channelName;
  final String title;
  final String? filePath;
  final String? cloudUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final int sizeBytes;
  final String status;
  final bool isScheduled;

  const RecordingsTableData({
    required this.id, required this.channelId, required this.channelName,
    required this.title, this.filePath, this.cloudUrl, required this.startTime,
    this.endTime, required this.sizeBytes, required this.status, required this.isScheduled,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {'id': Variable<String>(id)};
  RecordingsTableCompanion toCompanion(bool nullToAbsent) => RecordingsTableCompanion(id: Value(id));
  factory RecordingsTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      RecordingsTableData(id: data['id'], channelId: data['channel_id'], channelName: data['channel_name'], title: data['title'], startTime: DateTime.now(), sizeBytes: 0, status: 'pending', isScheduled: false);
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'id': id};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is RecordingsTableData && other.id == id);
  @override
  int get hashCode => id.hashCode;
}

class RecordingsTableCompanion extends UpdateCompanion<RecordingsTableData> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> channelName;
  final Value<String> title;
  final Value<String?> filePath;
  final Value<String?> cloudUrl;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> sizeBytes;
  final Value<String> status;
  final Value<bool> isScheduled;

  const RecordingsTableCompanion({
    this.id = const Value.absent(), this.channelId = const Value.absent(),
    this.channelName = const Value.absent(), this.title = const Value.absent(),
    this.filePath = const Value.absent(), this.cloudUrl = const Value.absent(),
    this.startTime = const Value.absent(), this.endTime = const Value.absent(),
    this.sizeBytes = const Value.absent(), this.status = const Value.absent(),
    this.isScheduled = const Value.absent(),
  });

  RecordingsTableCompanion.insert({
    required String id, required String channelId, required String channelName,
    required String title, this.filePath = const Value.absent(), this.cloudUrl = const Value.absent(),
    required DateTime startTime, this.endTime = const Value.absent(),
    this.sizeBytes = const Value.absent(), this.status = const Value.absent(),
    this.isScheduled = const Value.absent(),
  }) : id = Value(id), channelId = Value(channelId), channelName = Value(channelName),
       title = Value(title), startTime = Value(startTime);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (channelId.present) map['channel_id'] = Variable<String>(channelId.value);
    if (channelName.present) map['channel_name'] = Variable<String>(channelName.value);
    if (title.present) map['title'] = Variable<String>(title.value);
    if (filePath.present) map['file_path'] = Variable<String?>(filePath.value);
    if (cloudUrl.present) map['cloud_url'] = Variable<String?>(cloudUrl.value);
    if (startTime.present) map['start_time'] = Variable<DateTime>(startTime.value);
    if (endTime.present) map['end_time'] = Variable<DateTime?>(endTime.value);
    if (sizeBytes.present) map['size_bytes'] = Variable<int>(sizeBytes.value);
    if (status.present) map['status'] = Variable<String>(status.value);
    if (isScheduled.present) map['is_scheduled'] = Variable<bool>(isScheduled.value);
    return map;
  }
}

// --- SettingsTableData ---
class SettingsTableData extends DataClass implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  final String profileId;

  const SettingsTableData({required this.key, required this.value, required this.profileId});

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {
    'key': Variable<String>(key),
    'value': Variable<String>(value),
    'profile_id': Variable<String>(profileId),
  };

  SettingsTableCompanion toCompanion(bool nullToAbsent) => SettingsTableCompanion(key: Value(key), value: Value(value), profileId: Value(profileId));
  factory SettingsTableData.fromJson(Map<String, dynamic> data, {ValueSerializer? serializer}) =>
      SettingsTableData(key: data['key'], value: data['value'], profileId: data['profile_id'] ?? 'default');
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) => {'key': key, 'value': value};
  @override
  bool operator ==(Object other) => identical(this, other) || (other is SettingsTableData && other.key == key && other.profileId == profileId);
  @override
  int get hashCode => Object.hash(key, profileId);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> profileId;

  const SettingsTableCompanion({
    this.key = const Value.absent(), this.value = const Value.absent(),
    this.profileId = const Value.absent(),
  });

  SettingsTableCompanion.insert({required String key, required String value, this.profileId = const Value.absent()})
      : key = Value(key), value = Value(value);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) map['key'] = Variable<String>(key.value);
    if (value.present) map['value'] = Variable<String>(value.value);
    if (profileId.present) map['profile_id'] = Variable<String>(profileId.value);
    return map;
  }
}

// --- Abstract Database Class ---
abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);

  late final ChannelsTable channelsTable = ChannelsTable(this);
  late final SourcesTable sourcesTable = SourcesTable(this);
  late final ProfilesTable profilesTable = ProfilesTable(this);
  late final WatchHistoryTable watchHistoryTable = WatchHistoryTable(this);
  late final EpgProgramsTable epgProgramsTable = EpgProgramsTable(this);
  late final RecordingsTable recordingsTable = RecordingsTable(this);
  late final SettingsTable settingsTable = SettingsTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        channelsTable, sourcesTable, profilesTable,
        watchHistoryTable, epgProgramsTable, recordingsTable, settingsTable,
      ];
}
