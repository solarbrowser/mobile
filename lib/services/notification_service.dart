import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_download_notification');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<void> showDownloadStartedNotification(String filename) async {
    await _notifications.show(
      0,
      'Download Started',
      'Downloading $filename',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download notifications',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showProgress: true,
          maxProgress: 100,
          progress: 0,
          icon: '@drawable/ic_download_notification',
          enableVibration: false,
          playSound: false,
          channelShowBadge: false,
        ),
      ),
    );
  }

  Future<void> updateDownloadProgress(String filename, int progress) async {
    await _notifications.show(
      0,
      'Downloading',
      'Downloading $filename - $progress%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download notifications',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          icon: '@drawable/ic_download_notification',
          enableVibration: false,
          playSound: false,
          channelShowBadge: false,
        ),
      ),
    );
  }

  Future<void> showDownloadCompleteNotification(String filename) async {
    await _notifications.show(
      0,
      'Download Complete',
      '$filename has been downloaded',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          icon: '@drawable/ic_download_notification',
          channelShowBadge: true,
        ),
      ),
    );
  }
} 