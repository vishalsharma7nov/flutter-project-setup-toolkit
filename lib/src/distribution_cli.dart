import 'dart:io';

import 'package:args/args.dart';

import 'distribution/distribution_build_service.dart';
import 'distribution/distribution_models.dart';
import 'distribution/distribution_project_resolver.dart';
import 'env/env_source.dart';
import 'flutter_tools.dart';
import 'git/git_auth.dart';
import 'git/git_remote_source.dart';
import 'toolkit_studio_cli.dart' show runToolkitStudio;

Future<int> runBuildDistribution(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', help: 'Local Flutter project path')
    ..addOption('env', help: 'Environment name', defaultsTo: 'dev')
    ..addOption(
      'target',
      help: 'android_apk | ios_test_flight | both',
      defaultsTo: 'android_apk',
    )
    ..addOption('android-flavor', help: 'Android flavor override')
    ..addOption('ios-flavor', help: 'iOS flavor override')
    ..addOption('git-url', help: 'Git repository URL (remote build)')
    ..addOption('ref', help: 'Git branch, tag, or commit', defaultsTo: 'main')
    ..addOption('subdir', help: 'Subdirectory inside repo (monorepo)')
    ..addOption(
      'auth',
      help: 'ssh | https | https_token',
      defaultsTo: 'ssh',
    )
    ..addOption('token', help: 'HTTPS token (session only; not logged)')
    ..addOption(
      'env-source-file',
      help: 'Local env file when project env is missing',
    )
    ..addFlag('studio', help: 'Open Distribution Studio in browser', negatable: false);

  late final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    return 64;
  }

  if (args['studio'] as bool) {
    return runToolkitStudio(['--view', 'build']);
  }

  final env = args['env'] as String;
  final targetName = args['target'] as String;
  final target = _parseTarget(targetName);
  if (target == null) {
    stderr.writeln('Invalid target: $targetName');
    return 64;
  }

  if ((target == DistributionTarget.iosTestFlight ||
          target == DistributionTarget.both) &&
      !Platform.isMacOS) {
    stderr.writeln('iOS TestFlight builds require macOS with Xcode.');
    return 1;
  }

  try {
    detectFlutter();
  } on Object catch (e) {
    stderr.writeln('$e');
    return 1;
  }

  final gitUrl = args['git-url'] as String?;
  final projectPath = args['project'] as String?;
  Map<String, dynamic>? source;
  if (gitUrl != null && gitUrl.trim().isNotEmpty) {
    source = GitRemoteSource(
      url: gitUrl.trim(),
      ref: (args['ref'] as String?) ?? 'main',
      subdir: (args['subdir'] as String?) ?? '',
      auth: GitAuthMode.parse(args['auth'] as String?) ?? GitAuthMode.ssh,
      token: args['token'] as String?,
    ).toJson(includeSecrets: true);
  }

  if (projectPath == null && source == null) {
    stderr.writeln('Provide --project or --git-url');
    stderr.writeln(parser.usage);
    return 64;
  }

  EnvSourceRequest? envSource;
  final envFile = args['env-source-file'] as String?;
  if (envFile != null && envFile.trim().isNotEmpty) {
    envSource = EnvSourceRequest.fromJson({
      'mode': 'local_file',
      'path': envFile.trim(),
    });
  }

  final jobState = DistributionJobState();
  final buildService = DistributionBuildService(jobState);

  try {
    final resolved = await resolveDistributionProject(
      projectPath: projectPath,
      source: source,
    );
    if (resolved.sourceLabel != null) {
      stdout.writeln('Remote source: ${resolved.sourceLabel}');
    }
    stdout.writeln('Project: ${resolved.root.path}');
    stdout.writeln('Target: $targetName');
    stdout.writeln('Environment: $env');
    stdout.writeln('');

    await buildService.run(
      projectRoot: resolved.root,
      target: target,
      envName: env,
      androidFlavor: args['android-flavor'] as String?,
      iosFlavor: args['ios-flavor'] as String?,
      envSource: envSource,
    );
  } on Object catch (e) {
    stderr.writeln('Build failed: $e');
    return 1;
  }

  if (jobState.status == DistributionJobStatus.failed) {
    return 1;
  }
  return 0;
}

DistributionTarget? _parseTarget(String name) {
  for (final target in DistributionTarget.values) {
    if (target.name == name) return target;
  }
  return null;
}
