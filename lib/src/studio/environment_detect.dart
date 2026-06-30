import 'dart:io';

import 'studio_branding.dart';

import '../ci/ci_act_installer.dart';
import '../ci/ci_features.dart';
import '../devices/device_service.dart';
import '../flutter_tools.dart';

Future<Map<String, dynamic>> detectStudioEnvironment() async {
  final dart = await _detectDart();
  final fvmInstalled = _which('fvm') != null;
  FlutterCommand? flutter;
  String? flutterError;
  try {
    flutter = detectFlutter();
  } on Object catch (e) {
    flutterError = '$e';
  }

  String? flutterVersion;
  if (flutter != null) {
    flutterVersion = await _flutterVersionSafe(flutter);
  }

  final flutterInstalled = flutter != null && flutterVersion != null;
  final macos = Platform.isMacOS;
  final xcode = macos ? await _detectXcode() : {'installed': false};
  final gitInstalled = _which('git') != null;
  final dockerForAct =
      ciActStudioEnabled ? await isDockerAvailableForAct() : false;
  final ghInstalled = _which('gh') != null;
  var ghAuthOk = false;
  if (ghInstalled) {
    final ghStatus = await Process.run('gh', ['auth', 'status']);
    ghAuthOk = ghStatus.exitCode == 0;
  }

  return {
    'dart': dart,
    'flutter': {
      'installed': flutterInstalled,
      'version': flutterVersion,
      'source': flutter == null
          ? null
          : flutter.argsPrefix.isEmpty
              ? 'flutter'
              : 'fvm',
      'hint': flutterInstalled
          ? null
          : flutterError ??
              'Install Flutter from https://docs.flutter.dev/get-started/install '
              'or set FLUTTER_CMD',
    },
    'fvm': {'installed': fvmInstalled},
    'macos': macos,
    'xcode': xcode,
    'capabilities': {
      'setup': dart['installed'] as bool,
      'feature_scaffold': dart['installed'] as bool,
      'version_bump': (dart['installed'] as bool) && _which('git') != null,
      'build_android': flutterInstalled,
      'build_ios': flutterInstalled && macos && (xcode['installed'] as bool),
      'install_android': flutterInstalled && adbAvailable(),
      'install_ios': flutterInstalled && macos && (xcode['installed'] as bool),
      'quick_test': flutterInstalled && _which('git') != null,
      'ci_studio': dart['installed'] as bool && gitInstalled,
      'ci_act': ciActStudioEnabled &&
          dockerForAct &&
          (Platform.isMacOS || Platform.isLinux),
      'ci_publish': ghInstalled && ghAuthOk,
    },
  };
}

Future<Map<String, dynamic>> _detectDart() async {
  final dartPath = _which('dart');
  if (dartPath == null) {
    return {
      'installed': false,
      'version': null,
      'hint': 'Dart SDK is required to run $studioProductName',
    };
  }
  final result = await Process.run('dart', ['--version']);
  final version = result.stdout.toString().split('\n').first.trim();
  return {
    'installed': result.exitCode == 0,
    'version': version.isEmpty ? 'unknown' : version,
  };
}

Future<String?> _flutterVersionSafe(FlutterCommand flutter) async {
  final result = await Process.run(
    flutter.executable,
    flutter.buildArgs(['--version']),
  );
  if (result.exitCode != 0) return null;
  return result.stdout.toString().split('\n').first.trim();
}

Future<Map<String, dynamic>> _detectXcode() async {
  final result = await Process.run('xcodebuild', ['-version']);
  if (result.exitCode != 0) {
    return {'installed': false, 'version': null};
  }
  final firstLine = result.stdout.toString().split('\n').first.trim();
  return {'installed': true, 'version': firstLine};
}

String? _which(String name) {
  final result = Process.runSync('which', [name]);
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}
