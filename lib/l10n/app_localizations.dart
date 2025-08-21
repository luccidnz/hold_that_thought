import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold That Thought'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get homeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accentLabel;

  /// No description provided for @quickCapture.
  ///
  /// In en, this message translates to:
  /// **'Quick Capture'**
  String get quickCapture;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get searchHint;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note Saved'**
  String get noteSaved;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @bodyHint.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get bodyHint;

  /// No description provided for @pinButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin note'**
  String get pinButtonTooltip;

  /// No description provided for @viewAllNotesTooltip.
  ///
  /// In en, this message translates to:
  /// **'View all notes'**
  String get viewAllNotesTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @filterByTagTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by {tag}'**
  String filterByTagTooltip(String tag);

  /// No description provided for @settingsThemeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeModeLabel;

  /// No description provided for @settingsAccentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get settingsAccentLabel;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSyncLabel;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageMaori.
  ///
  /// In en, this message translates to:
  /// **'Māori'**
  String get settingsLanguageMaori;

  /// No description provided for @settingsSetAccent.
  ///
  /// In en, this message translates to:
  /// **'Set accent color to {accentName}'**
  String settingsSetAccent(String accentName);

  /// No description provided for @settingsAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync (stub)'**
  String get settingsAutoSync;

  /// No description provided for @noteDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Detail'**
  String get noteDetailTitle;

  /// No description provided for @noteDetailId.
  ///
  /// In en, this message translates to:
  /// **'Note ID: {id}'**
  String noteDetailId(String id);

  /// No description provided for @listPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Thoughts'**
  String get listPageTitle;

  /// No description provided for @listPageBody.
  ///
  /// In en, this message translates to:
  /// **'List Page'**
  String get listPageBody;

  /// No description provided for @listPageBodyFiltered.
  ///
  /// In en, this message translates to:
  /// **'List Page (Filtered by tag: {tag})'**
  String listPageBodyFiltered(String tag);

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'404 - Page Not Found'**
  String get notFoundBody;

  /// No description provided for @goHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHomeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mi':
      return AppLocalizationsMi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
