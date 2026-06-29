import 'dart:io';

import 'config.dart';
import 'interactive.dart';
import 'models.dart';

const stateManagementPackageNames = {
  StateManagement.bloc: 'flutter_bloc',
  StateManagement.riverpod: 'flutter_riverpod',
  StateManagement.provider: 'provider',
  StateManagement.getx: 'get',
  StateManagement.none: null,
};

class StateManagementApplyResult {
  StateManagementApplyResult({
    required this.applied,
    required this.skipped,
    this.detail,
    this.error,
  });

  final bool applied;
  final bool skipped;
  final String? detail;
  final String? error;
}

String stateManagementLabel(StateManagement value) {
  return switch (value) {
    StateManagement.none => 'none (no extra packages)',
    StateManagement.bloc => 'bloc (flutter_bloc)',
    StateManagement.riverpod => 'riverpod (flutter_riverpod)',
    StateManagement.provider => 'provider',
    StateManagement.getx => 'getx (get)',
  };
}

List<String> stateManagementChoiceLabels() {
  return StateManagement.values.map(stateManagementLabel).toList();
}

StateManagement stateManagementFromLabel(String label) {
  if (label.startsWith('bloc')) return StateManagement.bloc;
  if (label.startsWith('riverpod')) return StateManagement.riverpod;
  if (label.startsWith('provider')) return StateManagement.provider;
  if (label.startsWith('getx')) return StateManagement.getx;
  return StateManagement.none;
}

StateManagement promptStateManagement({
  StateManagement defaultChoice = StateManagement.none,
}) {
  final labels = stateManagementChoiceLabels();
  final defaultIndex = StateManagement.values.indexOf(defaultChoice);
  return stateManagementFromLabel(
    promptChoiceValue(
      'Which state management does this project use?',
      labels,
      defaultIndex: defaultIndex.clamp(0, labels.length - 1),
    ),
  );
}

StateManagement? resolveStateManagementFromConfig(Directory projectRoot) {
  final configFile = File(
    '${projectRoot.path}/release-toolkit.config.json',
  );
  if (!configFile.existsSync()) {
    return null;
  }
  try {
    final raw = loadConfig(projectRoot);
    return raw.stateManagement;
  } on Object {
    return null;
  }
}

bool hasPubDependency(Directory projectRoot, String packageName) {
  final pubspec = File('${projectRoot.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    return false;
  }
  return RegExp(
    '^\\s*${RegExp.escape(packageName)}\\s*:',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());
}

Future<StateManagementApplyResult> applyStateManagementPackages(
  Directory projectRoot,
  StateManagement stateManagement, {
  bool dryRun = false,
}) async {
  final packageName = stateManagementPackageNames[stateManagement];
  if (packageName == null) {
    return StateManagementApplyResult(
      applied: false,
      skipped: true,
      detail: 'No state management packages to add',
    );
  }

  if (hasPubDependency(projectRoot, packageName)) {
    return StateManagementApplyResult(
      applied: false,
      skipped: true,
      detail: 'pubspec.yaml already lists $packageName',
    );
  }

  final label = 'dart pub add $packageName';
  if (dryRun) {
    return StateManagementApplyResult(
      applied: false,
      skipped: false,
      detail: 'Would run: $label (in ${projectRoot.path})',
    );
  }

  final result = await Process.run(
    'dart',
    ['pub', 'add', packageName],
    workingDirectory: projectRoot.path,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    return StateManagementApplyResult(
      applied: false,
      skipped: false,
      error: message.isEmpty ? 'dart pub add $packageName failed' : message,
    );
  }

  return StateManagementApplyResult(
    applied: true,
    skipped: false,
    detail: 'Added dependency: $packageName',
  );
}
