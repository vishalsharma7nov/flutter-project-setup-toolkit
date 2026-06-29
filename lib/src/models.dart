import 'dart:io';

enum BumpLevel {
  patch(1),
  minor(2),
  major(3);

  const BumpLevel(this.rank);
  final int rank;

  @override
  String toString() => name;
}

class FileChange {
  const FileChange(this.status, this.path);
  final String status;
  final String path;
}

class VersionSnapshot {
  const VersionSnapshot(this.major, this.minor, this.patch, this.build);
  final int major;
  final int minor;
  final int patch;
  final int build;

  String get name => '$major.$minor.$patch';
  String get pubspec => '$name+$build';
}

class PlatformVersions {
  const PlatformVersions({this.android, this.ios});
  final VersionSnapshot? android;
  final VersionSnapshot? ios;
}

class Classification {
  Classification({this.level = BumpLevel.patch, List<String>? reasons})
      : reasons = reasons ?? [];

  BumpLevel level;
  final List<String> reasons;

  void merge(BumpLevel other, String reason) {
    if (other.rank > level.rank) {
      level = other;
    }
    reasons.add(reason);
  }
}

class EnvKeyChange {
  const EnvKeyChange(this.from, this.to);
  final String? from;
  final String to;
}

class EnvTargetResult {
  EnvTargetResult({
    required this.label,
    required this.envFile,
    required this.envUpdates,
    this.android,
    this.ios,
    Map<String, EnvKeyChange>? envChanges,
    this.envApplied = false,
  }) : envChanges = envChanges ?? {};

  final String label;
  final String envFile;
  final Map<String, String> envUpdates;
  Map<String, String>? android;
  Map<String, String>? ios;
  Map<String, EnvKeyChange> envChanges;
  bool envApplied;
}

class BuildConfig {
  const BuildConfig({
    this.androidFlavor,
    this.iosFlavor,
    this.iosScheme = 'Runner',
    this.openOrganizer = true,
  });

  final String? androidFlavor;
  final String? iosFlavor;
  final String iosScheme;
  final bool openOrganizer;
}

class MainDartEnvRule {
  const MainDartEnvRule({required this.match, required this.environment});
  final String match;
  final String environment;
}

enum ToolkitInstallMode {
  devDependency,
  localClone,
  globalCli,
}

enum StateManagement {
  bloc,
  riverpod,
  provider,
  getx,
  none;

  static StateManagement? parse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final option in StateManagement.values) {
      if (option.name == value) {
        return option;
      }
    }
    return null;
  }
}

class ToolkitInstallPlan {
  const ToolkitInstallPlan({
    required this.projectRoot,
    required this.mode,
    this.localToolkitPath,
    this.toolkitInstallPath,
    this.pubspecVersionConstraint = '^0.1.0',
  });

  final Directory projectRoot;
  final ToolkitInstallMode mode;
  final String? localToolkitPath;
  final String? toolkitInstallPath;
  final String pubspecVersionConstraint;
}
