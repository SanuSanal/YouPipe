import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show AppLifecycleState, ThemeMode, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'data/db/app_database.dart';
import 'data/home_feed.dart';
import 'data/library_repository.dart';
import 'data/subscriptions_feed.dart';
import 'data/video_info.dart';
import 'innertube/innertube.dart';
import 'player/video_player_service.dart';

// ---------------------------------------------------------------------------------------------------------------
// Core services (created in main() and injected with overrides)
// ---------------------------------------------------------------------------------------------------------------

final innerTubeProvider = Provider<InnerTube>((ref) => throw UnimplementedError('overridden in main'));
final videoInfoServiceProvider = Provider<VideoInfoService>((ref) => throw UnimplementedError('overridden in main'));
final playerServiceProvider = Provider<VideoPlayerService>((ref) => throw UnimplementedError('overridden in main'));
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('overridden in main'));
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));

final libraryProvider = Provider<LibraryRepository>((ref) => LibraryRepository(ref.watch(databaseProvider)));
final subscriptionsFeedServiceProvider = Provider<SubscriptionsFeed>(
  (ref) => SubscriptionsFeed(ref.watch(databaseProvider)),
);

// ---------------------------------------------------------------------------------------------------------------
// Settings (docs/data.md lists the keys)
// ---------------------------------------------------------------------------------------------------------------

/// YouTube's own quality presets.
enum VideoQualityPref {
  auto('Auto (recommended)', 'Adjusts to give you the best experience for your conditions', 1080),
  higher('Higher picture quality', 'Uses more data', 2160),
  dataSaver('Data saver', 'Lower picture quality', 480);

  const VideoQualityPref(this.label, this.description, this.maxHeight);
  final String label;
  final String description;
  final int maxHeight;
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.hl = 'en',
    this.gl = 'US',
    this.quality = VideoQualityPref.auto,
    this.autoplay = true,
    this.saveHistory = true,
    this.saveSearchHistory = true,
    this.resume = true,
    this.pip = true,
  });

  final ThemeMode themeMode;
  final String hl;
  final String gl;
  final VideoQualityPref quality;

  /// Play a related video when one ends (the player's Autoplay switch).
  final bool autoplay;
  final bool saveHistory;
  final bool saveSearchHistory;

  /// Continue videos where they were left.
  final bool resume;

  /// Picture-in-picture when leaving the app during playback.
  final bool pip;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? hl,
    String? gl,
    VideoQualityPref? quality,
    bool? autoplay,
    bool? saveHistory,
    bool? saveSearchHistory,
    bool? resume,
    bool? pip,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    hl: hl ?? this.hl,
    gl: gl ?? this.gl,
    quality: quality ?? this.quality,
    autoplay: autoplay ?? this.autoplay,
    saveHistory: saveHistory ?? this.saveHistory,
    saveSearchHistory: saveSearchHistory ?? this.saveSearchHistory,
    resume: resume ?? this.resume,
    pip: pip ?? this.pip,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    final s = AppSettings(
      themeMode: ThemeMode.values.asNameMap()[p.getString('themeMode')] ?? ThemeMode.system,
      hl: p.getString('hl') ?? 'en',
      gl: p.getString('gl') ?? 'US',
      quality: VideoQualityPref.values.asNameMap()[p.getString('quality')] ?? VideoQualityPref.auto,
      autoplay: p.getBool('autoplay') ?? true,
      saveHistory: p.getBool('saveHistory') ?? true,
      saveSearchHistory: p.getBool('saveSearchHistory') ?? true,
      resume: p.getBool('resume') ?? true,
      pip: p.getBool('pip') ?? true,
    );
    _apply(s);
    return s;
  }

  void _apply(AppSettings s) {
    ref.read(innerTubeProvider)
      ..hl = s.hl
      ..gl = s.gl;
    ref.read(videoInfoServiceProvider)
      ..hl = s.hl
      ..gl = s.gl;
    ref.read(playerServiceProvider).maxHeight = s.quality.maxHeight;
  }

  Future<void> update(AppSettings s) async {
    final regionChanged = s.hl != state.hl || s.gl != state.gl;
    state = s;
    _apply(s);
    await _prefs.setString('themeMode', s.themeMode.name);
    await _prefs.setString('hl', s.hl);
    await _prefs.setString('gl', s.gl);
    await _prefs.setString('quality', s.quality.name);
    await _prefs.setBool('autoplay', s.autoplay);
    await _prefs.setBool('saveHistory', s.saveHistory);
    await _prefs.setBool('saveSearchHistory', s.saveSearchHistory);
    await _prefs.setBool('resume', s.resume);
    await _prefs.setBool('pip', s.pip);
    if (regionChanged) ref.invalidate(homeProvider);
  }
}

// ---------------------------------------------------------------------------------------------------------------
// Playback: what's playing, the queue, autoplay (docs/playback.md)
// ---------------------------------------------------------------------------------------------------------------

@immutable
class NowPlaying {
  const NowPlaying({required this.video, required this.queue, required this.index, this.loop = false});

  final VideoItem video;

  /// Videos queued with "Play next" / "Add to queue" (the current one included at [index]).
  final List<VideoItem> queue;
  final int index;
  final bool loop;

  bool get hasNextInQueue => index + 1 < queue.length;

  NowPlaying copyWith({VideoItem? video, List<VideoItem>? queue, int? index, bool? loop}) => NowPlaying(
    video: video ?? this.video,
    queue: queue ?? this.queue,
    index: index ?? this.index,
    loop: loop ?? this.loop,
  );
}

final playbackProvider = NotifierProvider<PlaybackController, NowPlaying?>(PlaybackController.new);

class PlaybackController extends Notifier<NowPlaying?> {
  VideoPlayerService get _svc => ref.read(playerServiceProvider);
  LibraryRepository get _library => ref.read(libraryProvider);
  Timer? _saver;
  StreamSubscription<String>? _completions;

  /// Keeps the current video's up-next fetched and alive. The mini player and the background show no related
  /// list, and an unlistened autoDispose provider can be dropped before it answers (autoplay then never fired).
  ProviderSubscription<Future<VideoItem?>>? _upNext;
  String? _upNextId;

  @override
  NowPlaying? build() {
    _completions = _svc.completed.listen(_onCompleted);
    _svc
      ..onNext = next
      ..onPrevious = previous
      ..onStop = stop;
    // Remember where each video stopped, so it can resume (and for the red progress bars).
    _saver = Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
    _svc.info.addListener(_enrich);
    ref.onDispose(() {
      _saver?.cancel();
      _completions?.cancel();
      _upNext?.close();
      _svc.info.removeListener(_enrich);
    });
    return null;
  }

  void _watchUpNext(String id) {
    if (_upNextId == id && _upNext != null) return;
    _upNext?.close();
    _upNextId = id;
    _upNext = ref.listen(upNextProvider(id).future, (_, _) {});
  }

  /// The video Autoplay plays after [id]; a failed fetch (often the network waking up) is tried once more.
  Future<VideoItem?> _upNextOf(String id) async {
    for (var attempt = 0; ; attempt++) {
      _watchUpNext(id);
      try {
        return await _upNext!.read();
      } on Object catch (e) {
        debugPrint('YouPipe: up next for $id failed: $e');
        if (attempt > 0) return null;
        _upNext?.close();
        _upNext = null;
        ref.invalidate(upNextProvider(id));
      }
    }
  }

  /// Fills in what the card didn't know (channel avatar, duration…) once the video info arrives.
  void _enrich() {
    final i = _svc.info.value;
    final s = state;
    if (i == null || s == null || i.videoId != s.video.id) return;
    final v = s.video;
    final rich = VideoItem(
      id: v.id,
      title: i.title.isNotEmpty ? i.title : v.title,
      channelName: i.channelName.isNotEmpty ? i.channelName : v.channelName,
      channelId: i.channelId ?? v.channelId,
      channelAvatar: i.channelAvatar ?? v.channelAvatar,
      thumbnail: v.thumbnail ?? 'https://i.ytimg.com/vi/${v.id}/hqdefault.jpg',
      durationText: v.durationText,
      viewsText: v.viewsText,
      publishedText: v.publishedText,
      isShort: v.isShort || i.isShort,
      isLive: i.isLive,
    );
    state = s.copyWith(video: rich);
    if (ref.read(settingsProvider).saveHistory && !i.isLive) {
      unawaited(_library.recordWatch(rich, duration: i.duration));
    }
  }

  Future<void> _savePosition() async {
    final s = state;
    final c = _svc.controller.value;
    if (s == null || c == null || !c.value.isInitialized || s.video.isLive) return;
    if (!ref.read(settingsProvider).saveHistory) return;
    await _library.savePosition(s.video.id, c.value.position, c.value.duration);
  }

  /// Plays [video] now. With [queue], the queue becomes that list (from [index]).
  Future<void> play(VideoItem video, {List<VideoItem>? queue, int index = 0}) async {
    await _savePosition();
    state = NowPlaying(video: video, queue: queue ?? [video], index: queue == null ? 0 : index);
    await _start(video);
  }

  Future<void> _start(VideoItem video) async {
    ref.read(upNextCountdownProvider.notifier).cancel();
    _watchUpNext(video.id);
    final settings = ref.read(settingsProvider);
    final resume = settings.resume && !video.isLive ? await _library.resumePosition(video.id) : null;
    if (settings.saveHistory) await _library.recordWatch(video);
    await _svc.open(video.id, maxHeight: settings.quality.maxHeight, start: resume ?? Duration.zero);
    final c = _svc.controller.value;
    if (c != null && state?.loop == true) await c.setLooping(true);
  }

  Future<void> _playAt(int index) async {
    final s = state;
    if (s == null || index < 0 || index >= s.queue.length) return;
    await _savePosition();
    state = s.copyWith(video: s.queue[index], index: index);
    await _start(s.queue[index]);
  }

  /// Next in the queue, else (with Autoplay on, or when [force]d by the Next button) the first related video.
  Future<void> next({bool force = true}) async {
    final s = state;
    if (s == null) return;
    ref.read(upNextCountdownProvider.notifier).cancel();
    if (s.hasNextInQueue) return _playAt(s.index + 1);
    if (!force && !ref.read(settingsProvider).autoplay) return;
    final upNext = await _upNextOf(s.video.id);
    if (upNext == null || state?.video.id != s.video.id) return;
    // On the watch page YouTube counts down first, with Cancel; in the mini player, PiP or the background the next
    // video just starts.
    if (!force && _watching) {
      ref.read(upNextCountdownProvider.notifier).start(upNext, () => _playUpNext(s, upNext));
      return;
    }
    await _playUpNext(s, upNext);
  }

  /// The watch page (or fullscreen) is on screen.
  bool get _watching =>
      (ref.read(playerPanelProvider) || ref.read(fullscreenProvider)) &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      !Pip.instance.active.value;

  Future<void> _playUpNext(NowPlaying s, VideoItem upNext) async {
    if (state?.video.id != s.video.id) return;
    await _savePosition();
    state = s.copyWith(video: upNext, queue: [...s.queue, upNext], index: s.queue.length);
    await _start(upNext);
  }

  /// Back to the start, or the previous video when within the first 5 s.
  Future<void> previous() async {
    final s = state;
    final c = _svc.controller.value;
    if (s == null) return;
    ref.read(upNextCountdownProvider.notifier).cancel();
    if (c != null && c.value.position > const Duration(seconds: 5) || s.index == 0) {
      await c?.seekTo(Duration.zero);
      return;
    }
    await _playAt(s.index - 1);
  }

  void playNext(VideoItem video) {
    final s = state;
    if (s == null) {
      unawaited(play(video));
      return;
    }
    final q = [...s.queue]..insert(s.index + 1, video);
    state = s.copyWith(queue: q);
  }

  void addToQueue(VideoItem video) {
    final s = state;
    if (s == null) {
      unawaited(play(video));
      return;
    }
    state = s.copyWith(queue: [...s.queue, video]);
  }

  Future<void> toggleLoop() async {
    final s = state;
    if (s == null) return;
    state = s.copyWith(loop: !s.loop);
    await _svc.controller.value?.setLooping(!s.loop);
  }

  Future<void> _onCompleted(String videoId) async {
    final s = state;
    if (s == null || s.video.id != videoId) return;
    final c = _svc.controller.value;
    if (c != null && ref.read(settingsProvider).saveHistory) {
      await _library.savePosition(videoId, c.value.duration, c.value.duration);
    }
    await next(force: false);
  }

  Future<void> stop() async {
    await _savePosition();
    ref.read(upNextCountdownProvider.notifier).cancel();
    _upNext?.close();
    _upNext = null;
    _upNextId = null;
    state = null;
    await _svc.stop();
  }
}

/// YouTube's end-of-video "Up next" countdown on the watch page: the video, and when it starts.
@immutable
class UpNextCountdown {
  const UpNextCountdown(this.video, this.startsAt);

  final VideoItem video;
  final DateTime startsAt;
}

final upNextCountdownProvider = NotifierProvider<UpNextCountdownController, UpNextCountdown?>(
  UpNextCountdownController.new,
);

class UpNextCountdownController extends Notifier<UpNextCountdown?> {
  static const length = Duration(seconds: 5);

  Timer? _timer;
  VoidCallback? _onDone;

  @override
  UpNextCountdown? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void start(VideoItem video, VoidCallback onDone) {
    _timer?.cancel();
    _onDone = onDone;
    state = UpNextCountdown(video, DateTime.now().add(length));
    _timer = Timer(length, playNow);
  }

  /// Skips the rest of the countdown.
  void playNow() {
    final done = _onDone;
    cancel();
    done?.call();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _onDone = null;
    if (state != null) state = null;
  }
}

/// The video Autoplay would play after [videoId]: the first related, unfinished, non-Short video.
final upNextProvider = FutureProvider.autoDispose.family<VideoItem?, String>((ref, videoId) async {
  final related = await ref.watch(relatedProvider(videoId).future);
  final history = await ref.read(libraryProvider).watchHistory(limit: 300).first;
  final finished = {
    for (final h in history)
      if (h.progress > 0.9 || h.video.id == videoId) h.video.id,
  };
  return related.items
      .whereType<VideoItem>()
      .where((v) => !v.isShort && !v.isLive && !finished.contains(v.id))
      .firstOrNull;
});

/// The live player controller (null while loading).
final playerControllerProvider = Provider<VideoPlayerController?>((ref) {
  final svc = ref.watch(playerServiceProvider);
  void changed() => ref.invalidateSelf();
  svc.controller.addListener(changed);
  ref.onDispose(() => svc.controller.removeListener(changed));
  return svc.controller.value;
});

final currentInfoProvider = Provider<VideoInfo?>((ref) {
  final svc = ref.watch(playerServiceProvider);
  void changed() => ref.invalidateSelf();
  svc.info.addListener(changed);
  ref.onDispose(() => svc.info.removeListener(changed));
  return svc.info.value;
});

final playerErrorProvider = Provider<Object?>((ref) {
  final svc = ref.watch(playerServiceProvider);
  void changed() => ref.invalidateSelf();
  svc.error.addListener(changed);
  ref.onDispose(() => svc.error.removeListener(changed));
  return svc.error.value;
});

/// Playback on another device (casting): the player UI drives this instead of the phone's player.
abstract class RemoteControls {
  String get deviceName;
  bool get playing;
  Duration get position;
  Duration? get duration;
  Future<void> togglePlay();
  Future<void> seek(Duration position);
}

/// Set by the cast feature: the remote while casting, else null. Call from `build` (it watches providers).
RemoteControls? Function(WidgetRef ref)? remoteControlsOf;

/// Expanded (watch page) or collapsed (mini player).
final playerPanelProvider = NotifierProvider<PlayerPanelController, bool>(PlayerPanelController.new);

class PlayerPanelController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool expanded) => state = expanded;
  void expand() => state = true;
  void collapse() => state = false;
}

/// The selected bottom-nav tab (0 Home, 1 Shorts, 2 Subscriptions, 3 You); set by the shell.
final currentTabProvider = NotifierProvider<CurrentTabController, int>(CurrentTabController.new);

class CurrentTabController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) {
    if (state != i) state = i;
  }
}

final fullscreenProvider = NotifierProvider<FullscreenController, bool>(FullscreenController.new);

class FullscreenController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

// ---------------------------------------------------------------------------------------------------------------
// Paged lists
// ---------------------------------------------------------------------------------------------------------------

@immutable
class PagedList<T> {
  const PagedList(this.items, {this.continuation, this.loadingMore = false});

  final List<T> items;
  final String? continuation;
  final bool loadingMore;

  bool get hasMore => continuation != null;
}

/// Shared load-more logic for every continuation-paged list.
mixin _Paging<T> on AsyncNotifier<PagedList<T>> {
  Future<(List<T>, String?)> fetchMore(String token);

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(PagedList(current.items, continuation: current.continuation, loadingMore: true));
    try {
      final (items, next) = await fetchMore(current.continuation!);
      state = AsyncData(PagedList([...current.items, ...items], continuation: items.isEmpty ? null : next));
    } catch (e) {
      debugPrint('YouPipe: load more failed: $e');
      state = AsyncData(PagedList(current.items, continuation: current.continuation));
    }
  }
}

// Home -----------------------------------------------------------------------------------------------------------

@immutable
class HomeState {
  const HomeState({required this.chip, required this.items, this.loadingMore = false, this.hasMore = true});

  final HomeChip chip;
  final List<VideoItem> items;
  final bool loadingMore;
  final bool hasMore;
}

final homeChipProvider = NotifierProvider<HomeChipController, HomeChip>(HomeChipController.new);

class HomeChipController extends Notifier<HomeChip> {
  @override
  HomeChip build() => HomeChip.all;

  void select(HomeChip chip) => state = chip;
}

final homeProvider = AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends AsyncNotifier<HomeState> {
  /// The cached first page is shown once per launch, while the fresh mix loads (docs/data.md).
  static bool _cacheShown = false;

  /// Set once the user touches Home. After that a fresh feed no longer replaces the cached one, so a tap never
  /// lands on a video that just changed under the finger.
  static bool touched = false;

  Future<HomeMixer>? _mixer;

  @override
  Future<HomeState> build() async {
    final chip = ref.watch(homeChipProvider);
    final prefs = ref.read(prefsProvider);
    final fresh = _load(chip, prefs);
    _mixer = fresh.then((r) => r.$1)..ignore();
    if (chip == HomeChip.all && !_cacheShown) {
      _cacheShown = true;
      final cached = readVideoCache(prefs, _cacheKey);
      if (cached != null && cached.isNotEmpty) {
        unawaited(
          fresh.then((r) {
            if (ref.mounted && !touched) state = AsyncData(HomeState(chip: chip, items: r.$2, hasMore: r.$1.hasMore));
          }, onError: (_) {}),
        );
        return HomeState(chip: chip, items: cached);
      }
    }
    final (mixer, items) = await fresh;
    return HomeState(chip: chip, items: items, hasMore: mixer.hasMore);
  }

  static const _cacheKey = 'homeCache';

  Future<(HomeMixer, List<VideoItem>)> _load(HomeChip chip, SharedPreferences prefs) async {
    final yt = ref.read(innerTubeProvider);
    await yt.ensureVisitorData().catchError((_) => null);
    final subs = ref.read(subscriptionsFeedServiceProvider);
    unawaited(subs.refresh());
    final mixer = await HomeMixer.create(
      chip: chip,
      yt: yt,
      library: ref.read(libraryProvider),
      subscriptionFeed: await subs.watch().first,
    );
    final items = await mixer.next(20);
    if (chip == HomeChip.all && items.isNotEmpty) await writeVideoCache(prefs, _cacheKey, items);
    return (mixer, items);
  }

  Future<void> loadMore() async {
    final s = state.value;
    final pending = _mixer;
    if (s == null || pending == null || s.loadingMore || !s.hasMore) return;
    state = AsyncData(HomeState(chip: s.chip, items: s.items, loadingMore: true));
    try {
      final mixer = await pending;
      // The list may still be the cached page, which the fresh mix can repeat.
      final shown = {for (final v in s.items) v.id};
      final more = (await mixer.next(16)).where((v) => !shown.contains(v.id)).toList();
      if (!ref.mounted || !identical(pending, _mixer)) return;
      state = AsyncData(HomeState(chip: s.chip, items: [...s.items, ...more], hasMore: mixer.hasMore));
    } catch (_) {
      if (ref.mounted && identical(pending, _mixer)) state = AsyncData(HomeState(chip: s.chip, items: s.items));
    }
  }
}

/// Shorts for the Home shelf (from a Shorts search, which carries titles and view counts). At launch the cached
/// shelf shows straight away, so the feed below doesn't jump when it arrives; the fresh one is saved for next time.
final homeShortsProvider = FutureProvider<List<VideoItem>>((ref) async {
  final chip = ref.watch(homeChipProvider);
  final prefs = ref.read(prefsProvider);
  Future<List<VideoItem>> fetch() async {
    final page = await ref.read(innerTubeProvider).search(chip.query ?? 'trending', params: SearchFilter.shorts.params);
    final shorts = page.entries.allItems.whereType<VideoItem>().where((v) => v.isShort).take(12).toList();
    if (chip == HomeChip.all && shorts.isNotEmpty) await writeVideoCache(prefs, _shortsCacheKey, shorts);
    return shorts;
  }

  if (chip == HomeChip.all && !_shortsCacheShown) {
    _shortsCacheShown = true;
    final cached = readVideoCache(prefs, _shortsCacheKey);
    if (cached != null && cached.isNotEmpty) {
      unawaited(fetch().catchError((_) => const <VideoItem>[]));
      return cached;
    }
  }
  return fetch();
});

const _shortsCacheKey = 'homeShortsCache';
var _shortsCacheShown = false;

/// A list of videos saved in preferences, or null when missing or older than [maxAge].
List<VideoItem>? readVideoCache(SharedPreferences prefs, String key, {Duration maxAge = const Duration(hours: 12)}) {
  try {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, Object?>;
    final at = DateTime.fromMillisecondsSinceEpoch(j['at']! as int);
    if (DateTime.now().difference(at) > maxAge) return null;
    return [for (final v in j['items']! as List) VideoItem.fromJson((v as Map).cast<String, Object?>())];
  } catch (_) {
    return null;
  }
}

Future<void> writeVideoCache(SharedPreferences prefs, String key, List<VideoItem> items) => prefs.setString(
  key,
  jsonEncode({
    'at': DateTime.now().millisecondsSinceEpoch,
    'items': [for (final v in items) v.toJson()],
  }),
);

// Search ---------------------------------------------------------------------------------------------------------

typedef SearchQuery = ({String query, String? params});

final searchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResultsController, PagedList<FeedEntry>, SearchQuery>(SearchResultsController.new);

class SearchResultsController extends AsyncNotifier<PagedList<FeedEntry>> with _Paging<FeedEntry> {
  SearchResultsController(this.arg);

  final SearchQuery arg;
  List<SearchFilterGroup> filters = const [];

  @override
  Future<PagedList<FeedEntry>> build() async {
    final page = await ref.read(innerTubeProvider).search(arg.query, params: arg.params);
    filters = page.filters;
    return PagedList(page.entries, continuation: page.continuation);
  }

  @override
  Future<(List<FeedEntry>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).searchContinuation(token);
    return (page.entries, page.continuation);
  }
}

final searchSuggestionsProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, input) async {
  if (input.trim().isEmpty) return const [];
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  if (cancelled) throw StateError('cancelled');
  return ref.read(innerTubeProvider).suggestions(input);
});

final searchHistoryProvider = StreamProvider<List<String>>((ref) => ref.watch(libraryProvider).searches());

// Watch page -----------------------------------------------------------------------------------------------------

final relatedProvider = AsyncNotifierProvider.autoDispose.family<RelatedController, PagedList<YtItem>, String>(
  RelatedController.new,
);

class RelatedController extends AsyncNotifier<PagedList<YtItem>> with _Paging<YtItem> {
  RelatedController(this.videoId);

  final String videoId;

  @override
  Future<PagedList<YtItem>> build() async {
    final page = await ref.read(innerTubeProvider).related(videoId);
    return PagedList(page.items, continuation: page.continuation);
  }

  @override
  Future<(List<YtItem>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).nextContinuation(token);
    return (page.items, page.continuation);
  }
}

typedef CommentsKey = ({String videoId, String? sortToken});

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsController, PagedList<CommentData>, CommentsKey>(CommentsController.new);

class CommentsController extends AsyncNotifier<PagedList<CommentData>> with _Paging<CommentData> {
  CommentsController(this.key);

  final CommentsKey key;
  String? count;
  List<SortChip> sorts = const [];

  @override
  Future<PagedList<CommentData>> build() async {
    final yt = ref.read(innerTubeProvider);
    final page = key.sortToken == null ? await yt.comments(key.videoId) : await yt.commentsContinuation(key.sortToken!);
    count = page.count;
    if (page.sorts.isNotEmpty) sorts = page.sorts;
    return PagedList(page.comments, continuation: page.continuation);
  }

  @override
  Future<(List<CommentData>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).commentsContinuation(token);
    return (page.comments, page.continuation);
  }
}

/// A comment's replies, by its replies token.
final repliesProvider = AsyncNotifierProvider.autoDispose.family<RepliesController, PagedList<CommentData>, String>(
  RepliesController.new,
);

class RepliesController extends AsyncNotifier<PagedList<CommentData>> with _Paging<CommentData> {
  RepliesController(this.token);

  final String token;

  @override
  Future<PagedList<CommentData>> build() async {
    final page = await ref.read(innerTubeProvider).commentsContinuation(token);
    return PagedList(page.comments, continuation: page.continuation);
  }

  @override
  Future<(List<CommentData>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).commentsContinuation(token);
    return (page.comments, page.continuation);
  }
}

// Channel, playlist -----------------------------------------------------------------------------------------------

typedef ChannelTabKey = ({String channelId, String? params});

final channelProvider = FutureProvider.autoDispose.family<ChannelPage, ChannelTabKey>(
  (ref, key) => ref.read(innerTubeProvider).channel(key.channelId, params: key.params),
);

/// A channel tab's list: the tab's first page (or a re-sorted one, by sort chip token) plus continuations.
typedef ChannelListKey = ({String channelId, String? params, String? sortToken});

final channelListProvider = AsyncNotifierProvider.autoDispose
    .family<ChannelListController, PagedList<FeedEntry>, ChannelListKey>(ChannelListController.new);

class ChannelListController extends AsyncNotifier<PagedList<FeedEntry>> with _Paging<FeedEntry> {
  ChannelListController(this.key);

  final ChannelListKey key;

  @override
  Future<PagedList<FeedEntry>> build() async {
    if (key.sortToken != null) {
      final page = await ref.read(innerTubeProvider).browseContinuation(key.sortToken!);
      return PagedList(page.entries, continuation: page.continuation);
    }
    final page = await ref.watch(channelProvider((channelId: key.channelId, params: key.params)).future);
    return PagedList(page.content.entries, continuation: page.content.continuation);
  }

  @override
  Future<(List<FeedEntry>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).browseContinuation(token);
    return (page.entries, page.continuation);
  }
}

final playlistProvider = FutureProvider.autoDispose.family<PlaylistPage, String>(
  (ref, id) => ref.read(innerTubeProvider).playlist(id),
);

final playlistVideosProvider = AsyncNotifierProvider.autoDispose
    .family<PlaylistVideosController, PagedList<YtItem>, String>(PlaylistVideosController.new);

class PlaylistVideosController extends AsyncNotifier<PagedList<YtItem>> with _Paging<YtItem> {
  PlaylistVideosController(this.playlistId);

  final String playlistId;

  @override
  Future<PagedList<YtItem>> build() async {
    final page = await ref.watch(playlistProvider(playlistId).future);
    return PagedList(page.videos.items, continuation: page.videos.continuation);
  }

  @override
  Future<(List<YtItem>, String?)> fetchMore(String token) async {
    final page = await ref.read(innerTubeProvider).browseContinuation(token);
    return (page.entries.allItems.toList(), page.continuation);
  }

  /// Every video, following continuations (Play all / Shuffle on long playlists), up to 500.
  Future<List<VideoItem>> all() async {
    while (state.value?.hasMore == true && state.value!.items.length < 500) {
      final before = state.value!.items.length;
      await loadMore();
      if (state.value!.items.length == before) break;
    }
    return state.value?.items.whereType<VideoItem>().toList() ?? const [];
  }
}

// Library streams -------------------------------------------------------------------------------------------------

final historyProvider = StreamProvider<List<HistoryEntry>>((ref) => ref.watch(libraryProvider).watchHistory());

final watchProgressProvider = StreamProvider<Map<String, double>>((ref) => ref.watch(libraryProvider).watchProgress());

final likedVideosProvider = StreamProvider<List<VideoItem>>((ref) => ref.watch(libraryProvider).likedVideos());

final isLikedProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(libraryProvider).watchIsLiked(id),
);

final subscriptionsProvider = StreamProvider<List<ChannelItem>>((ref) => ref.watch(libraryProvider).subscriptions());

final isSubscribedProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(libraryProvider).watchIsSubscribed(id),
);

final subscriptionFeedProvider = StreamProvider<List<FeedVideo>>(
  (ref) => ref.watch(subscriptionsFeedServiceProvider).watch(),
);

final localPlaylistsProvider = StreamProvider<List<LocalPlaylistSummary>>(
  (ref) => ref.watch(libraryProvider).localPlaylists(),
);

final localPlaylistProvider = StreamProvider.autoDispose.family<Playlist?, int>(
  (ref, id) => ref.watch(libraryProvider).watchPlaylist(id),
);

final localPlaylistVideosProvider = StreamProvider.autoDispose.family<List<VideoItem>, int>(
  (ref, id) => ref.watch(libraryProvider).playlistVideos(id),
);

final playlistsContainingProvider = StreamProvider.autoDispose.family<Set<int>, String>(
  (ref, videoId) => ref.watch(libraryProvider).playlistsContaining(videoId),
);

final savedPlaylistsProvider = StreamProvider<List<PlaylistItem>>((ref) => ref.watch(libraryProvider).savedPlaylists());

final isPlaylistSavedProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(libraryProvider).watchIsPlaylistSaved(id),
);
