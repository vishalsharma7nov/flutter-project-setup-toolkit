import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'classify.dart';
import 'config.dart';
import 'git_runner.dart';
import 'models.dart';
import 'prompt.dart';
import 'version_logic.dart';

Future<int> runClassifyVersionBump(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('json', negatable: false)
    ..addFlag('suggest', negatable: false)
    ..addFlag('apply-env', negatable: false)
    ..addOption('project', abbr: 'p', help: 'Flutter project root')
    ..addOption('repo', help: 'Alias for --project')
    ..addOption('config', help: 'Path to release-toolkit.config.json')
    ..addOption('env', help: 'Named environment or both')
    ..addOption('env-file', help: 'Single env file path')
    ..addFlag('dry-run', negatable: false)
    ..addFlag('verbose', abbr: 'v', negatable: false)
    ..addFlag('yes', abbr: 'y', negatable: false);

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  final projectArg = args['project'] as String? ?? args['repo'] as String?;
  final projectRoot = resolveProjectRoot(projectArg);
  final configPath = args['config'] as String?;
  final config = loadConfig(
    projectRoot,
    configPath: configPath == null ? null : File(configPath),
  );

  final commit = args.rest.isNotEmpty ? args.rest.first : 'HEAD';
  final rawArgv = arguments;

  try {
    final git = GitRunner(projectRoot);
    final loaded = await git.loadCommit(commit);
    final classification = classifyCommit(
      loaded.subject,
      loaded.body,
      loaded.changes,
      loaded.diff,
    );
    final shortSha = await git.shortSha(commit);
    var selectedEnv = resolveSelectedEnv(
      config: config,
      env: args['env'] as String?,
      envFile: args['env-file'] as String?,
      applyEnv: args['apply-env'] as bool,
      json: args['json'] as bool,
      rawArgv: rawArgv,
    );

    final shouldCompute =
        args['suggest'] as bool || args['apply-env'] as bool;
    final envResults = <String, EnvTargetResult>{};

    if (shouldCompute) {
      final envFilePath = args['env-file'] as String?;
      if (envFilePath == null &&
          config.environments.isEmpty &&
          selectedEnv == 'custom') {
        throw ArgumentError(
          'No environments configured. Pass --env-file or add environments to release-toolkit.config.json',
        );
      }
      final targets = resolveEnvTargets(
        config,
        selectedEnv,
        envFilePath == null ? null : File(envFilePath),
      );
      for (final target in targets) {
        final bump = buildEnvVersionUpdates(
          classification.level,
          target.value,
          projectRoot,
          config,
        );
        final result = EnvTargetResult(
          label: target.key,
          envFile: target.value.path,
          envUpdates: bump.updates,
        );
        if (bump.current.android != null) {
          result.android = {
            'current': bump.current.android!.pubspec,
            'suggested': bump.suggested.android?.pubspec ?? '',
          };
        }
        if (bump.current.ios != null) {
          result.ios = {
            'current': bump.current.ios!.pubspec,
            'suggested': bump.suggested.ios?.pubspec ?? '',
          };
        }
        if (args['apply-env'] as bool) {
          result.envChanges = applyVersionToEnvFile(
            target.value,
            result.envUpdates,
            config.versionKeyList,
            dryRun: true,
          );
        }
        envResults[target.key] = result;
      }

      if (args['apply-env'] as bool &&
          !(args['dry-run'] as bool) &&
          !(args['json'] as bool) &&
          !shouldSkipConfirm(yes: args['yes'] as bool)) {
        if (!confirmApply(envResults)) {
          print('Version update cancelled.');
          return 0;
        }
      }

      if (args['apply-env'] as bool && !(args['dry-run'] as bool)) {
        for (final target in resolveEnvTargets(
          config,
          selectedEnv,
          envFilePath == null ? null : File(envFilePath),
        )) {
          final result = envResults[target.key]!;
          result.envChanges = applyVersionToEnvFile(
            target.value,
            result.envUpdates,
            config.versionKeyList,
            dryRun: false,
          );
          result.envApplied = true;
        }
      }
    }

    if (args['json'] as bool) {
      final payload = <String, dynamic>{
        'commit': shortSha,
        'bump': classification.level.name,
        'reasons': classification.reasons,
        'project': projectRoot.path,
        'runtime': 'dart',
      };
      if (shouldCompute) {
        payload['env'] =
            args['env-file'] == null ? selectedEnv : 'custom';
        payload['environments'] = {
          for (final entry in envResults.entries)
            entry.key: {
              'env_file': entry.value.envFile,
              'env_updates': entry.value.envUpdates,
              if (entry.value.android != null) 'android': entry.value.android,
              if (entry.value.ios != null) 'ios': entry.value.ios,
              'env_changes': {
                for (final c in entry.value.envChanges.entries)
                  c.key: {'from': c.value.from, 'to': c.value.to},
              },
              'env_applied': entry.value.envApplied,
            },
        };
      }
      print(const JsonEncoder.withIndent('  ').convert(payload));
      return 0;
    }

    print(classification.level.name);
    if (args['verbose'] as bool) {
      print('commit: $shortSha — ${loaded.subject}');
      for (final reason in classification.reasons) {
        print('  - $reason');
      }
    }
    if (shouldCompute) {
      for (final result in envResults.values) {
        if (args['verbose'] as bool) {
          if (result.android != null) {
            print(
              'android: ${result.android!['current']} -> ${result.android!['suggested']}',
            );
          }
          if (result.ios != null) {
            print(
              'ios: ${result.ios!['current']} -> ${result.ios!['suggested']}',
            );
          }
        }
        final mode = result.envApplied ? 'applied' : 'dry-run';
        print('env ($mode): ${result.envFile}');
        for (final entry in result.envChanges.entries) {
          final old = entry.value.from ?? '(missing)';
          print('  ${entry.key}: $old -> ${entry.value.to}');
        }
      }
    }
    return 0;
  } catch (e) {
    stderr.writeln(e);
    return 1;
  }
}
