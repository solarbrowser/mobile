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
import 'app_localizations_ko.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('tr'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
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

  /// No description provided for @selectAppearance.
  ///
  /// In en, this message translates to:
  /// **'Select how the app should look'**
  String get selectAppearance;

  /// No description provided for @selectSearchEngine.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred search engine'**
  String get selectSearchEngine;

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

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @tokyoNightTheme.
  ///
  /// In en, this message translates to:
  /// **'Tokyo Night'**
  String get tokyoNightTheme;

  /// No description provided for @solarizedLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Solarized Light'**
  String get solarizedLightTheme;

  /// No description provided for @draculaTheme.
  ///
  /// In en, this message translates to:
  /// **'Dracula'**
  String get draculaTheme;

  /// No description provided for @nordTheme.
  ///
  /// In en, this message translates to:
  /// **'Nord'**
  String get nordTheme;

  /// No description provided for @gruvboxTheme.
  ///
  /// In en, this message translates to:
  /// **'Gruvbox'**
  String get gruvboxTheme;

  /// No description provided for @oneDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'One Dark'**
  String get oneDarkTheme;

  /// No description provided for @catppuccinTheme.
  ///
  /// In en, this message translates to:
  /// **'Catppuccin'**
  String get catppuccinTheme;

  /// No description provided for @nordLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Nord Light'**
  String get nordLightTheme;

  /// No description provided for @gruvboxLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Gruvbox Light'**
  String get gruvboxLightTheme;

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

  /// Skip button text in permission dialogs
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @disable_classic_navigation_warning.
  ///
  /// In en, this message translates to:
  /// **'Disable Classic Navigation'**
  String get disable_classic_navigation_warning;

  /// No description provided for @disable_classic_navigation_message.
  ///
  /// In en, this message translates to:
  /// **'When classic navigation is disabled, you will switch to a swipe-based navigation system. In this system, you can swipe up the address bar to access many features, and swipe the address bar left or right to navigate forward or backward.'**
  String get disable_classic_navigation_message;

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

  /// Notifications section title in onboarding
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Description for notification permission in onboarding
  ///
  /// In en, this message translates to:
  /// **'Get notified when files are downloaded to your device'**
  String get notificationDescription;

  /// Button text to allow notifications
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get allowNotifications;

  /// Button text to skip notifications
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// Time indicator for events that just happened
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get just_now;

  /// Time indicator for events that happened minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String min_ago(int minutes);

  /// Time indicator for events that happened hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String hr_ago(int hours);

  /// Time indicator for events that happened yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

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

  /// Settings button label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Help menu item
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// About menu item
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

  /// Rate us menu item
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rate_us;

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// Terms of use menu item
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

  /// No description provided for @keep_tabs_open.
  ///
  /// In en, this message translates to:
  /// **'Keep Tabs Open'**
  String get keep_tabs_open;

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
  /// **'Solar'**
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

  /// Generic close button text
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

  /// Delete button text
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

  /// Label for new tab button
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

  /// No description provided for @permission_permanently_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission permanently denied. Please enable it in Settings.'**
  String get permission_permanently_denied;

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

  /// JavaScript toggle setting
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

  /// Setting title for auto-opening downloads
  ///
  /// In en, this message translates to:
  /// **'Auto-open Downloads'**
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

  /// No description provided for @sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sort_by;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

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

  /// No description provided for @install_packages_permission.
  ///
  /// In en, this message translates to:
  /// **'Install Packages Permission'**
  String get install_packages_permission;

  /// No description provided for @install_packages_permission_description.
  ///
  /// In en, this message translates to:
  /// **'Allow installation of apps from this browser'**
  String get install_packages_permission_description;

  /// No description provided for @permission_install_packages_required.
  ///
  /// In en, this message translates to:
  /// **'Install packages permission required'**
  String get permission_install_packages_required;

  /// No description provided for @storage_permission_install_packages_required.
  ///
  /// In en, this message translates to:
  /// **'Storage & Install Packages Permission'**
  String get storage_permission_install_packages_required;

  /// No description provided for @storage_permission_install_packages_description.
  ///
  /// In en, this message translates to:
  /// **'Solar Browser needs permission to access storage for downloads and install packages for APK installations'**
  String get storage_permission_install_packages_description;

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

  /// Label for classic navigation mode
  ///
  /// In en, this message translates to:
  /// **'Classic Navigation'**
  String get classic_navigation;

  /// Description for classic navigation setting
  ///
  /// In en, this message translates to:
  /// **'Use classic browser-style navigation controls'**
  String get classic_navigation_description;

  /// No description provided for @exit_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exit_confirmation;

  /// No description provided for @flutter_version.
  ///
  /// In en, this message translates to:
  /// **'Flutter Version'**
  String get flutter_version;

  /// Label for Photoncore version in settings
  ///
  /// In en, this message translates to:
  /// **'Photoncore Version'**
  String get photoncore_version;

  /// Label for engine version in settings
  ///
  /// In en, this message translates to:
  /// **'Engine Version'**
  String get engine_version;

  /// Software team label
  ///
  /// In en, this message translates to:
  /// **'Software Team'**
  String get software_team;

  /// Option to download an image
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get download_image;

  /// Option to share an image
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get share_image;

  /// Option to open something in a new tab
  ///
  /// In en, this message translates to:
  /// **'Open in New Tab'**
  String get open_in_new_tab;

  /// Option to copy an image link
  ///
  /// In en, this message translates to:
  /// **'Copy Image Link'**
  String get copy_image_link;

  /// Text for opening an image in a new tab
  ///
  /// In en, this message translates to:
  /// **'Open Image in New Tab'**
  String get open_image_in_new_tab;

  /// Option to open a link
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get open_link;

  /// Option to open a link in a new tab
  ///
  /// In en, this message translates to:
  /// **'Open Link in New Tab'**
  String get open_link_in_new_tab;

  /// Option to copy a link address
  ///
  /// In en, this message translates to:
  /// **'Copy Link Address'**
  String get copy_link_address;

  /// Error message when image download fails
  ///
  /// In en, this message translates to:
  /// **'Failed to download image'**
  String get failed_to_download_image;

  /// Setting to enable custom home page
  ///
  /// In en, this message translates to:
  /// **'Custom Home Page'**
  String get custom_home_page;

  /// Option to set the home page URL
  ///
  /// In en, this message translates to:
  /// **'Set Home Page URL'**
  String get set_home_page_url;

  /// Indicates that a value is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get not_set;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Status message when a file is being downloaded
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Message shown when there are no downloads
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get no_downloads_yet;

  /// Unknown permission status
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Message shown when user needs to press back again to exit the app
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get press_back_to_exit;

  /// Title for the permission request banner
  ///
  /// In en, this message translates to:
  /// **'Give Permission'**
  String get storage_permission_required;

  /// Title shown when all permissions are granted
  ///
  /// In en, this message translates to:
  /// **'All permissions given'**
  String get storage_permission_granted;

  /// Description text for the permission request
  ///
  /// In en, this message translates to:
  /// **'This app needs permission to access files for download functionality.'**
  String get storage_permission_description;

  /// Description text shown when all permissions are granted
  ///
  /// In en, this message translates to:
  /// **'The app should now work normally with full functionality.'**
  String get app_should_work_normally;

  /// Text for the permission grant button
  ///
  /// In en, this message translates to:
  /// **'Give Permission'**
  String get grant_permission;

  /// Title for download permissions section
  ///
  /// In en, this message translates to:
  /// **'Download Permissions'**
  String get download_permissions;

  /// Subtitle for download permissions setting
  ///
  /// In en, this message translates to:
  /// **'Manage permissions for downloads'**
  String get manage_download_permissions;

  /// Storage permission label
  ///
  /// In en, this message translates to:
  /// **'Storage Access'**
  String get storage_permission;

  /// Notification permission label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification_permission;

  /// Description for notification permission
  ///
  /// In en, this message translates to:
  /// **'For download progress and completion alerts'**
  String get notification_permission_description;

  /// Explanation text for permissions dialog
  ///
  /// In en, this message translates to:
  /// **'These permissions help improve your download experience. You can change them anytime in Android Settings.'**
  String get permission_explanation;

  /// Description for clear downloads history option
  ///
  /// In en, this message translates to:
  /// **'Remove download history (files remain)'**
  String get clear_downloads_history_description;

  /// Description for download location setting
  ///
  /// In en, this message translates to:
  /// **'Change where files are saved'**
  String get change_download_location;

  /// Request button text for permissions
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// Storage permission label
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// Manage external storage permission label
  ///
  /// In en, this message translates to:
  /// **'Manage External Storage'**
  String get manage_external_storage;

  /// Notification permission label
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// Permission granted status
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// Permission denied status
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// Permission restricted status
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get restricted;

  /// Permission limited status
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get limited;

  /// Permission permanently denied status
  ///
  /// In en, this message translates to:
  /// **'Permanently Denied'**
  String get permanently_denied;

  /// Message shown when storage permission is denied
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to download files'**
  String get storage_permission_denied;

  /// Label for new incognito tab button
  ///
  /// In en, this message translates to:
  /// **'New Incognito Tab'**
  String get new_incognito_tab;

  /// Incognito mode label
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get incognito_mode;

  /// Description of incognito mode features
  ///
  /// In en, this message translates to:
  /// **'In Incognito mode:\n• Browsing history isn\'t saved\n• Cookies are cleared when you close tabs\n• No data is stored locally'**
  String get incognito_description;

  /// Error message when a file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Error opening file'**
  String get error_opening_file;

  /// Message shown when a download is in progress
  ///
  /// In en, this message translates to:
  /// **'Download in progress'**
  String get download_in_progress;

  /// Message shown when a download is paused
  ///
  /// In en, this message translates to:
  /// **'Download paused'**
  String get download_paused;

  /// Message shown when a download is canceled
  ///
  /// In en, this message translates to:
  /// **'Download canceled'**
  String get download_canceled;

  /// Message shown when there is an error during download
  ///
  /// In en, this message translates to:
  /// **'Download error: {error}'**
  String download_error(String error);

  /// Label for button to open downloads folder
  ///
  /// In en, this message translates to:
  /// **'Open downloads folder'**
  String get open_downloads_folder;

  /// Message shown when trying to download a file that already exists
  ///
  /// In en, this message translates to:
  /// **'File already exists'**
  String get file_exists;

  /// Message shown when a file is successfully saved
  ///
  /// In en, this message translates to:
  /// **'File saved to Downloads'**
  String get file_saved;

  /// No description provided for @no_tabs_open.
  ///
  /// In en, this message translates to:
  /// **'No tabs open'**
  String get no_tabs_open;

  /// Incognito mode label
  ///
  /// In en, this message translates to:
  /// **'Incognito'**
  String get incognito;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clear_all;

  /// No description provided for @clear_history.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// No description provided for @clear_history_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your browsing history?'**
  String get clear_history_confirmation;

  /// No description provided for @no_history.
  ///
  /// In en, this message translates to:
  /// **'No browsing history'**
  String get no_history;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Shows how many days ago something happened
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String days_ago(int days);

  /// Shows how many weeks ago something happened
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String weeks_ago(int weeks);

  /// Shows how many months ago something happened
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String months_ago(int months);

  /// Title for first update note
  ///
  /// In en, this message translates to:
  /// **'Enhanced Theme System'**
  String get update1;

  /// Description for first update
  ///
  /// In en, this message translates to:
  /// **'Introducing a beautiful new theme system with more color options and improved dark mode support'**
  String get update1desc;

  /// Title for second update note
  ///
  /// In en, this message translates to:
  /// **'Performance Improvements'**
  String get update2;

  /// Description for second update
  ///
  /// In en, this message translates to:
  /// **'Faster page loading and smoother scrolling experience'**
  String get update2desc;

  /// Title for third update note
  ///
  /// In en, this message translates to:
  /// **'New Privacy Features'**
  String get update3;

  /// Description for third update
  ///
  /// In en, this message translates to:
  /// **'Enhanced tracking protection and improved incognito mode'**
  String get update3desc;

  /// Title for fourth update note
  ///
  /// In en, this message translates to:
  /// **'UI Refinements'**
  String get update4;

  /// Description for fourth update
  ///
  /// In en, this message translates to:
  /// **'Polished interface with better navigation and accessibility'**
  String get update4desc;

  /// Hint text shown in the search box
  ///
  /// In en, this message translates to:
  /// **'Search the web'**
  String get searchTheWeb;

  /// Title for the list of recent searches
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// Previous summaries button text
  ///
  /// In en, this message translates to:
  /// **'Previous Summaries'**
  String get previous_summaries;

  /// Label for summarizing selected text
  ///
  /// In en, this message translates to:
  /// **'Summarize Selected'**
  String get summarize_selected;

  /// Label for summarizing the entire page
  ///
  /// In en, this message translates to:
  /// **'Summarize Page'**
  String get summarize_page;

  /// Label for AI preferences section
  ///
  /// In en, this message translates to:
  /// **'AI Preferences'**
  String get ai_preferences;

  /// Label for AI provider selection
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get ai_provider;

  /// Label for AI summary length preference
  ///
  /// In en, this message translates to:
  /// **'Summary Length'**
  String get summary_length;

  /// No description provided for @generating_summary.
  ///
  /// In en, this message translates to:
  /// **'Generating summary...'**
  String get generating_summary;

  /// Notification message when summary is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Summary copied to clipboard'**
  String get summary_copied_to_clipboard;

  /// Label for AI summary language preference
  ///
  /// In en, this message translates to:
  /// **'Summary Language'**
  String get summary_language;

  /// Label for short summary length
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get length_short;

  /// Label for medium summary length
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get length_medium;

  /// Label for long summary length
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get length_long;

  /// Label for short summary length with word count
  ///
  /// In en, this message translates to:
  /// **'Short (75 words)'**
  String get summary_length_short;

  /// Label for medium summary length with word count
  ///
  /// In en, this message translates to:
  /// **'Medium (150 words)'**
  String get summary_length_medium;

  /// Label for long summary length with word count
  ///
  /// In en, this message translates to:
  /// **'Long (250 words)'**
  String get summary_length_long;

  /// Label for English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get summary_language_english;

  /// Label for Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get summary_language_turkish;

  /// Option to add current website as a PWA
  ///
  /// In en, this message translates to:
  /// **'Add to PWA'**
  String get add_to_pwa;

  /// Option to remove website from PWA list
  ///
  /// In en, this message translates to:
  /// **'Remove from PWA'**
  String get remove_from_pwa;

  /// Confirmation message when site is added as PWA
  ///
  /// In en, this message translates to:
  /// **'Added to PWA'**
  String get added_to_pwa;

  /// Confirmation message when site is removed from PWA list
  ///
  /// In en, this message translates to:
  /// **'Removed from PWA'**
  String get removed_from_pwa;

  /// Information about what PWAs are
  ///
  /// In en, this message translates to:
  /// **'Progressive Web Apps run like installed apps without browser controls'**
  String get pwa_info;

  /// Title for the shortcut creation dialog
  ///
  /// In en, this message translates to:
  /// **'Create Shortcut'**
  String get create_shortcut;

  /// Prompt for entering the shortcut name
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this shortcut:'**
  String get enter_shortcut_name;

  /// Hint for the shortcut name input field
  ///
  /// In en, this message translates to:
  /// **'Shortcut name'**
  String get shortcut_name;

  /// Description for keep tabs open setting
  ///
  /// In en, this message translates to:
  /// **'Keep tabs open between sessions'**
  String get keep_tabs_open_description;

  /// Developer section title
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Reset welcome screen option
  ///
  /// In en, this message translates to:
  /// **'Reset Welcome Screen'**
  String get reset_welcome_screen;

  /// Message when a tab is restored
  ///
  /// In en, this message translates to:
  /// **'Restored tab'**
  String get restored_tab;

  /// Dialog title for resetting welcome screen
  ///
  /// In en, this message translates to:
  /// **'Reset Welcome Screen'**
  String get welcome_screen_reset;

  /// Dialog message for resetting welcome screen
  ///
  /// In en, this message translates to:
  /// **'This will reset the welcome screen so it appears again next time you start the app.'**
  String get welcome_screen_reset_message;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Title for navigation customization
  ///
  /// In en, this message translates to:
  /// **'Customize Navigation'**
  String get customize_navigation;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get button_back;

  /// Forward button label
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get button_forward;

  /// Bookmark button label
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get button_bookmark;

  /// Bookmarks button label
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get button_bookmarks;

  /// Share button label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get button_share;

  /// Menu button label
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get button_menu;

  /// Label for available navigation buttons
  ///
  /// In en, this message translates to:
  /// **'Available buttons'**
  String get available_buttons;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Option to rename a PWA
  ///
  /// In en, this message translates to:
  /// **'Rename PWA'**
  String get rename_pwa;

  /// Hint for PWA name input field
  ///
  /// In en, this message translates to:
  /// **'PWA name'**
  String get pwa_name;

  /// Rename button text
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Confirmation message when PWA is renamed
  ///
  /// In en, this message translates to:
  /// **'PWA renamed'**
  String get pwa_renamed;

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Confirmation message when PWA is removed
  ///
  /// In en, this message translates to:
  /// **'PWA removed'**
  String get pwa_removed;

  /// Confirmation message when bookmark is removed
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmark_removed;

  /// Default title for untitled pages/tabs
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// Setting description for showing welcome screen
  ///
  /// In en, this message translates to:
  /// **'Show welcome screen on next launch'**
  String get show_welcome_screen_next_launch;

  /// Setting description for auto-opening downloads
  ///
  /// In en, this message translates to:
  /// **'Automatically open downloaded files'**
  String get automatically_open_downloaded_files;

  /// Setting description for asking download location
  ///
  /// In en, this message translates to:
  /// **'Ask where to save files before downloading'**
  String get ask_where_to_save_files;

  /// Button text for clearing all browsing history
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clear_all_history;

  /// Confirmation message for clearing all history
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your browsing history. This action cannot be undone.'**
  String get clear_all_history_confirm;

  /// Confirmation message when history is cleared
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get history_cleared;

  /// Title for navigation controls settings
  ///
  /// In en, this message translates to:
  /// **'Navigation Controls'**
  String get navigation_controls;

  /// Title for AI settings section
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get ai_settings;

  /// Title for AI summary settings
  ///
  /// In en, this message translates to:
  /// **'AI Summary Settings'**
  String get ai_summary_settings;

  /// Setting title for asking download location
  ///
  /// In en, this message translates to:
  /// **'Ask Download Location'**
  String get ask_download_location_title;

  /// Button to enable incognito mode
  ///
  /// In en, this message translates to:
  /// **'Enable Incognito Mode'**
  String get enable_incognito_mode;

  /// Button to disable incognito mode
  ///
  /// In en, this message translates to:
  /// **'Disable Incognito Mode'**
  String get disable_incognito_mode;

  /// Button to close all tabs
  ///
  /// In en, this message translates to:
  /// **'Close All Tabs'**
  String get close_all_tabs;

  /// Confirmation message for closing all tabs
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close all tabs? This action cannot be undone.'**
  String get close_all_tabs_confirm;

  /// Confirmation message for closing all tabs in a group
  ///
  /// In en, this message translates to:
  /// **'Close all tabs in \"{groupName}\"? This action cannot be undone.'**
  String close_all_tabs_in_group(String groupName);

  /// Other section title
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Settings group title for AI options
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// Setting subtitle for navigation customization
  ///
  /// In en, this message translates to:
  /// **'Rearrange navigation buttons'**
  String get rearrange_navigation_buttons;

  /// Label for current navigation bar display
  ///
  /// In en, this message translates to:
  /// **'Current Navigation Bar:'**
  String get current_navigation_bar;

  /// Instruction for checking permission status
  ///
  /// In en, this message translates to:
  /// **'Tap to check permission status'**
  String get tap_to_check_permission_status;

  /// Dialog title for creating a new tab group
  ///
  /// In en, this message translates to:
  /// **'Create Tab Group'**
  String get create_tab_group;

  /// Dialog title for managing tab groups
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manage_groups;

  /// Message when no tab groups exist
  ///
  /// In en, this message translates to:
  /// **'No groups created yet'**
  String get no_groups_created_yet;

  /// Input label for tab group name
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get group_name;

  /// Color selection label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Dialog title for closing a tab group
  ///
  /// In en, this message translates to:
  /// **'Close Group'**
  String get close_group;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Summarize button text
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get summarize;

  /// Message when no summaries are available
  ///
  /// In en, this message translates to:
  /// **'No summaries available'**
  String get no_summaries_available;

  /// Page summary dialog title
  ///
  /// In en, this message translates to:
  /// **'Page Summary'**
  String get page_summary;

  /// Error message when summary generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate summary'**
  String get failed_to_generate_summary;

  /// Button text to retry loading page
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// Error message when there's no page to summarize
  ///
  /// In en, this message translates to:
  /// **'No page to summarize'**
  String get no_page_to_summarize;

  /// Error message when no content is found to summarize
  ///
  /// In en, this message translates to:
  /// **'No content found to summarize'**
  String get no_content_found_to_summarize;

  /// Theme settings title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Check button text
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// Progressive Web App button label
  ///
  /// In en, this message translates to:
  /// **'PWA'**
  String get pwa;

  /// Confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Input dialog title
  ///
  /// In en, this message translates to:
  /// **'Input Required'**
  String get input_required;

  /// Alert dialog title
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// Dialog title for adding tabs to a group
  ///
  /// In en, this message translates to:
  /// **'Add Tabs to Group'**
  String get add_tabs_to_group;

  /// Tooltip for ungrouping tabs
  ///
  /// In en, this message translates to:
  /// **'Ungroup tabs'**
  String get ungroup_tabs;

  /// Tooltip for deleting a tab group
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get delete_group;

  /// Button text for copying AI summary
  ///
  /// In en, this message translates to:
  /// **'Copy Summary'**
  String get copy_summary;

  /// Message shown when an image link is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Image link copied to clipboard'**
  String get image_link_copied;

  /// Message shown when a link is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get link_copied;

  /// Message shown when there is an error loading a page
  ///
  /// In en, this message translates to:
  /// **'Error loading page'**
  String get error_loading_page;

  /// Message shown when there is no page to install as PWA
  ///
  /// In en, this message translates to:
  /// **'No page to install as PWA'**
  String get no_page_to_install;

  /// Message shown when a PWA is successfully installed
  ///
  /// In en, this message translates to:
  /// **'PWA installed'**
  String get pwa_installed;

  /// Message shown when PWA installation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to install PWA'**
  String get failed_to_install_pwa;

  /// Message shown when creating a PWA shortcut
  ///
  /// In en, this message translates to:
  /// **'Creating shortcut...'**
  String get creating_shortcut;

  /// Message guiding user to check home screen for newly created shortcut
  ///
  /// In en, this message translates to:
  /// **'Check your home screen for the new shortcut'**
  String get check_home_screen_for_shortcut;

  /// Message shown when there is an error opening a file due to missing app
  ///
  /// In en, this message translates to:
  /// **'Error opening file. Please install a suitable app to open this type of file.'**
  String get error_opening_file_install_app;

  /// Message shown when full storage access is needed
  ///
  /// In en, this message translates to:
  /// **'Full storage access is needed for downloading non-media files'**
  String get full_storage_access_needed;

  /// Message shown when there is an error removing a download
  ///
  /// In en, this message translates to:
  /// **'Error removing download'**
  String get error_removing_download;

  /// Option to copy an image
  ///
  /// In en, this message translates to:
  /// **'Copy Image'**
  String get copy_image;

  /// Message shown when text is copied
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get text_copied;

  /// Message shown when text is pasted
  ///
  /// In en, this message translates to:
  /// **'Text pasted'**
  String get text_pasted;

  /// Message shown when text is cut
  ///
  /// In en, this message translates to:
  /// **'Text cut'**
  String get text_cut;

  /// Message shown when clipboard is empty
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboard_empty;

  /// Message shown when there is an error pasting text
  ///
  /// In en, this message translates to:
  /// **'Error pasting text'**
  String get paste_error;

  /// Message shown when there is an error cutting text
  ///
  /// In en, this message translates to:
  /// **'Error cutting text'**
  String get cut_error;

  /// Message shown when image URL is copied
  ///
  /// In en, this message translates to:
  /// **'Image URL copied'**
  String get image_url_copied;

  /// Message shown when something is opened in a new tab
  ///
  /// In en, this message translates to:
  /// **'Opened in new tab'**
  String get opened_in_new_tab;

  /// Title for the image options dialog
  ///
  /// In en, this message translates to:
  /// **'Image Options'**
  String get image_options;

  /// Text for copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Text for paste action
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Text for cut action
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// App tagline shown in onboarding welcome screen
  ///
  /// In en, this message translates to:
  /// **'SOLAR - KEY TO THE COSMOS'**
  String get solarKeyToCosmos;

  /// Title for privacy policy and terms dialog
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// Button to accept legal terms and continue
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get acceptContinue;

  /// Welcome text shown in onboarding
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Description for system theme option
  ///
  /// In en, this message translates to:
  /// **'Follows system'**
  String get systemThemeDesc;

  /// Description for light theme option
  ///
  /// In en, this message translates to:
  /// **'Bright and clean'**
  String get lightThemeDesc;

  /// Description for dark theme option
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get darkThemeDesc;

  /// Description for solarized light theme option
  ///
  /// In en, this message translates to:
  /// **'Warm light theme'**
  String get solarizedLightThemeDesc;

  /// Description for nord light theme option
  ///
  /// In en, this message translates to:
  /// **'Cool light theme'**
  String get nordLightThemeDesc;

  /// Description for gruvbox light theme option
  ///
  /// In en, this message translates to:
  /// **'Retro light theme'**
  String get gruvboxLightThemeDesc;

  /// Description for tokyo night theme option
  ///
  /// In en, this message translates to:
  /// **'Vibrant night theme'**
  String get tokyoNightThemeDesc;

  /// Description for dracula theme option
  ///
  /// In en, this message translates to:
  /// **'Dark purple theme'**
  String get draculaThemeDesc;

  /// Description for nord theme option
  ///
  /// In en, this message translates to:
  /// **'Cool dark theme'**
  String get nordThemeDesc;

  /// Description for gruvbox theme option
  ///
  /// In en, this message translates to:
  /// **'Retro dark theme'**
  String get gruvboxThemeDesc;

  /// Description for one dark theme option
  ///
  /// In en, this message translates to:
  /// **'Editor-inspired theme'**
  String get oneDarkThemeDesc;

  /// Description for catppuccin theme option
  ///
  /// In en, this message translates to:
  /// **'Pastel dark theme'**
  String get catppuccinThemeDesc;

  /// Title for latest news section
  ///
  /// In en, this message translates to:
  /// **'Latest News'**
  String get latestNews;

  /// Error message when news fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading news'**
  String get errorLoadingNews;

  /// Default download location text
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get defaultLocation;

  /// Default title for web applications
  ///
  /// In en, this message translates to:
  /// **'Web App'**
  String get webApp;

  /// Example URL placeholder
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get exampleUrl;

  /// Placeholder text for text input fields
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get enterText;

  /// Error message when unable to get news data link
  ///
  /// In en, this message translates to:
  /// **'Could not get news data link from server'**
  String get failed_to_get_news_data;

  /// Error message when news fails to load from server
  ///
  /// In en, this message translates to:
  /// **'Failed to load news from server'**
  String get failed_to_load_news_server;

  /// Error message when there's a network error loading news
  ///
  /// In en, this message translates to:
  /// **'Network error while loading news'**
  String get network_error_loading_news;

  /// Error message when file download fails
  ///
  /// In en, this message translates to:
  /// **'Failed to download file'**
  String get failed_to_download_file;

  /// Error message when page summarization fails
  ///
  /// In en, this message translates to:
  /// **'Failed to summarize page'**
  String get failed_to_summarize_page;

  /// No description provided for @firebase_not_initialized.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not initialized. Please check your configuration.'**
  String get firebase_not_initialized;

  /// No description provided for @close_all.
  ///
  /// In en, this message translates to:
  /// **'Close All'**
  String get close_all;

  /// No description provided for @delete_file.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get delete_file;

  /// No description provided for @delete_file_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this file from your device?'**
  String get delete_file_confirm;

  /// No description provided for @remove_from_history.
  ///
  /// In en, this message translates to:
  /// **'Remove from History'**
  String get remove_from_history;

  /// No description provided for @delete_from_device.
  ///
  /// In en, this message translates to:
  /// **'Delete from Device'**
  String get delete_from_device;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// Error message when the selected download folder is not writable
  ///
  /// In en, this message translates to:
  /// **'Cannot write to selected folder. Using default Downloads folder.'**
  String get cannot_write_selected_folder;

  /// Error message when the selected folder is not writable and user should choose another
  ///
  /// In en, this message translates to:
  /// **'Cannot write to selected folder. Please choose a different location.'**
  String get cannot_write_selected_folder_choose_different;

  /// Error message when the configured download folder is not writable
  ///
  /// In en, this message translates to:
  /// **'Cannot write to configured folder. Using default Downloads folder.'**
  String get cannot_write_configured_folder;

  /// Error message when folder selection fails
  ///
  /// In en, this message translates to:
  /// **'Error selecting folder. Using default Downloads folder.'**
  String get error_selecting_folder_default;

  /// Notification when file is saved to app storage as fallback
  ///
  /// In en, this message translates to:
  /// **'File saved to app storage instead of selected folder'**
  String get file_saved_to_app_storage;

  /// Error message when file cannot be written to any location
  ///
  /// In en, this message translates to:
  /// **'Failed to write file to any location'**
  String get failed_write_any_location;

  /// Label for settings action button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_action;

  /// Permission dialog message for saving to Downloads folder
  ///
  /// In en, this message translates to:
  /// **'To save \"{fileName}\" to your Downloads folder where you can find it in Gallery or File Manager, Solar needs storage permission.'**
  String save_to_downloads_folder(String fileName);

  /// Alternative text for permission dialog when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Without permission, the file will be saved to Solar\'s private folder (accessible from Downloads panel).'**
  String get without_permission_private_folder;

  /// Message about enabling unknown apps for APK installation
  ///
  /// In en, this message translates to:
  /// **'You may need to enable \"Install Unknown Apps\" in Android settings after download.'**
  String get enable_unknown_apps_android;

  /// Message when files will be saved to private folder
  ///
  /// In en, this message translates to:
  /// **'Files will be saved to Solar\'s private folder instead.'**
  String get private_folder_instead;

  /// Title for downloads permission dialog
  ///
  /// In en, this message translates to:
  /// **'Save to Downloads?'**
  String get save_to_downloads_title;

  /// Title for gallery permission dialog
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery?'**
  String get save_to_gallery_title;

  /// Title for storage access dialog
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get storage_access_required;

  /// Title for package installation dialog
  ///
  /// In en, this message translates to:
  /// **'Install {packageName}?'**
  String install_package_title(String packageName);

  /// Message for package installation dialog
  ///
  /// In en, this message translates to:
  /// **'This will download and prepare \"{packageName}\" for installation on your device.'**
  String install_package_message(String packageName);

  /// Message for gallery permission dialog
  ///
  /// In en, this message translates to:
  /// **'To save images and videos to your Gallery app where they\'ll be visible system-wide, Solar needs media access.'**
  String get save_to_gallery_message;

  /// Message for storage access dialog
  ///
  /// In en, this message translates to:
  /// **'To save files to your device storage, Solar needs storage access permissions.'**
  String get storage_access_message;

  /// Permission name for media access
  ///
  /// In en, this message translates to:
  /// **'Photos, Videos & Audio'**
  String get photos_videos_audio_permission;

  /// Permission name for storage and media access
  ///
  /// In en, this message translates to:
  /// **'Storage & Media Access'**
  String get storage_media_access_permission;

  /// Permission name for package installation
  ///
  /// In en, this message translates to:
  /// **'Package Installation'**
  String get package_installation_permission;

  /// Permission name for storage access
  ///
  /// In en, this message translates to:
  /// **'Storage Access'**
  String get storage_access_permission;

  /// Alternative text when gallery permission is denied
  ///
  /// In en, this message translates to:
  /// **'Without permission, media files will only be visible in Solar\'s Downloads section.'**
  String get without_gallery_permission;

  /// Flutter version string in about section
  ///
  /// In en, this message translates to:
  /// **'Flutter 3.32.5'**
  String get flutter_version_string;

  /// Photoncore version string in about section
  ///
  /// In en, this message translates to:
  /// **'Photoncore 0.1.0'**
  String get photoncore_version_string;

  /// Engine version string in about section
  ///
  /// In en, this message translates to:
  /// **'4.7.0'**
  String get engine_version_string;

  /// Title for HTTP warning dialog
  ///
  /// In en, this message translates to:
  /// **'Unsecure Connection Warning'**
  String get http_warning_title;

  /// Message for HTTP warning dialog
  ///
  /// In en, this message translates to:
  /// **'You are about to visit a website that uses an unsecure connection (HTTP). Your data may be visible to others. Are you sure you want to continue?'**
  String get http_warning_message;

  /// Button text to continue despite warning
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continue_anyway;

  /// Button text to go back from warning
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get go_back;

  /// Button text to continue browsing in the web browser instead of opening native app
  ///
  /// In en, this message translates to:
  /// **'Continue in Browser'**
  String get continue_in_browser;

  /// Title for web page error dialog
  ///
  /// In en, this message translates to:
  /// **'Page Load Error'**
  String get web_page_error_title;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connection_error;

  /// Page not found error message
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get page_not_found;

  /// Connection reset error message
  ///
  /// In en, this message translates to:
  /// **'Connection Reset'**
  String get connection_reset;

  /// Connection timeout error message
  ///
  /// In en, this message translates to:
  /// **'Connection Timed Out'**
  String get connection_timed_out;

  /// DNS lookup error message
  ///
  /// In en, this message translates to:
  /// **'DNS Error'**
  String get dns_error;

  /// SSL certificate error message
  ///
  /// In en, this message translates to:
  /// **'SSL Certificate Error'**
  String get ssl_error;

  /// Generic network error message
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get network_error;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get server_error;

  /// Unable to connect error description
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the website. Please check your internet connection and try again.'**
  String get unable_to_connect;

  /// Page not found error description
  ///
  /// In en, this message translates to:
  /// **'The requested page could not be found on the server. The page may have been moved or deleted.'**
  String get page_not_found_description;

  /// Connection reset error description
  ///
  /// In en, this message translates to:
  /// **'The connection to the server was reset. This may be a temporary issue.'**
  String get connection_reset_description;

  /// Connection timeout error description
  ///
  /// In en, this message translates to:
  /// **'The connection to the server timed out. The server may be busy or your connection may be slow.'**
  String get connection_timeout_description;

  /// DNS error description
  ///
  /// In en, this message translates to:
  /// **'Unable to find the website. Please check the web address and try again.'**
  String get dns_error_description;

  /// SSL error description
  ///
  /// In en, this message translates to:
  /// **'There is a problem with the website\'s security certificate. The connection may not be secure.'**
  String get ssl_error_description;

  /// Network error description
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please check your internet connection and try again.'**
  String get network_error_description;

  /// Server error description
  ///
  /// In en, this message translates to:
  /// **'The server encountered an error and could not complete your request.'**
  String get server_error_description;

  /// Button text to go to home page
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get go_home;

  /// Title for package download completion dialog
  ///
  /// In en, this message translates to:
  /// **'Package Downloaded!'**
  String get package_downloaded;

  /// Header for installation instructions
  ///
  /// In en, this message translates to:
  /// **'Installation Steps:'**
  String get installation_steps;

  /// Step-by-step installation instructions for APK packages
  ///
  /// In en, this message translates to:
  /// **'1. Tap \"Install\" below to open the package\n2. Enable \"Install Unknown Apps\" if prompted\n3. Follow Android\'s installation wizard'**
  String get installation_instructions;

  /// View button text
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Install button text
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Notification message when file is deleted from device
  ///
  /// In en, this message translates to:
  /// **'File deleted from device'**
  String get file_deleted_from_device;

  /// Error message when file path is not found
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: path not found'**
  String get cannot_open_file_path_not_found;

  /// Error message when file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Error opening file: {message}'**
  String error_opening_file_message(String message);

  /// Error message when file opening throws exception
  ///
  /// In en, this message translates to:
  /// **'Error opening file: {error}'**
  String error_opening_file_exception(String error);

  /// Error message when trying to open a custom scheme URL but the app is not installed
  ///
  /// In en, this message translates to:
  /// **'Cannot open this link. The required app may not be installed.'**
  String get app_not_installed;

  /// Error message when app launch fails with app name
  ///
  /// In en, this message translates to:
  /// **'Cannot open {appName}. The app may not be installed.'**
  String app_launch_failed(String appName);

  /// User-friendly message when a link requires an app that is not available
  ///
  /// In en, this message translates to:
  /// **'This link requires an app that is not installed.'**
  String get app_required_not_installed;

  /// Error message for malformed URLs or custom schemes
  ///
  /// In en, this message translates to:
  /// **'Invalid link format.'**
  String get invalid_link_format;

  /// Error message when a link cannot be opened due to missing app
  ///
  /// In en, this message translates to:
  /// **'Cannot open this link. The required app may not be installed.'**
  String get cannot_open_link;

  /// Error message when no email app is available for mailto links
  ///
  /// In en, this message translates to:
  /// **'No email app found to send this message.'**
  String get email_app_not_found;

  /// Error message when no phone app is available for tel links
  ///
  /// In en, this message translates to:
  /// **'No phone app found to make this call.'**
  String get phone_app_not_found;

  /// Error message when no SMS app is available for sms links
  ///
  /// In en, this message translates to:
  /// **'No messaging app found to send this SMS.'**
  String get sms_app_not_found;

  /// Dialog title asking if user wants to open link in specific app
  ///
  /// In en, this message translates to:
  /// **'Open in {appName}?'**
  String open_in_app_title(String appName);

  /// Dialog message explaining the link can be opened in specific app
  ///
  /// In en, this message translates to:
  /// **'This link can be opened in the {appName} app for a better experience.'**
  String open_in_app_message(String appName);

  /// Button text to open link in specific app
  ///
  /// In en, this message translates to:
  /// **'Open in {appName}'**
  String open_in_app_button(String appName);

  /// Advanced settings section title
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// Warning dialog title when disabling JavaScript
  ///
  /// In en, this message translates to:
  /// **'Disable JavaScript?'**
  String get disable_javascript_warning;

  /// Warning message when disabling JavaScript
  ///
  /// In en, this message translates to:
  /// **'Disabling JavaScript may break many websites and features. Are you sure you want to continue?'**
  String get disable_javascript_message;

  /// Disable button text
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Keep enabled button text
  ///
  /// In en, this message translates to:
  /// **'Keep Enabled'**
  String get keep_enabled;

  /// JavaScript enabled notification
  ///
  /// In en, this message translates to:
  /// **'JavaScript enabled'**
  String get javascript_enabled;

  /// JavaScript disabled notification
  ///
  /// In en, this message translates to:
  /// **'JavaScript disabled'**
  String get javascript_disabled;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get error_network;

  /// Connection failed error
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get error_connection_failed;

  /// Timeout error message
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get error_timeout;

  /// 404 error message
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get error_not_found;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get error_server;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get error_unknown;

  /// SSL error message
  ///
  /// In en, this message translates to:
  /// **'SSL connection error'**
  String get error_ssl;

  /// DNS error message
  ///
  /// In en, this message translates to:
  /// **'DNS resolution failed'**
  String get error_dns;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @custom_home_url_unreachable.
  ///
  /// In en, this message translates to:
  /// **'The URL could not be reached. Are you sure you want to continue?'**
  String get custom_home_url_unreachable;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
