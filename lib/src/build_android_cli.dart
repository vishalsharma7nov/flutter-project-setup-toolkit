import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'flutter_tools.dart';

Future<int> runBuildAndroid(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p')
    ..addOption('env')
    ..addOption('env-file')
    ..addFlag('aab', negatable: false)
    ..addOption('flavor');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  final projectRoot = resolveProjectRoot(args['project'] as String?);
  final config = loadConfig(projectRoot);
  final envFile = resolveEnvFile(
    config: config,
    envName: args['env'] as String?,
    envFileArg: args['env-file'] as String? ?? Platform.environment['ENV_FILE'],
  );
  if (envFile == null || !envFile.existsSync()) {
    stderr.writeln('Could not resolve env file. Use --env-file or --env with config.');
    return 1;
  }

  final buildAab = args['aab'] as bool ||
      Platform.environment['BUILD_FORMAT'] == 'aab';
  final flavor = args['flavor'] as String? ??
      Platform.environment['ANDROID_FLAVOR'] ??
      config.build.androidFlavor;

  final flutter = detectFlutter();
  final version = await flutterVersion(flutter);
  final target = buildAab ? 'appbundle' : 'apk';

  print('');
  print('========== Flutter Android release build ==========');
  print('Project root:     ${projectRoot.path}');
  print('Flutter:          ${flutter.executable} ${flutter.argsPrefix.join(' ')}');
  print('Flutter version:  $version');
  print('Build format:     ${buildAab ? 'aab' : 'apk'}');
  print('Env file:         ${envFile.path}');
  if (flavor != null) print('Android flavor:   $flavor');
  print('');
  printEnvSummary(envFile);
  print('');
  print('Build command:');
  print('  ${flutter.executable} ${flutter.buildArgs([
        'build',
        target,
        '--release',
        if (flavor != null) ...['--flavor', flavor],
        '--dart-define-from-file=${envFile.path}',
        if (Platform.environment['APP_ENV'] != null)
          '--dart-define=APP_ENV=${Platform.environment['APP_ENV']}',
      ]).join(' ')}');
  print('============================================================');
  print('');

  if (!await confirmBuild('Continue with this build?')) {
    return 0;
  }

  final buildArgs = <String>[
    'build',
    target,
    '--release',
    if (flavor != null) ...['--flavor', flavor],
    '--dart-define-from-file=${envFile.path}',
  ];
  final appEnv = Platform.environment['APP_ENV'];
  if (appEnv != null) {
    buildArgs.add('--dart-define=APP_ENV=$appEnv');
  }

  await runFlutterBuild(projectRoot, flutter, buildArgs);

  final artifact = _findAndroidArtifact(projectRoot, buildAab);
  if (artifact == null) {
    stderr.writeln('Artifact not found under build/app/outputs');
    return 1;
  }
  print('Artifact: ${artifact.path}');
  return 0;
}

File? _findAndroidArtifact(Directory projectRoot, bool aab) {
  final dirs = aab
      ? [p.join('build', 'app', 'outputs', 'bundle', 'release')]
      : [
          p.join('build', 'app', 'outputs', 'flutter-apk'),
          p.join('build', 'app', 'outputs', 'apk', 'release'),
        ];
  final glob = aab ? '.aab' : '.apk';
  for (final dir in dirs) {
    final directory = Directory(p.join(projectRoot.path, dir));
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      if (entity is File && entity.path.endsWith(glob)) {
        return entity;
      }
    }
  }
  return null;
}
