import 'dart:io';

import '../config.dart';
import '../devices/device_service.dart';
import '../distribution/distribution_build_service.dart';
import '../distribution/distribution_models.dart';
import '../distribution/distribution_preflight.dart';
import '../env/env_source.dart';
import '../git/git_clone_service.dart';
import '../git/git_remote_source.dart';
import '../ios_xcode.dart';
import '../studio/flutter_project_structure.dart';
import 'quick_test_models.dart';
import 'quick_test_target.dart';

Future<Map<String, dynamic>> _quickTestContext({
  required Directory repoRoot,
  required String envName,
  EnvSourceRequest? envSource,
}) async {
  final target = resolveQuickTestTarget(repoRoot);
  await ensureQuickTestBuildReady(target);

  var envReady = false;
  String? envError;
  try {
    final resolved = resolveQuickTestEnvOptional(
      target: target,
      envName: envName,
      envSource: envSource,
    );
    envReady = resolved != null;
    resolved?.dispose();
  } on Object catch (e) {
    envError = '$e';
  }

  final structure = analyzeFlutterProjectStructure(target.buildRoot);
  final checks = _quickTestPreflightChecks(
    runDistributionPreflight(
      projectRoot: target.buildRoot,
      envName: envName,
    ),
    envReady: envReady,
  );

  final config = loadConfig(target.buildRoot);
  final repoConfig = target.buildRoot.path == target.repoRoot.path
      ? config
      : loadConfig(target.repoRoot);
  final detection = detectIosBuildSettings(target.buildRoot);
  final resolvedScheme = resolveConfiguredIosScheme(
    projectRoot: target.buildRoot,
    configuredScheme: config.build.iosScheme.trim().isNotEmpty
        ? config.build.iosScheme
        : repoConfig.build.iosScheme,
  );

  return {
    'target': target,
    'structure': structure,
    'checks': checks,
    'envReady': envReady,
    'envError': envError,
    'config': config,
    'repoConfig': repoConfig,
    'detection': detection,
    'resolvedScheme': resolvedScheme,
  };
}

Future<Map<String, dynamic>> runQuickTestPreflight({
  required GitRemoteSource source,
  required String envName,
  EnvSourceRequest? envSource,
  GitCloneService? gitClone,
  DeviceService? deviceService,
}) async {
  final service = gitClone ?? GitCloneService();
  await service.verifyAccess(source);
  final root = await service.cloneOrUpdate(source);

  final ctx = await _quickTestContext(
    repoRoot: root,
    envName: envName,
    envSource: envSource,
  );
  final target = ctx['target'] as QuickTestTarget;
  final structure = ctx['structure'] as FlutterProjectAnalysis;
  final checks = ctx['checks'] as List<Map<String, dynamic>>;
  final envReady = ctx['envReady'] as bool;
  final envError = ctx['envError'] as String?;
  final config = ctx['config'] as ToolkitConfig;
  final detection = ctx['detection'] as IosBuildDetection?;
  final resolvedScheme = ctx['resolvedScheme'] as String;

  final envMissing = !envReady;

  final devices = await (deviceService ?? DeviceService()).listConnectedDevices();

  return {
    'work_dir': root.path,
    'build_dir': target.buildRoot.path,
    'is_plugin': target.isPlugin,
    'uses_example_app': target.isPlugin,
    'source': source.toJson(),
    'flutter_ok': true,
    'structure': structure.toJson(),
    'structure_complete': structure.compatible,
    'checks': checks,
    'environments': config.environments.isNotEmpty
        ? config.environments
        : (ctx['repoConfig'] as ToolkitConfig).environments,
    'default_environment': config.defaultEnvironment ??
        (ctx['repoConfig'] as ToolkitConfig).defaultEnvironment,
    'env_ready': envReady,
    'can_run_without_env': true,
    if (envError != null) 'env_error': envError,
    'devices': devices.map((d) => d.toJson()).toList(),
    'ios_scheme': resolvedScheme,
    'ios_schemes': detection?.appSchemes ?? const [],
    if (detection?.archiveName != null) 'ios_archive_name': detection!.archiveName,
    if (envMissing)
      'env_help': buildEnvHelp(
        projectRoot: target.buildRoot,
        envName: envName,
        envMissing: true,
      ),
  };
}

class QuickTestPipeline {
  QuickTestPipeline(
    this.jobState, {
    GitCloneService? gitClone,
    DeviceService? deviceService,
  })  : _gitClone = gitClone ?? GitCloneService(),
        _deviceService = deviceService ?? DeviceService();

  final QuickTestJobState jobState;
  final GitCloneService _gitClone;
  final DeviceService _deviceService;
  DistributionBuildService? _buildService;

  Future<void> cancel() async {
    await _buildService?.cancel();
    await _deviceService.cancel();
    _log('Quick test cancelled.');
  }

  void _log(String message) {
    jobState.logs.add(message);
    stdout.writeln(message);
  }

  Future<void> run({
    required GitRemoteSource source,
    required String envName,
    EnvSourceRequest? envSource,
    QuickTestRunOptions options = const QuickTestRunOptions(),
  }) async {
    jobState
      ..status = QuickTestJobStatus.running
      ..startedAt = DateTime.now()
      ..finishedAt = null
      ..artifactPaths = []
      ..error = null
      ..logs.clear();

    ResolvedBuildEnv? resolvedEnv;
    try {
      _log('--- Quick Test: clone & validate ---');
      await _gitClone.verifyAccess(source);
      final repoRoot = await _gitClone.cloneOrUpdate(source);
      final ctx = await _quickTestContext(
        repoRoot: repoRoot,
        envName: envName,
        envSource: envSource,
      );
      final target = ctx['target'] as QuickTestTarget;
      final structure = ctx['structure'] as FlutterProjectAnalysis;
      if (target.isPlugin) {
        _log(
          'Flutter plugin detected — building and installing from '
          '${target.buildRoot.path}',
        );
      }

      if (!structure.compatible) {
        final issueText = structure.issues.join('; ');
        if (target.isPlugin && issueText.contains('Missing lib/main.dart')) {
          _log(
            'Note: plugin package root has no main.dart — using example/ for builds.',
          );
        } else {
          _log(
            'Warning: project structure is incomplete ($issueText). '
            'Run Setup Studio to repair.',
          );
        }
      }

      resolvedEnv = resolveQuickTestEnvOptional(
        target: target,
        envName: envName,
        envSource: envSource,
      );
      final envFile = resolvedEnv?.file;
      if (envFile != null && resolvedEnv!.usedOverlay) {
        _log('Using session env overlay: ${envFile.path}');
      } else if (envFile == null) {
        _log(
          'No env file configured — building without --dart-define-from-file. '
          'Add env secrets if the app requires dart-defines.',
        );
      }

      final config = ctx['config'] as ToolkitConfig;
      final repoConfig = ctx['repoConfig'] as ToolkitConfig;
      final buildRoot = target.buildRoot;
      final androidFlavor =
          options.androidFlavor ?? config.build.androidFlavor ?? repoConfig.build.androidFlavor;
      final iosFlavor =
          options.iosFlavor ?? config.build.iosFlavor ?? repoConfig.build.iosFlavor;
      final iosScheme = resolveConfiguredIosScheme(
        projectRoot: buildRoot,
        configuredScheme: options.iosScheme ??
            (config.build.iosScheme.trim().isNotEmpty
                ? config.build.iosScheme
                : repoConfig.build.iosScheme),
      );

      final iosBuild = resolveIosBuild(
        projectRoot: buildRoot,
        configuredFlavor: iosFlavor,
        configuredScheme: iosScheme,
      );
      final resolvedIosFlavor = iosBuild.flutterFlavor;

      final allDevices = await _deviceService.listConnectedDevices();
      final selectedIds = options.selectedDeviceIds.toSet();
      final hostInstall = options.installMode == QuickTestInstallMode.hostAdb &&
          (options.installToDevices ||
              options.platform != QuickTestPlatform.all);
      final targetDevices = hostInstall
          ? (selectedIds.isEmpty
              ? allDevices.where((d) => d.available).toList()
              : allDevices
                  .where((d) => d.available && selectedIds.contains(d.id))
                  .toList())
          : <ConnectedDevice>[];

      final runAndroid = options.platform == QuickTestPlatform.all ||
          options.platform == QuickTestPlatform.android;
      final runIosInstall = options.platform == QuickTestPlatform.all ||
          options.platform == QuickTestPlatform.ios;
      final runTestflight = options.platform == QuickTestPlatform.all &&
          options.includeTestflightIpa;

      if (options.platform == QuickTestPlatform.ios && !Platform.isMacOS) {
        throw StateError('iOS install requires macOS with Xcode.');
      }

      if (options.installMode == QuickTestInstallMode.clientDownload) {
        _log('Install mode: client_download — skipping host adb/flutter install');
      }

      if (hostInstall && targetDevices.isEmpty) {
        _log('No devices selected or connected — skipping install');
      }

      if (runAndroid) {
        _log('');
        _log('--- Android APK ---');
        final apkPath = await _runDistributionStep(
          projectRoot: buildRoot,
          envFile: envFile,
          target: DistributionTarget.androidApk,
          androidFlavor: androidFlavor,
          iosFlavor: iosFlavor,
          iosScheme: iosScheme,
        );

        for (final device
            in targetDevices.where((d) => d.platform == DevicePlatform.android)) {
          try {
            await _deviceService.installAndroidApk(
              deviceId: device.id,
              apkPath: apkPath,
              onLog: _log,
            );
          } on Object catch (e) {
            _log('Android install failed on ${device.name}: $e');
          }
        }
      }

      if (runIosInstall) {
        final iosDevices =
            targetDevices.where((d) => d.platform == DevicePlatform.ios).toList();
        if (iosDevices.isEmpty) {
          _log('No iOS devices selected or connected — skipping iOS install');
        } else if (iosBuild.error != null) {
          _log('iOS install skipped: ${iosBuild.error}');
        } else {
          _log('');
          _log('--- iOS device install (flutter build ios + flutter install) ---');
          for (final device in iosDevices) {
            try {
              await _deviceService.installIosApp(
                projectRoot: buildRoot,
                deviceId: device.id,
                envFile: envFile,
                flavor: resolvedIosFlavor,
                isSimulator: device.isSimulator,
                onLog: _log,
              );
            } on Object catch (e) {
              final hint = device.isSimulator
                  ? 'Simulator installs use a debug/simulator build. '
                      'For release testing, use a USB-connected iPhone.'
                  : 'Check Xcode signing (development/distribution cert) for this device.';
              _log(
                'iOS install failed on ${device.name}: $e\n$hint',
              );
            }
          }
        }
      }

      if (runTestflight && Platform.isMacOS) {
        _log('');
        _log('--- TestFlight IPA (upload via Xcode Organizer) ---');
        _log(
          'Note: TestFlight IPA is for App Store Connect upload, not USB sideloading.',
        );
        await _runDistributionStep(
          projectRoot: buildRoot,
          envFile: envFile,
          target: DistributionTarget.iosTestFlight,
          androidFlavor: androidFlavor,
          iosFlavor: iosFlavor,
          iosScheme: iosScheme,
        );
      } else if (options.includeTestflightIpa &&
          options.platform == QuickTestPlatform.all &&
          !Platform.isMacOS) {
        _log('TestFlight IPA skipped — requires macOS with Xcode');
      }

      jobState.status = QuickTestJobStatus.succeeded;
      _log('');
      _log('Quick test finished successfully.');
      for (final path in jobState.artifactPaths) {
        _log('Artifact: $path');
      }
    } on Object catch (e) {
      jobState.status = QuickTestJobStatus.failed;
      jobState.error = '$e';
      _log('');
      _log('Quick test failed: $e');
    } finally {
      resolvedEnv?.dispose();
      jobState.finishedAt = DateTime.now();
      _buildService = null;
    }
  }

  Future<String> _runDistributionStep({
    required Directory projectRoot,
    required File? envFile,
    required DistributionTarget target,
    String? androidFlavor,
    String? iosFlavor,
    String? iosScheme,
  }) async {
    final distJob = DistributionJobState();
    final buildService = DistributionBuildService(distJob);
    _buildService = buildService;

    await buildService.run(
      projectRoot: projectRoot,
      target: target,
      envName: 'dev',
      androidFlavor: androidFlavor,
      iosFlavor: iosFlavor,
      iosScheme: iosScheme,
      allowMissingEnv: true,
      envFileOverride: envFile,
      useEnvFileOverride: true,
    );

    jobState.logs.addAll(distJob.logs);
    jobState.artifactPaths.addAll(distJob.artifactPaths);

    if (distJob.status == DistributionJobStatus.failed) {
      throw StateError(distJob.error ?? 'Build step failed');
    }
    if (distJob.artifactPaths.isEmpty) {
      throw StateError('Build step produced no artifacts');
    }
    return distJob.artifactPaths.first;
  }
}

List<Map<String, dynamic>> _quickTestPreflightChecks(
  List<Map<String, dynamic>> checks, {
  required bool envReady,
}) {
  return checks.map((check) {
    final copy = Map<String, dynamic>.from(check);
    if (copy['id'] == 'env' && copy['status'] == 'fail' && !envReady) {
      copy['status'] = 'warn';
      copy['detail'] =
          '${copy['detail'] ?? 'Missing env file'} — optional if app has no dart-defines';
    }
    return copy;
  }).toList();
}
