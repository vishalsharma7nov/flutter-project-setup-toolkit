import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../env/env_source.dart';
import '../flutter_tools.dart';
import '../ios_xcode.dart';

List<Map<String, dynamic>> runDistributionPreflight({
  required Directory projectRoot,
  required String envName,
  String? androidFlavor,
  String? iosFlavor,
  String? iosScheme,
}) {
  final checks = <Map<String, dynamic>>[];

  void add(String id, String label, String status, {String? detail}) {
    checks.add({
      'id': id,
      'label': label,
      'status': status,
      'detail': detail,
    });
  }

  final pubspec = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (pubspec.existsSync()) {
    add('pubspec', 'Flutter project (pubspec.yaml)', 'pass');
  } else {
    add('pubspec', 'Flutter project (pubspec.yaml)', 'fail', detail: 'Not found');
    return checks;
  }

  final configFile = File(p.join(projectRoot.path, 'release-toolkit.config.json'));
  if (configFile.existsSync()) {
    add('config', 'release-toolkit.config.json', 'pass');
  } else {
    add(
      'config',
      'release-toolkit.config.json',
      'warn',
      detail: 'Run Setup first',
    );
  }

  try {
    final config = loadConfig(projectRoot);
    final envFile = config.resolveEnvPath(envName);
    if (envFile.existsSync()) {
      add('env', 'Env file for $envName', 'pass', detail: envFile.path);
    } else {
      add('env', 'Env file for $envName', 'fail', detail: 'Missing ${envFile.path}');
    }

    final resolvedAndroid = androidFlavor ?? config.build.androidFlavor;
    final resolvedIos = iosFlavor ?? config.build.iosFlavor;
    if (resolvedAndroid != null) {
      add('android_flavor', 'Android flavor', 'info', detail: resolvedAndroid);
    }

    final iosBuild = resolveIosBuild(
      projectRoot: projectRoot,
      configuredFlavor: resolvedIos,
      configuredScheme: resolveConfiguredIosScheme(
        projectRoot: projectRoot,
        configuredScheme: iosScheme ?? config.build.iosScheme,
      ),
    );
    if (iosBuild.error != null) {
      add('ios_scheme', 'iOS Xcode scheme', 'fail', detail: iosBuild.error);
    } else {
      add(
        'ios_scheme',
        'Xcode scheme ${iosBuild.archiveScheme}',
        'pass',
      );
      if (resolvedIos != null) {
        final flavorStatus = iosBuild.flutterFlavor == null &&
                resolvedIos.trim().isNotEmpty
            ? 'warn'
            : 'info';
        add(
          'ios_flavor',
          'iOS flavor',
          flavorStatus,
          detail: iosBuild.flutterFlavor ?? resolvedIos,
        );
      }
      if (iosBuild.warning != null) {
        add('ios_flavor_resolve', 'iOS flavor resolution', 'warn', detail: iosBuild.warning);
      }
    }
  } on Object catch (e) {
    add('config_load', 'Load config', 'fail', detail: '$e');
  }

  try {
    detectFlutter();
    add('flutter', 'Flutter SDK', 'pass');
  } on Object catch (e) {
    add('flutter', 'Flutter SDK', 'fail', detail: '$e');
  }

  if (!Platform.isMacOS) {
    add('macos', 'macOS (for iOS IPA)', 'warn', detail: 'iOS builds require macOS');
  } else {
    add('macos', 'macOS (for iOS IPA)', 'pass');
  }

  return checks;
}

Map<String, dynamic> distributionPreflightJson({
  required Directory projectRoot,
  required String envName,
  String? androidFlavor,
  String? iosFlavor,
  String? iosScheme,
}) {
  final checks = runDistributionPreflight(
    projectRoot: projectRoot,
    envName: envName,
    androidFlavor: androidFlavor,
    iosFlavor: iosFlavor,
    iosScheme: iosScheme,
  );
  final envMissing =
      checks.any((c) => c['id'] == 'env' && c['status'] == 'fail');
  return {
    'checks': checks,
    if (envMissing)
      'env_help': buildEnvHelp(
        projectRoot: projectRoot,
        envName: envName,
        envMissing: true,
      ),
  };
}
