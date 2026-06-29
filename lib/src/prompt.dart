import 'dart:io';

import 'config.dart';
import 'models.dart';

bool isInteractive() => stdin.hasTerminal && stdout.hasTerminal;

bool envWasExplicit(List<String> rawArgv) {
  return rawArgv.any((arg) => arg == '--env' || arg.startsWith('--env='));
}

bool shouldSkipConfirm({required bool yes}) {
  if (yes) return true;
  for (final key in ['SKIP_CONFIRM', 'CI', 'GITHUB_ACTIONS']) {
    final value = Platform.environment[key]?.toLowerCase();
    if (value == '1' || value == 'true' || value == 'yes') {
      return true;
    }
  }
  return !isInteractive();
}

String promptForEnv(ToolkitConfig config) {
  final options = config.environments.keys.toList()..sort();
  if (options.isEmpty) {
    throw StateError('No environments in release-toolkit.config.json');
  }
  final hint = options.join('/');
  while (true) {
    stdout.write('Update which env file? [$hint/both] (default: ${options.first}): ');
    final reply = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (reply.isEmpty) return options.first;
    if (reply == 'both' || config.environments.containsKey(reply)) {
      return reply;
    }
    print('Please enter one of: $hint, both');
  }
}

bool confirmApply(Map<String, EnvTargetResult> envResults) {
  print('\nThe following version keys will be updated:');
  for (final result in envResults.values) {
    print('  [${result.label}] ${result.envFile}');
    for (final entry in result.envChanges.entries) {
      final old = entry.value.from ?? '(missing)';
      print('    ${entry.key}: $old -> ${entry.value.to}');
    }
  }
  print('');
  while (true) {
    stdout.write('Apply these version changes? [y/N]: ');
    final reply = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (reply == 'y' || reply == 'yes') return true;
    if (reply == 'n' || reply == 'no' || reply.isEmpty) return false;
    print('Please answer y (yes) or n (no).');
  }
}

String resolveSelectedEnv({
  required ToolkitConfig config,
  required String? env,
  required String? envFile,
  required bool applyEnv,
  required bool json,
  required List<String> rawArgv,
}) {
  if (envFile != null) return 'custom';
  if (envWasExplicit(rawArgv)) {
    return env ?? (config.environments.keys.isNotEmpty
        ? (config.environments.keys.toList()..sort()).first
        : 'custom');
  }
  if (applyEnv && !json && isInteractive() && config.environments.isNotEmpty) {
    final selected = promptForEnv(config);
    print('Selected env: $selected');
    return selected;
  }
  if (env != null) return env;
  final detected = config.resolveEnvFromMainDart();
  if (detected != null) return detected;
  if (config.defaultEnvironment != null &&
      config.environments.containsKey(config.defaultEnvironment)) {
    return config.defaultEnvironment!;
  }
  if (config.environments.isNotEmpty) {
    return (config.environments.keys.toList()..sort()).first;
  }
  return 'custom';
}
