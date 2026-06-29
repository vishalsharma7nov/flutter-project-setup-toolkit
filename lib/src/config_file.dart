import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';

File releaseToolkitConfigFile(Directory projectRoot) =>
    File(p.join(projectRoot.path, 'release-toolkit.config.json'));

bool releaseToolkitConfigExists(Directory projectRoot) =>
    releaseToolkitConfigFile(projectRoot).existsSync();

Map<String, dynamic> readReleaseToolkitConfigRaw(Directory projectRoot) {
  final file = releaseToolkitConfigFile(projectRoot);
  if (!file.existsSync()) {
    return {};
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('release-toolkit.config.json must be a JSON object');
  }
  return decoded;
}

void writeReleaseToolkitConfigRaw(
  Directory projectRoot,
  Map<String, dynamic> raw,
) {
  validateFlutterProject(projectRoot);
  final file = releaseToolkitConfigFile(projectRoot);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(raw)}\n');
}

Map<String, dynamic> releaseToolkitConfigForApi(Directory projectRoot) {
  final file = releaseToolkitConfigFile(projectRoot);
  final exists = file.existsSync();
  final raw = exists ? readReleaseToolkitConfigRaw(projectRoot) : <String, dynamic>{};
  final config = loadConfig(projectRoot);
  return {
    'config_path': file.path,
    'config_exists': exists,
    'config': raw,
    'default_environment': config.defaultEnvironment,
    'environments': config.environments,
    'build': {
      'android_flavor': config.build.androidFlavor,
      'ios_flavor': config.build.iosFlavor,
      'ios_scheme': config.build.iosScheme,
      'open_organizer': config.build.openOrganizer,
    },
  };
}

Map<String, dynamic> applyReleaseToolkitConfigPatch(
  Map<String, dynamic> raw,
  Map<String, dynamic> patch,
) {
  final merged = Map<String, dynamic>.from(raw);

  if (patch.containsKey('default_environment')) {
    merged['default_environment'] = patch['default_environment'];
  }

  if (patch['environments'] is Map) {
    merged['environments'] = Map<String, String>.from(
      (patch['environments'] as Map).cast<String, String>(),
    );
  }

  if (patch['build'] is Map) {
    final buildPatch = Map<String, dynamic>.from(patch['build'] as Map);
    final build = Map<String, dynamic>.from(merged['build'] as Map? ?? {});
    for (final entry in buildPatch.entries) {
      if (entry.value == null) {
        build.remove(entry.key);
      } else {
        build[entry.key] = entry.value;
      }
    }
    merged['build'] = build;
  }

  if (patch.containsKey('state_management')) {
    merged['state_management'] = patch['state_management'];
  }
  if (patch['architecture'] is Map) {
    merged['architecture'] = patch['architecture'];
  }
  if (patch['api'] is Map) {
    merged['api'] = patch['api'];
  }

  return merged;
}

Map<String, dynamic> saveReleaseToolkitConfigPatch({
  required Directory projectRoot,
  required Map<String, dynamic> patch,
}) {
  validateFlutterProject(projectRoot);
  var raw = readReleaseToolkitConfigRaw(projectRoot);
  if (raw.isEmpty) {
    raw = {
      'default_environment': patch['default_environment'] ?? 'dev',
      'environments': patch['environments'] ??
          {
            'dev': '.env/dev.env',
            'prod': '.env/prod.env',
          },
      'build': {
        'ios_scheme': 'Runner',
        'open_organizer': true,
      },
    };
  }
  final merged = applyReleaseToolkitConfigPatch(raw, patch);
  writeReleaseToolkitConfigRaw(projectRoot, merged);
  return {
    'saved': true,
    'config_path': releaseToolkitConfigFile(projectRoot).path,
    ...releaseToolkitConfigForApi(projectRoot),
  };
}

Map<String, dynamic> buildOptionsPatch({
  String? androidFlavor,
  String? iosFlavor,
  String? iosScheme,
  bool? openOrganizer,
}) {
  final build = <String, dynamic>{};
  if (androidFlavor != null) {
    build['android_flavor'] =
        androidFlavor.trim().isEmpty ? null : androidFlavor.trim();
  }
  if (iosFlavor != null) {
    build['ios_flavor'] = iosFlavor.trim().isEmpty ? null : iosFlavor.trim();
  }
  if (iosScheme != null) {
    build['ios_scheme'] = iosScheme.trim().isEmpty ? 'Runner' : iosScheme.trim();
  }
  if (openOrganizer != null) {
    build['open_organizer'] = openOrganizer;
  }
  return build;
}

Map<String, dynamic> distributionConfigPatchFromUi({
  required Map<String, String> environments,
  String? defaultEnvironment,
  String? envPathForSelected,
  String? selectedEnv,
  String? androidFlavor,
  String? iosFlavor,
  String? iosScheme,
  bool? openOrganizer,
}) {
  final envs = Map<String, String>.from(environments);
  if (selectedEnv != null &&
      envPathForSelected != null &&
      selectedEnv.trim().isNotEmpty) {
    envs[selectedEnv.trim()] = envPathForSelected.trim();
  }

  return {
    'environments': envs,
    if (defaultEnvironment != null && defaultEnvironment.trim().isNotEmpty)
      'default_environment': defaultEnvironment.trim(),
    'build': buildOptionsPatch(
      androidFlavor: androidFlavor,
      iosFlavor: iosFlavor,
      iosScheme: iosScheme,
      openOrganizer: openOrganizer,
    ),
  };
}
