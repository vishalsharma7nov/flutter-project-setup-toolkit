import 'dart:io';

import 'package:path/path.dart' as p;

/// Schemes created by Flutter tooling that are not app build targets.
const flutterGeneratedSchemes = {'FlutterGeneratedPluginSwiftPackage'};

class IosXcodeProjectInfo {
  IosXcodeProjectInfo({required this.schemes});

  final List<String> schemes;

  List<String> get appSchemes => schemes
      .where((scheme) => !flutterGeneratedSchemes.contains(scheme))
      .toList();

  bool schemeExists(String name) => matchScheme(name) != null;

  String? matchScheme(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final normalized = name.trim().toLowerCase();
    for (final scheme in schemes) {
      if (scheme.toLowerCase() == normalized) {
        return scheme;
      }
    }
    return null;
  }
}

class IosBuildDetection {
  IosBuildDetection({
    required this.schemes,
    required this.appSchemes,
    required this.suggestedScheme,
    this.archiveName,
  });

  final List<String> schemes;
  final List<String> appSchemes;
  final String suggestedScheme;
  final String? archiveName;

  Map<String, dynamic> toJson() => {
        'schemes': schemes,
        'app_schemes': appSchemes,
        'suggested_scheme': suggestedScheme,
        if (archiveName != null) 'archive_name': archiveName,
      };
}

class IosFlutterFlavorResolution {
  IosFlutterFlavorResolution({
    required this.flutterFlavor,
    required this.archiveScheme,
    this.warning,
    this.error,
  });

  /// Value for Flutter's `--flavor` flag, or null to omit it.
  final String? flutterFlavor;

  /// Scheme name used to locate the `.xcarchive` after the build.
  final String archiveScheme;

  /// Non-fatal note when config did not match the Xcode project.
  final String? warning;

  /// Fatal resolution error; build should not proceed.
  final String? error;
}

IosXcodeProjectInfo? loadIosXcodeProjectInfo(Directory projectRoot) {
  final iosDir = Directory(p.join(projectRoot.path, 'ios'));
  if (!iosDir.existsSync()) return null;

  final schemes = <String>{};
  for (final entity in iosDir.listSync()) {
    if (entity is! Directory || !entity.path.endsWith('.xcodeproj')) continue;
    final schemesDir = Directory(
      p.join(entity.path, 'xcshareddata', 'xcschemes'),
    );
    if (!schemesDir.existsSync()) continue;
    for (final schemeEntry in schemesDir.listSync()) {
      if (schemeEntry is! File || !schemeEntry.path.endsWith('.xcscheme')) {
        continue;
      }
      schemes.add(p.basenameWithoutExtension(schemeEntry.path));
    }
  }

  if (schemes.isEmpty) return null;
  return IosXcodeProjectInfo(schemes: schemes.toList()..sort());
}

File? findIosSchemeFile(Directory projectRoot, String scheme) {
  final iosDir = Directory(p.join(projectRoot.path, 'ios'));
  if (!iosDir.existsSync()) return null;
  for (final entity in iosDir.listSync()) {
    if (entity is! Directory || !entity.path.endsWith('.xcodeproj')) continue;
    final schemeFile = File(
      p.join(entity.path, 'xcshareddata', 'xcschemes', '$scheme.xcscheme'),
    );
    if (schemeFile.existsSync()) return schemeFile;
  }
  return null;
}

String? readIosSchemeArchiveName(Directory projectRoot, String scheme) {
  final schemeFile = findIosSchemeFile(projectRoot, scheme);
  if (schemeFile == null) return null;
  final content = schemeFile.readAsStringSync();
  final match = RegExp(
    r'customArchiveName\s*=\s*"([^"]+)"',
  ).firstMatch(content);
  return match?.group(1);
}

IosBuildDetection? detectIosBuildSettings(Directory projectRoot) {
  final info = loadIosXcodeProjectInfo(projectRoot);
  if (info == null) return null;

  final appSchemes = info.appSchemes;
  if (appSchemes.isEmpty) return null;

  final suggested = appSchemes.length == 1
      ? appSchemes.first
      : (info.matchScheme('Runner') ?? appSchemes.first);
  final archiveName = readIosSchemeArchiveName(projectRoot, suggested);

  return IosBuildDetection(
    schemes: info.schemes,
    appSchemes: appSchemes,
    suggestedScheme: suggested,
    archiveName: archiveName,
  );
}

String resolveConfiguredIosScheme({
  required Directory projectRoot,
  String? configuredScheme,
}) {
  final detection = detectIosBuildSettings(projectRoot);
  if (detection == null) {
    return configuredScheme?.trim().isNotEmpty == true
        ? configuredScheme!.trim()
        : 'Runner';
  }

  final requested = configuredScheme?.trim();
  if (requested != null && requested.isNotEmpty) {
    final info = loadIosXcodeProjectInfo(projectRoot);
    if (info?.matchScheme(requested) != null) {
      return info!.matchScheme(requested)!;
    }
  }

  return detection.suggestedScheme;
}

bool iosSchemeExists(Directory projectRoot, String scheme) {
  final info = loadIosXcodeProjectInfo(projectRoot);
  return info?.schemeExists(scheme) ?? false;
}

IosSchemeResolution resolveIosArchiveScheme({
  required IosXcodeProjectInfo info,
  String configuredScheme = 'Runner',
}) {
  final matched = info.matchScheme(configuredScheme);
  if (matched != null) {
    return IosSchemeResolution(scheme: matched);
  }

  final appSchemes = info.appSchemes;
  if (appSchemes.length == 1) {
    return IosSchemeResolution(
      scheme: appSchemes.first,
      warning:
          "Configured Xcode scheme '$configuredScheme' was not found. "
          "Using '${appSchemes.first}' instead.",
    );
  }

  return IosSchemeResolution(
    scheme: configuredScheme,
    error:
        "Xcode scheme '$configuredScheme' not found. "
        'Available schemes: ${info.schemes.join(', ')}',
  );
}

class IosSchemeResolution {
  IosSchemeResolution({
    required this.scheme,
    this.warning,
    this.error,
  });

  final String scheme;
  final String? warning;
  final String? error;
}

IosFlutterFlavorResolution resolveIosFlutterFlavor({
  required IosXcodeProjectInfo info,
  String? configuredFlavor,
  required String archiveScheme,
}) {
  final flavorMatch = info.matchScheme(configuredFlavor);
  if (configuredFlavor != null &&
      configuredFlavor.trim().isNotEmpty &&
      flavorMatch != null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: flavorMatch,
      archiveScheme: archiveScheme,
    );
  }

  String? warning;
  if (configuredFlavor != null && configuredFlavor.trim().isNotEmpty) {
    warning =
        "Configured iOS flavor '$configuredFlavor' does not match any Xcode "
        'scheme (${info.schemes.join(', ')}). '
        'On iOS, --flavor must match an Xcode scheme name — not the app name '
        'or Android product flavor. Ignoring ios_flavor for this build.';
  }

  final appSchemes = info.appSchemes;
  final runner = info.matchScheme('Runner');

  if (runner != null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: null,
      archiveScheme: archiveScheme,
      warning: warning,
    );
  }

  if (appSchemes.length == 1) {
    final only = appSchemes.first;
    return IosFlutterFlavorResolution(
      flutterFlavor: only,
      archiveScheme: archiveScheme,
      warning: warning,
    );
  }

  final archiveMatch = info.matchScheme(archiveScheme);
  if (archiveMatch != null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: archiveMatch,
      archiveScheme: archiveScheme,
      warning: warning,
    );
  }

  return IosFlutterFlavorResolution(
    flutterFlavor: null,
    archiveScheme: archiveScheme,
    warning: warning,
    error:
        'Could not resolve an iOS build scheme. '
        'Available schemes: ${info.schemes.join(', ')}. '
        'Set build.ios_scheme in release-toolkit.config.json to an existing '
        'Xcode scheme, or set build.ios_flavor to match a scheme name.',
  );
}

IosFlutterFlavorResolution resolveIosBuild({
  required Directory projectRoot,
  String? configuredFlavor,
  String configuredScheme = 'Runner',
}) {
  final info = loadIosXcodeProjectInfo(projectRoot);
  if (info == null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: configuredFlavor,
      archiveScheme: configuredScheme,
      error: 'No Xcode project found under ios/',
    );
  }

  final schemeResolution = resolveIosArchiveScheme(
    info: info,
    configuredScheme: configuredScheme,
  );
  if (schemeResolution.error != null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: configuredFlavor,
      archiveScheme: configuredScheme,
      error: schemeResolution.error,
    );
  }

  final flavorResolution = resolveIosFlutterFlavor(
    info: info,
    configuredFlavor: configuredFlavor,
    archiveScheme: schemeResolution.scheme,
  );

  if (schemeResolution.warning != null &&
      flavorResolution.warning == null &&
      flavorResolution.error == null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: flavorResolution.flutterFlavor,
      archiveScheme: flavorResolution.archiveScheme,
      warning: schemeResolution.warning,
    );
  }

  if (schemeResolution.warning != null && flavorResolution.warning != null) {
    return IosFlutterFlavorResolution(
      flutterFlavor: flavorResolution.flutterFlavor,
      archiveScheme: flavorResolution.archiveScheme,
      warning: '${schemeResolution.warning}\n${flavorResolution.warning}',
    );
  }

  return flavorResolution;
}

List<String> iosArchiveCandidateNames({
  required String archiveScheme,
  String? flutterFlavor,
  String? customArchiveName,
}) {
  return [
    if (flutterFlavor != null) '$flutterFlavor.xcarchive',
    if (customArchiveName != null) '$customArchiveName.xcarchive',
    '$archiveScheme.xcarchive',
    'Runner.xcarchive',
  ];
}
