// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hold That Thought';

  @override
  String get homeTitle => 'Notes';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentLabel => 'Accent';

  @override
  String get quickCapture => 'Quick Capture';

  @override
  String get searchHint => 'Search notes…';

  @override
  String get pinned => 'Pinned';

  @override
  String get allNotes => 'All Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get view => 'View';

  @override
  String get noteSaved => 'Note Saved';

  @override
  String get titleHint => 'Title';

  @override
  String get bodyHint => 'Body';

  @override
  String get pinButtonTooltip => 'Pin note';

  @override
  String get viewAllNotesTooltip => 'View all notes';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String filterByTagTooltip(String tag) {
    return 'Filter by $tag';
  }

  @override
  String get settingsThemeModeLabel => 'Theme Mode';

  @override
  String get settingsAccentLabel => 'Accent Color';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsSyncLabel => 'Sync';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageMaori => 'Māori';

  @override
  String settingsSetAccent(String accentName) {
    return 'Set accent color to $accentName';
  }

  @override
  String get settingsAutoSync => 'Auto-sync (stub)';

  @override
  String get noteDetailTitle => 'Note Detail';

  @override
  String noteDetailId(String id) {
    return 'Note ID: $id';
  }

  @override
  String get listPageTitle => 'Thoughts';

  @override
  String get listPageBody => 'List Page';

  @override
  String listPageBodyFiltered(String tag) {
    return 'List Page (Filtered by tag: $tag)';
  }

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get notFoundBody => '404 - Page Not Found';

  @override
  String get goHomeButton => 'Go Home';
}
