import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcome => 'Willkommen bei Solar';

  @override
  String get welcomeSubtitle => 'Ein moderner, schneller und sicherer Browser';

  @override
  String get chooseLanguage => 'Wählen Sie Ihre Sprache';

  @override
  String get chooseTheme => 'Wählen Sie Ihr Design';

  @override
  String get chooseSearchEngine => 'Wählen Sie Ihre Suchmaschine';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get continueText => 'Fortfahren';

  @override
  String get updated => 'Solar Browser wurde aktualisiert!';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get general => 'Allgemein';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Einstellungen';

  @override
  String get help => 'Hilfe';

  @override
  String get about => 'Über';

  @override
  String get language => 'Sprache';

  @override
  String get search_engine => 'Suchmaschine';

  @override
  String get dark_mode => 'Dunkelmodus';

  @override
  String get text_size => 'Textgröße';

  @override
  String get show_images => 'Bilder anzeigen';

  @override
  String get download_location => 'Download-Speicherort';

  @override
  String get ask_download_location => 'Nach Speicherort fragen';

  @override
  String get rate_us => 'Bewerten Sie uns';

  @override
  String get privacy_policy => 'Datenschutzerklärung';

  @override
  String get terms_of_use => 'Nutzungsbedingungen';

  @override
  String get customize_browser => 'Browser anpassen';

  @override
  String get learn_more => 'Mehr erfahren';

  @override
  String get tabs => 'Tabs';

  @override
  String get history => 'Verlauf';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get search_in_page => 'Auf Seite suchen';
}
