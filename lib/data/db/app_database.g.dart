// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideosTable extends Videos with TableInfo<$VideosTable, Video> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelNameMeta = const VerificationMeta('channelName');
  @override
  late final GeneratedColumn<String> channelName = GeneratedColumn<String>(
    'channel_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelAvatarMeta = const VerificationMeta('channelAvatar');
  @override
  late final GeneratedColumn<String> channelAvatar = GeneratedColumn<String>(
    'channel_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationTextMeta = const VerificationMeta('durationText');
  @override
  late final GeneratedColumn<String> durationText = GeneratedColumn<String>(
    'duration_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viewsTextMeta = const VerificationMeta('viewsText');
  @override
  late final GeneratedColumn<String> viewsText = GeneratedColumn<String>(
    'views_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedTextMeta = const VerificationMeta('publishedText');
  @override
  late final GeneratedColumn<String> publishedText = GeneratedColumn<String>(
    'published_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isShortMeta = const VerificationMeta('isShort');
  @override
  late final GeneratedColumn<bool> isShort = GeneratedColumn<bool>(
    'is_short',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_short" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLiveMeta = const VerificationMeta('isLive');
  @override
  late final GeneratedColumn<bool> isLive = GeneratedColumn<bool>(
    'is_live',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_live" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    title,
    channelName,
    channelId,
    channelAvatar,
    thumbnail,
    durationText,
    viewsText,
    publishedText,
    isShort,
    isLive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(Insertable<Video> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('channel_name')) {
      context.handle(_channelNameMeta, channelName.isAcceptableOrUnknown(data['channel_name']!, _channelNameMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta, channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    }
    if (data.containsKey('channel_avatar')) {
      context.handle(
        _channelAvatarMeta,
        channelAvatar.isAcceptableOrUnknown(data['channel_avatar']!, _channelAvatarMeta),
      );
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta, thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    }
    if (data.containsKey('duration_text')) {
      context.handle(_durationTextMeta, durationText.isAcceptableOrUnknown(data['duration_text']!, _durationTextMeta));
    }
    if (data.containsKey('views_text')) {
      context.handle(_viewsTextMeta, viewsText.isAcceptableOrUnknown(data['views_text']!, _viewsTextMeta));
    }
    if (data.containsKey('published_text')) {
      context.handle(
        _publishedTextMeta,
        publishedText.isAcceptableOrUnknown(data['published_text']!, _publishedTextMeta),
      );
    }
    if (data.containsKey('is_short')) {
      context.handle(_isShortMeta, isShort.isAcceptableOrUnknown(data['is_short']!, _isShortMeta));
    }
    if (data.containsKey('is_live')) {
      context.handle(_isLiveMeta, isLive.isAcceptableOrUnknown(data['is_live']!, _isLiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  Video map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Video(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      channelName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_name']),
      channelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_id']),
      channelAvatar: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_avatar']),
      thumbnail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail']),
      durationText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}duration_text']),
      viewsText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}views_text']),
      publishedText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}published_text']),
      isShort: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_short'])!,
      isLive: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_live'])!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class Video extends DataClass implements Insertable<Video> {
  final String videoId;
  final String title;
  final String? channelName;
  final String? channelId;
  final String? channelAvatar;
  final String? thumbnail;
  final String? durationText;
  final String? viewsText;
  final String? publishedText;
  final bool isShort;
  final bool isLive;
  const Video({
    required this.videoId,
    required this.title,
    this.channelName,
    this.channelId,
    this.channelAvatar,
    this.thumbnail,
    this.durationText,
    this.viewsText,
    this.publishedText,
    required this.isShort,
    required this.isLive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || channelName != null) {
      map['channel_name'] = Variable<String>(channelName);
    }
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<String>(channelId);
    }
    if (!nullToAbsent || channelAvatar != null) {
      map['channel_avatar'] = Variable<String>(channelAvatar);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || durationText != null) {
      map['duration_text'] = Variable<String>(durationText);
    }
    if (!nullToAbsent || viewsText != null) {
      map['views_text'] = Variable<String>(viewsText);
    }
    if (!nullToAbsent || publishedText != null) {
      map['published_text'] = Variable<String>(publishedText);
    }
    map['is_short'] = Variable<bool>(isShort);
    map['is_live'] = Variable<bool>(isLive);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      videoId: Value(videoId),
      title: Value(title),
      channelName: channelName == null && nullToAbsent ? const Value.absent() : Value(channelName),
      channelId: channelId == null && nullToAbsent ? const Value.absent() : Value(channelId),
      channelAvatar: channelAvatar == null && nullToAbsent ? const Value.absent() : Value(channelAvatar),
      thumbnail: thumbnail == null && nullToAbsent ? const Value.absent() : Value(thumbnail),
      durationText: durationText == null && nullToAbsent ? const Value.absent() : Value(durationText),
      viewsText: viewsText == null && nullToAbsent ? const Value.absent() : Value(viewsText),
      publishedText: publishedText == null && nullToAbsent ? const Value.absent() : Value(publishedText),
      isShort: Value(isShort),
      isLive: Value(isLive),
    );
  }

  factory Video.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Video(
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      channelName: serializer.fromJson<String?>(json['channelName']),
      channelId: serializer.fromJson<String?>(json['channelId']),
      channelAvatar: serializer.fromJson<String?>(json['channelAvatar']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      durationText: serializer.fromJson<String?>(json['durationText']),
      viewsText: serializer.fromJson<String?>(json['viewsText']),
      publishedText: serializer.fromJson<String?>(json['publishedText']),
      isShort: serializer.fromJson<bool>(json['isShort']),
      isLive: serializer.fromJson<bool>(json['isLive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'channelName': serializer.toJson<String?>(channelName),
      'channelId': serializer.toJson<String?>(channelId),
      'channelAvatar': serializer.toJson<String?>(channelAvatar),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'durationText': serializer.toJson<String?>(durationText),
      'viewsText': serializer.toJson<String?>(viewsText),
      'publishedText': serializer.toJson<String?>(publishedText),
      'isShort': serializer.toJson<bool>(isShort),
      'isLive': serializer.toJson<bool>(isLive),
    };
  }

  Video copyWith({
    String? videoId,
    String? title,
    Value<String?> channelName = const Value.absent(),
    Value<String?> channelId = const Value.absent(),
    Value<String?> channelAvatar = const Value.absent(),
    Value<String?> thumbnail = const Value.absent(),
    Value<String?> durationText = const Value.absent(),
    Value<String?> viewsText = const Value.absent(),
    Value<String?> publishedText = const Value.absent(),
    bool? isShort,
    bool? isLive,
  }) => Video(
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    channelName: channelName.present ? channelName.value : this.channelName,
    channelId: channelId.present ? channelId.value : this.channelId,
    channelAvatar: channelAvatar.present ? channelAvatar.value : this.channelAvatar,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    durationText: durationText.present ? durationText.value : this.durationText,
    viewsText: viewsText.present ? viewsText.value : this.viewsText,
    publishedText: publishedText.present ? publishedText.value : this.publishedText,
    isShort: isShort ?? this.isShort,
    isLive: isLive ?? this.isLive,
  );
  Video copyWithCompanion(VideosCompanion data) {
    return Video(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      channelName: data.channelName.present ? data.channelName.value : this.channelName,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      channelAvatar: data.channelAvatar.present ? data.channelAvatar.value : this.channelAvatar,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      durationText: data.durationText.present ? data.durationText.value : this.durationText,
      viewsText: data.viewsText.present ? data.viewsText.value : this.viewsText,
      publishedText: data.publishedText.present ? data.publishedText.value : this.publishedText,
      isShort: data.isShort.present ? data.isShort.value : this.isShort,
      isLive: data.isLive.present ? data.isLive.value : this.isLive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Video(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channelName: $channelName, ')
          ..write('channelId: $channelId, ')
          ..write('channelAvatar: $channelAvatar, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationText: $durationText, ')
          ..write('viewsText: $viewsText, ')
          ..write('publishedText: $publishedText, ')
          ..write('isShort: $isShort, ')
          ..write('isLive: $isLive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    title,
    channelName,
    channelId,
    channelAvatar,
    thumbnail,
    durationText,
    viewsText,
    publishedText,
    isShort,
    isLive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Video &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.channelName == this.channelName &&
          other.channelId == this.channelId &&
          other.channelAvatar == this.channelAvatar &&
          other.thumbnail == this.thumbnail &&
          other.durationText == this.durationText &&
          other.viewsText == this.viewsText &&
          other.publishedText == this.publishedText &&
          other.isShort == this.isShort &&
          other.isLive == this.isLive);
}

class VideosCompanion extends UpdateCompanion<Video> {
  final Value<String> videoId;
  final Value<String> title;
  final Value<String?> channelName;
  final Value<String?> channelId;
  final Value<String?> channelAvatar;
  final Value<String?> thumbnail;
  final Value<String?> durationText;
  final Value<String?> viewsText;
  final Value<String?> publishedText;
  final Value<bool> isShort;
  final Value<bool> isLive;
  final Value<int> rowid;
  const VideosCompanion({
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.channelName = const Value.absent(),
    this.channelId = const Value.absent(),
    this.channelAvatar = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.durationText = const Value.absent(),
    this.viewsText = const Value.absent(),
    this.publishedText = const Value.absent(),
    this.isShort = const Value.absent(),
    this.isLive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideosCompanion.insert({
    required String videoId,
    required String title,
    this.channelName = const Value.absent(),
    this.channelId = const Value.absent(),
    this.channelAvatar = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.durationText = const Value.absent(),
    this.viewsText = const Value.absent(),
    this.publishedText = const Value.absent(),
    this.isShort = const Value.absent(),
    this.isLive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       title = Value(title);
  static Insertable<Video> custom({
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? channelName,
    Expression<String>? channelId,
    Expression<String>? channelAvatar,
    Expression<String>? thumbnail,
    Expression<String>? durationText,
    Expression<String>? viewsText,
    Expression<String>? publishedText,
    Expression<bool>? isShort,
    Expression<bool>? isLive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (channelName != null) 'channel_name': channelName,
      if (channelId != null) 'channel_id': channelId,
      if (channelAvatar != null) 'channel_avatar': channelAvatar,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (durationText != null) 'duration_text': durationText,
      if (viewsText != null) 'views_text': viewsText,
      if (publishedText != null) 'published_text': publishedText,
      if (isShort != null) 'is_short': isShort,
      if (isLive != null) 'is_live': isLive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideosCompanion copyWith({
    Value<String>? videoId,
    Value<String>? title,
    Value<String?>? channelName,
    Value<String?>? channelId,
    Value<String?>? channelAvatar,
    Value<String?>? thumbnail,
    Value<String?>? durationText,
    Value<String?>? viewsText,
    Value<String?>? publishedText,
    Value<bool>? isShort,
    Value<bool>? isLive,
    Value<int>? rowid,
  }) {
    return VideosCompanion(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      channelId: channelId ?? this.channelId,
      channelAvatar: channelAvatar ?? this.channelAvatar,
      thumbnail: thumbnail ?? this.thumbnail,
      durationText: durationText ?? this.durationText,
      viewsText: viewsText ?? this.viewsText,
      publishedText: publishedText ?? this.publishedText,
      isShort: isShort ?? this.isShort,
      isLive: isLive ?? this.isLive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (channelName.present) {
      map['channel_name'] = Variable<String>(channelName.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (channelAvatar.present) {
      map['channel_avatar'] = Variable<String>(channelAvatar.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (durationText.present) {
      map['duration_text'] = Variable<String>(durationText.value);
    }
    if (viewsText.present) {
      map['views_text'] = Variable<String>(viewsText.value);
    }
    if (publishedText.present) {
      map['published_text'] = Variable<String>(publishedText.value);
    }
    if (isShort.present) {
      map['is_short'] = Variable<bool>(isShort.value);
    }
    if (isLive.present) {
      map['is_live'] = Variable<bool>(isLive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideosCompanion(')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channelName: $channelName, ')
          ..write('channelId: $channelId, ')
          ..write('channelAvatar: $channelAvatar, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationText: $durationText, ')
          ..write('viewsText: $viewsText, ')
          ..write('publishedText: $publishedText, ')
          ..write('isShort: $isShort, ')
          ..write('isLive: $isLive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTable extends WatchHistory with TableInfo<$WatchHistoryTable, WatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES videos (video_id)'),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta('watchedAt');
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta('positionMs');
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, watchedAt, positionMs, durationMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(Insertable<WatchHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(_watchedAtMeta, watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta));
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(_positionMsMeta, positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  WatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryData(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      watchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}watched_at'])!,
      positionMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position_ms'])!,
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
    );
  }

  @override
  $WatchHistoryTable createAlias(String alias) {
    return $WatchHistoryTable(attachedDatabase, alias);
  }
}

class WatchHistoryData extends DataClass implements Insertable<WatchHistoryData> {
  final String videoId;
  final DateTime watchedAt;
  final int positionMs;
  final int durationMs;
  const WatchHistoryData({
    required this.videoId,
    required this.watchedAt,
    required this.positionMs,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      videoId: Value(videoId),
      watchedAt: Value(watchedAt),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
    );
  }

  factory WatchHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryData(
      videoId: serializer.fromJson<String>(json['videoId']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  WatchHistoryData copyWith({String? videoId, DateTime? watchedAt, int? positionMs, int? durationMs}) =>
      WatchHistoryData(
        videoId: videoId ?? this.videoId,
        watchedAt: watchedAt ?? this.watchedAt,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
      );
  WatchHistoryData copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryData(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      positionMs: data.positionMs.present ? data.positionMs.value : this.positionMs,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryData(')
          ..write('videoId: $videoId, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, watchedAt, positionMs, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryData &&
          other.videoId == this.videoId &&
          other.watchedAt == this.watchedAt &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryData> {
  final Value<String> videoId;
  final Value<DateTime> watchedAt;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<int> rowid;
  const WatchHistoryCompanion({
    this.videoId = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    required String videoId,
    required DateTime watchedAt,
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       watchedAt = Value(watchedAt);
  static Insertable<WatchHistoryData> custom({
    Expression<String>? videoId,
    Expression<DateTime>? watchedAt,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<String>? videoId,
    Value<DateTime>? watchedAt,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<int>? rowid,
  }) {
    return WatchHistoryCompanion(
      videoId: videoId ?? this.videoId,
      watchedAt: watchedAt ?? this.watchedAt,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('videoId: $videoId, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LikedVideosTable extends LikedVideos with TableInfo<$LikedVideosTable, LikedVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LikedVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES videos (video_id)'),
  );
  static const VerificationMeta _likedAtMeta = const VerificationMeta('likedAt');
  @override
  late final GeneratedColumn<DateTime> likedAt = GeneratedColumn<DateTime>(
    'liked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, likedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liked_videos';
  @override
  VerificationContext validateIntegrity(Insertable<LikedVideo> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('liked_at')) {
      context.handle(_likedAtMeta, likedAt.isAcceptableOrUnknown(data['liked_at']!, _likedAtMeta));
    } else if (isInserting) {
      context.missing(_likedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  LikedVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LikedVideo(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      likedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}liked_at'])!,
    );
  }

  @override
  $LikedVideosTable createAlias(String alias) {
    return $LikedVideosTable(attachedDatabase, alias);
  }
}

class LikedVideo extends DataClass implements Insertable<LikedVideo> {
  final String videoId;
  final DateTime likedAt;
  const LikedVideo({required this.videoId, required this.likedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['liked_at'] = Variable<DateTime>(likedAt);
    return map;
  }

  LikedVideosCompanion toCompanion(bool nullToAbsent) {
    return LikedVideosCompanion(videoId: Value(videoId), likedAt: Value(likedAt));
  }

  factory LikedVideo.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LikedVideo(
      videoId: serializer.fromJson<String>(json['videoId']),
      likedAt: serializer.fromJson<DateTime>(json['likedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'likedAt': serializer.toJson<DateTime>(likedAt),
    };
  }

  LikedVideo copyWith({String? videoId, DateTime? likedAt}) =>
      LikedVideo(videoId: videoId ?? this.videoId, likedAt: likedAt ?? this.likedAt);
  LikedVideo copyWithCompanion(LikedVideosCompanion data) {
    return LikedVideo(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      likedAt: data.likedAt.present ? data.likedAt.value : this.likedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LikedVideo(')
          ..write('videoId: $videoId, ')
          ..write('likedAt: $likedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, likedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LikedVideo && other.videoId == this.videoId && other.likedAt == this.likedAt);
}

class LikedVideosCompanion extends UpdateCompanion<LikedVideo> {
  final Value<String> videoId;
  final Value<DateTime> likedAt;
  final Value<int> rowid;
  const LikedVideosCompanion({
    this.videoId = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LikedVideosCompanion.insert({required String videoId, required DateTime likedAt, this.rowid = const Value.absent()})
    : videoId = Value(videoId),
      likedAt = Value(likedAt);
  static Insertable<LikedVideo> custom({
    Expression<String>? videoId,
    Expression<DateTime>? likedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (likedAt != null) 'liked_at': likedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LikedVideosCompanion copyWith({Value<String>? videoId, Value<DateTime>? likedAt, Value<int>? rowid}) {
    return LikedVideosCompanion(
      videoId: videoId ?? this.videoId,
      likedAt: likedAt ?? this.likedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (likedAt.present) {
      map['liked_at'] = Variable<DateTime>(likedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LikedVideosCompanion(')
          ..write('videoId: $videoId, ')
          ..write('likedAt: $likedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subscribedAtMeta = const VerificationMeta('subscribedAt');
  @override
  late final GeneratedColumn<DateTime> subscribedAt = GeneratedColumn<DateTime>(
    'subscribed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [channelId, name, avatar, subscribedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Subscription> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta, channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(_avatarMeta, avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta));
    }
    if (data.containsKey('subscribed_at')) {
      context.handle(_subscribedAtMeta, subscribedAt.isAcceptableOrUnknown(data['subscribed_at']!, _subscribedAtMeta));
    } else if (isInserting) {
      context.missing(_subscribedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      channelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatar: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}avatar']),
      subscribedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}subscribed_at'])!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String channelId;
  final String name;
  final String? avatar;
  final DateTime subscribedAt;
  const Subscription({required this.channelId, required this.name, this.avatar, required this.subscribedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    map['subscribed_at'] = Variable<DateTime>(subscribedAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      channelId: Value(channelId),
      name: Value(name),
      avatar: avatar == null && nullToAbsent ? const Value.absent() : Value(avatar),
      subscribedAt: Value(subscribedAt),
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      channelId: serializer.fromJson<String>(json['channelId']),
      name: serializer.fromJson<String>(json['name']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      subscribedAt: serializer.fromJson<DateTime>(json['subscribedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'name': serializer.toJson<String>(name),
      'avatar': serializer.toJson<String?>(avatar),
      'subscribedAt': serializer.toJson<DateTime>(subscribedAt),
    };
  }

  Subscription copyWith({
    String? channelId,
    String? name,
    Value<String?> avatar = const Value.absent(),
    DateTime? subscribedAt,
  }) => Subscription(
    channelId: channelId ?? this.channelId,
    name: name ?? this.name,
    avatar: avatar.present ? avatar.value : this.avatar,
    subscribedAt: subscribedAt ?? this.subscribedAt,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      subscribedAt: data.subscribedAt.present ? data.subscribedAt.value : this.subscribedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('channelId: $channelId, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('subscribedAt: $subscribedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(channelId, name, avatar, subscribedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.channelId == this.channelId &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.subscribedAt == this.subscribedAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> channelId;
  final Value<String> name;
  final Value<String?> avatar;
  final Value<DateTime> subscribedAt;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.channelId = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.subscribedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String channelId,
    required String name,
    this.avatar = const Value.absent(),
    required DateTime subscribedAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       name = Value(name),
       subscribedAt = Value(subscribedAt);
  static Insertable<Subscription> custom({
    Expression<String>? channelId,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<DateTime>? subscribedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (subscribedAt != null) 'subscribed_at': subscribedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? channelId,
    Value<String>? name,
    Value<String?>? avatar,
    Value<DateTime>? subscribedAt,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      subscribedAt: subscribedAt ?? this.subscribedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (subscribedAt.present) {
      map['subscribed_at'] = Variable<DateTime>(subscribedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('subscribedAt: $subscribedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedVideosTable extends FeedVideos with TableInfo<$FeedVideosTable, FeedVideoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelNameMeta = const VerificationMeta('channelName');
  @override
  late final GeneratedColumn<String> channelName = GeneratedColumn<String>(
    'channel_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta('publishedAt');
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
    'views',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isShortMeta = const VerificationMeta('isShort');
  @override
  late final GeneratedColumn<bool> isShort = GeneratedColumn<bool>(
    'is_short',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_short" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    channelId,
    channelName,
    title,
    publishedAt,
    thumbnail,
    views,
    isShort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_videos';
  @override
  VerificationContext validateIntegrity(Insertable<FeedVideoRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta, channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('channel_name')) {
      context.handle(_channelNameMeta, channelName.isAcceptableOrUnknown(data['channel_name']!, _channelNameMeta));
    } else if (isInserting) {
      context.missing(_channelNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(_publishedAtMeta, publishedAt.isAcceptableOrUnknown(data['published_at']!, _publishedAtMeta));
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta, thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    }
    if (data.containsKey('views')) {
      context.handle(_viewsMeta, views.isAcceptableOrUnknown(data['views']!, _viewsMeta));
    }
    if (data.containsKey('is_short')) {
      context.handle(_isShortMeta, isShort.isAcceptableOrUnknown(data['is_short']!, _isShortMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  FeedVideoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedVideoRow(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      channelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      channelName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_name'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      publishedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}published_at'])!,
      thumbnail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail']),
      views: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}views']),
      isShort: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_short'])!,
    );
  }

  @override
  $FeedVideosTable createAlias(String alias) {
    return $FeedVideosTable(attachedDatabase, alias);
  }
}

class FeedVideoRow extends DataClass implements Insertable<FeedVideoRow> {
  final String videoId;
  final String channelId;
  final String channelName;
  final String title;
  final DateTime publishedAt;
  final String? thumbnail;
  final int? views;
  final bool isShort;
  const FeedVideoRow({
    required this.videoId,
    required this.channelId,
    required this.channelName,
    required this.title,
    required this.publishedAt,
    this.thumbnail,
    this.views,
    required this.isShort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['channel_id'] = Variable<String>(channelId);
    map['channel_name'] = Variable<String>(channelName);
    map['title'] = Variable<String>(title);
    map['published_at'] = Variable<DateTime>(publishedAt);
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || views != null) {
      map['views'] = Variable<int>(views);
    }
    map['is_short'] = Variable<bool>(isShort);
    return map;
  }

  FeedVideosCompanion toCompanion(bool nullToAbsent) {
    return FeedVideosCompanion(
      videoId: Value(videoId),
      channelId: Value(channelId),
      channelName: Value(channelName),
      title: Value(title),
      publishedAt: Value(publishedAt),
      thumbnail: thumbnail == null && nullToAbsent ? const Value.absent() : Value(thumbnail),
      views: views == null && nullToAbsent ? const Value.absent() : Value(views),
      isShort: Value(isShort),
    );
  }

  factory FeedVideoRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedVideoRow(
      videoId: serializer.fromJson<String>(json['videoId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      channelName: serializer.fromJson<String>(json['channelName']),
      title: serializer.fromJson<String>(json['title']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      views: serializer.fromJson<int?>(json['views']),
      isShort: serializer.fromJson<bool>(json['isShort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'channelId': serializer.toJson<String>(channelId),
      'channelName': serializer.toJson<String>(channelName),
      'title': serializer.toJson<String>(title),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'views': serializer.toJson<int?>(views),
      'isShort': serializer.toJson<bool>(isShort),
    };
  }

  FeedVideoRow copyWith({
    String? videoId,
    String? channelId,
    String? channelName,
    String? title,
    DateTime? publishedAt,
    Value<String?> thumbnail = const Value.absent(),
    Value<int?> views = const Value.absent(),
    bool? isShort,
  }) => FeedVideoRow(
    videoId: videoId ?? this.videoId,
    channelId: channelId ?? this.channelId,
    channelName: channelName ?? this.channelName,
    title: title ?? this.title,
    publishedAt: publishedAt ?? this.publishedAt,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    views: views.present ? views.value : this.views,
    isShort: isShort ?? this.isShort,
  );
  FeedVideoRow copyWithCompanion(FeedVideosCompanion data) {
    return FeedVideoRow(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      channelName: data.channelName.present ? data.channelName.value : this.channelName,
      title: data.title.present ? data.title.value : this.title,
      publishedAt: data.publishedAt.present ? data.publishedAt.value : this.publishedAt,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      views: data.views.present ? data.views.value : this.views,
      isShort: data.isShort.present ? data.isShort.value : this.isShort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedVideoRow(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('channelName: $channelName, ')
          ..write('title: $title, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('views: $views, ')
          ..write('isShort: $isShort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, channelId, channelName, title, publishedAt, thumbnail, views, isShort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedVideoRow &&
          other.videoId == this.videoId &&
          other.channelId == this.channelId &&
          other.channelName == this.channelName &&
          other.title == this.title &&
          other.publishedAt == this.publishedAt &&
          other.thumbnail == this.thumbnail &&
          other.views == this.views &&
          other.isShort == this.isShort);
}

class FeedVideosCompanion extends UpdateCompanion<FeedVideoRow> {
  final Value<String> videoId;
  final Value<String> channelId;
  final Value<String> channelName;
  final Value<String> title;
  final Value<DateTime> publishedAt;
  final Value<String?> thumbnail;
  final Value<int?> views;
  final Value<bool> isShort;
  final Value<int> rowid;
  const FeedVideosCompanion({
    this.videoId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.channelName = const Value.absent(),
    this.title = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.views = const Value.absent(),
    this.isShort = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedVideosCompanion.insert({
    required String videoId,
    required String channelId,
    required String channelName,
    required String title,
    required DateTime publishedAt,
    this.thumbnail = const Value.absent(),
    this.views = const Value.absent(),
    this.isShort = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       channelId = Value(channelId),
       channelName = Value(channelName),
       title = Value(title),
       publishedAt = Value(publishedAt);
  static Insertable<FeedVideoRow> custom({
    Expression<String>? videoId,
    Expression<String>? channelId,
    Expression<String>? channelName,
    Expression<String>? title,
    Expression<DateTime>? publishedAt,
    Expression<String>? thumbnail,
    Expression<int>? views,
    Expression<bool>? isShort,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (channelId != null) 'channel_id': channelId,
      if (channelName != null) 'channel_name': channelName,
      if (title != null) 'title': title,
      if (publishedAt != null) 'published_at': publishedAt,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (views != null) 'views': views,
      if (isShort != null) 'is_short': isShort,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedVideosCompanion copyWith({
    Value<String>? videoId,
    Value<String>? channelId,
    Value<String>? channelName,
    Value<String>? title,
    Value<DateTime>? publishedAt,
    Value<String?>? thumbnail,
    Value<int?>? views,
    Value<bool>? isShort,
    Value<int>? rowid,
  }) {
    return FeedVideosCompanion(
      videoId: videoId ?? this.videoId,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      title: title ?? this.title,
      publishedAt: publishedAt ?? this.publishedAt,
      thumbnail: thumbnail ?? this.thumbnail,
      views: views ?? this.views,
      isShort: isShort ?? this.isShort,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (channelName.present) {
      map['channel_name'] = Variable<String>(channelName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (isShort.present) {
      map['is_short'] = Variable<bool>(isShort.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedVideosCompanion(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('channelName: $channelName, ')
          ..write('title: $title, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('views: $views, ')
          ..write('isShort: $isShort, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWatchLaterMeta = const VerificationMeta('isWatchLater');
  @override
  late final GeneratedColumn<bool> isWatchLater = GeneratedColumn<bool>(
    'is_watch_later',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_watch_later" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, isWatchLater];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<Playlist> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_watch_later')) {
      context.handle(_isWatchLaterMeta, isWatchLater.isAcceptableOrUnknown(data['is_watch_later']!, _isWatchLaterMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isWatchLater: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_watch_later'])!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final DateTime createdAt;
  final bool isWatchLater;
  const Playlist({required this.id, required this.name, required this.createdAt, required this.isWatchLater});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_watch_later'] = Variable<bool>(isWatchLater);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      isWatchLater: Value(isWatchLater),
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isWatchLater: serializer.fromJson<bool>(json['isWatchLater']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isWatchLater': serializer.toJson<bool>(isWatchLater),
    };
  }

  Playlist copyWith({int? id, String? name, DateTime? createdAt, bool? isWatchLater}) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    isWatchLater: isWatchLater ?? this.isWatchLater,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isWatchLater: data.isWatchLater.present ? data.isWatchLater.value : this.isWatchLater,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isWatchLater: $isWatchLater')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, isWatchLater);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.isWatchLater == this.isWatchLater);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<bool> isWatchLater;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isWatchLater = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
    this.isWatchLater = const Value.absent(),
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<bool>? isWatchLater,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (isWatchLater != null) 'is_watch_later': isWatchLater,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<bool>? isWatchLater,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isWatchLater: isWatchLater ?? this.isWatchLater,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isWatchLater.present) {
      map['is_watch_later'] = Variable<bool>(isWatchLater.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isWatchLater: $isWatchLater')
          ..write(')'))
        .toString();
  }
}

class $PlaylistItemsTable extends PlaylistItems with TableInfo<$PlaylistItemsTable, PlaylistEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES playlists (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES videos (video_id)'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, playlistId, videoId, position, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_items';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistEntryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(_playlistIdMeta, playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntryRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $PlaylistItemsTable createAlias(String alias) {
    return $PlaylistItemsTable(attachedDatabase, alias);
  }
}

class PlaylistEntryRow extends DataClass implements Insertable<PlaylistEntryRow> {
  final int id;
  final int playlistId;
  final String videoId;
  final int position;
  final DateTime addedAt;
  const PlaylistEntryRow({
    required this.id,
    required this.playlistId,
    required this.videoId,
    required this.position,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['video_id'] = Variable<String>(videoId);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistItemsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      videoId: Value(videoId),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistEntryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntryRow(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      videoId: serializer.fromJson<String>(json['videoId']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'videoId': serializer.toJson<String>(videoId),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistEntryRow copyWith({int? id, int? playlistId, String? videoId, int? position, DateTime? addedAt}) =>
      PlaylistEntryRow(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        videoId: videoId ?? this.videoId,
        position: position ?? this.position,
        addedAt: addedAt ?? this.addedAt,
      );
  PlaylistEntryRow copyWithCompanion(PlaylistItemsCompanion data) {
    return PlaylistEntryRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present ? data.playlistId.value : this.playlistId,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, videoId, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntryRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.videoId == this.videoId &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistItemsCompanion extends UpdateCompanion<PlaylistEntryRow> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> videoId;
  final Value<int> position;
  final Value<DateTime> addedAt;
  const PlaylistItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.videoId = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  PlaylistItemsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String videoId,
    required int position,
    required DateTime addedAt,
  }) : playlistId = Value(playlistId),
       videoId = Value(videoId),
       position = Value(position),
       addedAt = Value(addedAt);
  static Insertable<PlaylistEntryRow> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? videoId,
    Expression<int>? position,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (videoId != null) 'video_id': videoId,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  PlaylistItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? playlistId,
    Value<String>? videoId,
    Value<int>? position,
    Value<DateTime>? addedAt,
  }) {
    return PlaylistItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      videoId: videoId ?? this.videoId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('videoId: $videoId, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedPlaylistsTable extends SavedPlaylists with TableInfo<$SavedPlaylistsTable, SavedPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countTextMeta = const VerificationMeta('countText');
  @override
  late final GeneratedColumn<String> countText = GeneratedColumn<String>(
    'count_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, title, owner, thumbnail, countText, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<SavedPlaylist> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(_playlistIdMeta, playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(_ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta, thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    }
    if (data.containsKey('count_text')) {
      context.handle(_countTextMeta, countText.isAcceptableOrUnknown(data['count_text']!, _countTextMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta, savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId};
  @override
  SavedPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlaylist(
      playlistId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      owner: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}owner']),
      thumbnail: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}thumbnail']),
      countText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}count_text']),
      savedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedPlaylistsTable createAlias(String alias) {
    return $SavedPlaylistsTable(attachedDatabase, alias);
  }
}

class SavedPlaylist extends DataClass implements Insertable<SavedPlaylist> {
  final String playlistId;
  final String title;
  final String? owner;
  final String? thumbnail;
  final String? countText;
  final DateTime savedAt;
  const SavedPlaylist({
    required this.playlistId,
    required this.title,
    this.owner,
    this.thumbnail,
    this.countText,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || owner != null) {
      map['owner'] = Variable<String>(owner);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || countText != null) {
      map['count_text'] = Variable<String>(countText);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SavedPlaylistsCompanion(
      playlistId: Value(playlistId),
      title: Value(title),
      owner: owner == null && nullToAbsent ? const Value.absent() : Value(owner),
      thumbnail: thumbnail == null && nullToAbsent ? const Value.absent() : Value(thumbnail),
      countText: countText == null && nullToAbsent ? const Value.absent() : Value(countText),
      savedAt: Value(savedAt),
    );
  }

  factory SavedPlaylist.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlaylist(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      title: serializer.fromJson<String>(json['title']),
      owner: serializer.fromJson<String?>(json['owner']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      countText: serializer.fromJson<String?>(json['countText']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'title': serializer.toJson<String>(title),
      'owner': serializer.toJson<String?>(owner),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'countText': serializer.toJson<String?>(countText),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedPlaylist copyWith({
    String? playlistId,
    String? title,
    Value<String?> owner = const Value.absent(),
    Value<String?> thumbnail = const Value.absent(),
    Value<String?> countText = const Value.absent(),
    DateTime? savedAt,
  }) => SavedPlaylist(
    playlistId: playlistId ?? this.playlistId,
    title: title ?? this.title,
    owner: owner.present ? owner.value : this.owner,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    countText: countText.present ? countText.value : this.countText,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedPlaylist copyWithCompanion(SavedPlaylistsCompanion data) {
    return SavedPlaylist(
      playlistId: data.playlistId.present ? data.playlistId.value : this.playlistId,
      title: data.title.present ? data.title.value : this.title,
      owner: data.owner.present ? data.owner.value : this.owner,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      countText: data.countText.present ? data.countText.value : this.countText,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylist(')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('owner: $owner, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('countText: $countText, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, title, owner, thumbnail, countText, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlaylist &&
          other.playlistId == this.playlistId &&
          other.title == this.title &&
          other.owner == this.owner &&
          other.thumbnail == this.thumbnail &&
          other.countText == this.countText &&
          other.savedAt == this.savedAt);
}

class SavedPlaylistsCompanion extends UpdateCompanion<SavedPlaylist> {
  final Value<String> playlistId;
  final Value<String> title;
  final Value<String?> owner;
  final Value<String?> thumbnail;
  final Value<String?> countText;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedPlaylistsCompanion({
    this.playlistId = const Value.absent(),
    this.title = const Value.absent(),
    this.owner = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.countText = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedPlaylistsCompanion.insert({
    required String playlistId,
    required String title,
    this.owner = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.countText = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       title = Value(title),
       savedAt = Value(savedAt);
  static Insertable<SavedPlaylist> custom({
    Expression<String>? playlistId,
    Expression<String>? title,
    Expression<String>? owner,
    Expression<String>? thumbnail,
    Expression<String>? countText,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (title != null) 'title': title,
      if (owner != null) 'owner': owner,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (countText != null) 'count_text': countText,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedPlaylistsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? title,
    Value<String?>? owner,
    Value<String?>? thumbnail,
    Value<String?>? countText,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedPlaylistsCompanion(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      thumbnail: thumbnail ?? this.thumbnail,
      countText: countText ?? this.countText,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (countText.present) {
      map['count_text'] = Variable<String>(countText.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylistsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('title: $title, ')
          ..write('owner: $owner, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('countText: $countText, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta('searchedAt');
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(Insertable<SearchHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(_queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(_searchedAtMeta, searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta));
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      query: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      searchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}searched_at'])!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass implements Insertable<SearchHistoryData> {
  final String query;
  final DateTime searchedAt;
  const SearchHistoryData({required this.query, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['searched_at'] = Variable<DateTime>(searchedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(query: Value(query), searchedAt: Value(searchedAt));
  }

  factory SearchHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      query: serializer.fromJson<String>(json['query']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
    };
  }

  SearchHistoryData copyWith({String? query, DateTime? searchedAt}) =>
      SearchHistoryData(query: query ?? this.query, searchedAt: searchedAt ?? this.searchedAt);
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      query: data.query.present ? data.query.value : this.query,
      searchedAt: data.searchedAt.present ? data.searchedAt.value : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData && other.query == this.query && other.searchedAt == this.searchedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<String> query;
  final Value<DateTime> searchedAt;
  final Value<int> rowid;
  const SearchHistoryCompanion({
    this.query = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    required String query,
    required DateTime searchedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       searchedAt = Value(searchedAt);
  static Insertable<SearchHistoryData> custom({
    Expression<String>? query,
    Expression<DateTime>? searchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryCompanion copyWith({Value<String>? query, Value<DateTime>? searchedAt, Value<int>? rowid}) {
    return SearchHistoryCompanion(
      query: query ?? this.query,
      searchedAt: searchedAt ?? this.searchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES videos (video_id)'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState, int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<DownloadState>($DownloadsTable.$converterstate);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, state, height, path, sizeBytes, downloadedBytes, error, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta, height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(data['downloaded_bytes']!, _downloadedBytesMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(_errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      state: $DownloadsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}state'])!,
      ),
      height: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path']),
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      downloadedBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      error: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error']),
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadState, int, int> $converterstate = const EnumIndexConverter<DownloadState>(
    DownloadState.values,
  );
}

class Download extends DataClass implements Insertable<Download> {
  final String videoId;
  final DownloadState state;

  /// The quality asked for; after downloading, the one actually saved.
  final int height;
  final String? path;
  final int sizeBytes;
  final int downloadedBytes;
  final String? error;
  final DateTime addedAt;
  const Download({
    required this.videoId,
    required this.state,
    required this.height,
    this.path,
    required this.sizeBytes,
    required this.downloadedBytes,
    this.error,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    {
      map['state'] = Variable<int>($DownloadsTable.$converterstate.toSql(state));
    }
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String>(path);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      videoId: Value(videoId),
      state: Value(state),
      height: Value(height),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      sizeBytes: Value(sizeBytes),
      downloadedBytes: Value(downloadedBytes),
      error: error == null && nullToAbsent ? const Value.absent() : Value(error),
      addedAt: Value(addedAt),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      videoId: serializer.fromJson<String>(json['videoId']),
      state: $DownloadsTable.$converterstate.fromJson(serializer.fromJson<int>(json['state'])),
      height: serializer.fromJson<int>(json['height']),
      path: serializer.fromJson<String?>(json['path']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      error: serializer.fromJson<String?>(json['error']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'state': serializer.toJson<int>($DownloadsTable.$converterstate.toJson(state)),
      'height': serializer.toJson<int>(height),
      'path': serializer.toJson<String?>(path),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'error': serializer.toJson<String?>(error),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Download copyWith({
    String? videoId,
    DownloadState? state,
    int? height,
    Value<String?> path = const Value.absent(),
    int? sizeBytes,
    int? downloadedBytes,
    Value<String?> error = const Value.absent(),
    DateTime? addedAt,
  }) => Download(
    videoId: videoId ?? this.videoId,
    state: state ?? this.state,
    height: height ?? this.height,
    path: path.present ? path.value : this.path,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    error: error.present ? error.value : this.error,
    addedAt: addedAt ?? this.addedAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      state: data.state.present ? data.state.value : this.state,
      height: data.height.present ? data.height.value : this.height,
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      downloadedBytes: data.downloadedBytes.present ? data.downloadedBytes.value : this.downloadedBytes,
      error: data.error.present ? data.error.value : this.error,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('videoId: $videoId, ')
          ..write('state: $state, ')
          ..write('height: $height, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('error: $error, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, state, height, path, sizeBytes, downloadedBytes, error, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.videoId == this.videoId &&
          other.state == this.state &&
          other.height == this.height &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.error == this.error &&
          other.addedAt == this.addedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> videoId;
  final Value<DownloadState> state;
  final Value<int> height;
  final Value<String?> path;
  final Value<int> sizeBytes;
  final Value<int> downloadedBytes;
  final Value<String?> error;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.videoId = const Value.absent(),
    this.state = const Value.absent(),
    this.height = const Value.absent(),
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String videoId,
    required DownloadState state,
    required int height,
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.error = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       state = Value(state),
       height = Value(height),
       addedAt = Value(addedAt);
  static Insertable<Download> custom({
    Expression<String>? videoId,
    Expression<int>? state,
    Expression<int>? height,
    Expression<String>? path,
    Expression<int>? sizeBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? error,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (state != null) 'state': state,
      if (height != null) 'height': height,
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (error != null) 'error': error,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? videoId,
    Value<DownloadState>? state,
    Value<int>? height,
    Value<String?>? path,
    Value<int>? sizeBytes,
    Value<int>? downloadedBytes,
    Value<String?>? error,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      videoId: videoId ?? this.videoId,
      state: state ?? this.state,
      height: height ?? this.height,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      error: error ?? this.error,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>($DownloadsTable.$converterstate.toSql(state.value));
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('videoId: $videoId, ')
          ..write('state: $state, ')
          ..write('height: $height, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('error: $error, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $WatchHistoryTable watchHistory = $WatchHistoryTable(this);
  late final $LikedVideosTable likedVideos = $LikedVideosTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $FeedVideosTable feedVideos = $FeedVideosTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistItemsTable playlistItems = $PlaylistItemsTable(this);
  late final $SavedPlaylistsTable savedPlaylists = $SavedPlaylistsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    videos,
    watchHistory,
    likedVideos,
    subscriptions,
    feedVideos,
    playlists,
    playlistItems,
    savedPlaylists,
    searchHistory,
    downloads,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('playlists', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('playlist_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$VideosTableCreateCompanionBuilder = VideosCompanion Function({
  required String videoId,
  required String title,
  Value<String?> channelName,
  Value<String?> channelId,
  Value<String?> channelAvatar,
  Value<String?> thumbnail,
  Value<String?> durationText,
  Value<String?> viewsText,
  Value<String?> publishedText,
  Value<bool> isShort,
  Value<bool> isLive,
  Value<int> rowid,
});
typedef $$VideosTableUpdateCompanionBuilder = VideosCompanion Function({
  Value<String> videoId,
  Value<String> title,
  Value<String?> channelName,
  Value<String?> channelId,
  Value<String?> channelAvatar,
  Value<String?> thumbnail,
  Value<String?> durationText,
  Value<String?> viewsText,
  Value<String?> publishedText,
  Value<bool> isShort,
  Value<bool> isLive,
  Value<int> rowid,
});

final class $$VideosTableReferences extends BaseReferences<_$AppDatabase, $VideosTable, Video> {
  $$VideosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WatchHistoryTable, List<WatchHistoryData>> _watchHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.watchHistory, aliasName: 'videos__video_id__watch_history__video_id');

  $$WatchHistoryTableProcessedTableManager get watchHistoryRefs {
    final manager = $$WatchHistoryTableTableManager(
      $_db,
      $_db.watchHistory,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_watchHistoryRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LikedVideosTable, List<LikedVideo>> _likedVideosRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.likedVideos, aliasName: 'videos__video_id__liked_videos__video_id');

  $$LikedVideosTableProcessedTableManager get likedVideosRefs {
    final manager = $$LikedVideosTableTableManager(
      $_db,
      $_db.likedVideos,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_likedVideosRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistEntryRow>> _playlistItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.playlistItems, aliasName: 'videos__video_id__playlist_items__video_id');

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DownloadsTable, List<Download>> _downloadsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.downloads, aliasName: 'videos__video_id__downloads__video_id');

  $$DownloadsTableProcessedTableManager get downloadsRefs {
    final manager = $$DownloadsTableTableManager(
      $_db,
      $_db.downloads,
    ).filter((f) => f.videoId.videoId.sqlEquals($_itemColumn<String>('video_id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VideosTableFilterComposer extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelAvatar =>
      $composableBuilder(column: $table.channelAvatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get durationText =>
      $composableBuilder(column: $table.durationText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get viewsText =>
      $composableBuilder(column: $table.viewsText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publishedText =>
      $composableBuilder(column: $table.publishedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isShort =>
      $composableBuilder(column: $table.isShort, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLive =>
      $composableBuilder(column: $table.isLive, builder: (column) => ColumnFilters(column));

  Expression<bool> watchHistoryRefs(Expression<bool> Function($$WatchHistoryTableFilterComposer f) f) {
    final $$WatchHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WatchHistoryTableFilterComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> likedVideosRefs(Expression<bool> Function($$LikedVideosTableFilterComposer f) f) {
    final $$LikedVideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.likedVideos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LikedVideosTableFilterComposer(
            $db: $db,
            $table: $db.likedVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistItemsRefs(Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadsRefs(Expression<bool> Function($$DownloadsTableFilterComposer f) f) {
    final $$DownloadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$DownloadsTableFilterComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VideosTableOrderingComposer extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelAvatar =>
      $composableBuilder(column: $table.channelAvatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get durationText =>
      $composableBuilder(column: $table.durationText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get viewsText =>
      $composableBuilder(column: $table.viewsText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publishedText =>
      $composableBuilder(column: $table.publishedText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isShort =>
      $composableBuilder(column: $table.isShort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLive =>
      $composableBuilder(column: $table.isLive, builder: (column) => ColumnOrderings(column));
}

class $$VideosTableAnnotationComposer extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId => $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => column);

  GeneratedColumn<String> get channelId => $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get channelAvatar =>
      $composableBuilder(column: $table.channelAvatar, builder: (column) => column);

  GeneratedColumn<String> get thumbnail => $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<String> get durationText =>
      $composableBuilder(column: $table.durationText, builder: (column) => column);

  GeneratedColumn<String> get viewsText => $composableBuilder(column: $table.viewsText, builder: (column) => column);

  GeneratedColumn<String> get publishedText =>
      $composableBuilder(column: $table.publishedText, builder: (column) => column);

  GeneratedColumn<bool> get isShort => $composableBuilder(column: $table.isShort, builder: (column) => column);

  GeneratedColumn<bool> get isLive => $composableBuilder(column: $table.isLive, builder: (column) => column);

  Expression<T> watchHistoryRefs<T extends Object>(Expression<T> Function($$WatchHistoryTableAnnotationComposer a) f) {
    final $$WatchHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WatchHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> likedVideosRefs<T extends Object>(Expression<T> Function($$LikedVideosTableAnnotationComposer a) f) {
    final $$LikedVideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.likedVideos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LikedVideosTableAnnotationComposer(
            $db: $db,
            $table: $db.likedVideos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(Expression<T> Function($$DownloadsTableAnnotationComposer a) f) {
    final $$DownloadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$DownloadsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideosTable,
          Video,
          $$VideosTableFilterComposer,
          $$VideosTableOrderingComposer,
          $$VideosTableAnnotationComposer,
          $$VideosTableCreateCompanionBuilder,
          $$VideosTableUpdateCompanionBuilder,
          (Video, $$VideosTableReferences),
          Video,
          PrefetchHooks Function({
            bool watchHistoryRefs,
            bool likedVideosRefs,
            bool playlistItemsRefs,
            bool downloadsRefs,
          })
        > {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> channelName = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> channelAvatar = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> durationText = const Value.absent(),
                Value<String?> viewsText = const Value.absent(),
                Value<String?> publishedText = const Value.absent(),
                Value<bool> isShort = const Value.absent(),
                Value<bool> isLive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion(
                videoId: videoId,
                title: title,
                channelName: channelName,
                channelId: channelId,
                channelAvatar: channelAvatar,
                thumbnail: thumbnail,
                durationText: durationText,
                viewsText: viewsText,
                publishedText: publishedText,
                isShort: isShort,
                isLive: isLive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String title,
                Value<String?> channelName = const Value.absent(),
                Value<String?> channelId = const Value.absent(),
                Value<String?> channelAvatar = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> durationText = const Value.absent(),
                Value<String?> viewsText = const Value.absent(),
                Value<String?> publishedText = const Value.absent(),
                Value<bool> isShort = const Value.absent(),
                Value<bool> isLive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideosCompanion.insert(
                videoId: videoId,
                title: title,
                channelName: channelName,
                channelId: channelId,
                channelAvatar: channelAvatar,
                thumbnail: thumbnail,
                durationText: durationText,
                viewsText: viewsText,
                publishedText: publishedText,
                isShort: isShort,
                isLive: isLive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$VideosTable, Video>(table), $$VideosTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({watchHistoryRefs = false, likedVideosRefs = false, playlistItemsRefs = false, downloadsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (watchHistoryRefs) db.watchHistory,
                    if (likedVideosRefs) db.likedVideos,
                    if (playlistItemsRefs) db.playlistItems,
                    if (downloadsRefs) db.downloads,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (watchHistoryRefs)
                        await $_getPrefetchedData<Video, $VideosTable, WatchHistoryData>(
                          currentTable: table,
                          referencedTable: $$VideosTableReferences._watchHistoryRefsTable(db),
                          managerFromTypedResult: (p0) => $$VideosTableReferences(db, table, p0).watchHistoryRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (likedVideosRefs)
                        await $_getPrefetchedData<Video, $VideosTable, LikedVideo>(
                          currentTable: table,
                          referencedTable: $$VideosTableReferences._likedVideosRefsTable(db),
                          managerFromTypedResult: (p0) => $$VideosTableReferences(db, table, p0).likedVideosRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (playlistItemsRefs)
                        await $_getPrefetchedData<Video, $VideosTable, PlaylistEntryRow>(
                          currentTable: table,
                          referencedTable: $$VideosTableReferences._playlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) => $$VideosTableReferences(db, table, p0).playlistItemsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                      if (downloadsRefs)
                        await $_getPrefetchedData<Video, $VideosTable, Download>(
                          currentTable: table,
                          referencedTable: $$VideosTableReferences._downloadsRefsTable(db),
                          managerFromTypedResult: (p0) => $$VideosTableReferences(db, table, p0).downloadsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.videoId == item.videoId),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideosTable,
      Video,
      $$VideosTableFilterComposer,
      $$VideosTableOrderingComposer,
      $$VideosTableAnnotationComposer,
      $$VideosTableCreateCompanionBuilder,
      $$VideosTableUpdateCompanionBuilder,
      (Video, $$VideosTableReferences),
      Video,
      PrefetchHooks Function({bool watchHistoryRefs, bool likedVideosRefs, bool playlistItemsRefs, bool downloadsRefs})
    >;
typedef $$WatchHistoryTableCreateCompanionBuilder = WatchHistoryCompanion Function({
  required String videoId,
  required DateTime watchedAt,
  Value<int> positionMs,
  Value<int> durationMs,
  Value<int> rowid,
});
typedef $$WatchHistoryTableUpdateCompanionBuilder = WatchHistoryCompanion Function({
  Value<String> videoId,
  Value<DateTime> watchedAt,
  Value<int> positionMs,
  Value<int> durationMs,
  Value<int> rowid,
});

final class $$WatchHistoryTableReferences extends BaseReferences<_$AppDatabase, $WatchHistoryTable, WatchHistoryData> {
  $$WatchHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VideosTable _videoIdTable(_$AppDatabase db) =>
      db.videos.createAlias('watch_history__video_id__videos__video_id');

  $$VideosTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$VideosTableTableManager($_db, $_db.videos).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WatchHistoryTableFilterComposer extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionMs =>
      $composableBuilder(column: $table.positionMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  $$VideosTableFilterComposer get videoId {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableOrderingComposer extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionMs =>
      $composableBuilder(column: $table.positionMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  $$VideosTableOrderingComposer get videoId {
    final $$VideosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableOrderingComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableAnnotationComposer extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get watchedAt => $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(column: $table.positionMs, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  $$VideosTableAnnotationComposer get videoId {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoryTable,
          WatchHistoryData,
          $$WatchHistoryTableFilterComposer,
          $$WatchHistoryTableOrderingComposer,
          $$WatchHistoryTableAnnotationComposer,
          $$WatchHistoryTableCreateCompanionBuilder,
          $$WatchHistoryTableUpdateCompanionBuilder,
          (WatchHistoryData, $$WatchHistoryTableReferences),
          WatchHistoryData,
          PrefetchHooks Function({bool videoId})
        > {
  $$WatchHistoryTableTableManager(_$AppDatabase db, $WatchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchHistoryCompanion(
                videoId: videoId,
                watchedAt: watchedAt,
                positionMs: positionMs,
                durationMs: durationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required DateTime watchedAt,
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchHistoryCompanion.insert(
                videoId: videoId,
                watchedAt: watchedAt,
                positionMs: positionMs,
                durationMs: durationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchHistoryTable, WatchHistoryData>(table),
                  $$WatchHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$WatchHistoryTableReferences._videoIdTable(db),
                        referencedColumn: $$WatchHistoryTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoryTable,
      WatchHistoryData,
      $$WatchHistoryTableFilterComposer,
      $$WatchHistoryTableOrderingComposer,
      $$WatchHistoryTableAnnotationComposer,
      $$WatchHistoryTableCreateCompanionBuilder,
      $$WatchHistoryTableUpdateCompanionBuilder,
      (WatchHistoryData, $$WatchHistoryTableReferences),
      WatchHistoryData,
      PrefetchHooks Function({bool videoId})
    >;
typedef $$LikedVideosTableCreateCompanionBuilder = LikedVideosCompanion Function({
  required String videoId,
  required DateTime likedAt,
  Value<int> rowid,
});
typedef $$LikedVideosTableUpdateCompanionBuilder = LikedVideosCompanion Function({
  Value<String> videoId,
  Value<DateTime> likedAt,
  Value<int> rowid,
});

final class $$LikedVideosTableReferences extends BaseReferences<_$AppDatabase, $LikedVideosTable, LikedVideo> {
  $$LikedVideosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VideosTable _videoIdTable(_$AppDatabase db) =>
      db.videos.createAlias('liked_videos__video_id__videos__video_id');

  $$VideosTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$VideosTableTableManager($_db, $_db.videos).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LikedVideosTableFilterComposer extends Composer<_$AppDatabase, $LikedVideosTable> {
  $$LikedVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => ColumnFilters(column));

  $$VideosTableFilterComposer get videoId {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedVideosTableOrderingComposer extends Composer<_$AppDatabase, $LikedVideosTable> {
  $$LikedVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => ColumnOrderings(column));

  $$VideosTableOrderingComposer get videoId {
    final $$VideosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableOrderingComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedVideosTableAnnotationComposer extends Composer<_$AppDatabase, $LikedVideosTable> {
  $$LikedVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get likedAt => $composableBuilder(column: $table.likedAt, builder: (column) => column);

  $$VideosTableAnnotationComposer get videoId {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LikedVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LikedVideosTable,
          LikedVideo,
          $$LikedVideosTableFilterComposer,
          $$LikedVideosTableOrderingComposer,
          $$LikedVideosTableAnnotationComposer,
          $$LikedVideosTableCreateCompanionBuilder,
          $$LikedVideosTableUpdateCompanionBuilder,
          (LikedVideo, $$LikedVideosTableReferences),
          LikedVideo,
          PrefetchHooks Function({bool videoId})
        > {
  $$LikedVideosTableTableManager(_$AppDatabase db, $LikedVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LikedVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LikedVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LikedVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> videoId = const Value.absent(),
            Value<DateTime> likedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LikedVideosCompanion(videoId: videoId, likedAt: likedAt, rowid: rowid),
          createCompanionCallback: ({
            required String videoId,
            required DateTime likedAt,
            Value<int> rowid = const Value.absent(),
          }) => LikedVideosCompanion.insert(videoId: videoId, likedAt: likedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$LikedVideosTable, LikedVideo>(table), $$LikedVideosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$LikedVideosTableReferences._videoIdTable(db),
                        referencedColumn: $$LikedVideosTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LikedVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LikedVideosTable,
      LikedVideo,
      $$LikedVideosTableFilterComposer,
      $$LikedVideosTableOrderingComposer,
      $$LikedVideosTableAnnotationComposer,
      $$LikedVideosTableCreateCompanionBuilder,
      $$LikedVideosTableUpdateCompanionBuilder,
      (LikedVideo, $$LikedVideosTableReferences),
      LikedVideo,
      PrefetchHooks Function({bool videoId})
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder = SubscriptionsCompanion Function({
  required String channelId,
  required String name,
  Value<String?> avatar,
  required DateTime subscribedAt,
  Value<int> rowid,
});
typedef $$SubscriptionsTableUpdateCompanionBuilder = SubscriptionsCompanion Function({
  Value<String> channelId,
  Value<String> name,
  Value<String?> avatar,
  Value<DateTime> subscribedAt,
  Value<int> rowid,
});

class $$SubscriptionsTableFilterComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get subscribedAt =>
      $composableBuilder(column: $table.subscribedAt, builder: (column) => ColumnFilters(column));
}

class $$SubscriptionsTableOrderingComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get subscribedAt =>
      $composableBuilder(column: $table.subscribedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubscriptionsTableAnnotationComposer extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId => $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar => $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<DateTime> get subscribedAt =>
      $composableBuilder(column: $table.subscribedAt, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (Subscription, BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<DateTime> subscribedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                channelId: channelId,
                name: name,
                avatar: avatar,
                subscribedAt: subscribedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String name,
                Value<String?> avatar = const Value.absent(),
                required DateTime subscribedAt,
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                channelId: channelId,
                name: name,
                avatar: avatar,
                subscribedAt: subscribedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionsTable, Subscription>(table),
                  BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (Subscription, BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>),
      Subscription,
      PrefetchHooks Function()
    >;
typedef $$FeedVideosTableCreateCompanionBuilder = FeedVideosCompanion Function({
  required String videoId,
  required String channelId,
  required String channelName,
  required String title,
  required DateTime publishedAt,
  Value<String?> thumbnail,
  Value<int?> views,
  Value<bool> isShort,
  Value<int> rowid,
});
typedef $$FeedVideosTableUpdateCompanionBuilder = FeedVideosCompanion Function({
  Value<String> videoId,
  Value<String> channelId,
  Value<String> channelName,
  Value<String> title,
  Value<DateTime> publishedAt,
  Value<String?> thumbnail,
  Value<int?> views,
  Value<bool> isShort,
  Value<int> rowid,
});

class $$FeedVideosTableFilterComposer extends Composer<_$AppDatabase, $FeedVideosTable> {
  $$FeedVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get publishedAt =>
      $composableBuilder(column: $table.publishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get views => $composableBuilder(column: $table.views, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isShort =>
      $composableBuilder(column: $table.isShort, builder: (column) => ColumnFilters(column));
}

class $$FeedVideosTableOrderingComposer extends Composer<_$AppDatabase, $FeedVideosTable> {
  $$FeedVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get publishedAt =>
      $composableBuilder(column: $table.publishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get views =>
      $composableBuilder(column: $table.views, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isShort =>
      $composableBuilder(column: $table.isShort, builder: (column) => ColumnOrderings(column));
}

class $$FeedVideosTableAnnotationComposer extends Composer<_$AppDatabase, $FeedVideosTable> {
  $$FeedVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId => $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get channelId => $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get channelName =>
      $composableBuilder(column: $table.channelName, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt =>
      $composableBuilder(column: $table.publishedAt, builder: (column) => column);

  GeneratedColumn<String> get thumbnail => $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<int> get views => $composableBuilder(column: $table.views, builder: (column) => column);

  GeneratedColumn<bool> get isShort => $composableBuilder(column: $table.isShort, builder: (column) => column);
}

class $$FeedVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedVideosTable,
          FeedVideoRow,
          $$FeedVideosTableFilterComposer,
          $$FeedVideosTableOrderingComposer,
          $$FeedVideosTableAnnotationComposer,
          $$FeedVideosTableCreateCompanionBuilder,
          $$FeedVideosTableUpdateCompanionBuilder,
          (FeedVideoRow, BaseReferences<_$AppDatabase, $FeedVideosTable, FeedVideoRow>),
          FeedVideoRow,
          PrefetchHooks Function()
        > {
  $$FeedVideosTableTableManager(_$AppDatabase db, $FeedVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FeedVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FeedVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FeedVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> channelName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> views = const Value.absent(),
                Value<bool> isShort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedVideosCompanion(
                videoId: videoId,
                channelId: channelId,
                channelName: channelName,
                title: title,
                publishedAt: publishedAt,
                thumbnail: thumbnail,
                views: views,
                isShort: isShort,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String channelId,
                required String channelName,
                required String title,
                required DateTime publishedAt,
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> views = const Value.absent(),
                Value<bool> isShort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedVideosCompanion.insert(
                videoId: videoId,
                channelId: channelId,
                channelName: channelName,
                title: title,
                publishedAt: publishedAt,
                thumbnail: thumbnail,
                views: views,
                isShort: isShort,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedVideosTable, FeedVideoRow>(table),
                  BaseReferences<_$AppDatabase, $FeedVideosTable, FeedVideoRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedVideosTable,
      FeedVideoRow,
      $$FeedVideosTableFilterComposer,
      $$FeedVideosTableOrderingComposer,
      $$FeedVideosTableAnnotationComposer,
      $$FeedVideosTableCreateCompanionBuilder,
      $$FeedVideosTableUpdateCompanionBuilder,
      (FeedVideoRow, BaseReferences<_$AppDatabase, $FeedVideosTable, FeedVideoRow>),
      FeedVideoRow,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required DateTime createdAt,
  Value<bool> isWatchLater,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<bool> isWatchLater,
});

final class $$PlaylistsTableReferences extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistEntryRow>> _playlistItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.playlistItems, aliasName: 'playlists__id__playlist_items__playlist_id');

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlaylistsTableFilterComposer extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWatchLater =>
      $composableBuilder(column: $table.isWatchLater, builder: (column) => ColumnFilters(column));

  Expression<bool> playlistItemsRefs(Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWatchLater =>
      $composableBuilder(column: $table.isWatchLater, builder: (column) => ColumnOrderings(column));
}

class $$PlaylistsTableAnnotationComposer extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isWatchLater =>
      $composableBuilder(column: $table.isWatchLater, builder: (column) => column);

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistItemsRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isWatchLater = const Value.absent(),
          }) => PlaylistsCompanion(id: id, name: name, createdAt: createdAt, isWatchLater: isWatchLater),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required DateTime createdAt,
            Value<bool> isWatchLater = const Value.absent(),
          }) => PlaylistsCompanion.insert(id: id, name: name, createdAt: createdAt, isWatchLater: isWatchLater),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$PlaylistsTable, Playlist>(table), $$PlaylistsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({playlistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (playlistItemsRefs) db.playlistItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistItemsRefs)
                    await $_getPrefetchedData<Playlist, $PlaylistsTable, PlaylistEntryRow>(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences._playlistItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PlaylistsTableReferences(db, table, p0).playlistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistItemsRefs})
    >;
typedef $$PlaylistItemsTableCreateCompanionBuilder = PlaylistItemsCompanion Function({
  Value<int> id,
  required int playlistId,
  required String videoId,
  required int position,
  required DateTime addedAt,
});
typedef $$PlaylistItemsTableUpdateCompanionBuilder = PlaylistItemsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> videoId,
  Value<int> position,
  Value<DateTime> addedAt,
});

final class $$PlaylistItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistItemsTable, PlaylistEntryRow> {
  $$PlaylistItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_items__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $VideosTable _videoIdTable(_$AppDatabase db) =>
      db.videos.createAlias('playlist_items__video_id__videos__video_id');

  $$VideosTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$VideosTableTableManager($_db, $_db.videos).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaylistItemsTableFilterComposer extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VideosTableFilterComposer get videoId {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableOrderingComposer extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VideosTableOrderingComposer get videoId {
    final $$VideosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableOrderingComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableAnnotationComposer extends Composer<_$AppDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VideosTableAnnotationComposer get videoId {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistItemsTable,
          PlaylistEntryRow,
          $$PlaylistItemsTableFilterComposer,
          $$PlaylistItemsTableOrderingComposer,
          $$PlaylistItemsTableAnnotationComposer,
          $$PlaylistItemsTableCreateCompanionBuilder,
          $$PlaylistItemsTableUpdateCompanionBuilder,
          (PlaylistEntryRow, $$PlaylistItemsTableReferences),
          PlaylistEntryRow,
          PrefetchHooks Function({bool playlistId, bool videoId})
        > {
  $$PlaylistItemsTableTableManager(_$AppDatabase db, $PlaylistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PlaylistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PlaylistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PlaylistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlistId = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => PlaylistItemsCompanion(
                id: id,
                playlistId: playlistId,
                videoId: videoId,
                position: position,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlistId,
                required String videoId,
                required int position,
                required DateTime addedAt,
              }) => PlaylistItemsCompanion.insert(
                id: id,
                playlistId: playlistId,
                videoId: videoId,
                position: position,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistItemsTable, PlaylistEntryRow>(table),
                  $$PlaylistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistItemsTableReferences._playlistIdTable(db),
                        referencedColumn: $$PlaylistItemsTableReferences._playlistIdTable(db).id,
                      ) as T;
                    }
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$PlaylistItemsTableReferences._videoIdTable(db),
                        referencedColumn: $$PlaylistItemsTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistItemsTable,
      PlaylistEntryRow,
      $$PlaylistItemsTableFilterComposer,
      $$PlaylistItemsTableOrderingComposer,
      $$PlaylistItemsTableAnnotationComposer,
      $$PlaylistItemsTableCreateCompanionBuilder,
      $$PlaylistItemsTableUpdateCompanionBuilder,
      (PlaylistEntryRow, $$PlaylistItemsTableReferences),
      PlaylistEntryRow,
      PrefetchHooks Function({bool playlistId, bool videoId})
    >;
typedef $$SavedPlaylistsTableCreateCompanionBuilder = SavedPlaylistsCompanion Function({
  required String playlistId,
  required String title,
  Value<String?> owner,
  Value<String?> thumbnail,
  Value<String?> countText,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedPlaylistsTableUpdateCompanionBuilder = SavedPlaylistsCompanion Function({
  Value<String> playlistId,
  Value<String> title,
  Value<String?> owner,
  Value<String?> thumbnail,
  Value<String?> countText,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedPlaylistsTableFilterComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get countText =>
      $composableBuilder(column: $table.countText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedPlaylistsTableOrderingComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId =>
      $composableBuilder(column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get countText =>
      $composableBuilder(column: $table.countText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedPlaylistsTableAnnotationComposer extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get owner => $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get thumbnail => $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<String> get countText => $composableBuilder(column: $table.countText, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt => $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedPlaylistsTable,
          SavedPlaylist,
          $$SavedPlaylistsTableFilterComposer,
          $$SavedPlaylistsTableOrderingComposer,
          $$SavedPlaylistsTableAnnotationComposer,
          $$SavedPlaylistsTableCreateCompanionBuilder,
          $$SavedPlaylistsTableUpdateCompanionBuilder,
          (SavedPlaylist, BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>),
          SavedPlaylist,
          PrefetchHooks Function()
        > {
  $$SavedPlaylistsTableTableManager(_$AppDatabase db, $SavedPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SavedPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SavedPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SavedPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> owner = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> countText = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion(
                playlistId: playlistId,
                title: title,
                owner: owner,
                thumbnail: thumbnail,
                countText: countText,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String title,
                Value<String?> owner = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<String?> countText = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion.insert(
                playlistId: playlistId,
                title: title,
                owner: owner,
                thumbnail: thumbnail,
                countText: countText,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedPlaylistsTable, SavedPlaylist>(table),
                  BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedPlaylistsTable,
      SavedPlaylist,
      $$SavedPlaylistsTableFilterComposer,
      $$SavedPlaylistsTableOrderingComposer,
      $$SavedPlaylistsTableAnnotationComposer,
      $$SavedPlaylistsTableCreateCompanionBuilder,
      $$SavedPlaylistsTableUpdateCompanionBuilder,
      (SavedPlaylist, BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>),
      SavedPlaylist,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder = SearchHistoryCompanion Function({
  required String query,
  required DateTime searchedAt,
  Value<int> rowid,
});
typedef $$SearchHistoryTableUpdateCompanionBuilder = SearchHistoryCompanion Function({
  Value<String> query,
  Value<DateTime> searchedAt,
  Value<int> rowid,
});

class $$SearchHistoryTableFilterComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchHistoryTableOrderingComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchHistoryTableAnnotationComposer extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query => $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => column);
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryTable,
          SearchHistoryData,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (SearchHistoryData, BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>),
          SearchHistoryData,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> query = const Value.absent(),
            Value<DateTime> searchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SearchHistoryCompanion(query: query, searchedAt: searchedAt, rowid: rowid),
          createCompanionCallback: ({
            required String query,
            required DateTime searchedAt,
            Value<int> rowid = const Value.absent(),
          }) => SearchHistoryCompanion.insert(query: query, searchedAt: searchedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryTable, SearchHistoryData>(table),
                  BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryTable,
      SearchHistoryData,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (SearchHistoryData, BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>),
      SearchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String videoId,
  required DownloadState state,
  required int height,
  Value<String?> path,
  Value<int> sizeBytes,
  Value<int> downloadedBytes,
  Value<String?> error,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> videoId,
  Value<DownloadState> state,
  Value<int> height,
  Value<String?> path,
  Value<int> sizeBytes,
  Value<int> downloadedBytes,
  Value<String?> error,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

final class $$DownloadsTableReferences extends BaseReferences<_$AppDatabase, $DownloadsTable, Download> {
  $$DownloadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VideosTable _videoIdTable(_$AppDatabase db) => db.videos.createAlias('downloads__video_id__videos__video_id');

  $$VideosTableProcessedTableManager get videoId {
    final $_column = $_itemColumn<String>('video_id')!;

    final manager = $$VideosTableTableManager($_db, $_db.videos).filter((f) => f.videoId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_videoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DownloadsTableFilterComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DownloadState, DownloadState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$VideosTableFilterComposer get videoId {
    final $$VideosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableFilterComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableOrderingComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$VideosTableOrderingComposer get videoId {
    final $$VideosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableOrderingComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableAnnotationComposer extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DownloadState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get height => $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes =>
      $composableBuilder(column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<String> get error => $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$VideosTableAnnotationComposer get videoId {
    final $$VideosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.videoId,
      referencedTable: $db.videos,
      getReferencedColumn: (t) => t.videoId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$VideosTableAnnotationComposer(
            $db: $db,
            $table: $db.videos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (Download, $$DownloadsTableReferences),
          Download,
          PrefetchHooks Function({bool videoId})
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<DownloadState> state = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String?> path = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                videoId: videoId,
                state: state,
                height: height,
                path: path,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                error: error,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required DownloadState state,
                required int height,
                Value<String?> path = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                videoId: videoId,
                state: state,
                height: height,
                path: path,
                sizeBytes: sizeBytes,
                downloadedBytes: downloadedBytes,
                error: error,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$DownloadsTable, Download>(table), $$DownloadsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({videoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (videoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.videoId,
                        referencedTable: $$DownloadsTableReferences._videoIdTable(db),
                        referencedColumn: $$DownloadsTableReferences._videoIdTable(db).videoId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, $$DownloadsTableReferences),
      Download,
      PrefetchHooks Function({bool videoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideosTableTableManager get videos => $$VideosTableTableManager(_db, _db.videos);
  $$WatchHistoryTableTableManager get watchHistory => $$WatchHistoryTableTableManager(_db, _db.watchHistory);
  $$LikedVideosTableTableManager get likedVideos => $$LikedVideosTableTableManager(_db, _db.likedVideos);
  $$SubscriptionsTableTableManager get subscriptions => $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$FeedVideosTableTableManager get feedVideos => $$FeedVideosTableTableManager(_db, _db.feedVideos);
  $$PlaylistsTableTableManager get playlists => $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistItemsTableTableManager get playlistItems => $$PlaylistItemsTableTableManager(_db, _db.playlistItems);
  $$SavedPlaylistsTableTableManager get savedPlaylists => $$SavedPlaylistsTableTableManager(_db, _db.savedPlaylists);
  $$SearchHistoryTableTableManager get searchHistory => $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$DownloadsTableTableManager get downloads => $$DownloadsTableTableManager(_db, _db.downloads);
}
