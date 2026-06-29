import 'dart:io';

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
      'artifact_urls': artifactPaths.map(quickTestArtifactDownloadUrl).toList(),
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

enum QuickTestInstallMode {
  hostAdb,
  clientDownload,
}

class QuickTestRunOptions {
  const QuickTestRunOptions({
    this.platform = QuickTestPlatform.all,
    this.installMode = QuickTestInstallMode.hostAdb,
    this.installToDevices = true,
    this.includeTestflightIpa = true,
    this.selectedDeviceIds = const [],
    this.androidFlavor,
    this.iosFlavor,
    this.iosScheme,
  });

  final QuickTestPlatform platform;
  final QuickTestInstallMode installMode;
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
    final installModeRaw = json['install_mode'] as String? ?? 'host_adb';
    final installMode = switch (installModeRaw) {
      'client_download' => QuickTestInstallMode.clientDownload,
      _ => QuickTestInstallMode.hostAdb,
    };
    return QuickTestRunOptions(
      platform: platform,
      installMode: installMode,
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

String quickTestArtifactDownloadUrl(String artifactPath) {
  return '/api/quick-test/artifacts/download?path=${Uri.encodeComponent(artifactPath)}';
}

bool quickTestArtifactPathAllowed(String requestedPath, List<String> allowedPaths) {
  if (allowedPaths.isEmpty) return false;
  final requested = _canonicalArtifactPath(requestedPath);
  for (final allowed in allowedPaths) {
    if (requested == _canonicalArtifactPath(allowed)) {
      return true;
    }
  }
  return false;
}

String _canonicalArtifactPath(String path) {
  return File(path).absolute.path;
}

String quickTestArtifactContentType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.apk')) {
    return 'application/vnd.android.package-archive';
  }
  if (lower.endsWith('.ipa')) {
    return 'application/octet-stream';
  }
  return 'application/octet-stream';
}
