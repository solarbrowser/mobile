// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get welcomeToSolar => 'Solar へようこそ';

  @override
  String get welcomeDescription => 'モダンで高速、安全なブラウザ';

  @override
  String get termsOfService => '続行すると、利用規約とプライバシーポリシーに同意したことになります';

  @override
  String get whats_new => '新機能';

  @override
  String get chooseLanguage => '言語を選択';

  @override
  String get chooseTheme => 'テーマを選択';

  @override
  String get chooseSearchEngine => '検索エンジンを選択';

  @override
  String get selectAppearance => 'アプリの外観を選択してください';

  @override
  String get selectSearchEngine => 'お好みの検索エンジンを選択してください';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => 'システム';

  @override
  String get tokyoNightTheme => 'Tokyo Night';

  @override
  String get solarizedLightTheme => 'Solarized ライト';

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
  String get nordLightTheme => 'Nord ライト';

  @override
  String get gruvboxLightTheme => 'Gruvbox ライト';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get skip => 'スキップ';

  @override
  String get getStarted => '始める';

  @override
  String get continueText => '続行';

  @override
  String get notifications => '通知';

  @override
  String get notificationDescription => 'デバイスにファイルがダウンロードされたときに通知を受け取る';

  @override
  String get allowNotifications => '通知を許可';

  @override
  String get skipForNow => '今はスキップ';

  @override
  String get just_now => 'たった今';

  @override
  String min_ago(int minutes) {
    return '$minutes分前';
  }

  @override
  String hr_ago(int hours) {
    return '$hours時間前';
  }

  @override
  String get yesterday => '昨日';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get and => 'と';

  @override
  String get data_collection => 'データ収集';

  @override
  String get data_collection_details =>
      '• ブラウザの機能に必要な最小限のデータのみを収集します\n• 閲覧履歴はお使いのデバイスに保存されます\n• オンライン活動を追跡することはありません\n• データはいつでも消去できます';

  @override
  String get general => '一般';

  @override
  String get appearance => '外観';

  @override
  String get downloads => 'ダウンロード';

  @override
  String get settings => '設定';

  @override
  String get help => 'ヘルプ';

  @override
  String get about => '情報';

  @override
  String get language => '言語';

  @override
  String get search_engine => '検索エンジン';

  @override
  String get dark_mode => 'ダークモード';

  @override
  String get text_size => '文字サイズ';

  @override
  String get show_images => '画像を表示';

  @override
  String get download_location => 'ダウンロード先';

  @override
  String get ask_download_location => '保存先を確認';

  @override
  String get rate_us => '評価する';

  @override
  String get privacy_policy => 'プライバシーポリシー';

  @override
  String get terms_of_use => '利用規約';

  @override
  String get customize_browser => 'ブラウザをカスタマイズ';

  @override
  String get learn_more => '詳細を見る';

  @override
  String get tabs => 'タブ';

  @override
  String get keep_tabs_open => 'タブを開いたままにする';

  @override
  String get history => '履歴';

  @override
  String get bookmarks => 'ブックマーク';

  @override
  String get search_in_page => 'ページ内検索';

  @override
  String get app_name => 'Solar';

  @override
  String get search_or_enter_address => '検索またはアドレスを入力';

  @override
  String get current_location => '現在の場所';

  @override
  String get change_location => '場所を変更';

  @override
  String get clear_browser_data => 'ブラウザデータを消去';

  @override
  String get browsing_history => 'ブラウザ履歴';

  @override
  String get cookies => 'Cookie';

  @override
  String get cache => 'キャッシュ';

  @override
  String get form_data => 'フォームデータ';

  @override
  String get saved_passwords => '保存されたパスワード';

  @override
  String get cancel => 'キャンセル';

  @override
  String get clear => '消去';

  @override
  String get close => '閉じる';

  @override
  String get browser_data_cleared => 'ブラウザデータが消去されました';

  @override
  String get no_downloads => 'ダウンロードはありません';

  @override
  String get no_bookmarks => 'ブックマークはありません';

  @override
  String get download_started => 'ダウンロードを開始しました';

  @override
  String get download_completed => 'ダウンロードが完了しました';

  @override
  String get download_failed => 'ダウンロードに失敗しました';

  @override
  String get open => '開く';

  @override
  String get delete => '削除';

  @override
  String get delete_download => 'ダウンロードを削除';

  @override
  String get delete_bookmark => 'ブックマークを削除';

  @override
  String get add_bookmark => 'ブックマークを追加';

  @override
  String get bookmark_added => 'ブックマークに追加しました';

  @override
  String get bookmark_exists => '既にブックマークに追加されています';

  @override
  String get share => '共有';

  @override
  String get copy_link => 'リンクをコピー';

  @override
  String get paste_and_go => '貼り付けて移動';

  @override
  String get find_in_page => 'ページ内を検索';

  @override
  String get desktop_site => 'デスクトップサイト';

  @override
  String get new_tab => '新しいタブ';

  @override
  String get close_tab => 'タブを閉じる';

  @override
  String get tab_overview => 'タブの概要';

  @override
  String get home => 'ホーム';

  @override
  String get reload => '再読み込み';

  @override
  String get stop => '停止';

  @override
  String get forward => '進む';

  @override
  String get more => 'その他';

  @override
  String get reset_browser => 'ブラウザをリセット';

  @override
  String get reset_browser_confirm =>
      '履歴、ブックマーク、設定などのすべてのデータが消去されます。この操作は元に戻せません。';

  @override
  String get reset => 'リセット';

  @override
  String get reset_complete => 'ブラウザがリセットされました';

  @override
  String get permission_denied => 'ストレージのアクセス許可が拒否されました';

  @override
  String get permission_permanently_denied => '許可が恒久的に拒否されました。設定で有効にしてください。';

  @override
  String get download_location_changed => 'ダウンロード先を変更しました';

  @override
  String get error_changing_location => '場所の変更中にエラーが発生しました';

  @override
  String get enable_cookies => 'Cookie を有効にする';

  @override
  String get enable_javascript => 'JavaScript を有効にする';

  @override
  String get hardware_acceleration => 'ハードウェアアクセラレーション';

  @override
  String get save_form_data => 'フォームデータを保存';

  @override
  String get do_not_track => 'トラッキング拒否';

  @override
  String get download_location_description => 'ダウンロードしたファイルの保存先を選択';

  @override
  String get text_size_description => 'ウェブページの文字サイズを調整';

  @override
  String get text_size_small => '小';

  @override
  String get text_size_medium => '中';

  @override
  String get text_size_large => '大';

  @override
  String get text_size_very_large => '最大';

  @override
  String get cookies_description => 'ウェブサイトによるCookieの保存と読み取りを許可';

  @override
  String get javascript_description => 'ウェブサイトの機能を向上させるためにJavaScriptを有効化';

  @override
  String get hardware_acceleration_description => 'GPUを使用してパフォーマンスを向上';

  @override
  String get form_data_description => 'フォームに入力した情報を保存';

  @override
  String get do_not_track_description => 'ウェブサイトにトラッキング拒否を要求';

  @override
  String get exit_app => 'アプリを終了';

  @override
  String get exit_app_confirm => '本当に終了しますか？';

  @override
  String get exit => '終了';

  @override
  String get size => 'サイズ';

  @override
  String get auto_open_downloads => 'ダウンロードを自動で開く';

  @override
  String get clear_downloads_history => 'ダウンロード履歴を消去';

  @override
  String get downloads_history_cleared => 'ダウンロード履歴を消去しました';

  @override
  String get sort_by => '並び替え';

  @override
  String get name => '名前';

  @override
  String get date => '日付';

  @override
  String delete_download_confirm(String fileName) {
    return '$fileNameをダウンロード履歴から削除しますか？\nダウンロードしたファイルは削除されません。';
  }

  @override
  String get download_removed => 'ダウンロード履歴から削除しました';

  @override
  String download_size(String size) {
    return 'サイズ: $size';
  }

  @override
  String get install_packages_permission => 'パッケージインストール許可';

  @override
  String get install_packages_permission_description =>
      'このブラウザからアプリのインストールを許可する';

  @override
  String get permission_install_packages_required => 'パッケージインストール許可が必要です';

  @override
  String get storage_permission_install_packages_required =>
      'ストレージ・パッケージインストール許可';

  @override
  String get storage_permission_install_packages_description =>
      'Solar ブラウザはダウンロード用のストレージアクセスとAPKインストール用のパッケージインストールの許可が必要です';

  @override
  String get clear_downloads_history_confirm =>
      'これはダウンロード履歴のみを消去し、ダウンロードしたファイルは削除されません。';

  @override
  String get clear_downloads_history_title => 'ダウンロード履歴を消去';

  @override
  String get slide_up_panel => 'パネルを上にスライド';

  @override
  String get slide_down_panel => 'パネルを下にスライド';

  @override
  String get move_url_bar => 'URLバーを移動';

  @override
  String get url_bar_icon => 'URLバーアイコン';

  @override
  String get url_bar_expanded => 'URLバー展開';

  @override
  String get search_or_type_url => 'URLを検索または入力';

  @override
  String get secure_connection => '安全な接続';

  @override
  String get insecure_connection => '安全でない接続';

  @override
  String get refresh_page => 'ページを更新';

  @override
  String get close_search => '検索を閉じる';

  @override
  String get allow_popups => 'ポップアップ';

  @override
  String get allow_popups_description => 'ポップアップウィンドウを許可';

  @override
  String get popups_blocked => 'ポップアップがブロックされました';

  @override
  String get allow_once => '一度だけ許可';

  @override
  String get allow_always => '常に許可';

  @override
  String get block => 'ブロック';

  @override
  String get blocked_popups => 'ブロックされたポップアップ';

  @override
  String get no_blocked_popups => 'ブロックされたポップアップはありません';

  @override
  String allow_popups_from(String domain) {
    return '$domainからのポップアップを許可';
  }

  @override
  String get classic_navigation => 'クラシックナビゲーション';

  @override
  String get classic_navigation_description => 'クラシックブラウザスタイルのナビゲーションコントロールを使用';

  @override
  String get exit_confirmation => 'アプリを終了';

  @override
  String get flutter_version => 'Flutter バージョン';

  @override
  String get photoncore_version => 'Photoncore バージョン';

  @override
  String get engine_version => 'エンジンバージョン';

  @override
  String get software_team => 'ソフトウェアチーム';

  @override
  String get download_image => '画像をダウンロード';

  @override
  String get share_image => '画像を共有';

  @override
  String get open_in_new_tab => '新しいタブで開く';

  @override
  String get copy_image_link => '画像リンクをコピー';

  @override
  String get open_image_in_new_tab => '新しいタブで画像を開く';

  @override
  String get open_link => 'リンクを開く';

  @override
  String get open_link_in_new_tab => '新しいタブでリンクを開く';

  @override
  String get copy_link_address => 'リンクアドレスをコピー';

  @override
  String get failed_to_download_image => '画像のダウンロードに失敗しました';

  @override
  String get custom_home_page => 'カスタムホームページ';

  @override
  String get set_home_page_url => 'ホームページURLを設定';

  @override
  String get not_set => '設定されていません';

  @override
  String get save => '保存';

  @override
  String get downloading => 'ダウンロード中...';

  @override
  String get no_downloads_yet => 'ダウンロードはありません';

  @override
  String get unknown => '不明';

  @override
  String get press_back_to_exit => 'もう一度押すと終了します';

  @override
  String get storage_permission_required => '許可を与える';

  @override
  String get storage_permission_granted => 'ストレージ権限が付与されました';

  @override
  String get storage_permission_description =>
      'このアプリはダウンロード機能のためにファイルへのアクセス許可が必要です。';

  @override
  String get app_should_work_normally => 'アプリは完全な機能で正常に動作するはずです。';

  @override
  String get grant_permission => '許可を与える';

  @override
  String get download_permissions => 'ダウンロード権限';

  @override
  String get manage_download_permissions => 'ダウンロード権限を管理';

  @override
  String get storage_permission => 'ストレージアクセス';

  @override
  String get notification_permission => '通知';

  @override
  String get notification_permission_description => 'ダウンロード進行状況と完了アラート用';

  @override
  String get permission_explanation =>
      'これらの権限は、ダウンロード体験を向上させるのに役立ちます。Android設定でいつでも変更できます。';

  @override
  String get clear_downloads_history_description => 'ダウンロード履歴を削除（ファイルは残る）';

  @override
  String get change_download_location => 'ダウンロード場所を変更';

  @override
  String get request => 'リクエスト';

  @override
  String get storage => 'ストレージ';

  @override
  String get manage_external_storage => '外部ストレージを管理';

  @override
  String get notification => '通知';

  @override
  String get granted => '許可されました';

  @override
  String get denied => '拒否されました';

  @override
  String get restricted => '制限されています';

  @override
  String get limited => '制限付き';

  @override
  String get permanently_denied => '永続的に拒否されました';

  @override
  String get storage_permission_denied => 'ファイルをダウンロードするにはストレージ許可が必要です';

  @override
  String get new_incognito_tab => '新しいシークレットタブ';

  @override
  String get incognito_mode => 'シークレットモード';

  @override
  String get incognito_description =>
      'シークレットモードでは:\n• ブラウジング履歴は保存されません\n• タブを閉じるとクッキーがクリアされます\n• データはローカルに保存されません';

  @override
  String get error_opening_file => 'ファイルを開く際のエラー';

  @override
  String get download_in_progress => 'ダウンロード中';

  @override
  String get download_paused => 'ダウンロード一時停止';

  @override
  String get download_canceled => 'ダウンロードキャンセル';

  @override
  String download_error(String error) {
    return 'ダウンロードエラー: $error';
  }

  @override
  String get open_downloads_folder => 'ダウンロードフォルダを開く';

  @override
  String get file_exists => 'ファイルが既に存在します';

  @override
  String get file_saved => 'ファイルがダウンロードに保存されました';

  @override
  String get no_tabs_open => '開いているタブがありません';

  @override
  String get incognito => 'シークレット';

  @override
  String get clear_all => 'すべてクリア';

  @override
  String get clear_history => '履歴をクリア';

  @override
  String get clear_history_confirmation => 'ブラウジング履歴をクリアしてもよろしいですか？';

  @override
  String get no_history => 'ブラウジング履歴がありません';

  @override
  String get today => '今日';

  @override
  String days_ago(int days) {
    return '$days日前';
  }

  @override
  String weeks_ago(int weeks) {
    return '$weeks週間前';
  }

  @override
  String months_ago(int months) {
    return '$monthsヶ月前';
  }

  @override
  String get update1 => 'テーマシステムの改善';

  @override
  String get update1desc => 'より多くのカラーオプションと改善されたダークモードサポートを備えた新しいテーマシステム';

  @override
  String get update2 => 'パフォーマンスの向上';

  @override
  String get update2desc => 'ページの読み込みが高速化し、よりスムーズなスクロール体験を実現';

  @override
  String get update3 => '新しいプライバシー機能';

  @override
  String get update3desc => 'トラッキング保護の強化とシークレットモードの最適化';

  @override
  String get update4 => 'UIの改善';

  @override
  String get update4desc => 'より良いナビゲーションとアクセシビリティを備えた改善されたユーザーインターフェース';

  @override
  String get searchTheWeb => 'ウェブを検索';

  @override
  String get recentSearches => '最近の検索';

  @override
  String get previous_summaries => '以前の要約';

  @override
  String get summarize_selected => '選択部分を要約';

  @override
  String get summarize_page => 'ページを要約';

  @override
  String get ai_preferences => 'AI設定';

  @override
  String get ai_provider => 'AIプロバイダー';

  @override
  String get summary_length => '要約の長さ';

  @override
  String get generating_summary => '要約を生成中...';

  @override
  String get summary_copied_to_clipboard => '要約がクリップボードにコピーされました';

  @override
  String get summary_language => '要約の言語';

  @override
  String get length_short => '短い';

  @override
  String get length_medium => '中程度';

  @override
  String get length_long => '長い';

  @override
  String get summary_length_short => '短い（75単語）';

  @override
  String get summary_length_medium => '中程度（150単語）';

  @override
  String get summary_length_long => '長い（250単語）';

  @override
  String get summary_language_english => '英語';

  @override
  String get summary_language_turkish => 'トルコ語';

  @override
  String get add_to_pwa => 'PWAに追加';

  @override
  String get remove_from_pwa => 'PWAから削除';

  @override
  String get added_to_pwa => 'PWAに追加されました';

  @override
  String get removed_from_pwa => 'PWAから削除されました';

  @override
  String get pwa_info => 'プログレッシブウェブアプリはブラウザコントロールなしでインストールされたアプリのように動作します';

  @override
  String get create_shortcut => 'ショートカットを作成';

  @override
  String get enter_shortcut_name => 'このショートカットの名前を入力してください:';

  @override
  String get shortcut_name => 'ショートカット名';

  @override
  String get keep_tabs_open_description => 'セッション間でタブを開いたままにする';

  @override
  String get developer => '開発者';

  @override
  String get reset_welcome_screen => 'ウェルカム画面をリセット';

  @override
  String get restored_tab => 'タブが復元されました';

  @override
  String get welcome_screen_reset => 'ウェルカム画面をリセット';

  @override
  String get welcome_screen_reset_message =>
      'これにより、ウェルカム画面がリセットされ、次回アプリを起動するときに再び表示されます。';

  @override
  String get ok => 'OK';

  @override
  String get customize_navigation => 'ナビゲーションをカスタマイズ';

  @override
  String get button_back => '戻る';

  @override
  String get button_forward => '進む';

  @override
  String get button_bookmark => 'ブックマーク';

  @override
  String get button_bookmarks => 'ブックマーク';

  @override
  String get button_share => '共有';

  @override
  String get button_menu => 'メニュー';

  @override
  String get available_buttons => '利用可能なボタン';

  @override
  String get add => '追加';

  @override
  String get rename_pwa => 'PWAの名前を変更';

  @override
  String get pwa_name => 'PWA名';

  @override
  String get rename => '名前を変更';

  @override
  String get pwa_renamed => 'PWAの名前が変更されました';

  @override
  String get remove => '削除';

  @override
  String get pwa_removed => 'PWAが削除されました';

  @override
  String get bookmark_removed => 'ブックマークが削除されました';

  @override
  String get untitled => '無題';

  @override
  String get show_welcome_screen_next_launch => '次回起動時にウェルカム画面を表示';

  @override
  String get automatically_open_downloaded_files => 'ダウンロードしたファイルを自動的に開く';

  @override
  String get ask_where_to_save_files => 'ダウンロード前にファイルの保存場所を尋ねる';

  @override
  String get clear_all_history => 'すべての履歴を消去';

  @override
  String get clear_all_history_confirm =>
      'これにより、すべての閲覧履歴が完全に削除されます。この操作は元に戻せません。';

  @override
  String get history_cleared => '履歴が消去されました';

  @override
  String get navigation_controls => 'ナビゲーションコントロール';

  @override
  String get ai_settings => 'AI設定';

  @override
  String get ai_summary_settings => 'AI要約設定';

  @override
  String get ask_download_location_title => 'ダウンロード場所を尋ねる';

  @override
  String get enable_incognito_mode => 'シークレットモードを有効にする';

  @override
  String get disable_incognito_mode => 'シークレットモードを無効にする';

  @override
  String get close_all_tabs => 'すべてのタブを閉じる';

  @override
  String get close_all_tabs_confirm => 'すべてのタブを閉じてもよろしいですか？この操作は元に戻せません。';

  @override
  String close_all_tabs_in_group(String groupName) {
    return '\"$groupName\"のすべてのタブを閉じますか？この操作は元に戻せません。';
  }

  @override
  String get other => 'その他';

  @override
  String get ai => 'AI';

  @override
  String get rearrange_navigation_buttons => 'ナビゲーションボタンを再配置';

  @override
  String get current_navigation_bar => '現在のナビゲーションバー：';

  @override
  String get tap_to_check_permission_status => 'タップして権限ステータスを確認';

  @override
  String get create_tab_group => 'タブグループを作成';

  @override
  String get manage_groups => 'グループを管理';

  @override
  String get no_groups_created_yet => 'まだグループが作成されていません';

  @override
  String get group_name => 'グループ名';

  @override
  String get color => '色';

  @override
  String get close_group => 'グループを閉じる';

  @override
  String get create => '作成';

  @override
  String get summarize => '要約';

  @override
  String get no_summaries_available => '利用可能な要約はありません';

  @override
  String get page_summary => 'ページ要約';

  @override
  String get failed_to_generate_summary => '要約の生成に失敗しました';

  @override
  String get try_again => '再試行';

  @override
  String get no_page_to_summarize => '要約するページがありません';

  @override
  String get no_content_found_to_summarize => '要約するコンテンツが見つかりません';

  @override
  String get theme => 'テーマ';

  @override
  String get check => 'チェック';

  @override
  String get pwa => 'PWA';

  @override
  String get confirm => '確認';

  @override
  String get input_required => '入力が必要';

  @override
  String get alert => 'アラート';

  @override
  String get add_tabs_to_group => 'タブをグループに追加';

  @override
  String get ungroup_tabs => 'タブのグループ化を解除';

  @override
  String get delete_group => 'グループを削除';

  @override
  String get copy_summary => '要約をコピー';

  @override
  String get image_link_copied => '画像リンクをクリップボードにコピーしました';

  @override
  String get link_copied => 'リンクをクリップボードにコピーしました';

  @override
  String get error_loading_page => 'ページの読み込み中にエラーが発生しました';

  @override
  String get no_page_to_install => 'PWAとしてインストールするページがありません';

  @override
  String get pwa_installed => 'PWAがインストールされました';

  @override
  String get failed_to_install_pwa => 'PWAのインストールに失敗しました';

  @override
  String get creating_shortcut => 'ショートカットを作成中';

  @override
  String get check_home_screen_for_shortcut => 'ホーム画面でショートカットを確認してください';

  @override
  String get error_opening_file_install_app =>
      'ファイルを開くときにエラーが発生しました。このタイプのファイルを開くには、適切なアプリをインストールしてください。';

  @override
  String get full_storage_access_needed =>
      'メディア以外のファイルをダウンロードするには、ストレージへの完全なアクセスが必要です';

  @override
  String get error_removing_download => 'ダウンロードの削除中にエラーが発生しました';

  @override
  String get copy_image => '画像をコピー';

  @override
  String get text_copied => 'テキストをコピーしました';

  @override
  String get text_pasted => 'テキストを貼り付けました';

  @override
  String get text_cut => 'テキストを切り取りました';

  @override
  String get clipboard_empty => 'クリップボードが空です';

  @override
  String get paste_error => 'テキストの貼り付け中にエラーが発生しました';

  @override
  String get cut_error => 'テキストの切り取り中にエラーが発生しました';

  @override
  String get image_url_copied => '画像URLをコピーしました';

  @override
  String get opened_in_new_tab => '新しいタブで開きました';

  @override
  String get image_options => '画像オプション';

  @override
  String get copy => 'コピー';

  @override
  String get paste => '貼り付け';

  @override
  String get cut => '切り取り';

  @override
  String get solarKeyToCosmos => 'SOLAR - KEY TO THE COSMOS';

  @override
  String get legalInformation => '法的情報';

  @override
  String get acceptContinue => '同意して続行';

  @override
  String get welcome => 'ようこそ';

  @override
  String get systemThemeDesc => 'システムに従う';

  @override
  String get lightThemeDesc => '明るくきれい';

  @override
  String get darkThemeDesc => '目に優しい';

  @override
  String get solarizedLightThemeDesc => '暖かいライトテーマ';

  @override
  String get nordLightThemeDesc => '涼しいライトテーマ';

  @override
  String get gruvboxLightThemeDesc => 'レトロライトテーマ';

  @override
  String get tokyoNightThemeDesc => '活気あるナイトテーマ';

  @override
  String get draculaThemeDesc => 'ダークパープルテーマ';

  @override
  String get nordThemeDesc => '涼しいダークテーマ';

  @override
  String get gruvboxThemeDesc => 'レトロダークテーマ';

  @override
  String get oneDarkThemeDesc => 'エディター風テーマ';

  @override
  String get catppuccinThemeDesc => 'パステルダークテーマ';

  @override
  String get latestNews => '最新ニュース';

  @override
  String get errorLoadingNews => 'ニュース読み込みエラー';

  @override
  String get defaultLocation => 'デフォルトの場所';

  @override
  String get webApp => 'ウェブアプリ';

  @override
  String get exampleUrl => 'https://例.com';

  @override
  String get enterText => 'テキストを入力...';

  @override
  String get failed_to_get_news_data => 'サーバーからニュースデータリンクを取得できませんでした';

  @override
  String get failed_to_load_news_server => 'サーバーからニュースの読み込みに失敗しました';

  @override
  String get network_error_loading_news => 'ニュース読み込み中にネットワークエラー';

  @override
  String get failed_to_download_file => 'ファイルのダウンロードに失敗しました';

  @override
  String get failed_to_summarize_page => 'ページの要約に失敗しました';

  @override
  String get firebase_not_initialized => 'Firebaseが初期化されていません。設定を確認してください。';

  @override
  String get close_all => 'すべて閉じる';

  @override
  String get delete_file => 'ファイルを削除';

  @override
  String get delete_file_confirm => 'このファイルをデバイスから完全に削除してもよろしいですか？';

  @override
  String get remove_from_history => '履歴から削除';

  @override
  String get delete_from_device => 'デバイスから削除';

  @override
  String get notice => '通知';

  @override
  String get cannot_write_selected_folder =>
      '選択したフォルダに書き込みできません。デフォルトのダウンロードフォルダを使用します。';

  @override
  String get cannot_write_selected_folder_choose_different =>
      '選択したフォルダに書き込みできません。別の場所を選択してください。';

  @override
  String get cannot_write_configured_folder =>
      '設定されたフォルダに書き込みできません。デフォルトのダウンロードフォルダを使用します。';

  @override
  String get error_selecting_folder_default =>
      'フォルダの選択でエラーが発生しました。デフォルトのダウンロードフォルダを使用します。';

  @override
  String get file_saved_to_app_storage => 'ファイルは選択したフォルダではなくアプリストレージに保存されました';

  @override
  String get failed_write_any_location => 'どの場所にもファイルを書き込めませんでした';

  @override
  String get settings_action => '設定';

  @override
  String save_to_downloads_folder(String fileName) {
    return 'ギャラリーやファイルマネージャーで見つけることができるダウンロードフォルダに\"$fileName\"を保存するには、Solarにストレージ権限が必要です。';
  }

  @override
  String get without_permission_private_folder =>
      '権限がない場合、ファイルはSolarのプライベートフォルダに保存されます（ダウンロードパネルからアクセス可能）。';

  @override
  String get enable_unknown_apps_android =>
      'ダウンロード後、Android設定で「不明なアプリのインストール」を有効にする必要がある場合があります。';

  @override
  String get private_folder_instead => 'ファイルは代わりにSolarのプライベートフォルダに保存されます。';

  @override
  String get save_to_downloads_title => 'ダウンロードに保存しますか？';

  @override
  String get save_to_gallery_title => 'ギャラリーに保存しますか？';

  @override
  String get storage_access_required => 'ストレージアクセスが必要です';

  @override
  String install_package_title(String packageName) {
    return '$packageNameをインストールしますか？';
  }

  @override
  String install_package_message(String packageName) {
    return 'これにより\"$packageName\"がダウンロードされ、お使いのデバイスでのインストール準備が行われます。';
  }

  @override
  String get save_to_gallery_message =>
      'システム全体で表示されるギャラリーアプリに画像と動画を保存するには、Solarにメディアアクセスが必要です。';

  @override
  String get storage_access_message =>
      'デバイスストレージにファイルを保存するには、Solarにストレージアクセス権限が必要です。';

  @override
  String get photos_videos_audio_permission => '写真、動画、音声';

  @override
  String get storage_media_access_permission => 'ストレージ＆メディアアクセス';

  @override
  String get package_installation_permission => 'パッケージインストール';

  @override
  String get storage_access_permission => 'ストレージアクセス';

  @override
  String get without_gallery_permission =>
      '権限がない場合、メディアファイルはSolarのダウンロードセクションでのみ表示されます。';

  @override
  String get flutter_version_string => 'Flutter 3.32.5';

  @override
  String get photoncore_version_string => 'Photoncore 0.1.0';

  @override
  String get engine_version_string => '4.7.0';

  @override
  String get http_warning_title => '安全でない接続の警告';

  @override
  String get http_warning_message =>
      '安全でない接続（HTTP）を使用するウェブサイトにアクセスしようとしています。あなたのデータが他の人に見られる可能性があります。続行してもよろしいですか？';

  @override
  String get continue_anyway => 'とにかく続行';

  @override
  String get go_back => '戻る';

  @override
  String get continue_in_browser => 'ブラウザで続行';

  @override
  String get web_page_error_title => 'ページ読み込みエラー';

  @override
  String get connection_error => '接続エラー';

  @override
  String get page_not_found => 'ページが見つかりません';

  @override
  String get connection_reset => '接続がリセットされました';

  @override
  String get connection_timed_out => '接続がタイムアウトしました';

  @override
  String get dns_error => 'DNSエラー';

  @override
  String get ssl_error => 'SSL証明書エラー';

  @override
  String get network_error => 'ネットワークエラー';

  @override
  String get server_error => 'サーバーエラー';

  @override
  String get unable_to_connect => 'ウェブサイトに接続できません。インターネット接続を確認して再試行してください。';

  @override
  String get page_not_found_description =>
      '要求されたページがサーバーで見つかりませんでした。ページが移動または削除された可能性があります。';

  @override
  String get connection_reset_description =>
      'サーバーへの接続がリセットされました。これは一時的な問題である可能性があります。';

  @override
  String get connection_timeout_description =>
      'サーバーへの接続がタイムアウトしました。サーバーが混雑しているか、接続が遅い可能性があります。';

  @override
  String get dns_error_description => 'ウェブサイトが見つかりません。ウェブアドレスを確認して再試行してください。';

  @override
  String get ssl_error_description =>
      'ウェブサイトのセキュリティ証明書に問題があります。接続が安全でない可能性があります。';

  @override
  String get network_error_description =>
      'ネットワークエラーが発生しました。インターネット接続を確認して再試行してください。';

  @override
  String get server_error_description => 'サーバーでエラーが発生し、リクエストを完了できませんでした。';

  @override
  String get go_home => 'ホームに戻る';

  @override
  String get package_downloaded => 'パッケージがダウンロードされました！';

  @override
  String get installation_steps => 'インストール手順：';

  @override
  String get installation_instructions =>
      '1. 下の「インストール」をタップしてパッケージを開いてください\n2. 促された場合は「不明なアプリのインストール」を有効にしてください\n3. Androidのインストールウィザードに従ってください';

  @override
  String get view => '表示';

  @override
  String get install => 'インストール';

  @override
  String get file_deleted_from_device => 'ファイルがデバイスから削除されました';

  @override
  String get cannot_open_file_path_not_found => 'ファイルを開けません：パスが見つかりません';

  @override
  String error_opening_file_message(String message) {
    return 'ファイルを開くエラー：$message';
  }

  @override
  String error_opening_file_exception(String error) {
    return 'ファイルを開くエラー：$error';
  }

  @override
  String get app_not_installed => 'このリンクを開けません。必要なアプリがインストールされていない可能性があります。';

  @override
  String app_launch_failed(String appName) {
    return '$appNameを開けません。アプリがインストールされていない可能性があります。';
  }

  @override
  String get app_required_not_installed => 'このリンクにはインストールされていないアプリが必要です。';

  @override
  String get invalid_link_format => '無効なリンク形式です。';

  @override
  String get cannot_open_link => 'このリンクを開けません。必要なアプリがインストールされていない可能性があります。';

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
}
