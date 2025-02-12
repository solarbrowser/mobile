import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @welcomeToSolar.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Solar'**
  String get welcomeToSolar;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'A modern, fast, and secure browser'**
  String get welcomeDescription;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get termsOfService;

  /// No description provided for @whats_new.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whats_new;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguage;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Theme'**
  String get chooseTheme;

  /// No description provided for @chooseSearchEngine.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Search Engine'**
  String get chooseSearchEngine;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Solar Browser Updated!'**
  String get updated;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @data_collection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get data_collection;

  /// No description provided for @data_collection_details.
  ///
  /// In en, this message translates to:
  /// **'• We collect minimal data necessary for browser functionality\n• Your browsing history stays on your device\n• We don\'t track your online activity\n• You can clear all data at any time'**
  String get data_collection_details;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @search_engine.
  ///
  /// In en, this message translates to:
  /// **'Search Engine'**
  String get search_engine;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @text_size.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get text_size;

  /// No description provided for @show_images.
  ///
  /// In en, this message translates to:
  /// **'Show Images'**
  String get show_images;

  /// No description provided for @download_location.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get download_location;

  /// No description provided for @ask_download_location.
  ///
  /// In en, this message translates to:
  /// **'Ask Download Location'**
  String get ask_download_location;

  /// No description provided for @rate_us.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rate_us;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @terms_of_use.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms_of_use;

  /// No description provided for @customize_browser.
  ///
  /// In en, this message translates to:
  /// **'Customize Browser'**
  String get customize_browser;

  /// No description provided for @learn_more.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learn_more;

  /// No description provided for @tabs.
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get tabs;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @search_in_page.
  ///
  /// In en, this message translates to:
  /// **'Search in page'**
  String get search_in_page;

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Solar Browser'**
  String get app_name;

  /// No description provided for @search_or_enter_address.
  ///
  /// In en, this message translates to:
  /// **'Search or enter address'**
  String get search_or_enter_address;

  /// No description provided for @current_location.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get current_location;

  /// No description provided for @change_location.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get change_location;

  /// No description provided for @clear_browser_data.
  ///
  /// In en, this message translates to:
  /// **'Clear Browser Data'**
  String get clear_browser_data;

  /// No description provided for @browsing_history.
  ///
  /// In en, this message translates to:
  /// **'Browsing History'**
  String get browsing_history;

  /// No description provided for @cookies.
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get cookies;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @form_data.
  ///
  /// In en, this message translates to:
  /// **'Form Data'**
  String get form_data;

  /// No description provided for @saved_passwords.
  ///
  /// In en, this message translates to:
  /// **'Saved Passwords'**
  String get saved_passwords;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @browser_data_cleared.
  ///
  /// In en, this message translates to:
  /// **'Browser data cleared'**
  String get browser_data_cleared;

  /// No description provided for @no_downloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get no_downloads;

  /// No description provided for @no_bookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get no_bookmarks;

  /// No description provided for @download_started.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get download_started;

  /// No description provided for @download_completed.
  ///
  /// In en, this message translates to:
  /// **'Download completed'**
  String get download_completed;

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get download_failed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_download.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get delete_download;

  /// No description provided for @delete_bookmark.
  ///
  /// In en, this message translates to:
  /// **'Delete Bookmark'**
  String get delete_bookmark;

  /// No description provided for @add_bookmark.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get add_bookmark;

  /// No description provided for @bookmark_added.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmark_added;

  /// No description provided for @bookmark_exists.
  ///
  /// In en, this message translates to:
  /// **'Already bookmarked'**
  String get bookmark_exists;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy_link.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copy_link;

  /// No description provided for @paste_and_go.
  ///
  /// In en, this message translates to:
  /// **'Paste and Go'**
  String get paste_and_go;

  /// No description provided for @find_in_page.
  ///
  /// In en, this message translates to:
  /// **'Find in Page'**
  String get find_in_page;

  /// No description provided for @desktop_site.
  ///
  /// In en, this message translates to:
  /// **'Desktop Site'**
  String get desktop_site;

  /// No description provided for @new_tab.
  ///
  /// In en, this message translates to:
  /// **'New Tab'**
  String get new_tab;

  /// No description provided for @close_tab.
  ///
  /// In en, this message translates to:
  /// **'Close Tab'**
  String get close_tab;

  /// No description provided for @tab_overview.
  ///
  /// In en, this message translates to:
  /// **'Tab Overview'**
  String get tab_overview;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @reset_browser.
  ///
  /// In en, this message translates to:
  /// **'Reset Browser'**
  String get reset_browser;

  /// No description provided for @reset_browser_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will clear all your data including history, bookmarks, and settings. This action cannot be undone.'**
  String get reset_browser_confirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @reset_complete.
  ///
  /// In en, this message translates to:
  /// **'Browser has been reset'**
  String get reset_complete;

  /// No description provided for @permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get permission_denied;

  /// No description provided for @download_location_changed.
  ///
  /// In en, this message translates to:
  /// **'Download location changed successfully'**
  String get download_location_changed;

  /// No description provided for @error_changing_location.
  ///
  /// In en, this message translates to:
  /// **'Error changing download location'**
  String get error_changing_location;

  /// No description provided for @enable_cookies.
  ///
  /// In en, this message translates to:
  /// **'Enable Cookies'**
  String get enable_cookies;

  /// No description provided for @enable_javascript.
  ///
  /// In en, this message translates to:
  /// **'Enable JavaScript'**
  String get enable_javascript;

  /// No description provided for @hardware_acceleration.
  ///
  /// In en, this message translates to:
  /// **'Hardware Acceleration'**
  String get hardware_acceleration;

  /// No description provided for @save_form_data.
  ///
  /// In en, this message translates to:
  /// **'Save Form Data'**
  String get save_form_data;

  /// No description provided for @do_not_track.
  ///
  /// In en, this message translates to:
  /// **'Do Not Track'**
  String get do_not_track;

  /// No description provided for @download_location_description.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save your downloaded files'**
  String get download_location_description;

  /// No description provided for @text_size_description.
  ///
  /// In en, this message translates to:
  /// **'Adjust the size of text on web pages'**
  String get text_size_description;

  /// No description provided for @text_size_small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get text_size_small;

  /// No description provided for @text_size_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get text_size_medium;

  /// No description provided for @text_size_large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get text_size_large;

  /// No description provided for @text_size_very_large.
  ///
  /// In en, this message translates to:
  /// **'Very Large'**
  String get text_size_very_large;

  /// No description provided for @cookies_description.
  ///
  /// In en, this message translates to:
  /// **'Allow websites to save and read cookie data'**
  String get cookies_description;

  /// No description provided for @javascript_description.
  ///
  /// In en, this message translates to:
  /// **'Enable JavaScript for better website functionality'**
  String get javascript_description;

  /// No description provided for @hardware_acceleration_description.
  ///
  /// In en, this message translates to:
  /// **'Use GPU for better performance'**
  String get hardware_acceleration_description;

  /// No description provided for @form_data_description.
  ///
  /// In en, this message translates to:
  /// **'Save information entered in forms'**
  String get form_data_description;

  /// No description provided for @do_not_track_description.
  ///
  /// In en, this message translates to:
  /// **'Request websites not to track your activity'**
  String get do_not_track_description;

  /// No description provided for @exit_app.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exit_app;

  /// No description provided for @exit_app_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exit_app_confirm;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @auto_open_downloads.
  ///
  /// In en, this message translates to:
  /// **'Auto-open downloads'**
  String get auto_open_downloads;

  /// No description provided for @clear_downloads_history.
  ///
  /// In en, this message translates to:
  /// **'Clear downloads history'**
  String get clear_downloads_history;

  /// No description provided for @downloads_history_cleared.
  ///
  /// In en, this message translates to:
  /// **'Downloads history cleared'**
  String get downloads_history_cleared;

  /// Confirmation message for deleting a download from history
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete {fileName} from downloads history?\nThe downloaded file will not be deleted.'**
  String delete_download_confirm(String fileName);

  /// No description provided for @download_removed.
  ///
  /// In en, this message translates to:
  /// **'Download removed from history'**
  String get download_removed;

  /// No description provided for @download_size.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String download_size(String size);

  /// No description provided for @clear_downloads_history_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will only clear the downloads history, not the downloaded files.'**
  String get clear_downloads_history_confirm;

  /// No description provided for @clear_downloads_history_title.
  ///
  /// In en, this message translates to:
  /// **'Clear Downloads History'**
  String get clear_downloads_history_title;

  /// No description provided for @slide_up_panel.
  ///
  /// In en, this message translates to:
  /// **'Slide up panel'**
  String get slide_up_panel;

  /// No description provided for @slide_down_panel.
  ///
  /// In en, this message translates to:
  /// **'Slide down panel'**
  String get slide_down_panel;

  /// No description provided for @move_url_bar.
  ///
  /// In en, this message translates to:
  /// **'Move URL bar'**
  String get move_url_bar;

  /// No description provided for @url_bar_icon.
  ///
  /// In en, this message translates to:
  /// **'URL bar icon'**
  String get url_bar_icon;

  /// No description provided for @url_bar_expanded.
  ///
  /// In en, this message translates to:
  /// **'URL bar expanded'**
  String get url_bar_expanded;

  /// No description provided for @search_or_type_url.
  ///
  /// In en, this message translates to:
  /// **'Search or type URL'**
  String get search_or_type_url;

  /// No description provided for @secure_connection.
  ///
  /// In en, this message translates to:
  /// **'Secure connection'**
  String get secure_connection;

  /// No description provided for @insecure_connection.
  ///
  /// In en, this message translates to:
  /// **'Insecure connection'**
  String get insecure_connection;

  /// No description provided for @refresh_page.
  ///
  /// In en, this message translates to:
  /// **'Refresh page'**
  String get refresh_page;

  /// No description provided for @close_search.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get close_search;

  /// No description provided for @allow_popups.
  ///
  /// In en, this message translates to:
  /// **'Pop-ups'**
  String get allow_popups;

  /// No description provided for @allow_popups_description.
  ///
  /// In en, this message translates to:
  /// **'Allow pop-up windows'**
  String get allow_popups_description;

  /// No description provided for @popups_blocked.
  ///
  /// In en, this message translates to:
  /// **'Pop-up blocked'**
  String get popups_blocked;

  /// No description provided for @allow_once.
  ///
  /// In en, this message translates to:
  /// **'Allow once'**
  String get allow_once;

  /// No description provided for @allow_always.
  ///
  /// In en, this message translates to:
  /// **'Allow always'**
  String get allow_always;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @blocked_popups.
  ///
  /// In en, this message translates to:
  /// **'Blocked pop-ups'**
  String get blocked_popups;

  /// No description provided for @no_blocked_popups.
  ///
  /// In en, this message translates to:
  /// **'No blocked pop-ups'**
  String get no_blocked_popups;

  /// Message shown when allowing popups from a specific domain
  ///
  /// In en, this message translates to:
  /// **'Allow pop-ups from {domain}'**
  String allow_popups_from(String domain);

  /// No description provided for @exit_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exit_confirmation;

  /// Flutter version label
  ///
  /// In en, this message translates to:
  /// **'Flutter Version'**
  String get flutter_version;

  /// Software team label
  ///
  /// In en, this message translates to:
  /// **'Software Team'**
  String get software_team;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'hi', 'it', 'ja', 'pt', 'ru', 'tr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'tr': return AppLocalizationsTr();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
