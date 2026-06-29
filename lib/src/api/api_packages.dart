import 'dart:io';

import '../state_management.dart';
import 'api_config.dart';
import 'api_protocol.dart';

class ApiPackagesApplyResult {
  ApiPackagesApplyResult({
    required this.applied,
    required this.skipped,
    this.details = const [],
    this.error,
  });

  final bool applied;
  final bool skipped;
  final List<String> details;
  final String? error;
}

Future<ApiPackagesApplyResult> applyApiPackages(
  Directory projectRoot,
  ApiConfig config, {
  bool dryRun = false,
}) async {
  if (config.usesExternalSdk) {
    final sdk = config.externalSdk;
    if (sdk != null && sdk.isConfigured) {
      return applyExternalSdkDependency(projectRoot, sdk, dryRun: dryRun);
    }
    return ApiPackagesApplyResult(
      applied: false,
      skipped: true,
      details: ['External SDK selected but not configured'],
    );
  }

  final packages = _packagesForConfig(config);
  if (packages.isEmpty) {
    return ApiPackagesApplyResult(
      applied: false,
      skipped: true,
      details: ['No API packages to add'],
    );
  }

  final details = <String>[];
  for (final package in packages) {
    if (hasPubDependency(projectRoot, package)) {
      details.add('Already in pubspec: $package');
      continue;
    }
    final label = 'dart pub add $package';
    if (dryRun) {
      details.add('Would run: $label');
      continue;
    }
    final result = await Process.run(
      'dart',
      ['pub', 'add', package],
      workingDirectory: projectRoot.path,
    );
    if (result.exitCode != 0) {
      final message = '${result.stderr}'.trim();
      return ApiPackagesApplyResult(
        applied: false,
        skipped: false,
        details: details,
        error: message.isEmpty ? '$label failed' : message,
      );
    }
    details.add('Added dependency: $package');
  }

  return ApiPackagesApplyResult(
    applied: details.any((d) => d.startsWith('Added ')),
    skipped: details.isNotEmpty && details.every((d) => d.startsWith('Already')),
    details: details,
  );
}

List<String> _packagesForConfig(ApiConfig config) {
  final packages = <String>[];
  void add(String name) {
    if (!packages.contains(name)) packages.add(name);
  }

  final protocol = config.protocol;
  if (protocol == ApiProtocol.rest || protocol == ApiProtocol.mixed) {
    if (config.restClient == RestClientStyle.dio) {
      add('dio');
      add('connectivity_plus');
    } else {
      add('http');
    }
    if (config.useRetrofit) add('retrofit');
  }
  if (protocol == ApiProtocol.grpc || protocol == ApiProtocol.mixed) {
    add('grpc');
    add('protobuf');
  }
  if (protocol == ApiProtocol.graphql) {
    add('graphql_flutter');
  }
  if (protocol == ApiProtocol.websocket ||
      config.realtime == RealtimeStyle.websocket) {
    add('web_socket_channel');
  }
  if (protocol == ApiProtocol.firebase) {
    add('firebase_core');
  }
  if (protocol == ApiProtocol.supabase) {
    add('supabase_flutter');
  }

  switch (config.localCache) {
    case LocalCacheStyle.hive:
      add('hive');
      add('hive_flutter');
    case LocalCacheStyle.drift:
      add('drift');
      add('sqlite3_flutter_libs');
      add('path_provider');
    case LocalCacheStyle.isar:
      add('isar');
      add('isar_flutter_libs');
    case LocalCacheStyle.sharedPreferences:
      add('shared_preferences');
    case LocalCacheStyle.none:
      break;
  }

  if (config.authInterceptor) {
    add('flutter_secure_storage');
  }

  if (config.codegen.jsonSerializable || config.useRetrofit) {
    add('json_annotation');
  }

  return packages;
}

Future<ApiPackagesApplyResult> applyExternalSdkDependency(
  Directory projectRoot,
  ExternalSdkConfig sdk, {
  bool dryRun = false,
}) async {
  if (!sdk.isConfigured) {
    return ApiPackagesApplyResult(
      applied: false,
      skipped: true,
      details: ['External SDK package name is required'],
    );
  }

  if (hasPubDependency(projectRoot, sdk.packageName)) {
    return ApiPackagesApplyResult(
      applied: false,
      skipped: true,
      details: ['pubspec.yaml already lists ${sdk.packageName}'],
    );
  }

  final args = <String>['pub', 'add', sdk.packageName];
  switch (sdk.source) {
    case 'git':
      final git = sdk.git;
      if (git == null || !git.isValid) {
        return ApiPackagesApplyResult(
          applied: false,
          skipped: false,
          error: 'Git URL is required for external SDK',
        );
      }
      args.addAll(['--git-url', git.url]);
      if (git.ref != null && git.ref!.isNotEmpty) {
        args.addAll(['--git-ref', git.ref!]);
      }
      if (git.path != null && git.path!.isNotEmpty) {
        args.addAll(['--git-path', git.path!]);
      }
    case 'path':
      final path = sdk.path;
      if (path == null || path.isEmpty) {
        return ApiPackagesApplyResult(
          applied: false,
          skipped: false,
          error: 'Path is required for external SDK',
        );
      }
      args.addAll(['--path', path]);
    case 'hosted':
      final hosted = sdk.hosted;
      if (hosted == null || !hosted.isValid) {
        return ApiPackagesApplyResult(
          applied: false,
          skipped: false,
          error: 'Hosted registry URL is required for external SDK',
        );
      }
      args.addAll([
        '--hosted-url',
        hosted.url,
        '--hosted-name',
        sdk.packageName,
      ]);
      args.add(hosted.version);
    default:
      return ApiPackagesApplyResult(
        applied: false,
        skipped: false,
        error: "Unknown external SDK source '${sdk.source}'",
      );
  }

  final label = 'dart ${args.join(' ')}';
  if (dryRun) {
    return ApiPackagesApplyResult(
      applied: false,
      skipped: false,
      details: ['Would run: $label (in ${projectRoot.path})'],
    );
  }

  final result = await Process.run(
    'dart',
    args,
    workingDirectory: projectRoot.path,
  );
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    return ApiPackagesApplyResult(
      applied: false,
      skipped: false,
      error: message.isEmpty ? '$label failed' : message,
    );
  }

  return ApiPackagesApplyResult(
    applied: true,
    skipped: false,
    details: ['Added external SDK: ${sdk.packageName} (${sdk.source})'],
  );
}
