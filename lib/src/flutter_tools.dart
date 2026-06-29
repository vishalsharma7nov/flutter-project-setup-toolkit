import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'prompt.dart';

class FlutterCommand {
  FlutterCommand(this.executable, this.argsPrefix);
  final String executable;
  final List<String> argsPrefix;

  List<String> buildArgs(List<String> tail) => [...argsPrefix, ...tail];
}

FlutterCommand detectFlutter() {
  final override = Platform.environment['FLUTTER_CMD'];
  if (override != null && override.trim().isNotEmpty) {
    return FlutterCommand(override.split(' ').first, override.split(' ').skip(1).toList());
  }
  final fvm = _which('fvm');
  if (fvm != null) {
    return FlutterCommand(fvm, const ['flutter']);
  }
  final flutter = _which('flutter');
  if (flutter != null) {
    return FlutterCommand(flutter, const []);
  }
  throw StateError('Flutter not found on PATH. Install Flutter or set FLUTTER_CMD.');
}

String? _which(String name) {
  final result = Process.runSync('which', [name]);
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}

Future<String> flutterVersion(FlutterCommand flutter) async {
  final result = await Process.run(
    flutter.executable,
    flutter.buildArgs(['--version']),
  );
  if (result.exitCode != 0) return 'unknown';
  return result.stdout.toString().split('\n').first.trim();
}

File? resolveEnvFile({
  required ToolkitConfig config,
  String? envName,
  String? envFileArg,
}) {
  if (envFileArg != null) {
    return p.isAbsolute(envFileArg)
        ? File(envFileArg)
        : File(p.join(config.projectRoot.path, envFileArg));
  }
  if (envName != null && envName.isNotEmpty) {
    return config.resolveEnvPath(envName);
  }
  final fromMain = config.resolveEnvFromMainDart();
  if (fromMain != null) {
    return config.resolveEnvPath(fromMain);
  }
  if (config.defaultEnvironment != null &&
      config.environments.containsKey(config.defaultEnvironment)) {
    return config.resolveEnvPath(config.defaultEnvironment!);
  }
  return null;
}

void printEnvSummary(File envFile) {
  print('Dart defines from ${envFile.path}:');
  for (final line in envFile.readAsLinesSync()) {
    var trimmed = line.split('#').first.trim();
    if (trimmed.isEmpty || !trimmed.contains('=')) continue;
    final key = trimmed.substring(0, trimmed.indexOf('=')).trim();
    var value = trimmed.substring(trimmed.indexOf('=') + 1).trim();
    if (RegExp(r'KEY|SECRET|TOKEN|PASSWORD').hasMatch(key)) {
      value = '***';
    }
    print('  ${key.padRight(28)} $value');
  }
}

Future<bool> confirmBuild(String prompt) async {
  if (shouldSkipConfirm(yes: false)) {
    if (Platform.environment['SKIP_CONFIRM'] == 'true') {
      print('SKIP_CONFIRM=true — continuing without prompt.');
    }
    return true;
  }
  while (true) {
    stdout.write('$prompt [y/N]: ');
    final reply = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (reply == 'y' || reply == 'yes') {
      print('Starting build...');
      return true;
    }
    if (reply == 'n' || reply == 'no' || reply.isEmpty) {
      print('Build cancelled.');
      return false;
    }
    print('Please answer y (yes) or n (no).');
  }
}

Future<void> runFlutterBuild(
  Directory projectRoot,
  FlutterCommand flutter,
  List<String> buildArgs,
) async {
  final result = await Process.run(
    flutter.executable,
    flutter.buildArgs(buildArgs),
    workingDirectory: projectRoot.path,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
