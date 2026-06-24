class DetectedApp {
  final String appId;
  final String? appName;
  final bool allowed;
  final bool isNew;

  DetectedApp({
    required this.appId,
    this.appName,
    required this.allowed,
    required this.isNew,
  });

  DetectedApp copyWith({
    String? appId,
    String? appName,
    bool? allowed,
    bool? isNew,
  }) {
    return DetectedApp(
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      allowed: allowed ?? this.allowed,
      isNew: isNew ?? this.isNew,
    );
  }
}
