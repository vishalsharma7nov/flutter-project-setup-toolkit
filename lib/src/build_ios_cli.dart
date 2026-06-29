import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'flutter_tools.dart';
import 'ios_xcode.dart';

Future<int> runBuildIosIpa(List<String> arguments) async {
  if (!Platform.isMacOS) {
    stderr.writeln('iOS IPA builds require macOS with Xcode.');
    return 1;
  }

  final parser = ArgParser()
    ..addOption('project', abbr: 'p')
    ..addOption('env')
    ..addOption('env-file')
    ..addOption('scheme')
    ..addOption('flavor')
    ..addFlag('no-organizer', negatable: false);

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

  final scheme = args['scheme'] as String? ??
      Platform.environment['IOS_SCHEME'] ??
      resolveConfiguredIosScheme(
        projectRoot: projectRoot,
        configuredScheme: config.build.iosScheme,
      );
  final flavor = args['flavor'] as String? ??
      Platform.environment['IOS_FLAVOR'] ??
      config.build.iosFlavor;
  final openOrganizer = !(args['no-organizer'] as bool) &&
      Platform.environment['OPEN_ORGANIZER'] != 'false' &&
      config.build.openOrganizer;

  final iosBuild = resolveIosBuild(
    projectRoot: projectRoot,
    configuredFlavor: flavor,
    configuredScheme: scheme,
  );
  if (iosBuild.error != null) {
    stderr.writeln(iosBuild.error);
    return 1;
  }
  if (iosBuild.warning != null) {
    for (final line in iosBuild.warning!.split('\n')) {
      stderr.writeln('Note: $line');
    }
  }

  final flutter = detectFlutter();
  final version = await flutterVersion(flutter);

  print('');
  print('========== Flutter iOS IPA release build ==========');
  print('Project root:     ${projectRoot.path}');
  print('Flutter:          ${flutter.executable} ${flutter.argsPrefix.join(' ')}');
  print('Flutter version:  $version');
  print('Xcode scheme:     ${iosBuild.archiveScheme}');
  if (iosBuild.flutterFlavor != null) {
    print('iOS flavor:       ${iosBuild.flutterFlavor}');
  } else if (flavor != null) {
    print('iOS flavor:       (none — default scheme ${iosBuild.archiveScheme})');
  }
  print('Env file:         ${envFile.path}');
  print('Open Organizer:   $openOrganizer');
  print('');
  printEnvSummary(envFile);
  print('============================================================');
  print('');

  if (!await confirmBuild('Continue with this build?')) {
    return 0;
  }

  final buildArgs = <String>[
    'build',
    'ipa',
    '--release',
    if (iosBuild.flutterFlavor != null) ...['--flavor', iosBuild.flutterFlavor!],
    '--dart-define-from-file=${envFile.path}',
  ];
  final appEnv = Platform.environment['APP_ENV'];
  if (appEnv != null) {
    buildArgs.add('--dart-define=APP_ENV=$appEnv');
  }

  await runFlutterBuild(projectRoot, flutter, buildArgs);

  final archive = _findArchive(
    projectRoot,
    iosBuild.archiveScheme,
    iosBuild.flutterFlavor,
    archiveName: readIosSchemeArchiveName(projectRoot, iosBuild.archiveScheme),
  );
  if (archive == null) {
    stderr.writeln('Archive not found under build/ios/archive');
    return 1;
  }
  print('Archive: ${archive.path}');

  final ipaDir = Directory(p.join(projectRoot.path, 'build', 'ios', 'ipa'));
  if (ipaDir.existsSync()) {
    for (final entity in ipaDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.ipa')) {
        print('IPA: ${entity.path}');
      }
    }
  }

  if (openOrganizer) {
    await Process.run('open', [archive.path]);
  }
  return 0;
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
