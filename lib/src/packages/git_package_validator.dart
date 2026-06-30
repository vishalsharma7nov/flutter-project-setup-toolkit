import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

import '../flutter_tools.dart';

/// Parsed GitHub / Git repository reference for a Dart package.
class ParsedGitPackage {
  ParsedGitPackage({
    required this.url,
    this.ref = 'main',
    this.path = '',
    this.suggestedName,
  });

  final String url;
  final String ref;
  final String path;
  final String? suggestedName;

  Map<String, dynamic> toJson() => {
        'source': 'git',
        'git_url': url,
        'git_ref': ref,
        if (path.isNotEmpty) 'git_path': path,
        if (suggestedName != null) 'suggested_name': suggestedName,
      };
}

class GitValidationCheck {
  GitValidationCheck({
    required this.id,
    required this.ok,
    required this.message,
  });

  final String id;
  final bool ok;
  final String message;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ok': ok,
        'message': message,
      };
}

class GitPackageValidationReport {
  GitPackageValidationReport({
    required this.valid,
    required this.checks,
    this.packageName,
    this.description,
    this.gitUrl,
    this.gitRef,
    this.gitPath,
    this.error,
  });

  final bool valid;
  final List<GitValidationCheck> checks;
  final String? packageName;
  final String? description;
  final String? gitUrl;
  final String? gitRef;
  final String? gitPath;
  final String? error;

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'checks': checks.map((c) => c.toJson()).toList(),
        if (packageName != null) 'package_name': packageName,
        if (description != null) 'description': description,
        if (gitUrl != null) 'git_url': gitUrl,
        if (gitRef != null) 'git_ref': gitRef,
        if (gitPath != null) 'git_path': gitPath,
        if (error != null) 'error': error,
      };
}

final _githubHttpsPattern = RegExp(
  r'^(?:https?://)?(?:www\.)?github\.com/([^/\s#?]+)/([^/\s#?]+)'
  r'(?:\.git)?(?:/tree/([^/\s#?]+)(?:/(.+))?)?/?$',
  caseSensitive: false,
);

final _githubSshPattern = RegExp(
  r'^git@github\.com:([^/\s#?]+)/([^/\s#?.]+)(?:\.git)?$',
  caseSensitive: false,
);

final _genericGitHttpsPattern = RegExp(
  r'^(https?://\S+?)(?:\.git)?/?$',
  caseSensitive: false,
);

/// Parse a GitHub or generic Git HTTPS URL into clone parameters.
ParsedGitPackage? parseGitPackageInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final ssh = _githubSshPattern.firstMatch(trimmed);
  if (ssh != null) {
    final owner = ssh.group(1)!;
    final repo = ssh.group(2)!.replaceAll(RegExp(r'\.git$'), '');
    return ParsedGitPackage(
      url: 'https://github.com/$owner/$repo.git',
      suggestedName: _suggestedPackageName(repo),
    );
  }

  final gh = _githubHttpsPattern.firstMatch(trimmed);
  if (gh != null) {
    final owner = gh.group(1)!;
    final repo = gh.group(2)!.replaceAll(RegExp(r'\.git$'), '');
    final ref = gh.group(3) ?? 'main';
    final subPath = (gh.group(4) ?? '').trim();
    return ParsedGitPackage(
      url: 'https://github.com/$owner/$repo.git',
      ref: ref,
      path: subPath,
      suggestedName: _suggestedPackageName(repo),
    );
  }

  if (trimmed.startsWith('git@') || trimmed.contains('://')) {
    final generic = _genericGitHttpsPattern.firstMatch(trimmed);
    if (generic != null) {
      var url = generic.group(1)!;
      if (!url.endsWith('.git')) {
        url = '$url.git';
      }
      final segments = Uri.parse(url.replaceAll('.git', '')).pathSegments;
      final repo = segments.isNotEmpty ? segments.last : null;
      return ParsedGitPackage(
        url: url,
        suggestedName: repo == null ? null : _suggestedPackageName(repo),
      );
    }
  }

  return null;
}

String _suggestedPackageName(String repo) {
  return repo
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

/// Validate [pubspec.yaml] content without cloning.
List<GitValidationCheck> validatePubspecStructure(String content) {
  final checks = <GitValidationCheck>[];

  Pubspec? pubspec;
  try {
    pubspec = Pubspec.parse(content, lenient: true);
    checks.add(
      GitValidationCheck(
        id: 'pubspec_parse',
        ok: true,
        message: 'pubspec.yaml parses successfully',
      ),
    );
  } on Object catch (e) {
    checks.add(
      GitValidationCheck(
        id: 'pubspec_parse',
        ok: false,
        message: 'pubspec.yaml is invalid: $e',
      ),
    );
    return checks;
  }

  if (pubspec.name.isEmpty) {
    checks.add(
      GitValidationCheck(
        id: 'package_name',
        ok: false,
        message: 'pubspec.yaml is missing a package name',
      ),
    );
  } else if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(pubspec.name)) {
    checks.add(
      GitValidationCheck(
        id: 'package_name',
        ok: false,
        message: 'Package name "${pubspec.name}" is not a valid pub identifier',
      ),
    );
  } else {
    checks.add(
      GitValidationCheck(
        id: 'package_name',
        ok: true,
        message: 'Package name: ${pubspec.name}',
      ),
    );
  }

  final sdkConstraint = pubspec.environment['sdk'];
  if (sdkConstraint == null) {
    checks.add(
      GitValidationCheck(
        id: 'sdk_constraint',
        ok: false,
        message: 'pubspec.yaml is missing environment.sdk',
      ),
    );
  } else {
    checks.add(
      GitValidationCheck(
        id: 'sdk_constraint',
        ok: true,
        message: 'SDK constraint: $sdkConstraint',
      ),
    );
  }

  return checks;
}

/// Validate package layout on disk (after clone).
List<GitValidationCheck> validatePackageLayout(Directory packageRoot) {
  final checks = <GitValidationCheck>[];
  final pubspecFile = File(p.join(packageRoot.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    checks.add(
      GitValidationCheck(
        id: 'pubspec_file',
        ok: false,
        message: 'pubspec.yaml not found in ${packageRoot.path}',
      ),
    );
    return checks;
  }

  checks.add(
    GitValidationCheck(
      id: 'pubspec_file',
      ok: true,
      message: 'pubspec.yaml found',
    ),
  );

  checks.addAll(validatePubspecStructure(pubspecFile.readAsStringSync()));

  final libDir = Directory(p.join(packageRoot.path, 'lib'));
  if (!libDir.existsSync()) {
    checks.add(
      GitValidationCheck(
        id: 'lib_directory',
        ok: false,
        message: 'lib/ directory not found — not a standard Dart package layout',
      ),
    );
  } else {
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    if (dartFiles.isEmpty) {
      checks.add(
        GitValidationCheck(
          id: 'lib_directory',
          ok: false,
          message: 'lib/ exists but contains no .dart files',
        ),
      );
    } else {
      checks.add(
        GitValidationCheck(
          id: 'lib_directory',
          ok: true,
          message: 'lib/ contains ${dartFiles.length} Dart file(s)',
        ),
      );
    }
  }

  return checks;
}

bool _checksPass(List<GitValidationCheck> checks) =>
    checks.isNotEmpty && checks.every((c) => c.ok);

/// Shallow-clone a Git package and verify structure + `pub get`.
class GitPackageValidator {
  Future<GitPackageValidationReport> validate({
    required String gitUrl,
    String gitRef = 'main',
    String gitPath = '',
  }) async {
    final checks = <GitValidationCheck>[];
    Directory? tempDir;

    try {
      checks.add(await _checkRepositoryAccess(gitUrl, gitRef));

      tempDir = Directory(
        p.join(
          Directory.systemTemp.path,
          'rtk-git-pkg-${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await tempDir.create(recursive: true);

      final cloneCheck = await _shallowClone(gitUrl, gitRef, tempDir);
      checks.add(cloneCheck);
      if (!cloneCheck.ok) {
        return _report(
          checks: checks,
          gitUrl: gitUrl,
          gitRef: gitRef,
          gitPath: gitPath,
          error: cloneCheck.message,
        );
      }

      final packageRoot = gitPath.isEmpty
          ? tempDir
          : Directory(p.join(tempDir.path, gitPath));
      if (!packageRoot.existsSync()) {
        checks.add(
          GitValidationCheck(
            id: 'git_path',
            ok: false,
            message: 'Path "$gitPath" not found in repository',
          ),
        );
        return _report(
          checks: checks,
          gitUrl: gitUrl,
          gitRef: gitRef,
          gitPath: gitPath,
          error: 'Package path not found in repository',
        );
      }

      if (gitPath.isNotEmpty) {
        checks.add(
          GitValidationCheck(
            id: 'git_path',
            ok: true,
            message: 'Monorepo path found: $gitPath',
          ),
        );
      }

      checks.addAll(validatePackageLayout(packageRoot));
      if (!_checksPass(checks)) {
        return _report(
          checks: checks,
          gitUrl: gitUrl,
          gitRef: gitRef,
          gitPath: gitPath,
          error: 'Package structure validation failed',
        );
      }

      final pubspec = Pubspec.parse(
        File(p.join(packageRoot.path, 'pubspec.yaml')).readAsStringSync(),
        lenient: true,
      );

      final pubGetCheck = await _checkPubGet(packageRoot);
      checks.add(pubGetCheck);

      return _report(
        checks: checks,
        gitUrl: gitUrl,
        gitRef: gitRef,
        gitPath: gitPath.isEmpty ? null : gitPath,
        packageName: pubspec.name,
        description: pubspec.description,
        error: pubGetCheck.ok ? null : pubGetCheck.message,
      );
    } on Object catch (e) {
      checks.add(
        GitValidationCheck(
          id: 'unexpected',
          ok: false,
          message: '$e',
        ),
      );
      return _report(
        checks: checks,
        gitUrl: gitUrl,
        gitRef: gitRef,
        gitPath: gitPath,
        error: '$e',
      );
    } finally {
      if (tempDir != null && tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } on Object {
          // Best-effort cleanup.
        }
      }
    }
  }

  Future<GitValidationCheck> _checkRepositoryAccess(
    String gitUrl,
    String gitRef,
  ) async {
    final result = await Process.run(
      'git',
      ['ls-remote', gitUrl, gitRef],
      environment: {'GIT_TERMINAL_PROMPT': '0'},
    );
    if (result.exitCode != 0) {
      final detail = '${result.stderr}'.trim();
      return GitValidationCheck(
        id: 'repo_access',
        ok: false,
        message: detail.isEmpty
            ? 'Cannot access repository or ref "$gitRef"'
            : detail,
      );
    }
    return GitValidationCheck(
      id: 'repo_access',
      ok: true,
      message: 'Repository accessible (ref: $gitRef)',
    );
  }

  Future<GitValidationCheck> _shallowClone(
    String gitUrl,
    String gitRef,
    Directory target,
  ) async {
    var result = await Process.run(
      'git',
      [
        'clone',
        '--depth',
        '1',
        '--branch',
        gitRef,
        gitUrl,
        target.path,
      ],
      environment: {'GIT_TERMINAL_PROMPT': '0'},
    );

    if (result.exitCode != 0) {
      // Retry without branch (detached HEAD at default).
      result = await Process.run(
        'git',
        ['clone', '--depth', '1', gitUrl, target.path],
        environment: {'GIT_TERMINAL_PROMPT': '0'},
      );
      if (result.exitCode != 0) {
        final detail = '${result.stderr}'.trim();
        return GitValidationCheck(
          id: 'git_clone',
          ok: false,
          message: detail.isEmpty ? 'git clone failed' : detail,
        );
      }
      if (gitRef.isNotEmpty && gitRef != 'main') {
        final checkout = await Process.run(
          'git',
          ['checkout', gitRef],
          workingDirectory: target.path,
          environment: {'GIT_TERMINAL_PROMPT': '0'},
        );
        if (checkout.exitCode != 0) {
          return GitValidationCheck(
            id: 'git_clone',
            ok: false,
            message: 'Cloned repo but ref "$gitRef" not found',
          );
        }
      }
    }

    return GitValidationCheck(
      id: 'git_clone',
      ok: true,
      message: 'Shallow clone succeeded',
    );
  }

  Future<GitValidationCheck> _checkPubGet(Directory packageRoot) async {
    final isFlutter = _isFlutterPackage(packageRoot);
    late final String executable;
    late final List<String> args;

    if (isFlutter) {
      try {
        final flutter = detectFlutter();
        executable = flutter.executable;
        args = flutter.buildArgs(['pub', 'get']);
      } on Object catch (e) {
        return GitValidationCheck(
          id: 'pub_get',
          ok: false,
          message: 'Flutter package but Flutter SDK not available: $e',
        );
      }
    } else {
      executable = 'dart';
      args = ['pub', 'get'];
    }

    final result = await Process.run(
      executable,
      args,
      workingDirectory: packageRoot.path,
      runInShell: false,
    );

    if (result.exitCode != 0) {
      final detail = '${result.stderr}'.trim();
      return GitValidationCheck(
        id: 'pub_get',
        ok: false,
        message: detail.isEmpty
            ? '${isFlutter ? 'flutter' : 'dart'} pub get failed — package may be broken'
            : detail,
      );
    }

    return GitValidationCheck(
      id: 'pub_get',
      ok: true,
      message: '${isFlutter ? 'flutter' : 'dart'} pub get succeeded',
    );
  }

  bool _isFlutterPackage(Directory packageRoot) {
    final pubspec = File(p.join(packageRoot.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      return false;
    }
    final content = pubspec.readAsStringSync();
    return RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content) ||
        RegExp(r'sdk:\s*flutter', multiLine: true).hasMatch(content);
  }

  GitPackageValidationReport _report({
    required List<GitValidationCheck> checks,
    String? packageName,
    String? description,
    String? gitUrl,
    String? gitRef,
    String? gitPath,
    String? error,
  }) {
    return GitPackageValidationReport(
      valid: _checksPass(checks),
      checks: checks,
      packageName: packageName,
      description: description,
      gitUrl: gitUrl,
      gitRef: gitRef,
      gitPath: gitPath,
      error: error,
    );
  }
}
