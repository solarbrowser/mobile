import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcome => 'Добро пожаловать в Solar';

  @override
  String get welcomeSubtitle => 'Современный, быстрый и безопасный браузер';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get chooseTheme => 'Выберите тему';

  @override
  String get chooseSearchEngine => 'Выберите поисковую систему';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get next => 'Далее';

  @override
  String get back => 'Назад';

  @override
  String get getStarted => 'Начать';

  @override
  String get continueText => 'Продолжить';

  @override
  String get updated => 'Solar Browser обновлён!';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get general => 'Общие';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get downloads => 'Загрузки';

  @override
  String get settings => 'Настройки';

  @override
  String get help => 'Помощь';

  @override
  String get about => 'О программе';

  @override
  String get language => 'Язык';

  @override
  String get search_engine => 'Поисковая система';

  @override
  String get dark_mode => 'Тёмная тема';

  @override
  String get text_size => 'Размер текста';

  @override
  String get show_images => 'Показывать изображения';

  @override
  String get download_location => 'Папка загрузки';

  @override
  String get ask_download_location => 'Спрашивать путь';

  @override
  String get rate_us => 'Оценить нас';

  @override
  String get privacy_policy => 'Политика конфиденциальности';

  @override
  String get terms_of_use => 'Условия использования';

  @override
  String get customize_browser => 'Настроить браузер';

  @override
  String get learn_more => 'Узнать больше';

  @override
  String get tabs => 'Вкладки';

  @override
  String get history => 'История';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get search_in_page => 'Поиск на странице';
}
