import 'dart:io';

import '../config.dart';
import 'env_overlay.dart';

/// Parsed `env_source` block from API/CLI build requests.
class EnvSourceRequest {
  const EnvSourceRequest._({
    required this.mode,
    this.localFilePath,
    this.values,
    this.pasteContent,
  });

  factory EnvSourceRequest.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('env_source is null');
    }
    final mode = json['mode'] as String? ?? '';
    return switch (mode) {
      'local_file' => EnvSourceRequest._(
          mode: mode,
          localFilePath: json['path'] as String?,
        ),
      'session_values' => EnvSourceRequest._(
          mode: mode,
          values: (json['values'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ),
        ),
      'paste' => EnvSourceRequest._(
          mode: mode,
          pasteContent: json['content'] as String?,
        ),
      _ => throw ArgumentError('Unknown env_source mode: $mode'),
    };
  }

  final String mode;
  final String? localFilePath;
  final Map<String, String>? values;
  final String? pasteContent;
}

class ResolvedBuildEnv {
  ResolvedBuildEnv({
    required this.file,
    this.cleanup,
    this.usedOverlay = false,
  });

  final File file;
  final void Function()? cleanup;
  final bool usedOverlay;

  void dispose() => cleanup?.call();
}

/// Resolves the env file for a distribution build (project file or session overlay).
ResolvedBuildEnv resolveBuildEnv({
  required Directory projectRoot,
  required String envName,
  EnvSourceRequest? envSource,
  EnvOverlayWriter? writer,
}) {
  final resolved = resolveBuildEnvOptional(
    projectRoot: projectRoot,
    envName: envName,
    envSource: envSource,
    writer: writer,
  );
  if (resolved != null) {
    return resolved;
  }
  final config = loadConfig(projectRoot);
  File? projectEnv;
  try {
    projectEnv = config.resolveEnvPath(envName);
  } on Object {
    projectEnv = null;
  }
  final expected = projectEnv?.path ?? envName;
  throw StateError(
    'Missing env file for $envName ($expected). '
    'Provide env_source (local_file or session_values) or run Setup Studio.',
  );
}

/// Returns null when no project env file exists and no [envSource] overlay was given.
ResolvedBuildEnv? resolveBuildEnvOptional({
  required Directory projectRoot,
  required String envName,
  EnvSourceRequest? envSource,
  EnvOverlayWriter? writer,
}) {
  final config = loadConfig(projectRoot);
  File? projectEnv;
  try {
    projectEnv = config.resolveEnvPath(envName);
  } on Object {
    projectEnv = null;
  }

  if (projectEnv != null && projectEnv.existsSync()) {
    return ResolvedBuildEnv(file: projectEnv);
  }

  if (envSource == null) {
    return null;
  }

  final overlayWriter = writer ?? EnvOverlayWriter();
  final overlay = overlayWriter.writeSessionOverlay(
    localFilePath: envSource.localFilePath,
    values: envSource.values,
    pasteContent: envSource.pasteContent,
  );
  return ResolvedBuildEnv(
    file: overlay.file,
    cleanup: overlay.cleanup,
    usedOverlay: true,
  );
}

/// Flutter `--dart-define` args from an optional env file.
List<String> dartDefineArgsFromEnvFile(File? envFile) {
  final args = <String>[];
  if (envFile != null) {
    args.add('--dart-define-from-file=${envFile.path}');
  }
  final appEnv = Platform.environment['APP_ENV'];
  if (appEnv != null) {
    args.add('--dart-define=APP_ENV=$appEnv');
  }
  return args;
}

/// Keys suggested when env file is missing (for preflight `env_help`).
List<String> suggestedEnvKeys(Directory projectRoot) {
  final config = loadConfig(projectRoot);
  final keys = <String>[
    ...config.versionKeys.values,
    config.api.envLineForProtocol() ?? config.api.baseUrlEnvKey,
  ];
  return keys.where((key) => key.isNotEmpty).toSet().toList();
}

String? expectedEnvRelativePath(Directory projectRoot, String envName) {
  try {
    final config = loadConfig(projectRoot);
    return config.environments[envName];
  } on Object {
    return null;
  }
}

Map<String, dynamic>? buildEnvHelp({
  required Directory projectRoot,
  required String envName,
  required bool envMissing,
}) {
  if (!envMissing) return null;
  return {
    'expected_path': expectedEnvRelativePath(projectRoot, envName),
    'suggested_keys': suggestedEnvKeys(projectRoot),
    'can_overlay': true,
  };
}
