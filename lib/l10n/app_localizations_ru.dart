// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcomeToSolar => 'Добро пожаловать в Solar';

  @override
  String get welcomeDescription => 'Современный, быстрый и безопасный браузер';

  @override
  String get termsOfService =>
      'Продолжая, вы соглашаетесь с нашими Условиями использования и Политикой конфиденциальности';

  @override
  String get whats_new => 'Что нового';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get chooseTheme => 'Выберите тему';

  @override
  String get chooseSearchEngine => 'Выберите поисковую систему';

  @override
  String get selectAppearance => 'Выберите, как должно выглядеть приложение';

  @override
  String get selectSearchEngine => 'Выберите предпочитаемую поисковую систему';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get systemTheme => 'Системная';

  @override
  String get tokyoNightTheme => 'Tokyo Night';

  @override
  String get solarizedLightTheme => 'Solarized Светлый';

  @override
  String get draculaTheme => 'Dracula';

  @override
  String get nordTheme => 'Nord';

  @override
  String get gruvboxTheme => 'Gruvbox';

  @override
  String get oneDarkTheme => 'One Dark';

  @override
  String get catppuccinTheme => 'Catppuccin';

  @override
  String get nordLightTheme => 'Nord Светлый';

  @override
  String get gruvboxLightTheme => 'Gruvbox Светлый';

  @override
  String get next => 'Далее';

  @override
  String get back => 'Назад';

  @override
  String get skip => 'Пропустить';

  @override
  String get disable_classic_navigation_warning =>
      'Отключить классическую навигацию';

  @override
  String get disable_classic_navigation_message =>
      'Когда классическая навигация отключена, вы переходите к новой системе навигации на основе свайпов. В этой системе вы можете провести вверх по адресной строке для доступа к функциям, а для перехода вперед или назад — провести по адресной строке влево или вправо.';

  @override
  String get getStarted => 'Начать';

  @override
  String get continueText => 'Продолжить';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationDescription =>
      'Получайте уведомления о загруженных файлах на ваше устройство';

  @override
  String get allowNotifications => 'Разрешить Уведомления';

  @override
  String get skipForNow => 'Пропустить Пока';

  @override
  String get just_now => 'Только что';

  @override
  String min_ago(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String hr_ago(int hours) {
    return '$hours ч назад';
  }

  @override
  String get yesterday => 'Вчера';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get and => 'и';

  @override
  String get data_collection => 'Сбор данных';

  @override
  String get data_collection_details =>
      '• Мы собираем минимум данных, необходимых для работы браузера\n• Ваша история просмотров остаётся на вашем устройстве\n• Мы не отслеживаем вашу онлайн-активность\n• Вы можете удалить все данные в любое время';

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
  String get ask_download_location => 'Спрашивать папку для загрузки';

  @override
  String get rate_us => 'Оцените нас';

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
  String get keep_tabs_open => 'Сохранять вкладки открытыми';

  @override
  String get history => 'История';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get search_in_page => 'Поиск на странице';

  @override
  String get app_name => 'Solar Browser';

  @override
  String get search_or_enter_address => 'Поиск или ввод адреса';

  @override
  String get current_location => 'Текущая папка';

  @override
  String get change_location => 'Изменить папку';

  @override
  String get clear_browser_data => 'Очистить данные браузера';

  @override
  String get browsing_history => 'История просмотров';

  @override
  String get cookies => 'Файлы cookie';

  @override
  String get cache => 'Кэш';

  @override
  String get form_data => 'Данные форм';

  @override
  String get saved_passwords => 'Сохранённые пароли';

  @override
  String get cancel => 'Отмена';

  @override
  String get clear => 'Очистить';

  @override
  String get close => 'Закрыть';

  @override
  String get browser_data_cleared => 'Данные браузера очищены';

  @override
  String get no_downloads => 'Нет загрузок';

  @override
  String get no_bookmarks => 'Нет закладок';

  @override
  String get download_started => 'Загрузка начата';

  @override
  String get download_completed => 'Загрузка завершена';

  @override
  String get download_failed => 'Ошибка загрузки';

  @override
  String get open => 'Открыть';

  @override
  String get delete => 'Удалить';

  @override
  String get delete_download => 'Удалить загрузку';

  @override
  String get delete_bookmark => 'Удалить закладку';

  @override
  String get add_bookmark => 'Добавить закладку';

  @override
  String get bookmark_added => 'Закладка добавлена';

  @override
  String get bookmark_exists => 'Закладка уже существует';

  @override
  String get share => 'Поделиться';

  @override
  String get copy_link => 'Копировать ссылку';

  @override
  String get paste_and_go => 'Вставить и перейти';

  @override
  String get find_in_page => 'Найти на странице';

  @override
  String get desktop_site => 'Версия для ПК';

  @override
  String get new_tab => 'Новая вкладка';

  @override
  String get close_tab => 'Закрыть вкладку';

  @override
  String get tab_overview => 'Обзор вкладок';

  @override
  String get home => 'Домой';

  @override
  String get reload => 'Обновить';

  @override
  String get stop => 'Остановить';

  @override
  String get forward => 'Вперёд';

  @override
  String get more => 'Ещё';

  @override
  String get reset_browser => 'Сбросить браузер';

  @override
  String get reset_browser_confirm =>
      'Это действие удалит все ваши данные, включая историю, закладки и настройки. Это действие нельзя отменить.';

  @override
  String get reset => 'Сбросить';

  @override
  String get reset_complete => 'Браузер сброшен';

  @override
  String get permission_denied => 'Доступ к хранилищу запрещён';

  @override
  String get permission_permanently_denied =>
      'Доступ запрещён навсегда. Пожалуйста, включите его в Настройках.';

  @override
  String get download_location_changed => 'Папка загрузки изменена';

  @override
  String get error_changing_location => 'Ошибка при изменении папки';

  @override
  String get enable_cookies => 'Включить файлы cookie';

  @override
  String get enable_javascript => 'Включить JavaScript';

  @override
  String get hardware_acceleration => 'Аппаратное ускорение';

  @override
  String get save_form_data => 'Сохранять данные форм';

  @override
  String get do_not_track => 'Не отслеживать';

  @override
  String get download_location_description =>
      'Выберите папку для сохранения загруженных файлов';

  @override
  String get text_size_description =>
      'Настройте размер текста на веб-страницах';

  @override
  String get text_size_small => 'Мелкий';

  @override
  String get text_size_medium => 'Средний';

  @override
  String get text_size_large => 'Крупный';

  @override
  String get text_size_very_large => 'Очень крупный';

  @override
  String get cookies_description =>
      'Разрешить сайтам сохранять и читать данные cookie';

  @override
  String get javascript_description =>
      'Включить JavaScript для лучшей функциональности сайтов';

  @override
  String get hardware_acceleration_description =>
      'Использовать GPU для повышения производительности';

  @override
  String get form_data_description => 'Сохранять информацию, введённую в формы';

  @override
  String get do_not_track_description =>
      'Запрашивать у сайтов не отслеживать вашу активность';

  @override
  String get exit_app => 'Выйти из приложения';

  @override
  String get exit_app_confirm => 'Вы уверены, что хотите выйти?';

  @override
  String get exit => 'Выйти';

  @override
  String get size => 'Размер';

  @override
  String get auto_open_downloads => 'Автоматически открывать загрузки';

  @override
  String get clear_downloads_history => 'Очистить историю загрузок';

  @override
  String get downloads_history_cleared => 'История загрузок очищена';

  @override
  String get sort_by => 'Сортировать по';

  @override
  String get name => 'Имя';

  @override
  String get date => 'Дата';

  @override
  String delete_download_confirm(String fileName) {
    return 'Удалить $fileName из истории загрузок?\nЗагруженный файл не будет удалён.';
  }

  @override
  String get download_removed => 'Загрузка удалена из истории';

  @override
  String download_size(String size) {
    return 'Размер: $size';
  }

  @override
  String get install_packages_permission => 'Разрешение на установку пакетов';

  @override
  String get install_packages_permission_description =>
      'Разрешить установку приложений из этого браузера';

  @override
  String get permission_install_packages_required =>
      'Требуется разрешение на установку пакетов';

  @override
  String get storage_permission_install_packages_required =>
      'Разрешение на хранение и установку пакетов';

  @override
  String get storage_permission_install_packages_description =>
      'Браузеру Solar требуется разрешение на доступ к хранилищу для загрузок и установку пакетов для установки APK';

  @override
  String get clear_downloads_history_confirm =>
      'Это очистит только историю загрузок, загруженные файлы не будут удалены.';

  @override
  String get clear_downloads_history_title => 'Очистить историю загрузок';

  @override
  String get slide_up_panel => 'Сдвинуть панель вверх';

  @override
  String get slide_down_panel => 'Сдвинуть панель вниз';

  @override
  String get move_url_bar => 'Переместить адресную строку';

  @override
  String get url_bar_icon => 'Значок адресной строки';

  @override
  String get url_bar_expanded => 'Адресная строка развёрнута';

  @override
  String get search_or_type_url => 'Поиск или ввод URL';

  @override
  String get secure_connection => 'Безопасное соединение';

  @override
  String get insecure_connection => 'Небезопасное соединение';

  @override
  String get refresh_page => 'Обновить страницу';

  @override
  String get close_search => 'Закрыть поиск';

  @override
  String get allow_popups => 'Всплывающие окна';

  @override
  String get allow_popups_description => 'Разрешить всплывающие окна';

  @override
  String get popups_blocked => 'Всплывающее окно заблокировано';

  @override
  String get allow_once => 'Разрешить один раз';

  @override
  String get allow_always => 'Разрешить всегда';

  @override
  String get block => 'Блокировать';

  @override
  String get blocked_popups => 'Заблокированные всплывающие окна';

  @override
  String get no_blocked_popups => 'Нет заблокированных всплывающих окон';

  @override
  String allow_popups_from(String domain) {
    return 'Разрешить всплывающие окна с $domain';
  }

  @override
  String get classic_navigation => 'Классическая навигация';

  @override
  String get classic_navigation_description =>
      'Показывать кнопки навигации внизу экрана';

  @override
  String get exit_confirmation => 'Выйти из приложения';

  @override
  String get flutter_version => 'Версия Flutter';

  @override
  String get photoncore_version => 'Версия Photoncore';

  @override
  String get engine_version => 'Версия движка';

  @override
  String get software_team => 'Команда разработчиков';

  @override
  String get download_image => 'Скачать изображение';

  @override
  String get share_image => 'Поделиться изображением';

  @override
  String get open_in_new_tab => 'Открыть в новой вкладке';

  @override
  String get copy_image_link => 'Скопировать ссылку на изображение';

  @override
  String get open_image_in_new_tab => 'Открыть изображение в новой вкладке';

  @override
  String get open_link => 'Открыть ссылку';

  @override
  String get open_link_in_new_tab => 'Открыть ссылку в новой вкладке';

  @override
  String get copy_link_address => 'Скопировать адрес ссылки';

  @override
  String get failed_to_download_image => 'Не удалось загрузить изображение';

  @override
  String get custom_home_page => 'Пользовательская домашняя страница';

  @override
  String get set_home_page_url => 'Установить URL домашней страницы';

  @override
  String get not_set => 'Не установлено';

  @override
  String get save => 'Сохранить';

  @override
  String get downloading => 'Загрузка...';

  @override
  String get no_downloads_yet => 'Нет загрузок';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get press_back_to_exit => 'Нажмите ещё раз для выхода';

  @override
  String get storage_permission_required => 'Дать разрешение';

  @override
  String get storage_permission_granted =>
      'Разрешение на хранение предоставлено';

  @override
  String get storage_permission_description =>
      'Этому приложению требуется разрешение на доступ к файлам для функции загрузки.';

  @override
  String get app_should_work_normally =>
      'Приложение должно работать нормально с полным функционалом.';

  @override
  String get grant_permission => 'Дать разрешение';

  @override
  String get download_permissions => 'Разрешения загрузки';

  @override
  String get manage_download_permissions => 'Управление разрешениями загрузки';

  @override
  String get storage_permission => 'Доступ к хранилищу';

  @override
  String get notification_permission => 'Уведомления';

  @override
  String get notification_permission_description =>
      'Для оповещений о ходе загрузки и завершении';

  @override
  String get permission_explanation =>
      'Эти разрешения помогают улучшить ваш опыт загрузки. Вы можете изменить их в любое время в настройках Android.';

  @override
  String get clear_downloads_history_description =>
      'Удалить историю загрузок (файлы остаются)';

  @override
  String get change_download_location => 'Изменить место загрузки';

  @override
  String get request => 'Запрос';

  @override
  String get storage => 'Хранилище';

  @override
  String get manage_external_storage => 'Управление внешним хранилищем';

  @override
  String get notification => 'Уведомление';

  @override
  String get granted => 'Предоставлено';

  @override
  String get denied => 'Отклонено';

  @override
  String get restricted => 'Ограничено';

  @override
  String get limited => 'Ограничено';

  @override
  String get permanently_denied => 'Постоянно отклонено';

  @override
  String get storage_permission_denied =>
      'Для загрузки файлов требуется разрешение на доступ к хранилищу';

  @override
  String get new_incognito_tab => 'Новая вкладка в режиме инкогнито';

  @override
  String get incognito_mode => 'Режим инкогнито';

  @override
  String get incognito_description =>
      'В режиме инкогнито:\n• История браузера не сохраняется\n• Файлы cookie удаляются при закрытии вкладок\n• Данные не сохраняются локально';

  @override
  String get error_opening_file => 'Ошибка открытия файла';

  @override
  String get download_in_progress => 'Идет загрузка';

  @override
  String get download_paused => 'Загрузка приостановлена';

  @override
  String get download_canceled => 'Загрузка отменена';

  @override
  String download_error(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get open_downloads_folder => 'Открыть папку загрузок';

  @override
  String get file_exists => 'Файл уже существует';

  @override
  String get file_saved => 'Файл сохранен в Загрузки';

  @override
  String get no_tabs_open => 'Нет открытых вкладок';

  @override
  String get incognito => 'Инкогнито';

  @override
  String get clear_all => 'Очистить все';

  @override
  String get clear_history => 'Очистить историю';

  @override
  String get clear_history_confirmation =>
      'Вы уверены, что хотите очистить историю браузера?';

  @override
  String get no_history => 'Нет истории браузера';

  @override
  String get today => 'Сегодня';

  @override
  String days_ago(int days) {
    return '$days дней назад';
  }

  @override
  String weeks_ago(int weeks) {
    return '$weeks недель назад';
  }

  @override
  String months_ago(int months) {
    return '$months месяцев назад';
  }

  @override
  String get update1 => 'Улучшенная система тем';

  @override
  String get update1desc =>
      'Новая система тем с большим выбором цветов и улучшенной поддержкой тёмного режима';

  @override
  String get update2 => 'Улучшения производительности';

  @override
  String get update2desc =>
      'Более быстрая загрузка страниц и плавная прокрутка';

  @override
  String get update3 => 'Новые функции конфиденциальности';

  @override
  String get update3desc =>
      'Улучшенная защита от отслеживания и оптимизация режима инкогнито';

  @override
  String get update4 => 'Улучшения интерфейса';

  @override
  String get update4desc =>
      'Улучшенный пользовательский интерфейс с более удобной навигацией и доступностью';

  @override
  String get searchTheWeb => 'Поиск в интернете';

  @override
  String get recentSearches => 'Недавние поиски';

  @override
  String get previous_summaries => 'Предыдущие резюме';

  @override
  String get summarize_selected => 'Сводка выбранного';

  @override
  String get summarize_page => 'Сводка страницы';

  @override
  String get ai_preferences => 'Настройки ИИ';

  @override
  String get ai_provider => 'Провайдер ИИ';

  @override
  String get summary_length => 'Длина сводки';

  @override
  String get generating_summary => 'Создание резюме...';

  @override
  String get summary_copied_to_clipboard => 'Резюме скопировано в буфер обмена';

  @override
  String get summary_language => 'Язык сводки';

  @override
  String get length_short => 'Короткий';

  @override
  String get length_medium => 'Средний';

  @override
  String get length_long => 'Длинный';

  @override
  String get summary_length_short => 'Короткий (75 слов)';

  @override
  String get summary_length_medium => 'Средний (150 слов)';

  @override
  String get summary_length_long => 'Длинный (250 слов)';

  @override
  String get summary_language_english => 'Английский';

  @override
  String get summary_language_turkish => 'Турецкий';

  @override
  String get add_to_pwa => 'Добавить в PWA';

  @override
  String get remove_from_pwa => 'Удалить из PWA';

  @override
  String get added_to_pwa => 'Добавлено в PWA';

  @override
  String get removed_from_pwa => 'Удалено из PWA';

  @override
  String get pwa_info =>
      'Прогрессивные веб-приложения работают как установленные приложения без элементов управления браузера';

  @override
  String get create_shortcut => 'Создать ярлык';

  @override
  String get enter_shortcut_name => 'Введите имя для этого ярлыка:';

  @override
  String get shortcut_name => 'Имя ярлыка';

  @override
  String get keep_tabs_open_description => 'Сохранять вкладки между сессиями';

  @override
  String get developer => 'Разработчик';

  @override
  String get reset_welcome_screen => 'Сбросить экран приветствия';

  @override
  String get restored_tab => 'Вкладка восстановлена';

  @override
  String get welcome_screen_reset => 'Сброс экрана приветствия';

  @override
  String get welcome_screen_reset_message =>
      'Это сбросит экран приветствия, чтобы он снова появился при следующем запуске приложения.';

  @override
  String get ok => 'ОК';

  @override
  String get customize_navigation => 'Настроить навигацию';

  @override
  String get button_back => 'Назад';

  @override
  String get button_forward => 'Вперед';

  @override
  String get button_bookmark => 'Закладка';

  @override
  String get button_bookmarks => 'Закладки';

  @override
  String get button_share => 'Поделиться';

  @override
  String get button_menu => 'Меню';

  @override
  String get available_buttons => 'Доступные кнопки';

  @override
  String get add => 'ДОБАВИТЬ';

  @override
  String get rename_pwa => 'Переименовать PWA';

  @override
  String get pwa_name => 'Имя PWA';

  @override
  String get rename => 'Переименовать';

  @override
  String get pwa_renamed => 'PWA переименовано';

  @override
  String get remove => 'Удалить';

  @override
  String get pwa_removed => 'PWA удалено';

  @override
  String get bookmark_removed => 'Закладка удалена';

  @override
  String get untitled => 'Без названия';

  @override
  String get show_welcome_screen_next_launch =>
      'Показать экран приветствия при следующем запуске';

  @override
  String get automatically_open_downloaded_files =>
      'Автоматически открывать загруженные файлы';

  @override
  String get ask_where_to_save_files =>
      'Спрашивать, где сохранять файлы перед загрузкой';

  @override
  String get clear_all_history => 'Очистить Всю Историю';

  @override
  String get clear_all_history_confirm =>
      'Это навсегда удалит всю вашу историю просмотров. Это действие нельзя отменить.';

  @override
  String get history_cleared => 'История очищена';

  @override
  String get navigation_controls => 'Элементы Навигации';

  @override
  String get ai_settings => 'Настройки ИИ';

  @override
  String get ai_summary_settings => 'Настройки Резюме ИИ';

  @override
  String get ask_download_location_title => 'Спросить Местоположение Загрузки';

  @override
  String get enable_incognito_mode => 'Включить режим инкогнито';

  @override
  String get disable_incognito_mode => 'Отключить режим инкогнито';

  @override
  String get close_all_tabs => 'Закрыть Все';

  @override
  String get close_all_tabs_confirm =>
      'Вы уверены, что хотите закрыть все вкладки? Это действие нельзя отменить.';

  @override
  String close_all_tabs_in_group(String groupName) {
    return 'Закрыть все вкладки в \"$groupName\"? Это действие нельзя отменить.';
  }

  @override
  String get other => 'Другое';

  @override
  String get ai => 'ИИ';

  @override
  String get rearrange_navigation_buttons => 'Переупорядочить кнопки навигации';

  @override
  String get current_navigation_bar => 'Текущая панель навигации:';

  @override
  String get tap_to_check_permission_status =>
      'Нажмите, чтобы проверить статус разрешений';

  @override
  String get create_tab_group => 'Создать группу вкладок';

  @override
  String get manage_groups => 'Управлять группами';

  @override
  String get no_groups_created_yet => 'Группы еще не созданы';

  @override
  String get group_name => 'Имя группы';

  @override
  String get color => 'Цвет';

  @override
  String get close_group => 'Закрыть группу';

  @override
  String get create => 'Создать';

  @override
  String get summarize => 'Резюмировать';

  @override
  String get no_summaries_available => 'Нет доступных резюме';

  @override
  String get page_summary => 'Резюме страницы';

  @override
  String get failed_to_generate_summary => 'Не удалось создать резюме';

  @override
  String get try_again => 'Попробовать Снова';

  @override
  String get no_page_to_summarize => 'Нет страницы для резюмирования';

  @override
  String get no_content_found_to_summarize =>
      'Не найдено содержимое для резюмирования';

  @override
  String get theme => 'Тема';

  @override
  String get check => 'Проверить';

  @override
  String get pwa => 'PWA';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get input_required => 'Требуется ввод';

  @override
  String get alert => 'Предупреждение';

  @override
  String get add_tabs_to_group => 'Добавить вкладки в группу';

  @override
  String get ungroup_tabs => 'Разгруппировать вкладки';

  @override
  String get delete_group => 'Удалить группу';

  @override
  String get copy_summary => 'Копировать резюме';

  @override
  String get image_link_copied =>
      'Ссылка на изображение скопирована в буфер обмена';

  @override
  String get link_copied => 'Ссылка скопирована в буфер обмена';

  @override
  String get error_loading_page => 'Ошибка загрузки страницы';

  @override
  String get no_page_to_install => 'Нет страницы для установки как PWA';

  @override
  String get pwa_installed => 'PWA установлено';

  @override
  String get failed_to_install_pwa => 'Не удалось установить PWA';

  @override
  String get creating_shortcut => 'Создание ярлыка';

  @override
  String get check_home_screen_for_shortcut =>
      'Проверьте ярлык на главном экране';

  @override
  String get error_opening_file_install_app =>
      'Ошибка при открытии файла. Пожалуйста, установите подходящее приложение для открытия этого типа файлов.';

  @override
  String get full_storage_access_needed =>
      'Для загрузки немультимедийных файлов необходим полный доступ к хранилищу';

  @override
  String get error_removing_download => 'Ошибка при удалении загрузки';

  @override
  String get copy_image => 'Копировать изображение';

  @override
  String get text_copied => 'Текст скопирован';

  @override
  String get text_pasted => 'Текст вставлен';

  @override
  String get text_cut => 'Текст вырезан';

  @override
  String get clipboard_empty => 'Буфер обмена пуст';

  @override
  String get paste_error => 'Ошибка при вставке текста';

  @override
  String get cut_error => 'Ошибка при вырезании текста';

  @override
  String get image_url_copied => 'URL изображения скопирован';

  @override
  String get opened_in_new_tab => 'Открыто в новой вкладке';

  @override
  String get image_options => 'Параметры изображения';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get cut => 'Вырезать';

  @override
  String get solarKeyToCosmos => 'SOLAR - KEY TO THE COSMOS';

  @override
  String get legalInformation => 'Правовая Информация';

  @override
  String get acceptContinue => 'Принять и Продолжить';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get systemThemeDesc => 'Следует системе';

  @override
  String get lightThemeDesc => 'Яркая и чистая';

  @override
  String get darkThemeDesc => 'Легкая для глаз';

  @override
  String get solarizedLightThemeDesc => 'Теплая светлая тема';

  @override
  String get nordLightThemeDesc => 'Прохладная светлая тема';

  @override
  String get gruvboxLightThemeDesc => 'Ретро светлая тема';

  @override
  String get tokyoNightThemeDesc => 'Яркая ночная тема';

  @override
  String get draculaThemeDesc => 'Темно-фиолетовая тема';

  @override
  String get nordThemeDesc => 'Прохладная темная тема';

  @override
  String get gruvboxThemeDesc => 'Ретро темная тема';

  @override
  String get oneDarkThemeDesc => 'Тема в стиле редактора';

  @override
  String get catppuccinThemeDesc => 'Пастельная темная тема';

  @override
  String get latestNews => 'Последние Новости';

  @override
  String get errorLoadingNews => 'Ошибка загрузки новостей';

  @override
  String get defaultLocation => 'Местоположение по умолчанию';

  @override
  String get webApp => 'Веб-приложение';

  @override
  String get exampleUrl => 'https://пример.com';

  @override
  String get enterText => 'Введите текст...';

  @override
  String get failed_to_get_news_data =>
      'Не удалось получить ссылку на данные новостей с сервера';

  @override
  String get failed_to_load_news_server =>
      'Не удалось загрузить новости с сервера';

  @override
  String get network_error_loading_news => 'Ошибка сети при загрузке новостей';

  @override
  String get failed_to_download_file => 'Не удалось скачать файл';

  @override
  String get failed_to_summarize_page =>
      'Не удалось создать краткое изложение страницы';

  @override
  String get firebase_not_initialized =>
      'Firebase не инициализирован. Пожалуйста, проверьте вашу конфигурацию.';

  @override
  String get close_all => 'Закрыть Все';

  @override
  String get delete_file => 'Удалить Файл';

  @override
  String get delete_file_confirm =>
      'Вы уверены, что хотите навсегда удалить этот файл с вашего устройства?';

  @override
  String get remove_from_history => 'Удалить из Истории';

  @override
  String get delete_from_device => 'Удалить с Устройства';

  @override
  String get notice => 'Уведомление';

  @override
  String get cannot_write_selected_folder =>
      'Невозможно записать в выбранную папку. Используется папка загрузок по умолчанию.';

  @override
  String get cannot_write_selected_folder_choose_different =>
      'Невозможно записать в выбранную папку. Пожалуйста, выберите другое местоположение.';

  @override
  String get cannot_write_configured_folder =>
      'Невозможно записать в настроенную папку. Используется папка загрузок по умолчанию.';

  @override
  String get error_selecting_folder_default =>
      'Ошибка выбора папки. Используется папка загрузок по умолчанию.';

  @override
  String get file_saved_to_app_storage =>
      'Файл сохранен в хранилище приложения вместо выбранной папки';

  @override
  String get failed_write_any_location =>
      'Не удалось записать файл в любое местоположение';

  @override
  String get settings_action => 'Настройки';

  @override
  String save_to_downloads_folder(String fileName) {
    return 'Чтобы сохранить \"$fileName\" в папку Загрузки, где вы можете найти его в Галерее или Файловом менеджере, Solar нужно разрешение на хранение.';
  }

  @override
  String get without_permission_private_folder =>
      'Без разрешения файл будет сохранен в частную папку Solar (доступную из панели Загрузки).';

  @override
  String get enable_unknown_apps_android =>
      'Возможно, вам нужно будет включить \"Установка неизвестных приложений\" в настройках Android после загрузки.';

  @override
  String get private_folder_instead =>
      'Файлы будут сохранены в частную папку Solar вместо этого.';

  @override
  String get save_to_downloads_title => 'Сохранить в Загрузки?';

  @override
  String get save_to_gallery_title => 'Сохранить в Галерею?';

  @override
  String get storage_access_required => 'Требуется доступ к хранилищу';

  @override
  String install_package_title(String packageName) {
    return 'Установить $packageName?';
  }

  @override
  String install_package_message(String packageName) {
    return 'Это загрузит и подготовит \"$packageName\" для установки на ваше устройство.';
  }

  @override
  String get save_to_gallery_message =>
      'Чтобы сохранить изображения и видео в ваше приложение Галерея, где они будут видны во всей системе, Solar нужен доступ к медиа.';

  @override
  String get storage_access_message =>
      'Чтобы сохранить файлы в хранилище вашего устройства, Solar нужны разрешения доступа к хранилищу.';

  @override
  String get photos_videos_audio_permission => 'Фото, Видео и Аудио';

  @override
  String get storage_media_access_permission => 'Доступ к Хранилищу и Медиа';

  @override
  String get package_installation_permission => 'Установка Пакетов';

  @override
  String get storage_access_permission => 'Доступ к Хранилищу';

  @override
  String get without_gallery_permission =>
      'Без разрешения медиафайлы будут видны только в разделе Загрузки Solar.';

  @override
  String get flutter_version_string => 'Flutter 3.32.5';

  @override
  String get photoncore_version_string => 'Photoncore 0.1.0';

  @override
  String get engine_version_string => '4.7.0';

  @override
  String get http_warning_title => 'Предупреждение о Небезопасном Соединении';

  @override
  String get http_warning_message =>
      'Вы собираетесь посетить веб-сайт, который использует небезопасное соединение (HTTP). Ваши данные могут быть видны другим. Вы уверены, что хотите продолжить?';

  @override
  String get continue_anyway => 'Все равно Продолжить';

  @override
  String get go_back => 'Вернуться Назад';

  @override
  String get continue_in_browser => 'Продолжить в браузере';

  @override
  String get web_page_error_title => 'Ошибка Загрузки Страницы';

  @override
  String get connection_error => 'Ошибка Соединения';

  @override
  String get page_not_found => 'Страница Не Найдена';

  @override
  String get connection_reset => 'Соединение Сброшено';

  @override
  String get connection_timed_out => 'Время Ожидания Соединения Истекло';

  @override
  String get dns_error => 'Ошибка DNS';

  @override
  String get ssl_error => 'Ошибка SSL Сертификата';

  @override
  String get network_error => 'Ошибка Сети';

  @override
  String get server_error => 'Ошибка Сервера';

  @override
  String get unable_to_connect =>
      'Не удается подключиться к веб-сайту. Проверьте ваше интернет-соединение и попробуйте снова.';

  @override
  String get page_not_found_description =>
      'Запрашиваемая страница не найдена на сервере. Страница могла быть перемещена или удалена.';

  @override
  String get connection_reset_description =>
      'Соединение с сервером было сброшено. Это может быть временной проблемой.';

  @override
  String get connection_timeout_description =>
      'Время ожидания соединения с сервером истекло. Сервер может быть занят или ваше соединение может быть медленным.';

  @override
  String get dns_error_description =>
      'Не удается найти веб-сайт. Проверьте веб-адрес и попробуйте снова.';

  @override
  String get ssl_error_description =>
      'Проблема с сертификатом безопасности веб-сайта. Соединение может быть небезопасным.';

  @override
  String get network_error_description =>
      'Произошла ошибка сети. Проверьте ваше интернет-соединение и попробуйте снова.';

  @override
  String get server_error_description =>
      'Сервер столкнулся с ошибкой и не смог выполнить ваш запрос.';

  @override
  String get go_home => 'На Главную';

  @override
  String get package_downloaded => 'Пакет загружен!';

  @override
  String get installation_steps => 'Шаги установки:';

  @override
  String get installation_instructions =>
      '1. Нажмите \"Установить\" ниже, чтобы открыть пакет\n2. Включите \"Установка неизвестных приложений\", если будет предложено\n3. Следуйте мастеру установки Android';

  @override
  String get view => 'Просмотр';

  @override
  String get install => 'Установить';

  @override
  String get file_deleted_from_device => 'Файл удален с устройства';

  @override
  String get cannot_open_file_path_not_found =>
      'Невозможно открыть файл: путь не найден';

  @override
  String error_opening_file_message(String message) {
    return 'Ошибка открытия файла: $message';
  }

  @override
  String error_opening_file_exception(String error) {
    return 'Ошибка открытия файла: $error';
  }

  @override
  String get app_not_installed =>
      'Не удается открыть эту ссылку. Требуемое приложение может быть не установлено.';

  @override
  String app_launch_failed(String appName) {
    return 'Не удается открыть $appName. Приложение может быть не установлено.';
  }

  @override
  String get app_required_not_installed =>
      'Эта ссылка требует приложение, которое не установлено.';

  @override
  String get invalid_link_format => 'Неверный формат ссылки.';

  @override
  String get cannot_open_link =>
      'Не удается открыть эту ссылку. Необходимое приложение может быть не установлено.';

  @override
  String get email_app_not_found => 'No email app found to send this message.';

  @override
  String get phone_app_not_found => 'No phone app found to make this call.';

  @override
  String get sms_app_not_found => 'No messaging app found to send this SMS.';

  @override
  String open_in_app_title(String appName) {
    return 'Open in $appName?';
  }

  @override
  String open_in_app_message(String appName) {
    return 'This link can be opened in the $appName app for a better experience.';
  }

  @override
  String open_in_app_button(String appName) {
    return 'Open in $appName';
  }

  @override
  String get advanced => 'Расширенные';

  @override
  String get disable_javascript_warning => 'Отключить JavaScript';

  @override
  String get disable_javascript_message =>
      'Отключение JavaScript может привести к неправильной работе многих веб-сайтов. Вы уверены?';

  @override
  String get disable => 'Отключить';

  @override
  String get keep_enabled => 'Оставить включенным';

  @override
  String get javascript_enabled => 'JavaScript включен';

  @override
  String get javascript_disabled => 'JavaScript отключен';

  @override
  String get error_network => 'Network error';

  @override
  String get error_connection_failed => 'Connection failed';

  @override
  String get error_timeout => 'Request timeout';

  @override
  String get error_not_found => 'Page not found';

  @override
  String get error_server => 'Server error';

  @override
  String get error_unknown => 'Unknown error occurred';

  @override
  String get error_ssl => 'SSL connection error';

  @override
  String get error_dns => 'DNS resolution failed';

  @override
  String get warning => 'Предупреждение';

  @override
  String get custom_home_url_unreachable =>
      'Не удалось получить доступ к URL. Продолжить?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';
}
