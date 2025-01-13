import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('tr')
  ];

  /// Settings menu title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Downloads menu title
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// Tabs menu title
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get tabs;

  /// Bookmarks menu title
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// History menu title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Search engine settings title
  ///
  /// In en, this message translates to:
  /// **'Search Engine'**
  String get search_engine;

  /// Language settings title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// JavaScript settings title
  ///
  /// In en, this message translates to:
  /// **'JavaScript'**
  String get javascript;

  /// Dark mode settings title
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// General settings section title
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Appearance settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Language selection prompt
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// Search engine selection prompt
  ///
  /// In en, this message translates to:
  /// **'Select Search Engine'**
  String get select_search_engine;

  /// Check for updates button text
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get check_updates;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Developer credit label
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developed_by;

  /// License information label
  ///
  /// In en, this message translates to:
  /// **'Licensed under'**
  String get licensed_under;

  /// Patreon support button text
  ///
  /// In en, this message translates to:
  /// **'Support on Patreon'**
  String get support_patreon;

  /// In-page search prompt
  ///
  /// In en, this message translates to:
  /// **'Search in page'**
  String get search_in_page;

  /// Empty history message
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get no_history;

  /// Text size settings title
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get text_size;

  /// Theme color settings title
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get theme_color;

  /// Show images settings title
  ///
  /// In en, this message translates to:
  /// **'Show Images'**
  String get show_images;

  /// Downloads page title
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads_title;

  /// Empty downloads message
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get no_downloads;

  /// Clear history button text
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// Clear history dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history_title;

  /// Clear history confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your browsing history?'**
  String get clear_history_message;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// History cleared confirmation message
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get history_cleared;

  /// Help menu title
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// Terms of use link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms_of_use;

  /// Customization section description
  ///
  /// In en, this message translates to:
  /// **'Customize your browsing experience'**
  String get customize_browser;

  /// Learn more link text
  ///
  /// In en, this message translates to:
  /// **'Learn more about Solar Browser'**
  String get learn_more;

  /// Rate app button text
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rate_us;

  /// Download location settings title
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get download_location;

  /// Ask before downloading setting title
  ///
  /// In en, this message translates to:
  /// **'Ask Before Downloading'**
  String get ask_download_location;

  /// Enabled state text
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Disabled state text
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
