import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/data/video_info.dart';
import 'package:youpipe/innertube/models.dart';
import 'package:youpipe/player/video_player_service.dart';
import 'package:youpipe/providers.dart';

void main() {
  group('recovery budget', () {
    Duration s(int seconds) => Duration(seconds: seconds);

    test('a failing video gets up to 3 re-resolves in a row, then the error shows', () {
      expect(VideoPlayerService.nextRecovery(0, from: s(0), at: s(40)), 1);
      expect(VideoPlayerService.nextRecovery(1, from: s(40), at: s(45)), 2);
      expect(VideoPlayerService.nextRecovery(2, from: s(45), at: s(50)), 3);
      expect(VideoPlayerService.nextRecovery(3, from: s(50), at: s(55)), isNull);
    });

    test('playing a minute past the last recovery earns a fresh budget', () {
      expect(VideoPlayerService.nextRecovery(3, from: s(50), at: s(110)), 1);
      expect(VideoPlayerService.nextRecovery(3, from: s(600), at: s(3000)), 1);
    });
  });

  group('up next countdown', () {
    const video = VideoItem(id: 'next', title: 'Next video');

    // testWidgets runs on fake time, so the 5 s countdown takes no real time.
    testWidgets('plays the next video when the countdown runs out', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var played = 0;
      container.read(upNextCountdownProvider.notifier).start(video, () => played++);
      expect(container.read(upNextCountdownProvider)?.video.id, 'next');
      await tester.pump(const Duration(seconds: 4));
      expect(played, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(played, 1);
      expect(container.read(upNextCountdownProvider), isNull);
    });

    testWidgets('Cancel stops it; Play now skips the wait', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final countdown = container.read(upNextCountdownProvider.notifier);
      var played = 0;
      countdown.start(video, () => played++);
      countdown.cancel();
      await tester.pump(const Duration(seconds: 10));
      expect(played, 0);
      expect(container.read(upNextCountdownProvider), isNull);

      countdown.start(video, () => played++);
      countdown.playNow();
      expect(played, 1);
      await tester.pump(const Duration(seconds: 10));
      expect(played, 1);
    });
  });

  group('media session', () {
    // Going idle straight from playing left a stale notification: audio_service's detach on pause landed after its
    // cancel on idle.
    testWidgets('stopping while playing pauses first and ends the session a moment later', (tester) async {
      final handler = YouPipeAudioHandler(VideoPlayerService(VideoInfoService()));
      handler.playbackState.add(PlaybackState(playing: true, processingState: AudioProcessingState.ready));
      final states = <PlaybackState>[];
      final sub = handler.playbackState.skip(1).listen(states.add);
      addTearDown(sub.cancel);

      final cleared = handler.cleared();
      await tester.pump();
      expect(states.map((s) => (s.playing, s.processingState)), [(false, AudioProcessingState.ready)]);
      await tester.pump(const Duration(milliseconds: 500));
      await cleared;
      expect(states.last.processingState, AudioProcessingState.idle);
    });

    testWidgets('stopping while paused ends the session straight away', (tester) async {
      final handler = YouPipeAudioHandler(VideoPlayerService(VideoInfoService()));
      handler.playbackState.add(PlaybackState(processingState: AudioProcessingState.ready));
      await handler.cleared();
      expect(handler.playbackState.value.processingState, AudioProcessingState.idle);
    });
  });
}
