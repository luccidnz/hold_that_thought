import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/settings/settings_controller.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/sync/fake_sync_service.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:hold_that_thought/theme/app_theme.dart';
import 'package:hold_that_thought/theme/theme_controller.dart';
import 'package:hold_that_thought/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = ref.watch(themeProvider);
    final themeController = ref.read(themeProvider.notifier);
    final autoSync = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);
    final locale = ref.watch(localeProvider);
    final localeController = ref.read(localeProvider.notifier);

    void showDevTools() {
      final syncService = ref.read(syncServiceProvider) as FakeSyncService;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dev Tools'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Simulated Latency'),
                trailing: DropdownButton<Duration>(
                  value: syncService.latency,
                  items: const [
                    DropdownMenuItem(value: Duration.zero, child: Text('0ms')),
                    DropdownMenuItem(
                        value: Duration(milliseconds: 250),
                        child: Text('250ms')),
                    DropdownMenuItem(
                        value: Duration(milliseconds: 500),
                        child: Text('500ms')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      syncService.latency = value;
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Failure Rate'),
                trailing: DropdownButton<double>(
                  value: syncService.failureRate,
                  items: const [
                    DropdownMenuItem(value: 0.0, child: Text('0%')),
                    DropdownMenuItem(value: 0.05, child: Text('5%')),
                    DropdownMenuItem(value: 0.1, child: Text('10%')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      syncService.failureRate = value;
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Clear Remote Store'),
                onTap: () {
                  syncService.clearRemoteStore();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Clear Local Store'),
                onTap: () {
                  ref.read(notesRepositoryProvider).clearAllBoxes();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.settingsThemeModeLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.wb_sunny),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.nightlight_round),
              ),
            ],
            selected: {themeState.themeMode},
            onSelectionChanged: (newSelection) {
              themeController.setMode(newSelection.first);
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAccentLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: Accent.values.map((accent) {
              return Semantics(
                label: l10n.settingsSetAccent(accent.name),
                child: GestureDetector(
                  onTap: () {
                    themeController.setAccent(accent);
                  },
                  child: CircleAvatar(
                    backgroundColor: accent.color,
                    child: themeState.accent == accent
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            l10n.settingsLanguageLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<Locale?>(
            segments: [
              ButtonSegment(
                value: null,
                label: Text(l10n.settingsLanguageSystem),
                icon: const Icon(Icons.language),
              ),
              ButtonSegment(
                value: const Locale('en'),
                label: Text(l10n.settingsLanguageEnglish),
              ),
              ButtonSegment(
                value: const Locale('mi'),
                label: Text(l10n.settingsLanguageMaori),
              ),
            ],
            selected: {locale},
            onSelectionChanged: (newSelection) {
              localeController.setLocale(newSelection.first);
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            l10n.settingsSyncLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.settingsAutoSync),
            value: autoSync,
            onChanged: (value) {
              settingsController.setAutoSync(value);
            },
          ),
          if (kDebugMode)
            GestureDetector(
              onLongPress: showDevTools,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'App Version: 1.0.0 (long press for dev tools)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
