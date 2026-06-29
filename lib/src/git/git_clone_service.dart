import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../flutter_tools.dart';
import 'git_auth.dart';
import 'git_cache.dart';
import 'git_remote_source.dart';

/// Clones or updates a Git remote into the toolkit cache.
class GitCloneService {
  GitCloneService({GitCache? cache}) : _cache = cache ?? GitCache();

  final GitCache _cache;

  /// Verifies remote access without a full clone when possible.
  Future<void> verifyAccess(GitRemoteSource source) async {
    source.validate();
    final result = await Process.run(
      'git',
      ['ls-remote', source.authenticatedUrl(), source.ref],
      environment: _gitEnvironment(source),
    );
    if (result.exitCode != 0) {
      final detail = '${result.stderr}'.trim();
      throw StateError(
        detail.isEmpty
            ? 'Cannot access repository. Check SSH key, VPN, or token.'
            : detail,
      );
    }
  }

  /// Returns the Flutter project directory inside the cache (optional [subdir]).
  Future<Directory> cloneOrUpdate(GitRemoteSource source) async {
    source.validate();
    final cacheDir = _cache.directoryForKey(source.cacheKey);
    if (!_isGitRepo(cacheDir)) {
      await _clone(source, cacheDir);
    } else {
      await _fetchAndCheckout(source, cacheDir);
    }
    final projectDir = source.subdir.isEmpty
        ? cacheDir
        : Directory(p.join(cacheDir.path, source.subdir));
    if (!projectDir.existsSync()) {
      throw StateError(
        'Project subdirectory not found after clone: ${projectDir.path}',
      );
    }
    validateFlutterProject(projectDir);
    await _pubGet(projectDir);
    return projectDir;
  }

  Future<void> _clone(GitRemoteSource source, Directory cacheDir) async {
    if (cacheDir.listSync().isNotEmpty) {
      throw StateError('Cache directory is not empty: ${cacheDir.path}');
    }
    final args = <String>[
      'clone',
      '--depth',
      '1',
      '--branch',
      source.ref,
      source.authenticatedUrl(),
      cacheDir.path,
    ];
    final result = await Process.run(
      'git',
      args,
      environment: _gitEnvironment(source),
    );
    if (result.exitCode != 0) {
      final detail = '${result.stderr}'.trim();
      if (detail.contains('Authentication failed') ||
          detail.contains('Permission denied')) {
        throw StateError(
          'Cannot access repository. Check SSH key, VPN, or token.',
        );
      }
      throw StateError(
        detail.isEmpty ? 'git clone failed' : detail,
      );
    }
  }

  Future<void> _fetchAndCheckout(
    GitRemoteSource source,
    Directory cacheDir,
  ) async {
    var result = await Process.run(
      'git',
      ['fetch', '--depth', '1', 'origin', source.ref],
      workingDirectory: cacheDir.path,
      environment: _gitEnvironment(source),
    );
    if (result.exitCode != 0) {
      result = await Process.run(
        'git',
        ['fetch', 'origin', source.ref],
        workingDirectory: cacheDir.path,
        environment: _gitEnvironment(source),
      );
    }
    if (result.exitCode != 0) {
      throw StateError('git fetch failed: ${result.stderr}'.trim());
    }
    result = await Process.run(
      'git',
      ['checkout', 'FETCH_HEAD'],
      workingDirectory: cacheDir.path,
      environment: _gitEnvironment(source),
    );
    if (result.exitCode != 0) {
      throw StateError('git checkout failed: ${result.stderr}'.trim());
    }
  }

  Future<void> _pubGet(Directory projectDir) async {
    final flutter = detectFlutter();
    final result = await Process.run(
      flutter.executable,
      flutter.buildArgs(['pub', 'get']),
      workingDirectory: projectDir.path,
    );
    if (result.exitCode != 0) {
      throw StateError('flutter pub get failed: ${result.stderr}'.trim());
    }
  }

  bool _isGitRepo(Directory dir) =>
      Directory(p.join(dir.path, '.git')).existsSync();

  Map<String, String> _gitEnvironment(GitRemoteSource source) {
    return {
      ...Platform.environment,
      'GIT_TERMINAL_PROMPT': '0',
      if (source.auth == GitAuthMode.ssh) 'GIT_SSH_COMMAND': 'ssh -o BatchMode=yes',
    };
  }
}
