import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'models.dart';

(List<int>, int) parseVersionName(String name) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(name.trim());
  if (match == null) {
    throw ArgumentError("Invalid version name '$name'. Expected MAJOR.MINOR.PATCH");
  }
  return (
    [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ],
    0,
  );
}

Map<String, String> readEnvKeyValues(File envPath) {
  if (!envPath.existsSync()) return {};
  final values = <String, String>{};
  for (final line in envPath.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || !trimmed.contains('=')) {
      continue;
    }
    final parts = trimmed.split('=');
    values[parts.first.trim()] = parts.sublist(1).join('=').trim();
  }
  return values;
}

PlatformVersions readPlatformVersions(File envPath, ToolkitConfig config) {
  final values = readEnvKeyValues(envPath);
  VersionSnapshot? android;
  VersionSnapshot? ios;
  final androidName = values[config.androidNameKey];
  final androidCode = values[config.androidCodeKey];
  if (androidName != null && androidCode != null) {
    final parts = parseVersionName(androidName).$1;
    android = VersionSnapshot(parts[0], parts[1], parts[2], int.parse(androidCode));
  }
  final iosName = values[config.iosMarketingKey];
  final iosBuild = values[config.iosBuildKey];
  if (iosName != null && iosBuild != null) {
    final parts = parseVersionName(iosName).$1;
    ios = VersionSnapshot(parts[0], parts[1], parts[2], int.parse(iosBuild));
  }
  return PlatformVersions(android: android, ios: ios);
}

VersionSnapshot parsePubspecVersion(Directory repo) {
  final pubspec = File(p.join(repo.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StateError('pubspec.yaml not found');
  }
  final match = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$', multiLine: true)
      .firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    throw ArgumentError('pubspec.yaml version must be MAJOR.MINOR.PATCH+BUILD');
  }
  return VersionSnapshot(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
  );
}

(String, int) suggestNextVersion(VersionSnapshot current, BumpLevel level) {
  final build = current.build + 1;
  return switch (level) {
    BumpLevel.major => ('${current.major + 1}.0.0', build),
    BumpLevel.minor => ('${current.major}.${current.minor + 1}.0', build),
    BumpLevel.patch =>
      ('${current.major}.${current.minor}.${current.patch + 1}', build),
  };
}

(String, int) iosVersionValuesForBump(VersionSnapshot current, BumpLevel level) {
  final next = suggestNextVersion(current, level);
  final build = next.$1 == current.name ? current.build + 1 : 1;
  return (next.$1, build);
}

VersionSnapshot _snapshotFromName(String name, int build) {
  final parts = parseVersionName(name).$1;
  return VersionSnapshot(parts[0], parts[1], parts[2], build);
}

({
  Map<String, String> updates,
  PlatformVersions current,
  PlatformVersions suggested,
}) buildEnvVersionUpdates(
  BumpLevel level,
  File envPath,
  Directory repo,
  ToolkitConfig config,
) {
  var current = readPlatformVersions(envPath, config);
  final updates = <String, String>{};
  var androidCurrent = current.android ?? parsePubspecVersion(repo);
  if (current.android == null) {
    current = PlatformVersions(android: androidCurrent, ios: current.ios);
  }
  final androidNext = suggestNextVersion(androidCurrent, level);
  final suggestedAndroid = _snapshotFromName(androidNext.$1, androidNext.$2);
  updates[config.androidNameKey] = androidNext.$1;
  updates[config.androidCodeKey] = '${androidNext.$2}';

  VersionSnapshot? suggestedIos;
  if (current.ios != null) {
    final iosNext = iosVersionValuesForBump(current.ios!, level);
    suggestedIos = _snapshotFromName(iosNext.$1, iosNext.$2);
    updates[config.iosMarketingKey] = iosNext.$1;
    updates[config.iosBuildKey] = '${iosNext.$2}';
  }

  return (
    updates: updates,
    current: current,
    suggested: PlatformVersions(android: suggestedAndroid, ios: suggestedIos),
  );
}

Map<String, EnvKeyChange> applyVersionToEnvFile(
  File envPath,
  Map<String, String> newValues,
  List<String> versionKeys, {
  required bool dryRun,
}) {
  if (!envPath.existsSync()) {
    throw StateError('Env file not found: ${envPath.path}');
  }
  if (newValues.isEmpty) {
    throw ArgumentError('No version keys to update');
  }

  final lines = envPath.readAsLinesSync();
  final updated = <String>[];
  final seen = <String>{};
  final changes = <String, EnvKeyChange>{};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty &&
        !trimmed.startsWith('#') &&
        trimmed.contains('=')) {
      final key = trimmed.substring(0, trimmed.indexOf('=')).trim();
      if (newValues.containsKey(key)) {
        final oldValue = trimmed.substring(trimmed.indexOf('=') + 1).trim();
        final newValue = newValues[key]!;
        changes[key] = EnvKeyChange(oldValue, newValue);
        updated.add('$key=$newValue');
        seen.add(key);
        continue;
      }
    }
    updated.add(line);
  }

  final missing =
      versionKeys.where((k) => !seen.contains(k) && newValues.containsKey(k));
  if (missing.isNotEmpty) {
    var insertAt = 0;
    for (var i = 0; i < updated.length; i++) {
      if (updated[i].trim().startsWith('APP_ENV=')) {
        insertAt = i + 1;
      }
    }
    var offset = 0;
    for (final key in missing) {
      final newValue = newValues[key]!;
      changes[key] = EnvKeyChange(null, newValue);
      updated.insert(insertAt + offset, '$key=$newValue');
      offset++;
    }
  }

  if (!dryRun) {
    envPath.writeAsStringSync('${updated.join('\n')}\n');
  }
  return changes;
}
