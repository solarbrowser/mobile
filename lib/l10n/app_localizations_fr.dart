import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcome => 'Bienvenue sur Solar';

  @override
  String get welcomeSubtitle => 'Un navigateur moderne, rapide et sécurisé';

  @override
  String get chooseLanguage => 'Choisissez votre Langue';

  @override
  String get chooseTheme => 'Choisissez votre Thème';

  @override
  String get chooseSearchEngine => 'Choisissez votre Moteur de Recherche';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get getStarted => 'Commencer';

  @override
  String get continueText => 'Continuer';

  @override
  String get updated => 'Solar Browser mis à jour !';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get general => 'Général';

  @override
  String get appearance => 'Apparence';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get settings => 'Paramètres';

  @override
  String get help => 'Aide';

  @override
  String get about => 'À propos';

  @override
  String get language => 'Langue';

  @override
  String get search_engine => 'Moteur de Recherche';

  @override
  String get dark_mode => 'Mode Sombre';

  @override
  String get text_size => 'Taille du Texte';

  @override
  String get show_images => 'Afficher les Images';

  @override
  String get download_location => 'Emplacement de Téléchargement';

  @override
  String get ask_download_location => 'Demander l\'Emplacement';

  @override
  String get rate_us => 'Évaluez-nous';

  @override
  String get privacy_policy => 'Politique de Confidentialité';

  @override
  String get terms_of_use => 'Conditions d\'Utilisation';

  @override
  String get customize_browser => 'Personnaliser le Navigateur';

  @override
  String get learn_more => 'En Savoir Plus';

  @override
  String get tabs => 'Onglets';

  @override
  String get history => 'Historique';

  @override
  String get bookmarks => 'Favoris';

  @override
  String get search_in_page => 'Rechercher dans la page';
}
