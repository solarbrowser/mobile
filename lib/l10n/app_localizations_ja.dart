import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get welcome => 'Solar へようこそ';

  @override
  String get welcomeSubtitle => 'モダンで高速、安全なブラウザ';

  @override
  String get chooseLanguage => '言語を選択';

  @override
  String get chooseTheme => 'テーマを選択';

  @override
  String get chooseSearchEngine => '検索エンジンを選択';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get getStarted => '始める';

  @override
  String get continueText => '続ける';

  @override
  String get updated => 'Solar ブラウザが更新されました！';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

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
  String get history => '履歴';

  @override
  String get bookmarks => 'ブックマーク';

  @override
  String get search_in_page => 'ページ内検索';
}
