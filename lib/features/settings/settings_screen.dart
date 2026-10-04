import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../providers.dart';
import '../../ui/theme/yt_theme.dart';
import '../../ui/widgets/common.dart';

/// Extra settings sections registered by later features (SponsorBlock, downloads, account, updates).
final settingsExtraSections = <Widget Function(BuildContext, WidgetRef)>[];

const _languages = {
  'en': 'English',
  'hi': 'हिन्दी',
  'ml': 'മലയാളം',
  'ta': 'தமிழ்',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'ar': 'العربية',
  'ru': 'Русский',
};

const _regions = {
  'US': 'United States',
  'GB': 'United Kingdom',
  'IE': 'Ireland',
  'IN': 'India',
  'CA': 'Canada',
  'AU': 'Australia',
  'DE': 'Germany',
  'FR': 'France',
  'ES': 'Spain',
  'BR': 'Brazil',
  'JP': 'Japan',
  'KR': 'South Korea',
  'AE': 'United Arab Emirates',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final c = context.yt;
    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        t,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textSecondary),
      ),
    );
    Future<T?> pick<T>(String title, Map<T, String> options, T selected) => showDialog<T>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<T>(
            groupValue: selected,
            onChanged: (v) => Navigator.pop(d, v),
            child: Column(
              children: [
                for (final e in options.entries)
                  RadioListTile<T>(value: e.key, title: Text(e.value), activeColor: c.link),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Symbols.arrow_back)),
      ),
      body: MaxContentWidth(
        child: ListView(
          children: [
            header('General'),
            ListTile(
              title: const Text('Appearance'),
              subtitle: Text(switch (s.themeMode) {
                ThemeMode.system => 'Use device theme',
                ThemeMode.dark => 'Dark theme',
                ThemeMode.light => 'Light theme',
              }),
              onTap: () async {
                final m = await pick('Appearance', {
                  ThemeMode.system: 'Use device theme',
                  ThemeMode.dark: 'Dark theme',
                  ThemeMode.light: 'Light theme',
                }, s.themeMode);
                if (m != null) await ctl.update(s.copyWith(themeMode: m));
              },
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_languages[s.hl] ?? s.hl),
              onTap: () async {
                final v = await pick('Language', _languages, s.hl);
                if (v != null) await ctl.update(s.copyWith(hl: v));
              },
            ),
            ListTile(
              title: const Text('Location'),
              subtitle: Text(_regions[s.gl] ?? s.gl),
              onTap: () async {
                final v = await pick('Location', _regions, s.gl);
                if (v != null) await ctl.update(s.copyWith(gl: v));
              },
            ),
            SwitchListTile(
              title: const Text('Picture-in-picture'),
              subtitle: const Text('Keep watching in a small window when you leave the app'),
              value: s.pip,
              onChanged: (v) => ctl.update(s.copyWith(pip: v)),
            ),
            const Divider(),
            // Autoplay is switched in the player, like YouTube (docs/playback.md).
            header('Playback'),
            SwitchListTile(
              title: const Text('Resume where you left off'),
              value: s.resume,
              onChanged: (v) => ctl.update(s.copyWith(resume: v)),
            ),
            const Divider(),
            header('Video quality preferences'),
            RadioGroup<VideoQualityPref>(
              groupValue: s.quality,
              onChanged: (v) {
                if (v != null) ctl.update(s.copyWith(quality: v));
              },
              child: Column(
                children: [
                  for (final q in VideoQualityPref.values)
                    RadioListTile<VideoQualityPref>(
                      value: q,
                      activeColor: c.link,
                      title: Text(q.label),
                      subtitle: Text(q.description),
                    ),
                ],
              ),
            ),
            for (final section in settingsExtraSections) section(context, ref),
            const Divider(),
            header('Manage all history'),
            SwitchListTile(
              title: const Text('Pause watch history'),
              value: !s.saveHistory,
              onChanged: (v) => ctl.update(s.copyWith(saveHistory: !v)),
            ),
            SwitchListTile(
              title: const Text('Pause search history'),
              value: !s.saveSearchHistory,
              onChanged: (v) => ctl.update(s.copyWith(saveSearchHistory: !v)),
            ),
            ListTile(
              title: const Text('Clear watch history'),
              onTap: () async {
                await ref.read(libraryProvider).clearHistory();
                if (context.mounted) showSnack(context, 'Watch history cleared');
              },
            ),
            ListTile(
              title: const Text('Clear search history'),
              onTap: () async {
                await ref.read(libraryProvider).clearSearches();
                if (context.mounted) showSnack(context, 'Search history cleared');
              },
            ),
            const Divider(),
            header('About'),
            ListTile(
              title: const Text('Diagnostics'),
              subtitle: const Text('Test playback on this device'),
              onTap: () => context.push('/diagnostics'),
            ),
            ListTile(
              title: const Text('Open source licenses'),
              onTap: () => showLicensePage(context: context, applicationName: 'YouPipe'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Text(
                'YouPipe is an independent, open-source app. It isn\'t made by or affiliated with YouTube or Google.',
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
