// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeToSolar => 'مرحباً بك في Solar';

  @override
  String get welcomeDescription => 'متصفح حديث وسريع وآمن';

  @override
  String get termsOfService =>
      'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية';

  @override
  String get whats_new => 'ما الجديد';

  @override
  String get chooseLanguage => 'اختر لغتك';

  @override
  String get chooseTheme => 'اختر المظهر';

  @override
  String get chooseSearchEngine => 'اختر محرك البحث';

  @override
  String get selectAppearance => 'اختر كيف يجب أن يبدو التطبيق';

  @override
  String get selectSearchEngine => 'اختر محرك البحث المفضل لديك';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get systemTheme => 'النظام';

  @override
  String get tokyoNightTheme => 'Tokyo Night';

  @override
  String get solarizedLightTheme => 'Solarized فاتح';

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
  String get nordLightTheme => 'Nord فاتح';

  @override
  String get gruvboxLightTheme => 'Gruvbox فاتح';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get continueText => 'متابعة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationDescription =>
      'احصل على إشعارات عند تنزيل الملفات على جهازك';

  @override
  String get allowNotifications => 'السماح بالإشعارات';

  @override
  String get skipForNow => 'تخطي الآن';

  @override
  String get just_now => 'الآن';

  @override
  String min_ago(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String hr_ago(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String get yesterday => 'الأمس';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get and => 'و';

  @override
  String get data_collection => 'جمع البيانات';

  @override
  String get data_collection_details =>
      '• نجمع الحد الأدنى من البيانات اللازمة لوظائف المتصفح\n• يبقى سجل التصفح على جهازك\n• لا نتتبع نشاطك عبر الإنترنت\n• يمكنك مسح جميع البيانات في أي وقت';

  @override
  String get general => 'عام';

  @override
  String get appearance => 'المظهر';

  @override
  String get downloads => 'التنزيلات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get help => 'المساعدة';

  @override
  String get about => 'حول';

  @override
  String get language => 'اللغة';

  @override
  String get search_engine => 'محرك البحث';

  @override
  String get dark_mode => 'الوضع الداكن';

  @override
  String get text_size => 'حجم النص';

  @override
  String get show_images => 'عرض الصور';

  @override
  String get download_location => 'موقع التنزيل';

  @override
  String get ask_download_location => 'اسأل عن موقع التنزيل';

  @override
  String get rate_us => 'قيمنا';

  @override
  String get privacy_policy => 'سياسة الخصوصية';

  @override
  String get terms_of_use => 'شروط الاستخدام';

  @override
  String get customize_browser => 'تخصيص المتصفح';

  @override
  String get learn_more => 'معرفة المزيد';

  @override
  String get tabs => 'علامات التبويب';

  @override
  String get keep_tabs_open => 'الاحتفاظ بعلامات التبويب مفتوحة';

  @override
  String get history => 'السجل';

  @override
  String get bookmarks => 'الإشارات المرجعية';

  @override
  String get search_in_page => 'البحث في الصفحة';

  @override
  String get app_name => 'Solar Browser';

  @override
  String get search_or_enter_address => 'ابحث أو أدخل عنواناً';

  @override
  String get current_location => 'الموقع الحالي';

  @override
  String get change_location => 'تغيير الموقع';

  @override
  String get clear_browser_data => 'مسح بيانات المتصفح';

  @override
  String get browsing_history => 'سجل التصفح';

  @override
  String get cookies => 'ملفات تعريف الارتباط';

  @override
  String get cache => 'الذاكرة المؤقتة';

  @override
  String get form_data => 'بيانات النماذج';

  @override
  String get saved_passwords => 'كلمات المرور المحفوظة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get clear => 'مسح';

  @override
  String get close => 'إغلاق';

  @override
  String get browser_data_cleared => 'تم مسح بيانات المتصفح';

  @override
  String get no_downloads => 'لا توجد تنزيلات حتى الآن';

  @override
  String get no_bookmarks => 'لا توجد إشارات مرجعية حتى الآن';

  @override
  String get download_started => 'بدأ التنزيل';

  @override
  String get download_completed => 'اكتمل التنزيل';

  @override
  String get download_failed => 'فشل التنزيل';

  @override
  String get open => 'فتح';

  @override
  String get delete => 'حذف';

  @override
  String get delete_download => 'حذف التنزيل';

  @override
  String get delete_bookmark => 'حذف الإشارة المرجعية';

  @override
  String get add_bookmark => 'إضافة إشارة مرجعية';

  @override
  String get bookmark_added => 'تمت إضافة الإشارة المرجعية';

  @override
  String get bookmark_exists => 'الإشارة المرجعية موجودة بالفعل';

  @override
  String get share => 'مشاركة';

  @override
  String get copy_link => 'نسخ الرابط';

  @override
  String get paste_and_go => 'لصق وانتقال';

  @override
  String get find_in_page => 'البحث في الصفحة';

  @override
  String get desktop_site => 'موقع سطح المكتب';

  @override
  String get new_tab => 'علامة تبويب جديدة';

  @override
  String get close_tab => 'إغلاق علامة التبويب';

  @override
  String get tab_overview => 'نظرة عامة على علامات التبويب';

  @override
  String get home => 'الرئيسية';

  @override
  String get reload => 'إعادة تحميل';

  @override
  String get stop => 'إيقاف';

  @override
  String get forward => 'للأمام';

  @override
  String get more => 'المزيد';

  @override
  String get reset_browser => 'إعادة تعيين المتصفح';

  @override
  String get reset_browser_confirm =>
      'سيؤدي هذا إلى مسح جميع بياناتك بما في ذلك السجل والإشارات المرجعية والإعدادات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get reset_complete => 'تمت إعادة تعيين المتصفح';

  @override
  String get permission_denied => 'تم رفض إذن التخزين';

  @override
  String get permission_permanently_denied =>
      'تم رفض الإذن نهائياً. يرجى تفعيله في الإعدادات.';

  @override
  String get download_location_changed => 'تم تغيير موقع التنزيل بنجاح';

  @override
  String get error_changing_location => 'خطأ في تغيير موقع التنزيل';

  @override
  String get enable_cookies => 'تمكين ملفات تعريف الارتباط';

  @override
  String get enable_javascript => 'تمكين JavaScript';

  @override
  String get hardware_acceleration => 'تسريع الأجهزة';

  @override
  String get save_form_data => 'حفظ بيانات النماذج';

  @override
  String get do_not_track => 'عدم التتبع';

  @override
  String get download_location_description =>
      'اختر مكان حفظ الملفات التي تم تنزيلها';

  @override
  String get text_size_description => 'ضبط حجم النص على صفحات الويب';

  @override
  String get text_size_small => 'صغير';

  @override
  String get text_size_medium => 'متوسط';

  @override
  String get text_size_large => 'كبير';

  @override
  String get text_size_very_large => 'كبير جداً';

  @override
  String get cookies_description =>
      'السماح للمواقع بحفظ وقراءة بيانات ملفات تعريف الارتباط';

  @override
  String get javascript_description => 'تمكين JavaScript لتحسين وظائف المواقع';

  @override
  String get hardware_acceleration_description =>
      'استخدام وحدة معالجة الرسومات للحصول على أداء أفضل';

  @override
  String get form_data_description => 'حفظ المعلومات المدخلة في النماذج';

  @override
  String get do_not_track_description => 'طلب من المواقع عدم تتبع نشاطك';

  @override
  String get exit_app => 'الخروج من التطبيق';

  @override
  String get exit_app_confirm => 'هل أنت متأكد أنك تريد الخروج؟';

  @override
  String get exit => 'خروج';

  @override
  String get size => 'الحجم';

  @override
  String get auto_open_downloads => 'فتح التحميلات تلقائياً';

  @override
  String get clear_downloads_history => 'مسح سجل التنزيلات';

  @override
  String get downloads_history_cleared => 'تم مسح سجل التنزيلات';

  @override
  String get sort_by => 'ترتيب حسب';

  @override
  String get name => 'الاسم';

  @override
  String get date => 'التاريخ';

  @override
  String delete_download_confirm(String fileName) {
    return 'هل تريد حذف $fileName من سجل التنزيلات؟\nلن يتم حذف الملف الذي تم تنزيله.';
  }

  @override
  String get download_removed => 'تمت إزالة التنزيل من السجل';

  @override
  String download_size(String size) {
    return 'الحجم: $size';
  }

  @override
  String get install_packages_permission => 'إذن تثبيت الحزم';

  @override
  String get install_packages_permission_description =>
      'السماح بتثبيت التطبيقات من هذا المتصفح';

  @override
  String get permission_install_packages_required => 'إذن تثبيت الحزم مطلوب';

  @override
  String get storage_permission_install_packages_required =>
      'إذن التخزين وتثبيت الحزم';

  @override
  String get storage_permission_install_packages_description =>
      'متصفح Solar يحتاج إذن للوصول للتخزين للتنزيلات وتثبيت الحزم لتثبيت APK';

  @override
  String get clear_downloads_history_confirm =>
      'سيؤدي هذا إلى مسح سجل التنزيلات فقط، ولن يتم حذف الملفات التي تم تنزيلها.';

  @override
  String get clear_downloads_history_title => 'مسح سجل التنزيلات';

  @override
  String get slide_up_panel => 'تحريك اللوحة للأعلى';

  @override
  String get slide_down_panel => 'تحريك اللوحة للأسفل';

  @override
  String get move_url_bar => 'تحريك شريط العنوان';

  @override
  String get url_bar_icon => 'أيقونة شريط العنوان';

  @override
  String get url_bar_expanded => 'شريط العنوان موسع';

  @override
  String get search_or_type_url => 'البحث أو كتابة عنوان URL';

  @override
  String get secure_connection => 'اتصال آمن';

  @override
  String get insecure_connection => 'اتصال غير آمن';

  @override
  String get refresh_page => 'تحديث الصفحة';

  @override
  String get close_search => 'إغلاق البحث';

  @override
  String get allow_popups => 'النوافذ المنبثقة';

  @override
  String get allow_popups_description => 'السماح بالنوافذ المنبثقة';

  @override
  String get popups_blocked => 'تم حظر النافذة المنبثقة';

  @override
  String get allow_once => 'السماح مرة واحدة';

  @override
  String get allow_always => 'السماح دائماً';

  @override
  String get block => 'حظر';

  @override
  String get blocked_popups => 'النوافذ المنبثقة المحظورة';

  @override
  String get no_blocked_popups => 'لا توجد نوافذ منبثقة محظورة';

  @override
  String allow_popups_from(String domain) {
    return 'السماح بالنوافذ المنبثقة من $domain';
  }

  @override
  String get classic_navigation => 'التنقل الكلاسيكي';

  @override
  String get classic_navigation_description =>
      'استخدام عناصر التحكم في التنقل بنمط المتصفح الكلاسيكي';

  @override
  String get exit_confirmation => 'الخروج من التطبيق';

  @override
  String get flutter_version => 'إصدار Flutter';

  @override
  String get photoncore_version => 'إصدار Photoncore';

  @override
  String get engine_version => 'إصدار المحرك';

  @override
  String get software_team => 'فريق البرمجة';

  @override
  String get download_image => 'تحميل الصورة';

  @override
  String get share_image => 'مشاركة الصورة';

  @override
  String get open_in_new_tab => 'فتح في علامة تبويب جديدة';

  @override
  String get copy_image_link => 'نسخ رابط الصورة';

  @override
  String get open_image_in_new_tab => 'فتح الصورة في علامة تبويب جديدة';

  @override
  String get open_link => 'فتح الرابط';

  @override
  String get open_link_in_new_tab => 'فتح الرابط في علامة تبويب جديدة';

  @override
  String get copy_link_address => 'نسخ عنوان الرابط';

  @override
  String get failed_to_download_image => 'فشل في تنزيل الصورة';

  @override
  String get custom_home_page => 'صفحة رئيسية مخصصة';

  @override
  String get set_home_page_url => 'تعيين رابط الصفحة الرئيسية';

  @override
  String get not_set => 'غير محدد';

  @override
  String get save => 'حفظ';

  @override
  String get downloading => 'جاري التحميل...';

  @override
  String get no_downloads_yet => 'لا توجد تحميلات';

  @override
  String get unknown => 'غير معروف';

  @override
  String get press_back_to_exit => 'اضغط مرة أخرى للخروج';

  @override
  String get storage_permission_required => 'إذن التخزين مطلوب';

  @override
  String get storage_permission_granted => 'تم منح جميع الأذونات';

  @override
  String get storage_permission_description =>
      'هذا التطبيق يحتاج إذن للوصول للملفات لوظيفة التنزيل.';

  @override
  String get app_should_work_normally =>
      'يجب أن يعمل التطبيق بشكل طبيعي مع الوظائف الكاملة.';

  @override
  String get grant_permission => 'منح الإذن';

  @override
  String get download_permissions => 'أذونات التنزيل';

  @override
  String get manage_download_permissions => 'إدارة أذونات التنزيل';

  @override
  String get storage_permission => 'الوصول للتخزين';

  @override
  String get notification_permission => 'الإشعارات';

  @override
  String get notification_permission_description =>
      'للحصول على تنبيهات تقدم التنزيل والإكمال';

  @override
  String get permission_explanation =>
      'تساعد هذه الأذونات في تحسين تجربة التنزيل. يمكنك تغييرها في أي وقت في إعدادات Android.';

  @override
  String get clear_downloads_history_description =>
      'إزالة سجل التنزيلات (الملفات تبقى)';

  @override
  String get change_download_location => 'تغيير مكان حفظ الملفات';

  @override
  String get request => 'طلب';

  @override
  String get storage => 'التخزين';

  @override
  String get manage_external_storage => 'إدارة التخزين الخارجي';

  @override
  String get notification => 'إشعار';

  @override
  String get granted => 'ممنوح';

  @override
  String get denied => 'مرفوض';

  @override
  String get restricted => 'مقيد';

  @override
  String get limited => 'محدود';

  @override
  String get permanently_denied => 'مرفوض نهائياً';

  @override
  String get storage_permission_denied => 'إذن التخزين مطلوب لتنزيل الملفات';

  @override
  String get new_incognito_tab => 'علامة تبويب متخفية جديدة';

  @override
  String get incognito_mode => 'وضع التخفي';

  @override
  String get incognito_description =>
      'في وضع التخفي:\n• لا يتم حفظ سجل التصفح\n• يتم مسح ملفات تعريف الارتباط عند إغلاق علامات التبويب\n• لا يتم تخزين أي بيانات محلياً';

  @override
  String get error_opening_file =>
      'خطأ في فتح الملف. يرجى تثبيت تطبيق مناسب لفتح هذا النوع من الملفات.';

  @override
  String get download_in_progress => 'جاري التنزيل';

  @override
  String get download_paused => 'تم إيقاف التنزيل مؤقتاً';

  @override
  String get download_canceled => 'تم إلغاء التنزيل';

  @override
  String download_error(String error) {
    return 'خطأ في التنزيل: $error';
  }

  @override
  String get open_downloads_folder => 'فتح مجلد التنزيلات';

  @override
  String get file_exists => 'الملف موجود بالفعل';

  @override
  String get file_saved => 'تم حفظ الملف في التنزيلات';

  @override
  String get no_tabs_open => 'لا توجد علامات تبويب مفتوحة';

  @override
  String get incognito => 'خفي';

  @override
  String get clear_all => 'مسح الكل';

  @override
  String get clear_history => 'مسح السجل';

  @override
  String get clear_history_confirmation =>
      'هل أنت متأكد أنك تريد مسح سجل التصفح؟';

  @override
  String get no_history => 'لا يوجد سجل تصفح';

  @override
  String get today => 'اليوم';

  @override
  String days_ago(int days) {
    return 'منذ $days يوم';
  }

  @override
  String weeks_ago(int weeks) {
    return 'منذ $weeks أسبوع';
  }

  @override
  String months_ago(int months) {
    return 'منذ $months شهر';
  }

  @override
  String get update1 => 'نظام سمات محسّن';

  @override
  String get update1desc =>
      'نظام سمات جديد مع المزيد من خيارات الألوان ودعم محسّن للوضع المظلم';

  @override
  String get update2 => 'تحسينات في الأداء';

  @override
  String get update2desc => 'تحميل أسرع للصفحات وتجربة تمرير أكثر سلاسة';

  @override
  String get update3 => 'ميزات خصوصية جديدة';

  @override
  String get update3desc =>
      'حماية محسّنة من التتبع وتحسينات في وضع التصفح الخاص';

  @override
  String get update4 => 'تحسينات في واجهة المستخدم';

  @override
  String get update4desc => 'واجهة مستخدم محسّنة مع تنقل وإمكانية وصول أفضل';

  @override
  String get searchTheWeb => 'البحث في الويب';

  @override
  String get recentSearches => 'عمليات البحث الأخيرة';

  @override
  String get previous_summaries => 'الملخصات السابقة';

  @override
  String get summarize_selected => 'تلخيص المحدد';

  @override
  String get summarize_page => 'تلخيص الصفحة';

  @override
  String get ai_preferences => 'تفضيلات الذكاء الاصطناعي';

  @override
  String get ai_provider => 'مزود الذكاء الاصطناعي';

  @override
  String get summary_length => 'طول الملخص';

  @override
  String get generating_summary => 'جاري إنشاء الملخص...';

  @override
  String get summary_copied_to_clipboard => 'تم نسخ الملخص إلى الحافظة';

  @override
  String get summary_language => 'لغة الملخص';

  @override
  String get length_short => 'قصير';

  @override
  String get length_medium => 'متوسط';

  @override
  String get length_long => 'طويل';

  @override
  String get summary_length_short => 'قصير (75 كلمة)';

  @override
  String get summary_length_medium => 'متوسط (150 كلمة)';

  @override
  String get summary_length_long => 'طويل (250 كلمة)';

  @override
  String get summary_language_english => 'الإنجليزية';

  @override
  String get summary_language_turkish => 'التركية';

  @override
  String get add_to_pwa => 'إضافة إلى PWA';

  @override
  String get remove_from_pwa => 'إزالة من PWA';

  @override
  String get added_to_pwa => 'تمت الإضافة إلى PWA';

  @override
  String get removed_from_pwa => 'تمت الإزالة من PWA';

  @override
  String get pwa_info =>
      'تطبيقات الويب التقدمية تعمل مثل التطبيقات المثبتة بدون عناصر تحكم المتصفح';

  @override
  String get create_shortcut => 'إنشاء اختصار';

  @override
  String get enter_shortcut_name => 'أدخل اسماً لهذا الاختصار:';

  @override
  String get shortcut_name => 'اسم الاختصار';

  @override
  String get keep_tabs_open_description =>
      'الاحتفاظ بعلامات التبويب مفتوحة بين الجلسات';

  @override
  String get developer => 'المطور';

  @override
  String get reset_welcome_screen => 'إعادة تعيين شاشة الترحيب';

  @override
  String get restored_tab => 'تم استعادة علامة التبويب';

  @override
  String get welcome_screen_reset => 'إعادة تعيين شاشة الترحيب';

  @override
  String get welcome_screen_reset_message =>
      'سيؤدي هذا إلى إعادة تعيين شاشة الترحيب بحيث تظهر مرة أخرى في المرة القادمة التي تبدأ فيها التطبيق.';

  @override
  String get ok => 'موافق';

  @override
  String get customize_navigation => 'تخصيص التنقل';

  @override
  String get button_back => 'رجوع';

  @override
  String get button_forward => 'تقدم';

  @override
  String get button_bookmark => 'إشارة مرجعية';

  @override
  String get button_bookmarks => 'إشارات مرجعية';

  @override
  String get button_share => 'مشاركة';

  @override
  String get button_menu => 'قائمة';

  @override
  String get available_buttons => 'الأزرار المتاحة';

  @override
  String get add => 'إضافة';

  @override
  String get rename_pwa => 'إعادة تسمية PWA';

  @override
  String get pwa_name => 'اسم PWA';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get pwa_renamed => 'تم إعادة تسمية PWA';

  @override
  String get remove => 'إزالة';

  @override
  String get pwa_removed => 'تم إزالة PWA';

  @override
  String get bookmark_removed => 'تم حذف الإشارة المرجعية';

  @override
  String get untitled => 'بلا عنوان';

  @override
  String get show_welcome_screen_next_launch =>
      'إظهار شاشة الترحيب في التشغيل التالي';

  @override
  String get automatically_open_downloaded_files =>
      'فتح الملفات المنزلة تلقائياً';

  @override
  String get ask_where_to_save_files =>
      'السؤال عن مكان حفظ الملفات قبل التنزيل';

  @override
  String get clear_all_history => 'مسح كامل التاريخ';

  @override
  String get clear_all_history_confirm =>
      'سيؤدي هذا إلى حذف تاريخ التصفح بالكامل نهائياً. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get history_cleared => 'تم مسح التاريخ';

  @override
  String get navigation_controls => 'عناصر التحكم في التنقل';

  @override
  String get ai_settings => 'إعدادات الذكاء الاصطناعي';

  @override
  String get ai_summary_settings => 'إعدادات ملخص الذكاء الاصطناعي';

  @override
  String get ask_download_location_title => 'السؤال عن موقع التحميل';

  @override
  String get enable_incognito_mode => 'تفعيل الوضع الخفي';

  @override
  String get disable_incognito_mode => 'إيقاف الوضع الخفي';

  @override
  String get close_all_tabs => 'إغلاق جميع علامات التبويب';

  @override
  String get close_all_tabs_confirm =>
      'هل أنت متأكد من أنك تريد إغلاق جميع علامات التبويب؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String close_all_tabs_in_group(String groupName) {
    return 'إغلاق جميع علامات التبويب في \"$groupName\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get other => 'أخرى';

  @override
  String get ai => 'الذكاء الاصطناعي';

  @override
  String get rearrange_navigation_buttons => 'إعادة ترتيب أزرار التنقل';

  @override
  String get current_navigation_bar => 'شريط التنقل الحالي:';

  @override
  String get tap_to_check_permission_status => 'اضغط للتحقق من حالة الإذن';

  @override
  String get create_tab_group => 'إنشاء مجموعة علامات تبويب';

  @override
  String get manage_groups => 'إدارة المجموعات';

  @override
  String get no_groups_created_yet => 'لم يتم إنشاء مجموعات بعد';

  @override
  String get group_name => 'اسم المجموعة';

  @override
  String get color => 'اللون';

  @override
  String get close_group => 'إغلاق المجموعة';

  @override
  String get create => 'إنشاء';

  @override
  String get summarize => 'تلخيص';

  @override
  String get no_summaries_available => 'لا توجد ملخصات متاحة';

  @override
  String get page_summary => 'ملخص الصفحة';

  @override
  String get failed_to_generate_summary => 'فشل في إنشاء الملخص';

  @override
  String get try_again => 'حاول مرة أخرى';

  @override
  String get no_page_to_summarize => 'لا توجد صفحة للتلخيص';

  @override
  String get no_content_found_to_summarize => 'لم يتم العثور على محتوى للتلخيص';

  @override
  String get theme => 'السمة';

  @override
  String get check => 'فحص';

  @override
  String get pwa => 'PWA';

  @override
  String get confirm => 'تأكيد';

  @override
  String get input_required => 'مطلوب إدخال';

  @override
  String get alert => 'تحذير';

  @override
  String get add_tabs_to_group => 'إضافة علامات تبويب إلى المجموعة';

  @override
  String get ungroup_tabs => 'إلغاء تجميع علامات التبويب';

  @override
  String get delete_group => 'حذف المجموعة';

  @override
  String get copy_summary => 'نسخ الملخص';

  @override
  String get image_link_copied => 'تم نسخ رابط الصورة إلى الحافظة';

  @override
  String get link_copied => 'تم نسخ الرابط إلى الحافظة';

  @override
  String get error_loading_page => 'خطأ في تحميل الصفحة';

  @override
  String get no_page_to_install => 'لا توجد صفحة لتثبيتها كتطبيق ويب';

  @override
  String get pwa_installed => 'تم تثبيت تطبيق الويب';

  @override
  String get failed_to_install_pwa => 'فشل في تثبيت تطبيق الويب';

  @override
  String get error_opening_file_install_app =>
      'خطأ في فتح الملف. يرجى تثبيت تطبيق مناسب لفتح هذا النوع من الملفات.';

  @override
  String get full_storage_access_needed =>
      'مطلوب الوصول الكامل للتخزين لتنزيل الملفات غير الوسائطية';

  @override
  String get error_removing_download => 'خطأ في إزالة التنزيل';

  @override
  String get copy_image => 'نسخ الصورة';

  @override
  String get text_copied => 'تم نسخ النص';

  @override
  String get text_pasted => 'تم لصق النص';

  @override
  String get text_cut => 'تم قص النص';

  @override
  String get clipboard_empty => 'الحافظة فارغة';

  @override
  String get paste_error => 'خطأ في لصق النص';

  @override
  String get cut_error => 'خطأ في قص النص';

  @override
  String get image_url_copied => 'تم نسخ رابط الصورة';

  @override
  String get opened_in_new_tab => 'تم الفتح في علامة تبويب جديدة';

  @override
  String get image_options => 'خيارات الصورة';

  @override
  String get copy => 'نسخ';

  @override
  String get paste => 'لصق';

  @override
  String get cut => 'قص';

  @override
  String get solarKeyToCosmos => 'SOLAR - KEY TO THE COSMOS';

  @override
  String get legalInformation => 'المعلومات القانونية';

  @override
  String get acceptContinue => 'موافق ومتابعة';

  @override
  String get welcome => 'أهلاً وسهلاً';

  @override
  String get systemThemeDesc => 'يتبع النظام';

  @override
  String get lightThemeDesc => 'مشرق ونظيف';

  @override
  String get darkThemeDesc => 'مريح للعينين';

  @override
  String get solarizedLightThemeDesc => 'سمة فاتحة دافئة';

  @override
  String get nordLightThemeDesc => 'سمة فاتحة باردة';

  @override
  String get gruvboxLightThemeDesc => 'سمة فاتحة كلاسيكية';

  @override
  String get tokyoNightThemeDesc => 'سمة ليلية نابضة';

  @override
  String get draculaThemeDesc => 'سمة بنفسجية داكنة';

  @override
  String get nordThemeDesc => 'سمة داكنة باردة';

  @override
  String get gruvboxThemeDesc => 'سمة داكنة كلاسيكية';

  @override
  String get oneDarkThemeDesc => 'سمة مستوحاة من المحرر';

  @override
  String get catppuccinThemeDesc => 'سمة داكنة باستيل';

  @override
  String get latestNews => 'آخر الأخبار';

  @override
  String get errorLoadingNews => 'خطأ في تحميل الأخبار';

  @override
  String get defaultLocation => 'الموقع الافتراضي';

  @override
  String get webApp => 'تطبيق ويب';

  @override
  String get exampleUrl => 'https://مثال.com';

  @override
  String get enterText => 'أدخل النص...';

  @override
  String get failed_to_get_news_data =>
      'تعذر الحصول على رابط بيانات الأخبار من الخادم';

  @override
  String get failed_to_load_news_server => 'فشل في تحميل الأخبار من الخادم';

  @override
  String get network_error_loading_news => 'خطأ في الشبكة أثناء تحميل الأخبار';

  @override
  String get failed_to_download_file => 'فشل في تنزيل الملف';

  @override
  String get failed_to_summarize_page => 'فشل في تلخيص الصفحة';

  @override
  String get firebase_not_initialized =>
      'لم يتم تهيئة Firebase. يرجى التحقق من التكوين الخاص بك.';

  @override
  String get close_all => 'إغلاق الكل';

  @override
  String get delete_file => 'حذف الملف';

  @override
  String get delete_file_confirm =>
      'هل أنت متأكد من أنك تريد حذف هذا الملف نهائياً من جهازك؟';

  @override
  String get remove_from_history => 'إزالة من التاريخ';

  @override
  String get delete_from_device => 'حذف من الجهاز';

  @override
  String get notice => 'إشعار';

  @override
  String get cannot_write_selected_folder =>
      'لا يمكن الكتابة في المجلد المحدد. استخدام مجلد التنزيلات الافتراضي.';

  @override
  String get cannot_write_selected_folder_choose_different =>
      'لا يمكن الكتابة في المجلد المحدد. يرجى اختيار موقع مختلف.';

  @override
  String get cannot_write_configured_folder =>
      'لا يمكن الكتابة في المجلد المكون. استخدام مجلد التنزيلات الافتراضي.';

  @override
  String get error_selecting_folder_default =>
      'خطأ في تحديد المجلد. استخدام مجلد التنزيلات الافتراضي.';

  @override
  String get file_saved_to_app_storage =>
      'تم حفظ الملف في تخزين التطبيق بدلاً من المجلد المحدد';

  @override
  String get failed_write_any_location => 'فشل في كتابة الملف في أي موقع';

  @override
  String get settings_action => 'الإعدادات';

  @override
  String save_to_downloads_folder(String fileName) {
    return 'لحفظ \"$fileName\" في مجلد التنزيلات حيث يمكنك العثور عليه في المعرض أو مدير الملفات، يحتاج Solar إلى إذن التخزين.';
  }

  @override
  String get without_permission_private_folder =>
      'بدون إذن، سيتم حفظ الملف في مجلد Solar الخاص (يمكن الوصول إليه من لوحة التنزيلات).';

  @override
  String get enable_unknown_apps_android =>
      'قد تحتاج إلى تمكين \"تثبيت التطبيقات المجهولة\" في إعدادات Android بعد التنزيل.';

  @override
  String get private_folder_instead =>
      'سيتم حفظ الملفات في مجلد Solar الخاص بدلاً من ذلك.';

  @override
  String get save_to_downloads_title => 'حفظ في التنزيلات؟';

  @override
  String get save_to_gallery_title => 'حفظ في المعرض؟';

  @override
  String get storage_access_required => 'مطلوب الوصول إلى التخزين';

  @override
  String install_package_title(String packageName) {
    return 'تثبيت $packageName؟';
  }

  @override
  String install_package_message(String packageName) {
    return 'سيؤدي هذا إلى تنزيل وإعداد \"$packageName\" للتثبيت على جهازك.';
  }

  @override
  String get save_to_gallery_message =>
      'لحفظ الصور ومقاطع الفيديو في تطبيق المعرض حيث ستكون مرئية في جميع أنحاء النظام، يحتاج Solar إلى الوصول إلى الوسائط.';

  @override
  String get storage_access_message =>
      'لحفظ الملفات في تخزين جهازك، يحتاج Solar إلى أذونات الوصول إلى التخزين.';

  @override
  String get photos_videos_audio_permission => 'الصور والفيديو والصوت';

  @override
  String get storage_media_access_permission => 'الوصول إلى التخزين والوسائط';

  @override
  String get package_installation_permission => 'تثبيت الحزم';

  @override
  String get storage_access_permission => 'الوصول إلى التخزين';

  @override
  String get without_gallery_permission =>
      'بدون إذن، ستكون ملفات الوسائط مرئية فقط في قسم التنزيلات في Solar.';

  @override
  String get flutter_version_string => 'Flutter 3.32.5';

  @override
  String get photoncore_version_string => 'Photoncore 0.1.0';

  @override
  String get engine_version_string => '4.7.0';

  @override
  String get http_warning_title => 'تحذير الاتصال غير الآمن';

  @override
  String get http_warning_message =>
      'أنت على وشك زيارة موقع ويب يستخدم اتصالاً غير آمن (HTTP). قد تكون بياناتك مرئية للآخرين. هل أنت متأكد من أنك تريد المتابعة؟';

  @override
  String get continue_anyway => 'المتابعة على أي حال';

  @override
  String get go_back => 'العودة';

  @override
  String get web_page_error_title => 'خطأ في تحميل الصفحة';

  @override
  String get connection_error => 'خطأ في الاتصال';

  @override
  String get page_not_found => 'الصفحة غير موجودة';

  @override
  String get connection_reset => 'تم إعادة تعيين الاتصال';

  @override
  String get connection_timed_out => 'انتهت مهلة الاتصال';

  @override
  String get dns_error => 'خطأ DNS';

  @override
  String get ssl_error => 'خطأ شهادة SSL';

  @override
  String get network_error => 'خطأ في الشبكة';

  @override
  String get server_error => 'خطأ في الخادم';

  @override
  String get unable_to_connect =>
      'غير قادر على الاتصال بالموقع. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';

  @override
  String get page_not_found_description =>
      'الصفحة المطلوبة غير موجودة على الخادم. قد تكون الصفحة قد تم نقلها أو حذفها.';

  @override
  String get connection_reset_description =>
      'تم إعادة تعيين الاتصال بالخادم. قد تكون هذه مشكلة مؤقتة.';

  @override
  String get connection_timeout_description =>
      'انتهت مهلة الاتصال بالخادم. قد يكون الخادم مشغولاً أو قد يكون اتصالك بطيئاً.';

  @override
  String get dns_error_description =>
      'غير قادر على العثور على الموقع. يرجى التحقق من عنوان الويب والمحاولة مرة أخرى.';

  @override
  String get ssl_error_description =>
      'هناك مشكلة مع شهادة الأمان للموقع. قد لا يكون الاتصال آمناً.';

  @override
  String get network_error_description =>
      'حدث خطأ في الشبكة. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';

  @override
  String get server_error_description =>
      'واجه الخادم خطأ ولم يتمكن من إكمال طلبك.';

  @override
  String get go_home => 'الذهاب للرئيسية';

  @override
  String get package_downloaded => 'تم تنزيل الحزمة!';

  @override
  String get installation_steps => 'خطوات التثبيت:';

  @override
  String get installation_instructions =>
      '1. اضغط \"تثبيت\" أدناه لفتح الحزمة\n2. فعل \"تثبيت التطبيقات المجهولة\" إذا طُلب منك\n3. اتبع معالج التثبيت في Android';

  @override
  String get view => 'عرض';

  @override
  String get install => 'تثبيت';

  @override
  String get file_deleted_from_device => 'تم حذف الملف من الجهاز';

  @override
  String get cannot_open_file_path_not_found =>
      'لا يمكن فتح الملف: المسار غير موجود';

  @override
  String error_opening_file_message(String message) {
    return 'خطأ في فتح الملف: $message';
  }

  @override
  String error_opening_file_exception(String error) {
    return 'خطأ في فتح الملف: $error';
  }
}
