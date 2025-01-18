import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcome => 'Bienvenido a Solar';

  @override
  String get welcomeSubtitle => 'Un navegador moderno, rápido y seguro';

  @override
  String get chooseLanguage => 'Elige tu Idioma';

  @override
  String get chooseTheme => 'Elige tu Tema';

  @override
  String get chooseSearchEngine => 'Elige tu Motor de Búsqueda';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get continueText => 'Continuar';

  @override
  String get updated => '¡Solar Browser Actualizado!';

  @override
  String version(String version) {
    return 'Versión $version';
  }

  @override
  String get general => 'General';

  @override
  String get appearance => 'Apariencia';

  @override
  String get downloads => 'Descargas';

  @override
  String get settings => 'Ajustes';

  @override
  String get help => 'Ayuda';

  @override
  String get about => 'Acerca de';

  @override
  String get language => 'Idioma';

  @override
  String get search_engine => 'Motor de Búsqueda';

  @override
  String get dark_mode => 'Modo Oscuro';

  @override
  String get text_size => 'Tamaño del Texto';

  @override
  String get show_images => 'Mostrar Imágenes';

  @override
  String get download_location => 'Ubicación de Descargas';

  @override
  String get ask_download_location => 'Preguntar Ubicación';

  @override
  String get rate_us => 'Califícanos';

  @override
  String get privacy_policy => 'Política de Privacidad';

  @override
  String get terms_of_use => 'Términos de Uso';

  @override
  String get customize_browser => 'Personalizar Navegador';

  @override
  String get learn_more => 'Más Información';

  @override
  String get tabs => 'Pestañas';

  @override
  String get history => 'Historial';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get search_in_page => 'Buscar en página';
}
