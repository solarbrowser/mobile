class DownloadItem {
  final String url;
  final String filename;
  double progress;
  bool isCompleted;
  String? error;

  DownloadItem({
    required this.url,
    required this.filename,
    this.progress = 0.0,
    this.isCompleted = false,
    this.error,
  });
} 