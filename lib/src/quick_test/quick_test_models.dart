enum QuickTestJobStatus {
  idle,
  running,
  succeeded,
  failed,
}

class QuickTestJobState {
  QuickTestJobState({
    this.status = QuickTestJobStatus.idle,
    this.startedAt,
    this.finishedAt,
    this.artifactPaths = const [],
    this.error,
    List<String>? logs,
  }) : logs = logs ?? [];

  QuickTestJobStatus status;
  DateTime? startedAt;
  DateTime? finishedAt;
  List<String> artifactPaths;
  String? error;
  final List<String> logs;

  Map<String, dynamic> toJson({int logOffset = 0}) {
    final slice = logOffset < logs.length ? logs.sublist(logOffset) : <String>[];
    return {
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'artifact_paths': artifactPaths,
      'error': error,
      'logs': slice,
      'log_total': logs.length,
    };
  }
}

enum QuickTestPlatform {
  all,
  android,
  ios,
}

class QuickTestRunOptions {
  const QuickTestRunOptions({
    this.platform = QuickTestPlatform.all,
    this.installToDevices = true,
    this.includeTestflightIpa = true,
    this.selectedDeviceIds = const [],
    this.androidFlavor,
    this.iosFlavor,
    this.iosScheme,
  });

  final QuickTestPlatform platform;
  final bool installToDevices;
  final bool includeTestflightIpa;
  final List<String> selectedDeviceIds;
  final String? androidFlavor;
  final String? iosFlavor;
  final String? iosScheme;

  factory QuickTestRunOptions.fromJson(Map<String, dynamic> json) {
    final ids = json['selected_device_ids'];
    final platformRaw = json['platform'] as String? ?? 'all';
    final platform = switch (platformRaw) {
      'android' => QuickTestPlatform.android,
      'ios' => QuickTestPlatform.ios,
      _ => QuickTestPlatform.all,
    };
    return QuickTestRunOptions(
      platform: platform,
      installToDevices: json['install_to_devices'] as bool? ?? true,
      includeTestflightIpa: json['include_testflight_ipa'] as bool? ?? true,
      selectedDeviceIds: ids is List
          ? ids.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      androidFlavor: json['android_flavor'] as String?,
      iosFlavor: json['ios_flavor'] as String?,
      iosScheme: json['ios_scheme'] as String?,
    );
  }
}
