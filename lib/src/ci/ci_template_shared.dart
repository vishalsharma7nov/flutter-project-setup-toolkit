import '../config.dart';
import 'ci_workflow_spec.dart';

String sharedFlutterVersionLine(CiWorkflowSpec spec) {
  if (spec.flutterVersion != null && spec.flutterVersion!.isNotEmpty) {
    return spec.flutterVersion!;
  }
  return 'stable';
}

List<String> sharedAnalyzeCommands(CiWorkflowSpec spec) {
  final cmds = <String>['flutter pub get'];
  if (spec.analyze) {
    cmds.addAll(['dart analyze --fatal-infos', 'dart test']);
  }
  if (spec.coverage) {
    cmds.add('flutter test --coverage');
  }
  if (spec.formatCheck) {
    cmds.add('dart format --set-exit-if-changed .');
  }
  if (spec.architectureAudit) {
    cmds.add(
      'dart run ${spec.toolkitPackage}:architecture_audit --project . --json',
    );
  }
  return cmds;
}

String sharedAndroidBuildCommand(CiWorkflowSpec spec, ToolkitConfig config) {
  if (spec.useToolkitScripts) {
    return './scripts/build-android.sh';
  }
  final flavor = config.build.androidFlavor;
  final flavorArg =
      flavor != null && flavor.isNotEmpty ? ' --flavor $flavor' : '';
  return 'flutter build appbundle --release '
      '--dart-define-from-file=\$ENV_FILE_PATH '
      '--dart-define=APP_ENV=${spec.defaultEnv}$flavorArg';
}

String sharedIosBuildCommand(CiWorkflowSpec spec, ToolkitConfig config) {
  if (spec.useToolkitScripts) {
    return './scripts/build-ios-ipa.sh';
  }
  final scheme = config.build.iosScheme;
  final schemeArg = scheme != 'Runner' ? ' --scheme $scheme' : '';
  return 'flutter build ipa --release '
      '--export-options-plist=ios/ExportOptions.plist '
      '--dart-define-from-file=\$ENV_FILE_PATH '
      '--dart-define=APP_ENV=${spec.defaultEnv}$schemeArg';
}

String yamlScriptBlock(List<String> commands, {String indent = '    '}) {
  return commands.map((c) => '$indent- $c').join('\n');
}
