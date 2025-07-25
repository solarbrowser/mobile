// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get welcomeToSolar => 'Solar에 오신 것을 환영합니다';

  @override
  String get welcomeDescription => '현대적이고 빠르며 안전한 브라우저';

  @override
  String get termsOfService => '계속하면 서비스 약관 및 개인정보 보호정책에 동의하게 됩니다';

  @override
  String get whats_new => '새로운 기능';

  @override
  String get chooseLanguage => '언어 선택';

  @override
  String get chooseTheme => '테마 선택';

  @override
  String get chooseSearchEngine => '검색 엔진 선택';

  @override
  String get selectAppearance => '앱의 외관을 선택하세요';

  @override
  String get selectSearchEngine => '선호하는 검색 엔진을 선택하세요';

  @override
  String get lightTheme => '라이트';

  @override
  String get darkTheme => '다크';

  @override
  String get systemTheme => '시스템';

  @override
  String get tokyoNightTheme => 'Tokyo Night';

  @override
  String get solarizedLightTheme => 'Solarized 라이트';

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
  String get nordLightTheme => 'Nord 라이트';

  @override
  String get gruvboxLightTheme => 'Gruvbox 라이트';

  @override
  String get next => '다음';

  @override
  String get back => '뒤로';

  @override
  String get skip => '건너뛰기';

  @override
  String get disable_classic_navigation_warning => '클래식 내비게이션 비활성화';

  @override
  String get disable_classic_navigation_message =>
      '클래식 내비게이션이 비활성화되면 스와이프 기반의 새로운 내비게이션 시스템으로 전환됩니다. 이 시스템에서는 주소 표시줄을 위로 스와이프하여 다양한 기능에 접근하고, 앞으로/뒤로 이동하려면 주소 표시줄을 좌우로 스와이프하세요.';

  @override
  String get getStarted => '시작하기';

  @override
  String get continueText => '계속';

  @override
  String get notifications => '알림';

  @override
  String get notificationDescription => '기기에 파일이 다운로드될 때 알림 받기';

  @override
  String get allowNotifications => '알림 허용';

  @override
  String get skipForNow => '나중에 하기';

  @override
  String get just_now => '방금 전';

  @override
  String min_ago(int minutes) {
    return '$minutes분 전';
  }

  @override
  String hr_ago(int hours) {
    return '$hours시간 전';
  }

  @override
  String get yesterday => '어제';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get and => '및';

  @override
  String get data_collection => '데이터 수집';

  @override
  String get data_collection_details =>
      '• 브라우저 기능에 필요한 최소한의 데이터만 수집합니다\n• 검색 기록은 기기에 저장됩니다\n• 온라인 활동을 추적하지 않습니다\n• 언제든지 모든 데이터를 삭제할 수 있습니다';

  @override
  String get general => '일반';

  @override
  String get appearance => '모양';

  @override
  String get downloads => '다운로드';

  @override
  String get settings => '설정';

  @override
  String get help => '도움말';

  @override
  String get about => '정보';

  @override
  String get language => '언어';

  @override
  String get search_engine => '검색 엔진';

  @override
  String get dark_mode => '다크 모드';

  @override
  String get text_size => '텍스트 크기';

  @override
  String get show_images => '이미지 표시';

  @override
  String get download_location => '다운로드 위치';

  @override
  String get ask_download_location => '다운로드 위치 묻기';

  @override
  String get rate_us => '평가하기';

  @override
  String get privacy_policy => '개인정보 처리방침';

  @override
  String get terms_of_use => '이용약관';

  @override
  String get customize_browser => '브라우저 사용자 지정';

  @override
  String get learn_more => '자세히 알아보기';

  @override
  String get tabs => '탭';

  @override
  String get keep_tabs_open => '탭 열린 상태 유지';

  @override
  String get history => '기록';

  @override
  String get bookmarks => '북마크';

  @override
  String get search_in_page => '페이지에서 찾기';

  @override
  String get app_name => 'Solar 브라우저';

  @override
  String get search_or_enter_address => '검색어 또는 주소 입력';

  @override
  String get current_location => '현재 위치';

  @override
  String get change_location => '위치 변경';

  @override
  String get clear_browser_data => '브라우저 데이터 삭제';

  @override
  String get browsing_history => '검색 기록';

  @override
  String get cookies => '쿠키';

  @override
  String get cache => '캐시';

  @override
  String get form_data => '양식 데이터';

  @override
  String get saved_passwords => '저장된 비밀번호';

  @override
  String get cancel => '취소';

  @override
  String get clear => '삭제';

  @override
  String get close => '닫기';

  @override
  String get browser_data_cleared => '브라우저 데이터가 삭제되었습니다';

  @override
  String get no_downloads => '다운로드 없음';

  @override
  String get no_bookmarks => '북마크 없음';

  @override
  String get download_started => '다운로드 시작됨';

  @override
  String get download_completed => '다운로드 완료';

  @override
  String get download_failed => '다운로드 실패';

  @override
  String get open => '열기';

  @override
  String get delete => '삭제';

  @override
  String get delete_download => '다운로드 삭제';

  @override
  String get delete_bookmark => '북마크 삭제';

  @override
  String get add_bookmark => '북마크 추가';

  @override
  String get bookmark_added => '북마크가 추가되었습니다';

  @override
  String get bookmark_exists => '이미 북마크에 있습니다';

  @override
  String get share => '공유';

  @override
  String get copy_link => '링크 복사';

  @override
  String get paste_and_go => '붙여넣기 및 이동';

  @override
  String get find_in_page => '페이지에서 찾기';

  @override
  String get desktop_site => '데스크톱 사이트';

  @override
  String get new_tab => '새 탭';

  @override
  String get close_tab => '탭 닫기';

  @override
  String get tab_overview => '탭 개요';

  @override
  String get home => '홈';

  @override
  String get reload => '새로고침';

  @override
  String get stop => '중지';

  @override
  String get forward => '앞으로';

  @override
  String get more => '더보기';

  @override
  String get reset_browser => '브라우저 초기화';

  @override
  String get reset_browser_confirm =>
      '모든 데이터(기록, 북마크, 설정 포함)가 삭제됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get reset => '초기화';

  @override
  String get reset_complete => '브라우저가 초기화되었습니다';

  @override
  String get permission_denied => '저장소 권한이 거부되었습니다';

  @override
  String get permission_permanently_denied =>
      '권한이 영구적으로 거부되었습니다. 설정에서 활성화해 주세요.';

  @override
  String get download_location_changed => '다운로드 위치가 변경되었습니다';

  @override
  String get error_changing_location => '위치 변경 오류';

  @override
  String get enable_cookies => '쿠키 활성화';

  @override
  String get enable_javascript => 'JavaScript 사용';

  @override
  String get hardware_acceleration => '하드웨어 가속';

  @override
  String get save_form_data => '양식 데이터 저장';

  @override
  String get do_not_track => '추적 안 함';

  @override
  String get download_location_description => '다운로드한 파일을 저장할 위치 선택';

  @override
  String get text_size_description => '웹 페이지의 텍스트 크기 조정';

  @override
  String get text_size_small => '작게';

  @override
  String get text_size_medium => '중간';

  @override
  String get text_size_large => '크게';

  @override
  String get text_size_very_large => '매우 크게';

  @override
  String get cookies_description => '웹사이트가 쿠키 데이터를 저장하고 읽도록 허용';

  @override
  String get javascript_description => '더 나은 웹사이트 기능을 위해 JavaScript 활성화';

  @override
  String get hardware_acceleration_description => '더 나은 성능을 위해 GPU 사용';

  @override
  String get form_data_description => '양식에 입력한 정보 저장';

  @override
  String get do_not_track_description => '웹사이트에 활동 추적을 요청하지 않음';

  @override
  String get exit_app => '앱 종료';

  @override
  String get exit_app_confirm => '종료하시겠습니까?';

  @override
  String get exit => '종료';

  @override
  String get size => '크기';

  @override
  String get auto_open_downloads => '다운로드 자동 열기';

  @override
  String get clear_downloads_history => '다운로드 기록 삭제';

  @override
  String get downloads_history_cleared => '다운로드 기록이 삭제되었습니다';

  @override
  String get sort_by => '정렬 기준';

  @override
  String get name => '이름';

  @override
  String get date => '날짜';

  @override
  String delete_download_confirm(String fileName) {
    return '$fileName을(를) 다운로드 기록에서 삭제하시겠습니까?\n다운로드한 파일은 삭제되지 않습니다.';
  }

  @override
  String get download_removed => '다운로드가 기록에서 제거되었습니다';

  @override
  String download_size(String size) {
    return '크기: $size';
  }

  @override
  String get install_packages_permission => '패키지 설치 권한';

  @override
  String get install_packages_permission_description => '이 브라우저에서 앱 설치 허용';

  @override
  String get permission_install_packages_required => '패키지 설치 권한이 필요합니다';

  @override
  String get storage_permission_install_packages_required => '저장소 및 패키지 설치 권한';

  @override
  String get storage_permission_install_packages_description =>
      'Solar 브라우저는 다운로드를 위한 저장소 액세스와 APK 설치를 위한 패키지 설치 권한이 필요합니다';

  @override
  String get clear_downloads_history_confirm =>
      '다운로드 기록만 삭제되며 다운로드한 파일은 삭제되지 않습니다.';

  @override
  String get clear_downloads_history_title => '다운로드 기록 삭제';

  @override
  String get slide_up_panel => '패널 위로 밀기';

  @override
  String get slide_down_panel => '패널 아래로 밀기';

  @override
  String get move_url_bar => 'URL 바 이동';

  @override
  String get url_bar_icon => 'URL 바 아이콘';

  @override
  String get url_bar_expanded => 'URL 바 확장됨';

  @override
  String get search_or_type_url => 'URL 검색 또는 입력';

  @override
  String get secure_connection => '보안 연결';

  @override
  String get insecure_connection => '보안되지 않은 연결';

  @override
  String get refresh_page => '페이지 새로고침';

  @override
  String get close_search => '검색 닫기';

  @override
  String get allow_popups => '팝업';

  @override
  String get allow_popups_description => '팝업 창 허용';

  @override
  String get popups_blocked => '팝업이 차단됨';

  @override
  String get allow_once => '한 번만 허용';

  @override
  String get allow_always => '항상 허용';

  @override
  String get block => '차단';

  @override
  String get blocked_popups => '차단된 팝업';

  @override
  String get no_blocked_popups => '차단된 팝업 없음';

  @override
  String allow_popups_from(String domain) {
    return '$domain에서 팝업 허용';
  }

  @override
  String get classic_navigation => '클래식 내비게이션';

  @override
  String get classic_navigation_description => '클래식 브라우저 스타일 내비게이션 컨트롤 사용';

  @override
  String get exit_confirmation => '앱 종료';

  @override
  String get flutter_version => 'Flutter 버전';

  @override
  String get photoncore_version => 'Photoncore 버전';

  @override
  String get engine_version => '엔진 버전';

  @override
  String get software_team => '소프트웨어 팀';

  @override
  String get download_image => '이미지 다운로드';

  @override
  String get share_image => '이미지 공유';

  @override
  String get open_in_new_tab => '새 탭에서 열기';

  @override
  String get copy_image_link => '이미지 링크 복사';

  @override
  String get open_image_in_new_tab => '새 탭에서 이미지 열기';

  @override
  String get open_link => '링크 열기';

  @override
  String get open_link_in_new_tab => '새 탭에서 링크 열기';

  @override
  String get copy_link_address => '링크 주소 복사';

  @override
  String get failed_to_download_image => '이미지 다운로드 실패';

  @override
  String get custom_home_page => '사용자 정의 홈페이지';

  @override
  String get set_home_page_url => '홈페이지 URL 설정';

  @override
  String get not_set => '설정되지 않음';

  @override
  String get save => '저장';

  @override
  String get downloading => '다운로드 중...';

  @override
  String get no_downloads_yet => '다운로드 없음';

  @override
  String get unknown => '알 수 없음';

  @override
  String get press_back_to_exit => '한 번 더 누르면 종료됩니다';

  @override
  String get storage_permission_required => '권한 부여';

  @override
  String get storage_permission_granted => '저장소 권한이 승인되었습니다';

  @override
  String get storage_permission_description =>
      '이 앱은 다운로드 기능을 위해 파일 액세스 권한이 필요합니다.';

  @override
  String get app_should_work_normally => '앱이 완전한 기능으로 정상적으로 작동해야 합니다.';

  @override
  String get grant_permission => '권한 부여';

  @override
  String get download_permissions => '다운로드 권한';

  @override
  String get manage_download_permissions => '다운로드 권한 관리';

  @override
  String get storage_permission => '저장소 접근';

  @override
  String get notification_permission => '알림';

  @override
  String get notification_permission_description => '다운로드 진행률 및 완료 알림용';

  @override
  String get permission_explanation =>
      '이러한 권한은 다운로드 경험을 개선하는 데 도움이 됩니다. Android 설정에서 언제든지 변경할 수 있습니다.';

  @override
  String get clear_downloads_history_description => '다운로드 기록 삭제 (파일은 유지)';

  @override
  String get change_download_location => '다운로드 위치 변경';

  @override
  String get request => '요청';

  @override
  String get storage => '저장소';

  @override
  String get manage_external_storage => '외부 저장소 관리';

  @override
  String get notification => '알림';

  @override
  String get granted => '허용됨';

  @override
  String get denied => '거부됨';

  @override
  String get restricted => '제한됨';

  @override
  String get limited => '제한됨';

  @override
  String get permanently_denied => '영구 거부됨';

  @override
  String get storage_permission_denied => '파일을 다운로드하려면 저장소 권한이 필요합니다';

  @override
  String get new_incognito_tab => '새 시크릿 탭';

  @override
  String get incognito_mode => '시크릿 모드';

  @override
  String get incognito_description =>
      '시크릿 모드에서:\n• 브라우징 기록이 저장되지 않습니다\n• 탭을 닫을 때 쿠키가 삭제됩니다\n• 데이터가 로컬에 저장되지 않습니다';

  @override
  String get error_opening_file => '파일 열기 오류';

  @override
  String get download_in_progress => '다운로드 진행 중';

  @override
  String get download_paused => '다운로드 일시정지';

  @override
  String get download_canceled => '다운로드 취소됨';

  @override
  String download_error(String error) {
    return '다운로드 오류: $error';
  }

  @override
  String get open_downloads_folder => '다운로드 폴더 열기';

  @override
  String get file_exists => '파일이 이미 존재합니다';

  @override
  String get file_saved => '파일이 다운로드에 저장되었습니다';

  @override
  String get no_tabs_open => '열린 탭이 없습니다';

  @override
  String get incognito => '시크릿';

  @override
  String get clear_all => '모두 지우기';

  @override
  String get clear_history => '기록 지우기';

  @override
  String get clear_history_confirmation => '브라우징 기록을 지우시겠습니까?';

  @override
  String get no_history => '브라우징 기록이 없습니다';

  @override
  String get today => '오늘';

  @override
  String days_ago(int days) {
    return '$days일 전';
  }

  @override
  String weeks_ago(int weeks) {
    return '$weeks주 전';
  }

  @override
  String months_ago(int months) {
    return '$months개월 전';
  }

  @override
  String get update1 => '향상된 테마 시스템';

  @override
  String get update1desc => '더 많은 색상 옵션과 개선된 다크 모드 지원을 갖춘 새로운 테마 시스템';

  @override
  String get update2 => '성능 개선';

  @override
  String get update2desc => '더 빠른 페이지 로딩과 더 부드러운 스크롤 경험';

  @override
  String get update3 => '새로운 개인정보 보호 기능';

  @override
  String get update3desc => '향상된 추적 방지 및 시크릿 모드 최적화';

  @override
  String get update4 => 'UI 개선';

  @override
  String get update4desc => '더 나은 탐색과 접근성을 갖춘 개선된 사용자 인터페이스';

  @override
  String get searchTheWeb => '웹 검색';

  @override
  String get recentSearches => '최근 검색';

  @override
  String get previous_summaries => '이전 요약';

  @override
  String get summarize_selected => '선택된 부분 요약';

  @override
  String get summarize_page => '페이지 요약';

  @override
  String get ai_preferences => 'AI 설정';

  @override
  String get ai_provider => 'AI 제공업체';

  @override
  String get summary_length => '요약 길이';

  @override
  String get generating_summary => '요약 생성 중...';

  @override
  String get summary_copied_to_clipboard => '요약이 클립보드에 복사되었습니다';

  @override
  String get summary_language => '요약 언어';

  @override
  String get length_short => '짧게';

  @override
  String get length_medium => '보통';

  @override
  String get length_long => '길게';

  @override
  String get summary_length_short => '짧게 (75단어)';

  @override
  String get summary_length_medium => '보통 (150단어)';

  @override
  String get summary_length_long => '길게 (250단어)';

  @override
  String get summary_language_english => '영어';

  @override
  String get summary_language_turkish => '터키어';

  @override
  String get add_to_pwa => 'PWA에 추가';

  @override
  String get remove_from_pwa => 'PWA에서 제거';

  @override
  String get added_to_pwa => 'PWA에 추가됨';

  @override
  String get removed_from_pwa => 'PWA에서 제거됨';

  @override
  String get pwa_info => '프로그레시브 웹 앱은 브라우저 컨트롤 없이 설치된 앱처럼 실행됩니다';

  @override
  String get create_shortcut => '바로가기 만들기';

  @override
  String get enter_shortcut_name => '이 바로가기의 이름을 입력하세요:';

  @override
  String get shortcut_name => '바로가기 이름';

  @override
  String get keep_tabs_open_description => '세션 간에 탭 열어두기';

  @override
  String get developer => '개발자';

  @override
  String get reset_welcome_screen => '환영 화면 재설정';

  @override
  String get restored_tab => '복원된 탭';

  @override
  String get welcome_screen_reset => '환영 화면 재설정';

  @override
  String get welcome_screen_reset_message =>
      '이렇게 하면 환영 화면이 재설정되어 다음에 앱을 시작할 때 다시 나타납니다.';

  @override
  String get ok => '확인';

  @override
  String get customize_navigation => '내비게이션 사용자 정의';

  @override
  String get button_back => '뒤로';

  @override
  String get button_forward => '앞으로';

  @override
  String get button_bookmark => '북마크';

  @override
  String get button_bookmarks => '북마크';

  @override
  String get button_share => '공유';

  @override
  String get button_menu => '메뉴';

  @override
  String get available_buttons => '사용 가능한 버튼';

  @override
  String get add => '추가';

  @override
  String get rename_pwa => 'PWA 이름 바꾸기';

  @override
  String get pwa_name => 'PWA 이름';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get pwa_renamed => 'PWA 이름이 변경되었습니다';

  @override
  String get remove => '제거';

  @override
  String get pwa_removed => 'PWA가 제거되었습니다';

  @override
  String get bookmark_removed => '북마크가 제거되었습니다';

  @override
  String get untitled => '제목 없음';

  @override
  String get show_welcome_screen_next_launch => '다음 실행 시 환영 화면 표시';

  @override
  String get automatically_open_downloaded_files => '다운로드한 파일 자동으로 열기';

  @override
  String get ask_where_to_save_files => '다운로드 전에 파일 저장 위치 묻기';

  @override
  String get clear_all_history => '모든 기록 지우기';

  @override
  String get clear_all_history_confirm =>
      '모든 탐색 기록이 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get history_cleared => '기록이 지워졌습니다';

  @override
  String get navigation_controls => '내비게이션 컨트롤';

  @override
  String get ai_settings => 'AI 설정';

  @override
  String get ai_summary_settings => 'AI 요약 설정';

  @override
  String get ask_download_location_title => '다운로드 위치 묻기';

  @override
  String get enable_incognito_mode => '시크릿 모드 활성화';

  @override
  String get disable_incognito_mode => '시크릿 모드 비활성화';

  @override
  String get close_all_tabs => '모든 탭 닫기';

  @override
  String get close_all_tabs_confirm => '모든 탭을 닫으시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String close_all_tabs_in_group(String groupName) {
    return '\"$groupName\"의 모든 탭을 닫으시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get other => '기타';

  @override
  String get ai => 'AI';

  @override
  String get rearrange_navigation_buttons => '내비게이션 버튼 재배열';

  @override
  String get current_navigation_bar => '현재 내비게이션 바:';

  @override
  String get tap_to_check_permission_status => '권한 상태를 확인하려면 탭하세요';

  @override
  String get create_tab_group => '탭 그룹 만들기';

  @override
  String get manage_groups => '그룹 관리';

  @override
  String get no_groups_created_yet => '아직 생성된 그룹이 없습니다';

  @override
  String get group_name => '그룹 이름';

  @override
  String get color => '색상';

  @override
  String get close_group => '그룹 닫기';

  @override
  String get create => '생성';

  @override
  String get summarize => '요약';

  @override
  String get no_summaries_available => '사용 가능한 요약이 없습니다';

  @override
  String get page_summary => '페이지 요약';

  @override
  String get failed_to_generate_summary => '요약 생성 실패';

  @override
  String get try_again => '다시 시도';

  @override
  String get no_page_to_summarize => '요약할 페이지가 없습니다';

  @override
  String get no_content_found_to_summarize => '요약할 콘텐츠를 찾을 수 없습니다';

  @override
  String get theme => '테마';

  @override
  String get check => '확인';

  @override
  String get pwa => 'PWA';

  @override
  String get confirm => '확인';

  @override
  String get input_required => '입력 필요';

  @override
  String get alert => '알림';

  @override
  String get add_tabs_to_group => '그룹에 탭 추가';

  @override
  String get ungroup_tabs => '탭 그룹 해제';

  @override
  String get delete_group => '그룹 삭제';

  @override
  String get copy_summary => '요약 복사';

  @override
  String get image_link_copied => '이미지 링크가 클립보드에 복사되었습니다';

  @override
  String get link_copied => '링크가 클립보드에 복사되었습니다';

  @override
  String get error_loading_page => '페이지 로딩 중 오류 발생';

  @override
  String get no_page_to_install => 'PWA로 설치할 페이지가 없습니다';

  @override
  String get pwa_installed => 'PWA가 설치되었습니다';

  @override
  String get failed_to_install_pwa => 'PWA 설치에 실패했습니다';

  @override
  String get creating_shortcut => '바로가기 만드는 중';

  @override
  String get check_home_screen_for_shortcut => '홈 화면에서 바로가기를 확인하세요';

  @override
  String get error_opening_file_install_app =>
      '파일을 열 수 없습니다. 이 유형의 파일을 열 수 있는 적절한 앱을 설치해 주세요.';

  @override
  String get full_storage_access_needed =>
      '미디어가 아닌 파일을 다운로드하려면 전체 저장소 접근 권한이 필요합니다';

  @override
  String get error_removing_download => '다운로드 제거 중 오류 발생';

  @override
  String get copy_image => '이미지 복사';

  @override
  String get text_copied => '텍스트가 복사되었습니다';

  @override
  String get text_pasted => '텍스트가 붙여넣어졌습니다';

  @override
  String get text_cut => '텍스트가 잘라내어졌습니다';

  @override
  String get clipboard_empty => '클립보드가 비어 있습니다';

  @override
  String get paste_error => '텍스트 붙여넣기 중 오류 발생';

  @override
  String get cut_error => '텍스트 잘라내기 중 오류 발생';

  @override
  String get image_url_copied => '이미지 URL이 복사되었습니다';

  @override
  String get opened_in_new_tab => '새 탭에서 열렸습니다';

  @override
  String get image_options => '이미지 옵션';

  @override
  String get copy => '복사';

  @override
  String get paste => '붙여넣기';

  @override
  String get cut => '잘라내기';

  @override
  String get solarKeyToCosmos => 'SOLAR - KEY TO THE COSMOS';

  @override
  String get legalInformation => '법적 정보';

  @override
  String get acceptContinue => '동의하고 계속';

  @override
  String get welcome => '환영합니다';

  @override
  String get systemThemeDesc => '시스템 따름';

  @override
  String get lightThemeDesc => '밝고 깨끗함';

  @override
  String get darkThemeDesc => '눈에 편안함';

  @override
  String get solarizedLightThemeDesc => '따뜻한 라이트 테마';

  @override
  String get nordLightThemeDesc => '시원한 라이트 테마';

  @override
  String get gruvboxLightThemeDesc => '레트로 라이트 테마';

  @override
  String get tokyoNightThemeDesc => '생동감 있는 나이트 테마';

  @override
  String get draculaThemeDesc => '어두운 보라 테마';

  @override
  String get nordThemeDesc => '시원한 다크 테마';

  @override
  String get gruvboxThemeDesc => '레트로 다크 테마';

  @override
  String get oneDarkThemeDesc => '에디터 영감 테마';

  @override
  String get catppuccinThemeDesc => '파스텔 다크 테마';

  @override
  String get latestNews => '최신 뉴스';

  @override
  String get errorLoadingNews => '뉴스 로딩 오류';

  @override
  String get defaultLocation => '기본 위치';

  @override
  String get webApp => '웹 앱';

  @override
  String get exampleUrl => 'https://예시.com';

  @override
  String get enterText => '텍스트 입력...';

  @override
  String get failed_to_get_news_data => '서버에서 뉴스 데이터 링크를 가져올 수 없습니다';

  @override
  String get failed_to_load_news_server => '서버에서 뉴스를 로드하지 못했습니다';

  @override
  String get network_error_loading_news => '뉴스 로딩 중 네트워크 오류';

  @override
  String get failed_to_download_file => '파일 다운로드 실패';

  @override
  String get failed_to_summarize_page => '페이지 요약 실패';

  @override
  String get firebase_not_initialized => 'Firebase가 초기화되지 않았습니다. 구성을 확인하세요.';

  @override
  String get close_all => '모두 닫기';

  @override
  String get delete_file => '파일 삭제';

  @override
  String get delete_file_confirm => '이 파일을 기기에서 영구적으로 삭제하시겠습니까?';

  @override
  String get remove_from_history => '기록에서 제거';

  @override
  String get delete_from_device => '기기에서 삭제';

  @override
  String get notice => '알림';

  @override
  String get cannot_write_selected_folder =>
      '선택한 폴더에 쓸 수 없습니다. 기본 다운로드 폴더를 사용합니다.';

  @override
  String get cannot_write_selected_folder_choose_different =>
      '선택한 폴더에 쓸 수 없습니다. 다른 위치를 선택해주세요.';

  @override
  String get cannot_write_configured_folder =>
      '구성된 폴더에 쓸 수 없습니다. 기본 다운로드 폴더를 사용합니다.';

  @override
  String get error_selecting_folder_default =>
      '폴더 선택 중 오류가 발생했습니다. 기본 다운로드 폴더를 사용합니다.';

  @override
  String get file_saved_to_app_storage => '파일이 선택한 폴더 대신 앱 저장소에 저장되었습니다';

  @override
  String get failed_write_any_location => '어떤 위치에도 파일을 쓸 수 없습니다';

  @override
  String get settings_action => '설정';

  @override
  String save_to_downloads_folder(String fileName) {
    return '갤러리나 파일 관리자에서 찾을 수 있는 다운로드 폴더에 \"$fileName\"을(를) 저장하려면 Solar에 저장소 권한이 필요합니다.';
  }

  @override
  String get without_permission_private_folder =>
      '권한 없이는 파일이 Solar의 개인 폴더에 저장됩니다(다운로드 패널에서 접근 가능).';

  @override
  String get enable_unknown_apps_android =>
      '다운로드 후 Android 설정에서 \"알 수 없는 앱 설치\"를 활성화해야 할 수 있습니다.';

  @override
  String get private_folder_instead => '파일이 대신 Solar의 개인 폴더에 저장됩니다.';

  @override
  String get save_to_downloads_title => '다운로드에 저장하시겠습니까?';

  @override
  String get save_to_gallery_title => '갤러리에 저장하시겠습니까?';

  @override
  String get storage_access_required => '저장소 접근 권한이 필요합니다';

  @override
  String install_package_title(String packageName) {
    return '$packageName을(를) 설치하시겠습니까?';
  }

  @override
  String install_package_message(String packageName) {
    return '이것은 기기에 설치하기 위해 \"$packageName\"을(를) 다운로드하고 준비합니다.';
  }

  @override
  String get save_to_gallery_message =>
      '시스템 전체에서 볼 수 있는 갤러리 앱에 이미지와 비디오를 저장하려면 Solar에 미디어 접근 권한이 필요합니다.';

  @override
  String get storage_access_message =>
      '기기 저장소에 파일을 저장하려면 Solar에 저장소 접근 권한이 필요합니다.';

  @override
  String get photos_videos_audio_permission => '사진, 동영상 및 오디오';

  @override
  String get storage_media_access_permission => '저장소 및 미디어 접근';

  @override
  String get package_installation_permission => '패키지 설치';

  @override
  String get storage_access_permission => '저장소 접근';

  @override
  String get without_gallery_permission =>
      '권한 없이는 미디어 파일이 Solar의 다운로드 섹션에서만 볼 수 있습니다.';

  @override
  String get flutter_version_string => 'Flutter 3.32.5';

  @override
  String get photoncore_version_string => 'Photoncore 0.1.0';

  @override
  String get engine_version_string => '4.7.0';

  @override
  String get http_warning_title => '안전하지 않은 연결 경고';

  @override
  String get http_warning_message =>
      '안전하지 않은 연결(HTTP)을 사용하는 웹사이트를 방문하려고 합니다. 귀하의 데이터가 다른 사람에게 보일 수 있습니다. 계속하시겠습니까?';

  @override
  String get continue_anyway => '어쨌든 계속';

  @override
  String get go_back => '뒤로 가기';

  @override
  String get continue_in_browser => '브라우저에서 계속하기';

  @override
  String get web_page_error_title => '페이지 로드 오류';

  @override
  String get connection_error => '연결 오류';

  @override
  String get page_not_found => '페이지를 찾을 수 없음';

  @override
  String get connection_reset => '연결이 재설정됨';

  @override
  String get connection_timed_out => '연결 시간 초과';

  @override
  String get dns_error => 'DNS 오류';

  @override
  String get ssl_error => 'SSL 인증서 오류';

  @override
  String get network_error => '네트워크 오류';

  @override
  String get server_error => '서버 오류';

  @override
  String get unable_to_connect => '웹사이트에 연결할 수 없습니다. 인터넷 연결을 확인하고 다시 시도하세요.';

  @override
  String get page_not_found_description =>
      '요청한 페이지를 서버에서 찾을 수 없습니다. 페이지가 이동되거나 삭제되었을 수 있습니다.';

  @override
  String get connection_reset_description =>
      '서버와의 연결이 재설정되었습니다. 일시적인 문제일 수 있습니다.';

  @override
  String get connection_timeout_description =>
      '서버와의 연결이 시간 초과되었습니다. 서버가 바쁘거나 연결이 느릴 수 있습니다.';

  @override
  String get dns_error_description => '웹사이트를 찾을 수 없습니다. 웹 주소를 확인하고 다시 시도하세요.';

  @override
  String get ssl_error_description =>
      '웹사이트의 보안 인증서에 문제가 있습니다. 연결이 안전하지 않을 수 있습니다.';

  @override
  String get network_error_description =>
      '네트워크 오류가 발생했습니다. 인터넷 연결을 확인하고 다시 시도하세요.';

  @override
  String get server_error_description => '서버에서 오류가 발생하여 요청을 완료할 수 없습니다.';

  @override
  String get go_home => '홈으로 가기';

  @override
  String get package_downloaded => '패키지가 다운로드되었습니다!';

  @override
  String get installation_steps => '설치 단계:';

  @override
  String get installation_instructions =>
      '1. 아래 \"설치\"를 눌러 패키지를 여세요\n2. 요청되면 \"알 수 없는 앱 설치\"를 활성화하세요\n3. Android 설치 마법사를 따르세요';

  @override
  String get view => '보기';

  @override
  String get install => '설치';

  @override
  String get file_deleted_from_device => '기기에서 파일이 삭제되었습니다';

  @override
  String get cannot_open_file_path_not_found => '파일을 열 수 없습니다: 경로를 찾을 수 없음';

  @override
  String error_opening_file_message(String message) {
    return '파일 열기 오류: $message';
  }

  @override
  String error_opening_file_exception(String error) {
    return '파일 열기 오류: $error';
  }

  @override
  String get app_not_installed => '이 링크를 열 수 없습니다. 필요한 앱이 설치되지 않았을 수 있습니다.';

  @override
  String app_launch_failed(String appName) {
    return '$appName을(를) 열 수 없습니다. 앱이 설치되지 않았을 수 있습니다.';
  }

  @override
  String get app_required_not_installed => '이 링크는 설치되지 않은 앱이 필요합니다.';

  @override
  String get invalid_link_format => '잘못된 링크 형식입니다.';

  @override
  String get cannot_open_link => '이 링크를 열 수 없습니다. 필요한 앱이 설치되지 않았을 수 있습니다.';

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
  String get advanced => '고급';

  @override
  String get disable_javascript_warning => 'JavaScript 비활성화';

  @override
  String get disable_javascript_message =>
      'JavaScript를 비활성화하면 많은 웹사이트가 제대로 작동하지 않을 수 있습니다. 확실합니까?';

  @override
  String get disable => '비활성화';

  @override
  String get keep_enabled => '활성화 유지';

  @override
  String get javascript_enabled => 'JavaScript 활성화됨';

  @override
  String get javascript_disabled => 'JavaScript 비활성화됨';

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
  String get warning => '경고';

  @override
  String get custom_home_url_unreachable => 'URL에 연결할 수 없습니다. 계속하시겠습니까?';

  @override
  String get yes => '예';

  @override
  String get no => '아니요';
}
