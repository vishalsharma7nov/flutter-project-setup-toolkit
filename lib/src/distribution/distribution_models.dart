enum DistributionTarget {
  androidApk,
  androidAab,
  iosTestFlight,
  both,
}

enum DistributionJobStatus {
  idle,
  running,
  succeeded,
  failed,
}

class DistributionProjectInfo {
  DistributionProjectInfo({
    required this.projectPath,
    required this.environments,
    required this.defaultEnvironment,
    required this.flutterVersion,
    required this.isMacOS,
    this.androidFlavor,
    this.iosFlavor,
    this.iosScheme = 'Runner',
    this.iosSchemes = const [],
    this.iosArchiveName,
    this.configExists = false,
    this.configPath,
    this.openOrganizer = true,
    this.flutterInstalled = true,
  });

  final String projectPath;
  final Map<String, String> environments;
  final String? defaultEnvironment;
  final String flutterVersion;
  final bool isMacOS;
  final String? androidFlavor;
  final String? iosFlavor;
  final String iosScheme;
  final List<String> iosSchemes;
  final String? iosArchiveName;
  final bool configExists;
  final String? configPath;
  final bool openOrganizer;
  final bool flutterInstalled;

  Map<String, dynamic> toJson() => {
        'project_path': projectPath,
        'environments': environments,
        'default_environment': defaultEnvironment,
        'flutter_version': flutterVersion,
        'is_macos': isMacOS,
        'android_flavor': androidFlavor,
        'ios_flavor': iosFlavor,
        'ios_scheme': iosScheme,
        'ios_schemes': iosSchemes,
        if (iosArchiveName != null) 'ios_archive_name': iosArchiveName,
        'config_exists': configExists,
        if (configPath != null) 'config_path': configPath,
        'open_organizer': openOrganizer,
        'flutter_installed': flutterInstalled,
      };
}

class DistributionJobState {
  DistributionJobState({
    this.status = DistributionJobStatus.idle,
    this.target,
    this.startedAt,
    this.finishedAt,
    this.artifactPaths = const [],
    this.error,
    List<String>? logs,
  }) : logs = logs ?? [];

  DistributionJobStatus status;
  DistributionTarget? target;
  DateTime? startedAt;
  DateTime? finishedAt;
  List<String> artifactPaths;
  String? error;
  final List<String> logs;

  Map<String, dynamic> toJson({int logOffset = 0}) {
    final slice = logOffset < logs.length ? logs.sublist(logOffset) : <String>[];
    return {
      'status': status.name,
      'target': target?.name,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'artifact_paths': artifactPaths,
      'error': error,
      'logs': slice,
      'log_total': logs.length,
    };
  }
}
