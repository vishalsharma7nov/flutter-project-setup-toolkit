import 'dart:io';

import 'package:pub_api_client/pub_api_client.dart';

import '../config.dart';
import '../flutter_tools.dart';
import '../state_management.dart';
import 'git_package_validator.dart';

/// Parsed package name (and optional version) from a URL or plain name.
class ParsedPackageInput {
  ParsedPackageInput({required this.name, this.version});

  final String name;
  final String? version;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (version != null) 'version': version,
      };
}

/// Lightweight search hit for the Package Studio list.
class PackageSearchHit {
  PackageSearchHit({
    required this.name,
    this.description,
    this.latestVersion,
    this.likes,
    this.pubPoints,
  });

  final String name;
  final String? description;
  final String? latestVersion;
  final int? likes;
  final int? pubPoints;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (latestVersion != null) 'latest_version': latestVersion,
        if (likes != null) 'likes': likes,
        if (pubPoints != null) 'pub_points': pubPoints,
      };
}

/// Full package metadata for the detail panel.
class PackageDetail {
  PackageDetail({
    required this.name,
    required this.description,
    required this.latestVersion,
    required this.versions,
    this.homepage,
    this.repository,
    this.publisher,
    this.likes,
    this.pubPoints,
    this.popularity,
    this.url,
    this.isDiscontinued,
    this.replacedBy,
    this.alreadyInstalled = false,
  });

  final String name;
  final String description;
  final String latestVersion;
  final List<String> versions;
  final String? homepage;
  final String? repository;
  final String? publisher;
  final int? likes;
  final int? pubPoints;
  final double? popularity;
  final String? url;
  final bool? isDiscontinued;
  final String? replacedBy;
  final bool alreadyInstalled;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'latest_version': latestVersion,
        'versions': versions,
        if (homepage != null) 'homepage': homepage,
        if (repository != null) 'repository': repository,
        if (publisher != null) 'publisher': publisher,
        if (likes != null) 'likes': likes,
        if (pubPoints != null) 'pub_points': pubPoints,
        if (popularity != null) 'popularity': popularity,
        if (url != null) 'url': url,
        if (isDiscontinued != null) 'is_discontinued': isDiscontinued,
        if (replacedBy != null) 'replaced_by': replacedBy,
        'already_installed': alreadyInstalled,
      };
}

class PackageInstallResult {
  PackageInstallResult({
    required this.applied,
    required this.skipped,
    this.command,
    this.stdout = '',
    this.stderr = '',
    this.detail,
    this.error,
  });

  final bool applied;
  final bool skipped;
  final String? command;
  final String stdout;
  final String stderr;
  final String? detail;
  final String? error;

  Map<String, dynamic> toJson() => {
        'applied': applied,
        'skipped': skipped,
        if (command != null) 'command': command,
        'stdout': stdout,
        'stderr': stderr,
        if (detail != null) 'detail': detail,
        if (error != null) 'error': error,
      };
}

final _pubDevUrlPattern = RegExp(
  r'(?:https?://)?(?:www\.)?pub\.dev/packages/([a-z][a-z0-9_]*)'
  r'(?:/versions/([^/\s#?]+))?',
  caseSensitive: false,
);

final _packageNamePattern = RegExp(r'^[a-z][a-z0-9_]*$');

/// Extract package name and optional version from a pub.dev URL or plain name.
ParsedPackageInput? parsePackageInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final urlMatch = _pubDevUrlPattern.firstMatch(trimmed);
  if (urlMatch != null) {
    return ParsedPackageInput(
      name: urlMatch.group(1)!,
      version: urlMatch.group(2),
    );
  }

  if (!trimmed.contains('/') &&
      !trimmed.contains(' ') &&
      trimmed.contains(':')) {
    final versionSplit = trimmed.split(':');
    if (versionSplit.length == 2 &&
        _packageNamePattern.hasMatch(versionSplit[0]) &&
        versionSplit[1].isNotEmpty) {
      return ParsedPackageInput(
        name: versionSplit[0],
        version: versionSplit[1],
      );
    }
  }

  if (_packageNamePattern.hasMatch(trimmed)) {
    return ParsedPackageInput(name: trimmed);
  }

  return null;
}

/// Unified resolve result — pub.dev or Git.
Map<String, dynamic>? resolvePackageInput(String raw) {
  final pub = parsePackageInput(raw);
  if (pub != null) {
    return {
      'source': 'pub',
      'name': pub.name,
      if (pub.version != null) 'version': pub.version,
    };
  }
  final git = parseGitPackageInput(raw);
  if (git != null) {
    return git.toJson();
  }
  return null;
}

/// Build `pub add` tail arguments for a Git dependency.
List<String> buildGitPubAddArgs({
  required String packageName,
  required String gitUrl,
  String? gitRef,
  String? gitPath,
  bool dev = false,
}) {
  return [
    'pub',
    'add',
    if (dev) '--dev',
    packageName,
    '--git-url',
    gitUrl,
    if (gitRef != null && gitRef.isNotEmpty) ...['--git-ref', gitRef],
    if (gitPath != null && gitPath.isNotEmpty) ...['--git-path', gitPath],
  ];
}

/// Resolve executable and full argument list for git `pub add`.
({String executable, List<String> args}) resolveGitPubAddCommand({
  required Directory projectRoot,
  required String packageName,
  required String gitUrl,
  String? gitRef,
  String? gitPath,
  bool dev = false,
}) {
  final pubArgs = buildGitPubAddArgs(
    packageName: packageName,
    gitUrl: gitUrl,
    gitRef: gitRef,
    gitPath: gitPath,
    dev: dev,
  );
  if (isFlutterSdkProject(projectRoot)) {
    final flutter = detectFlutter();
    return (
      executable: flutter.executable,
      args: [...flutter.argsPrefix, ...pubArgs],
    );
  }
  return (executable: 'dart', args: pubArgs);
}

String formatGitPubAddCommand({
  required Directory projectRoot,
  required String packageName,
  required String gitUrl,
  String? gitRef,
  String? gitPath,
  bool dev = false,
}) {
  final resolved = resolveGitPubAddCommand(
    projectRoot: projectRoot,
    packageName: packageName,
    gitUrl: gitUrl,
    gitRef: gitRef,
    gitPath: gitPath,
    dev: dev,
  );
  return '${resolved.executable} ${resolved.args.join(' ')}';
}

List<String> buildPubAddArgs({
  required String packageName,
  String? version,
  bool dev = false,
}) {
  final descriptor =
      version != null && version.isNotEmpty ? '$packageName:$version' : packageName;
  return [
    'pub',
    'add',
    if (dev) '--dev',
    descriptor,
  ];
}

/// Resolve executable and full argument list for `pub add`.
({String executable, List<String> args}) resolvePubAddCommand({
  required Directory projectRoot,
  required String packageName,
  String? version,
  bool dev = false,
}) {
  final pubArgs = buildPubAddArgs(
    packageName: packageName,
    version: version,
    dev: dev,
  );
  if (isFlutterSdkProject(projectRoot)) {
    final flutter = detectFlutter();
    return (
      executable: flutter.executable,
      args: [...flutter.argsPrefix, ...pubArgs],
    );
  }
  return (executable: 'dart', args: pubArgs);
}

String formatPubAddCommand({
  required Directory projectRoot,
  required String packageName,
  String? version,
  bool dev = false,
}) {
  final resolved = resolvePubAddCommand(
    projectRoot: projectRoot,
    packageName: packageName,
    version: version,
    dev: dev,
  );
  return '${resolved.executable} ${resolved.args.join(' ')}';
}

class PubPackageService {
  PubPackageService({
    PubClient? client,
    GitPackageValidator? gitValidator,
  })  : _client = client ?? PubClient(),
        _gitValidator = gitValidator ?? GitPackageValidator();

  final PubClient _client;
  final GitPackageValidator _gitValidator;

  Future<Map<String, dynamic>> searchPackages(
    String query, {
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return {'packages': <Map<String, dynamic>>[], 'next': null};
    }

    final results = await _client.search(trimmed, page: page);
    final names = results.packages.map((r) => r.package).toList();
    final hits = await _enrichSearchHits(names.take(15).toList());

    return {
      'packages': hits.map((h) => h.toJson()).toList(),
      if (results.next != null) 'next': results.next,
    };
  }

  Future<List<PackageSearchHit>> _enrichSearchHits(List<String> names) async {
    if (names.isEmpty) {
      return [];
    }

    final futures = names.map((name) async {
      try {
        final info = await _client.packageInfo(name);
        PackageScore? score;
        try {
          score = await _client.packageScore(name);
        } on Object {
          score = null;
        }
        return PackageSearchHit(
          name: info.name,
          description: info.description.isEmpty ? null : info.description,
          latestVersion: info.version,
          likes: score?.likeCount,
          pubPoints: score?.grantedPoints,
        );
      } on Object {
        return PackageSearchHit(name: name);
      }
    });

    return Future.wait(futures);
  }

  Future<PackageDetail> fetchPackageDetail(
    String name, {
    Directory? projectRoot,
  }) async {
    final info = await _client.packageInfo(name);
    PackageScore? score;
    PackagePublisher? publisher;
    try {
      score = await _client.packageScore(name);
    } on Object {
      score = null;
    }
    try {
      publisher = await _client.packagePublisher(name);
    } on Object {
      publisher = null;
    }

    final pubspec = info.latestPubspec;
    final versions = info.versions.isNotEmpty
        ? info.versions.map((v) => v.version).toList()
        : [info.version];

    return PackageDetail(
      name: info.name,
      description: info.description,
      latestVersion: info.version,
      versions: versions.reversed.toList(),
      homepage: pubspec.homepage,
      repository: pubspec.repository?.toString(),
      publisher: publisher?.publisherId,
      likes: score?.likeCount,
      pubPoints: score?.grantedPoints,
      popularity: score?.popularityScore,
      url: info.url,
      isDiscontinued: info.isDiscontinued,
      replacedBy: info.replacedBy,
      alreadyInstalled: projectRoot != null &&
          hasPubDependency(projectRoot, info.name),
    );
  }

  Future<PackageInstallResult> installPackage(
    Directory projectRoot, {
    required String name,
    String? version,
    bool dev = false,
  }) async {
    validateFlutterProject(projectRoot);

    if (hasPubDependency(projectRoot, name)) {
      return PackageInstallResult(
        applied: false,
        skipped: true,
        detail: 'pubspec.yaml already lists $name',
        command: formatPubAddCommand(
          projectRoot: projectRoot,
          packageName: name,
          version: version,
          dev: dev,
        ),
      );
    }

    final resolved = resolvePubAddCommand(
      projectRoot: projectRoot,
      packageName: name,
      version: version,
      dev: dev,
    );
    final commandLabel = '${resolved.executable} ${resolved.args.join(' ')}';

    final result = await Process.run(
      resolved.executable,
      resolved.args,
      workingDirectory: projectRoot.path,
      runInShell: false,
    );

    final stdout = '${result.stdout}'.trim();
    final stderr = '${result.stderr}'.trim();

    if (result.exitCode != 0) {
      return PackageInstallResult(
        applied: false,
        skipped: false,
        command: commandLabel,
        stdout: stdout,
        stderr: stderr,
        error: stderr.isEmpty ? '$commandLabel failed' : stderr,
      );
    }

    final kind = dev ? 'dev dependency' : 'dependency';
    return PackageInstallResult(
      applied: true,
      skipped: false,
      command: commandLabel,
      stdout: stdout,
      stderr: stderr,
      detail: 'Added $kind: $name',
    );
  }

  Future<GitPackageValidationReport> validateGitPackage({
    required String gitUrl,
    String gitRef = 'main',
    String gitPath = '',
  }) {
    return _gitValidator.validate(
      gitUrl: gitUrl,
      gitRef: gitRef,
      gitPath: gitPath,
    );
  }

  Future<PackageInstallResult> installGitPackage(
    Directory projectRoot, {
    required String packageName,
    required String gitUrl,
    String? gitRef,
    String? gitPath,
    bool dev = false,
    bool skipValidation = false,
  }) async {
    validateFlutterProject(projectRoot);

    if (hasPubDependency(projectRoot, packageName)) {
      return PackageInstallResult(
        applied: false,
        skipped: true,
        detail: 'pubspec.yaml already lists $packageName',
        command: formatGitPubAddCommand(
          projectRoot: projectRoot,
          packageName: packageName,
          gitUrl: gitUrl,
          gitRef: gitRef,
          gitPath: gitPath,
          dev: dev,
        ),
      );
    }

    if (!skipValidation) {
      final validation = await _gitValidator.validate(
        gitUrl: gitUrl,
        gitRef: gitRef ?? 'main',
        gitPath: gitPath ?? '',
      );
      if (!validation.valid) {
        final failed = validation.checks
            .where((c) => !c.ok)
            .map((c) => c.message)
            .join('; ');
        return PackageInstallResult(
          applied: false,
          skipped: false,
          error: validation.error ??
              (failed.isEmpty
                  ? 'Git package validation failed'
                  : 'Validation failed: $failed'),
          stderr: validation.checks
              .map((c) => '${c.ok ? '✓' : '✗'} ${c.message}')
              .join('\n'),
        );
      }
    }

    final resolved = resolveGitPubAddCommand(
      projectRoot: projectRoot,
      packageName: packageName,
      gitUrl: gitUrl,
      gitRef: gitRef,
      gitPath: gitPath,
      dev: dev,
    );
    final commandLabel = '${resolved.executable} ${resolved.args.join(' ')}';

    final result = await Process.run(
      resolved.executable,
      resolved.args,
      workingDirectory: projectRoot.path,
      runInShell: false,
    );

    final stdout = '${result.stdout}'.trim();
    final stderr = '${result.stderr}'.trim();

    if (result.exitCode != 0) {
      return PackageInstallResult(
        applied: false,
        skipped: false,
        command: commandLabel,
        stdout: stdout,
        stderr: stderr,
        error: stderr.isEmpty ? '$commandLabel failed' : stderr,
      );
    }

    final kind = dev ? 'dev dependency' : 'dependency';
    return PackageInstallResult(
      applied: true,
      skipped: false,
      command: commandLabel,
      stdout: stdout,
      stderr: stderr,
      detail: 'Added git $kind: $packageName',
    );
  }

  void close() => _client.close();
}
