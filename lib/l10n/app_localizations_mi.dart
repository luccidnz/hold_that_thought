// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Maori (`mi`).
class AppLocalizationsMi extends AppLocalizations {
  AppLocalizationsMi([String locale = 'mi']) : super(locale);

  @override
  String get appTitle => 'Puritia Te Whakaaro';

  @override
  String get homeTitle => 'Ngā Tuhipoka';

  @override
  String get settingsTitle => 'Tautuhinga';

  @override
  String get themeLabel => 'Kaupapa';

  @override
  String get themeSystem => 'Pūnaha';

  @override
  String get themeLight => 'Mārama';

  @override
  String get themeDark => 'Pōuri';

  @override
  String get accentLabel => 'Tae Tohu';

  @override
  String get quickCapture => 'Hopukina Tere';

  @override
  String get searchHint => 'Rapu tuhipoka…';

  @override
  String get pinned => 'Kua Piri';

  @override
  String get allNotes => 'Ngā Tuhipoka Katoa';

  @override
  String get save => 'Tiaki';

  @override
  String get cancel => 'Whakakore';

  @override
  String get undo => 'Wetekia';

  @override
  String get view => 'Tirohia';

  @override
  String get noteSaved => 'Kua Tiakina te Tuhipoka';

  @override
  String get titleHint => 'Taitara';

  @override
  String get bodyHint => 'Tinana';

  @override
  String get pinButtonTooltip => 'Tīpina te tuhipoka';

  @override
  String get viewAllNotesTooltip => 'Tirohia ngā tuhipoka katoa';

  @override
  String get settingsTooltip => 'Tautuhinga';

  @override
  String filterByTagTooltip(String tag) {
    return 'Tātarihia mā te $tag';
  }

  @override
  String get settingsThemeModeLabel => 'Aratau Kaupapa';

  @override
  String get settingsAccentLabel => 'Tae Kōkaha';

  @override
  String get settingsLanguageLabel => 'Reo';

  @override
  String get settingsSyncLabel => 'Tukutahi';

  @override
  String get settingsThemeSystem => 'Pūnaha';

  @override
  String get settingsThemeLight => 'Mārama';

  @override
  String get settingsThemeDark => 'Pōuri';

  @override
  String get settingsLanguageSystem => 'Pūnaha';

  @override
  String get settingsLanguageEnglish => 'Ingarihi';

  @override
  String get settingsLanguageMaori => 'Māori';

  @override
  String settingsSetAccent(String accentName) {
    return 'Tautuhia te tae kōkaha ki te $accentName';
  }

  @override
  String get settingsAutoSync => 'Tukutahi-aunoa (tumau)';

  @override
  String get noteDetailTitle => 'Taipitopito Tuhipoka';

  @override
  String noteDetailId(String id) {
    return 'ID Tuhipoka: $id';
  }

  @override
  String get listPageTitle => 'Ngā Whakaaro';

  @override
  String get listPageBody => 'Whārangi Rārangi';

  @override
  String listPageBodyFiltered(String tag) {
    return 'Whārangi Rārangi (Kua tātarihia e te tūtohu: $tag)';
  }

  @override
  String get notFoundTitle => 'Kāore i Kitea te Whārangi';

  @override
  String get notFoundBody => '404 - Kāore i Kitea te Whārangi';

  @override
  String get goHomeButton => 'Hoki ki te Kāinga';
}
