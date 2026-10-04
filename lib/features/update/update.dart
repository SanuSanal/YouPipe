import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers.dart';
import '../../ui/widgets/common.dart';
import 'update_sheet.dart';
import 'updater.dart';

/// In-app updates from GitHub Releases (docs/updates.md).
final updaterProvider = Provider<Updater>((ref) => Updater());

final appInfoProvider = FutureProvider<AppInfo>((ref) => ref.watch(updaterProvider).appInfo());

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.update);

  final AvailableUpdate update;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.update, {this.received = 0, this.total = 0});

  final AvailableUpdate update;
  final int received;
  final int total;

  double? get progress => total > 0 ? received / total : null;
}

class UpdateInstalling extends UpdateState {
  const UpdateInstalling(this.update);

  final AvailableUpdate update;
}

class UpdateFailed extends UpdateState {
  const UpdateFailed(this.error, {this.update});

  final UpdateException error;

  /// The update being fetched or installed, so the sheet can offer a retry.
  final AvailableUpdate? update;
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  CancelToken? _cancel;

  Updater get _updater => ref.read(updaterProvider);
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  UpdateState build() => const UpdateIdle();

  bool get busy => state is UpdateChecking || state is UpdateDownloading || state is UpdateInstalling;

  /// The launch check: silent on errors, and skipped in debug builds (they report pubspec's version and are
  /// signed with a different key), when turned off, or when the user skipped this version.
  Future<AvailableUpdate?> checkOnLaunch() async {
    await _updater.cleanup().catchError((_) {});
    if (kDebugMode || !(ref.read(prefsProvider).getBool('autoUpdateCheck') ?? true) || busy) return null;
    try {
      final update = await _updater.check();
      if (update == null || update.version == _prefs.getString('skippedUpdateVersion')) return null;
      state = UpdateAvailable(update);
      return update;
    } on Object {
      return null;
    }
  }

  /// A check the user asked for. Returns the update, or null when up to date; throws [UpdateException].
  Future<AvailableUpdate?> checkNow() async {
    if (busy) {
      return switch (state) {
        UpdateDownloading(:final update) || UpdateInstalling(:final update) => update,
        _ => null,
      };
    }
    state = const UpdateChecking();
    try {
      final update = await _updater.check();
      state = update == null ? const UpdateIdle() : UpdateAvailable(update);
      return update;
    } on UpdateException {
      state = const UpdateIdle();
      rethrow;
    } on Object catch (e) {
      state = const UpdateIdle();
      throw UpdateException('NETWORK', e.toString());
    }
  }

  Future<void> skip(AvailableUpdate update) async {
    await _prefs.setString('skippedUpdateVersion', update.version);
    state = const UpdateIdle();
  }

  /// Downloads, verifies and installs [update]. Errors end up in [UpdateFailed].
  Future<void> downloadAndInstall(AvailableUpdate update) async {
    if (state is UpdateDownloading || state is UpdateInstalling) return;
    final cancel = _cancel = CancelToken();
    state = UpdateDownloading(update);
    try {
      final path = await _updater.download(
        update,
        cancelToken: cancel,
        onProgress: (received, total) => state = UpdateDownloading(update, received: received, total: total),
      );
      state = UpdateInstalling(update);
      await _updater.install(path);
      state = const UpdateIdle();
    } on UpdateException catch (e) {
      state = e.code == 'CANCELLED' ? UpdateAvailable(update) : UpdateFailed(e, update: update);
    } on Object catch (e) {
      state = UpdateFailed(UpdateException('INSTALL_FAILED', e.toString()), update: update);
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  void cancelDownload() => _cancel?.cancel();
}

/// Looks for a new release a few seconds after launch and offers it in the update sheet.
void checkForUpdateOnLaunch(BuildContext context, WidgetRef ref) {
  Future.delayed(const Duration(seconds: 3), () async {
    final update = await ref.read(updateProvider.notifier).checkOnLaunch();
    if (update != null && context.mounted) unawaited(showUpdateSheet(context, update));
  });
}

/// The Updates section of Settings.
Widget updateSettings(BuildContext context, WidgetRef ref) {
  final prefs = ref.watch(prefsProvider);
  final info = ref.watch(appInfoProvider).value;
  final busy = ref.watch(updateProvider) is UpdateChecking;
  return StatefulBuilder(
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            'Updates',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Check for updates automatically'),
          subtitle: const Text('Looks for a new release on GitHub when the app opens'),
          value: prefs.getBool('autoUpdateCheck') ?? true,
          onChanged: (v) async {
            await prefs.setBool('autoUpdateCheck', v);
            setState(() {});
          },
        ),
        ListTile(
          title: const Text('Check for updates'),
          subtitle: Text('Version ${info?.versionName ?? '…'}'),
          trailing: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          onTap: busy
              ? null
              : () async {
                  try {
                    final update = await ref.read(updateProvider.notifier).checkNow();
                    if (!context.mounted) return;
                    if (update == null) {
                      showSnack(context, "You're up to date");
                    } else {
                      unawaited(showUpdateSheet(context, update));
                    }
                  } on UpdateException catch (e) {
                    if (context.mounted) {
                      showSnack(context, e.code == 'NETWORK' ? "Couldn't check for updates" : e.message);
                    }
                  }
                },
        ),
      ],
    ),
  );
}
