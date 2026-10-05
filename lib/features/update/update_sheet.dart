import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/yt_theme.dart';
import 'update.dart';
import 'updater.dart';

/// "Update available": what's new, then Later / Skip this version / Update. Update downloads the APK for
/// this phone, checks it and opens Android's install screen. Closing the sheet doesn't stop a download.
Future<void> showUpdateSheet(BuildContext context, AvailableUpdate update) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => SafeArea(child: _UpdateSheet(update)),
);

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _UpdateSheet extends ConsumerWidget {
  const _UpdateSheet(this.update);

  final AvailableUpdate update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final controller = ref.read(updateProvider.notifier);
    final theme = Theme.of(context);
    final notes = cleanReleaseNotes(update.release.notes);

    final Widget actions = switch (state) {
      UpdateDownloading(:final received, :final total, :final progress) => _Progress(
        label: total > 0 ? 'Downloading… ${_mb(received)} of ${_mb(total)}' : 'Downloading…',
        value: progress,
        onCancel: controller.cancelDownload,
      ),
      UpdateInstalling() => const _Progress(label: 'Opening the installer…'),
      UpdateFailed(:final error) => _Failure(
        error: error,
        onRetry: () => controller.downloadAndInstall(update),
        onOpenReleases: () => ref.read(updaterProvider).openUrl(update.release.pageUrl),
      ),
      _ => Row(
        children: [
          TextButton(
            onPressed: () async {
              await controller.skip(update);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: context.yt.textSecondary),
            child: const Text('Skip this version'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: context.yt.textPrimary),
            child: const Text('Later'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => controller.downloadAndInstall(update),
            style: FilledButton.styleFrom(
              backgroundColor: context.yt.textPrimary,
              foregroundColor: context.yt.background,
              shape: const StadiumBorder(),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update available', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Version ${update.version} • ${_mb(update.apk.size)}', style: theme.textTheme.bodyMedium),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text("What's new", style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
              child: SingleChildScrollView(child: Text(notes, style: theme.textTheme.bodyMedium)),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref.read(updaterProvider).openUrl(update.release.pageUrl),
              style: TextButton.styleFrom(foregroundColor: context.yt.textSecondary, padding: EdgeInsets.zero),
              child: const Text('Full release notes'),
            ),
          ),
          const SizedBox(height: 8),
          actions,
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label, this.value, this.onCancel});

  final String label;
  final double? value;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LinearProgressIndicator(
        value: value,
        color: YtColors.red,
        backgroundColor: context.yt.divider,
        borderRadius: BorderRadius.circular(2),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: context.yt.textPrimary),
              child: const Text('Cancel'),
            ),
        ],
      ),
    ],
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry, required this.onOpenReleases});

  final UpdateException error;
  final VoidCallback onRetry;
  final VoidCallback onOpenReleases;

  String get _message => switch (error.code) {
    'NETWORK' => "Couldn't download the update. Check your connection and try again.",
    'HASH_MISMATCH' => 'The download was damaged. Try again.',
    'SIGNATURE_MISMATCH' =>
      'This copy of YouPipe was installed from a different build, so Android won\'t update it. '
          'Uninstall it, then install the latest version from GitHub.',
    'DOWNGRADE' => 'The installed version is newer than this release.',
    _ => "The update couldn't be installed (${error.message}).",
  };

  @override
  Widget build(BuildContext context) {
    final reinstall = error.code == 'SIGNATURE_MISMATCH' || error.code == 'DOWNGRADE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.yt.textPrimary)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: reinstall ? onOpenReleases : onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: context.yt.textPrimary,
              foregroundColor: context.yt.background,
              shape: const StadiumBorder(),
            ),
            child: Text(reinstall ? 'Open GitHub' : 'Try again'),
          ),
        ),
      ],
    );
  }
}
