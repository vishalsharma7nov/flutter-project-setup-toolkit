import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../config_file.dart';
import '../flutter_tools.dart';
import '../ios_xcode.dart';
import '../env/env_security.dart';
import '../env/env_source.dart';
import 'distribution_models.dart';

class DistributionBuildService {
  DistributionBuildService(this.jobState);

  final DistributionJobState jobState;
  Process? _activeProcess;

  Future<void> cancel() async {
    final process = _activeProcess;
    if (process == null) return;
    process.kill(ProcessSignal.sigterm);
    _log('Build cancelled.');
  }

  void _log(String message) {
    jobState.logs.add(message);
    stdout.writeln(message);
  }

  Future<void> run({
    required Directory projectRoot,
    required DistributionTarget target,
    required String envName,
    String? androidFlavor,
    String? iosFlavor,
    String? iosScheme,
    EnvSourceRequest? envSource,
    Map<String, dynamic>? configPatch,
    bool allowMissingEnv = false,
    File? envFileOverride,
    bool useEnvFileOverride = false,
  }) async {
    jobState
      ..status = DistributionJobStatus.running
      ..target = target
      ..startedAt = DateTime.now()
      ..finishedAt = null
      ..artifactPaths = []
      ..error = null
      ..logs.clear();

    ResolvedBuildEnv? resolvedEnv;
    try {
      if (configPatch != null) {
        saveReleaseToolkitConfigPatch(
          projectRoot: projectRoot,
          patch: configPatch,
        );
        _log('Updated release-toolkit.config.json');
      }

      final config = loadConfig(projectRoot);
      final File? envFile;
      if (useEnvFileOverride) {
        envFile = envFileOverride;
        if (envFile != null) {
          resolvedEnv = ResolvedBuildEnv(file: envFile);
        }
      } else if (allowMissingEnv) {
        resolvedEnv = resolveBuildEnvOptional(
          projectRoot: projectRoot,
          envName: envName,
          envSource: envSource,
        );
        envFile = resolvedEnv?.file;
      } else {
        resolvedEnv = resolveBuildEnv(
          projectRoot: projectRoot,
          envName: envName,
          envSource: envSource,
        );
        envFile = resolvedEnv.file;
      }
      if (envFile == null) {
        _log('No env file — building without --dart-define-from-file');
      } else if (resolvedEnv?.usedOverlay == true) {
        _log('Using session env overlay: ${envFile.path}');
      }

      final resolvedAndroidFlavor = androidFlavor ?? config.build.androidFlavor;
      final resolvedIosFlavor = iosFlavor ?? config.build.iosFlavor;
      final resolvedIosScheme = resolveConfiguredIosScheme(
        projectRoot: projectRoot,
        configuredScheme: iosScheme ?? config.build.iosScheme,
      );

      final flutter = detectFlutter();
      final version = await flutterVersion(flutter);
      _log('Project: ${projectRoot.path}');
      _log('Flutter: $version');
      if (envFile != null) {
        _log('Environment: $envName -> ${envFile.path}');
        _logEnvSummary(envFile);
      } else {
        _log('Environment: $envName (no env file)');
      }
      if (resolvedAndroidFlavor != null) {
        _log('Android flavor: $resolvedAndroidFlavor');
      }
      if (resolvedIosFlavor != null) {
        _log('iOS flavor: $resolvedIosFlavor');
      }
      _log('Target: ${target.name}');
      _log('');

      if (target == DistributionTarget.androidApk ||
          target == DistributionTarget.both) {
        final artifact = await _buildAndroidApk(
          projectRoot: projectRoot,
          config: config,
          envFile: envFile,
          flutter: flutter,
          flavor: resolvedAndroidFlavor,
        );
        jobState.artifactPaths.add(artifact.path);
      }

      if (target == DistributionTarget.androidAab) {
        final artifact = await _buildAndroidAab(
          projectRoot: projectRoot,
          config: config,
          envFile: envFile,
          flutter: flutter,
          flavor: resolvedAndroidFlavor,
        );
        jobState.artifactPaths.add(artifact.path);
      }

      if (target == DistributionTarget.iosTestFlight ||
          target == DistributionTarget.both) {
        if (!Platform.isMacOS) {
          throw StateError('iOS TestFlight builds require macOS with Xcode.');
        }
        final artifacts = await _buildIosTestFlight(
          projectRoot: projectRoot,
          config: config,
          envFile: envFile,
          flutter: flutter,
          flavor: resolvedIosFlavor,
          scheme: resolvedIosScheme,
        );
        jobState.artifactPaths.addAll(artifacts);
      }

      jobState.status = DistributionJobStatus.succeeded;
      _log('');
      _log('Build finished successfully.');
      for (final path in jobState.artifactPaths) {
        _log('Artifact: $path');
      }
    } on Object catch (e) {
      jobState.status = DistributionJobStatus.failed;
      jobState.error = '$e';
      _log('');
      _log('Build failed: $e');
    } finally {
      resolvedEnv?.dispose();
      jobState.finishedAt = DateTime.now();
    }
  }

  void _logEnvSummary(File envFile) {
    _log('Dart defines from ${envFile.path}:');
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.split('#').first.trim();
      if (trimmed.isEmpty || !trimmed.contains('=')) continue;
      _log(redactEnvLine(trimmed));
    }
    _log('');
  }

  Future<File> _buildAndroidApk({
    required Directory projectRoot,
    required ToolkitConfig config,
    required File? envFile,
    required FlutterCommand flutter,
    String? flavor,
  }) async {
    _log('--- Android APK (beta testers) ---');
    final buildArgs = <String>[
      'build',
      'apk',
      '--release',
      if (flavor != null) ...['--flavor', flavor],
      ...dartDefineArgsFromEnvFile(envFile),
    ];

    await _runFlutterBuildStreaming(projectRoot, flutter, buildArgs);
    final artifact = _findAndroidApk(projectRoot, flavor);
    if (artifact == null) {
      throw StateError('APK not found under build/app/outputs');
    }
    return artifact;
  }

  Future<File> _buildAndroidAab({
    required Directory projectRoot,
    required ToolkitConfig config,
    required File? envFile,
    required FlutterCommand flutter,
    String? flavor,
  }) async {
    _log('--- Android AAB (Play Store) ---');
    final buildArgs = <String>[
      'build',
      'appbundle',
      '--release',
      if (flavor != null) ...['--flavor', flavor],
      ...dartDefineArgsFromEnvFile(envFile),
    ];

    await _runFlutterBuildStreaming(projectRoot, flutter, buildArgs);
    final artifact = _findAndroidAab(projectRoot, flavor);
    if (artifact == null) {
      throw StateError('AAB not found under build/app/outputs');
    }
    return artifact;
  }

  Future<List<String>> _buildIosTestFlight({
    required Directory projectRoot,
    required ToolkitConfig config,
    required File? envFile,
    required FlutterCommand flutter,
    String? flavor,
    required String scheme,
  }) async {
    _log('--- iOS IPA (TestFlight) ---');
    final iosBuild = resolveIosBuild(
      projectRoot: projectRoot,
      configuredFlavor: flavor,
      configuredScheme: scheme,
    );
    if (iosBuild.error != null) {
      throw StateError(iosBuild.error!);
    }
    if (iosBuild.warning != null) {
      for (final line in iosBuild.warning!.split('\n')) {
        _log('Note: $line');
      }
    }
    final archiveName = readIosSchemeArchiveName(
      projectRoot,
      iosBuild.archiveScheme,
    );
    if (iosBuild.flutterFlavor != null) {
      _log('Flutter iOS flavor: ${iosBuild.flutterFlavor}');
    } else if (flavor != null) {
      _log(
        'Flutter iOS flavor: (none — using Xcode scheme ${iosBuild.archiveScheme})',
      );
    }
    _log('Xcode scheme: ${iosBuild.archiveScheme}');
    if (archiveName != null && archiveName != iosBuild.archiveScheme) {
      _log('Archive name: $archiveName');
    }

    final buildArgs = <String>[
      'build',
      'ipa',
      '--release',
      if (iosBuild.flutterFlavor != null) ...['--flavor', iosBuild.flutterFlavor!],
      ...dartDefineArgsFromEnvFile(envFile),
    ];

    await _runFlutterBuildStreaming(projectRoot, flutter, buildArgs);

    final paths = <String>[];
    final archive = _findArchive(
      projectRoot,
      iosBuild.archiveScheme,
      iosBuild.flutterFlavor,
      archiveName: archiveName,
    );
    if (archive != null) {
      paths.add(archive.path);
      _log('Archive: ${archive.path}');
      if (config.build.openOrganizer) {
        await Process.run('open', [archive.path]);
        _log('Opened Xcode Organizer for TestFlight upload.');
      }
    }

    final ipaDir = Directory(p.join(projectRoot.path, 'build', 'ios', 'ipa'));
    if (ipaDir.existsSync()) {
      for (final entity in ipaDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.ipa')) {
          paths.add(entity.path);
          _log('IPA: ${entity.path}');
        }
      }
    }
    if (paths.isEmpty) {
      throw StateError('IPA/archive not found under build/ios');
    }
    return paths;
  }

  Future<void> _runFlutterBuildStreaming(
    Directory projectRoot,
    FlutterCommand flutter,
    List<String> buildArgs,
  ) async {
    _log('> ${flutter.executable} ${flutter.buildArgs(buildArgs).join(' ')}');
    final process = await Process.start(
      flutter.executable,
      flutter.buildArgs(buildArgs),
      workingDirectory: projectRoot.path,
      mode: ProcessStartMode.normal,
    );
    _activeProcess = process;

    final stdoutFuture = () async {
      await for (final line in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        _log(line);
      }
    }();
    final stderrFuture = () async {
      await for (final line in process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        _log('[stderr] $line');
      }
    }();

    await Future.wait([stdoutFuture, stderrFuture]);

    final exitCode = await process.exitCode;
    _activeProcess = null;
    if (exitCode != 0) {
      throw StateError('flutter build exited with code $exitCode');
    }
  }
}

Future<DistributionProjectInfo> loadDistributionProjectInfoAsync(
  Directory projectRoot,
) async {
  validateFlutterProject(projectRoot);
  final config = loadConfig(projectRoot);
  var flutterVersionText = 'not installed';
  var flutterInstalled = false;
  try {
    final flutter = detectFlutter();
    flutterVersionText = await flutterVersion(flutter);
    flutterInstalled = true;
  } on Object {
    flutterVersionText = 'Flutter not found on PATH';
  }
  final detection = detectIosBuildSettings(projectRoot);
  final resolvedScheme = resolveConfiguredIosScheme(
    projectRoot: projectRoot,
    configuredScheme: config.build.iosScheme,
  );
  return DistributionProjectInfo(
    projectPath: projectRoot.path,
    environments: config.environments,
    defaultEnvironment: config.defaultEnvironment,
    flutterVersion: flutterVersionText,
    isMacOS: Platform.isMacOS,
    androidFlavor: config.build.androidFlavor,
    iosFlavor: config.build.iosFlavor,
    iosScheme: resolvedScheme,
    iosSchemes: detection?.appSchemes ?? const [],
    iosArchiveName: detection?.archiveName ??
        readIosSchemeArchiveName(projectRoot, resolvedScheme),
    configExists: releaseToolkitConfigExists(projectRoot),
    configPath: releaseToolkitConfigFile(projectRoot).path,
    openOrganizer: config.build.openOrganizer,
    flutterInstalled: flutterInstalled,
  );
}

File? _findAndroidApk(Directory projectRoot, String? flavor) {
  final dirs = <String>[
    p.join('build', 'app', 'outputs', 'flutter-apk'),
    p.join('build', 'app', 'outputs', 'apk', 'release'),
    if (flavor != null) p.join('build', 'app', 'outputs', 'apk', flavor, 'release'),
  ];
  for (final dir in dirs) {
    final directory = Directory(p.join(projectRoot.path, dir));
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.endsWith('.apk')) {
        return entity;
      }
    }
  }
  return null;
}

File? _findAndroidAab(Directory projectRoot, String? flavor) {
  final dirs = <String>[
    p.join('build', 'app', 'outputs', 'bundle', 'release'),
    if (flavor != null)
      p.join('build', 'app', 'outputs', 'bundle', flavor, 'release'),
  ];
  for (final dir in dirs) {
    final directory = Directory(p.join(projectRoot.path, dir));
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.endsWith('.aab')) {
        return entity;
      }
    }
  }
  return null;
}

Directory? _findArchive(
  Directory projectRoot,
  String scheme,
  String? flavor, {
  String? archiveName,
}) {
  final archiveRoot = Directory(p.join(projectRoot.path, 'build', 'ios', 'archive'));
  if (!archiveRoot.existsSync()) return null;
  final candidates = iosArchiveCandidateNames(
    archiveScheme: scheme,
    flutterFlavor: flavor,
    customArchiveName: archiveName,
  );
  for (final name in candidates) {
    final dir = Directory(p.join(archiveRoot.path, name));
    if (dir.existsSync()) return dir;
  }
  for (final entity in archiveRoot.listSync()) {
    if (entity is Directory && entity.path.endsWith('.xcarchive')) {
      return entity;
    }
  }
  return null;
}
