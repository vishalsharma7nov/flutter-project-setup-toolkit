import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../distribution/distribution_preflight.dart';
import '../env/env_source.dart';
import '../git/git_clone_service.dart';
import '../git/git_remote_source.dart';
import '../ios_xcode.dart';
class ResolvedDistributionProject {
  ResolvedDistributionProject({
    required this.root,
    this.sourceLabel,
  });

  final Directory root;
  final String? sourceLabel;
}

Future<ResolvedDistributionProject> resolveDistributionProject({
  String? projectPath,
  Map<String, dynamic>? source,
  GitCloneService? gitClone,
}) async {
  if (source != null && source['type'] == 'git') {
    final gitSource = GitRemoteSource.fromJson(source);
    final service = gitClone ?? GitCloneService();
    final root = await service.cloneOrUpdate(gitSource);
    return ResolvedDistributionProject(
      root: root,
      sourceLabel: '${gitSource.url}@${gitSource.ref}',
    );
  }
  if (projectPath == null || projectPath.trim().isEmpty) {
    throw ArgumentError('project path or git source is required');
  }
  final root = Directory(p.normalize(projectPath.trim()));
  validateFlutterProject(root);
  return ResolvedDistributionProject(root: root);
}

Future<Map<String, dynamic>> runRepoPreflight({
  required GitRemoteSource source,
  required String envName,
  String? androidFlavor,
  String? iosFlavor,
  String? iosScheme,
  GitCloneService? gitClone,
}) async {
  final service = gitClone ?? GitCloneService();
  await service.verifyAccess(source);
  final root = await service.cloneOrUpdate(source);
  final checks = runDistributionPreflight(
    projectRoot: root,
    envName: envName,
    androidFlavor: androidFlavor,
    iosFlavor: iosFlavor,
    iosScheme: iosScheme,
  );
  final config = loadConfig(root);
  final detection = detectIosBuildSettings(root);
  final resolvedScheme = resolveConfiguredIosScheme(
    projectRoot: root,
    configuredScheme: iosScheme ?? config.build.iosScheme,
  );
  final envMissing =
      checks.any((c) => c['id'] == 'env' && c['status'] == 'fail');
  return {
    'work_dir': root.path,
    'source': source.toJson(),
    'checks': checks,
    'environments': config.environments,
    'default_environment': config.defaultEnvironment,
    'ios_scheme': resolvedScheme,
    'ios_schemes': detection?.appSchemes ?? const [],
    if (detection?.archiveName != null) 'ios_archive_name': detection!.archiveName,
    if (envMissing)
      'env_help': buildEnvHelp(
        projectRoot: root,
        envName: envName,
        envMissing: true,
      ),
  };
}
