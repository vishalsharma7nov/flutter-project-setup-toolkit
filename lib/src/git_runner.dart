import 'dart:io';

import 'models.dart';

class GitRunner {
  GitRunner(this.repoRoot);
  final Directory repoRoot;

  Future<LoadedCommit> loadCommit(String commit) async {
    return LoadedCommit(
      subject: (await _run('log', '-1', '--format=%s', commit)).trim(),
      body: (await _run('log', '-1', '--format=%b', commit)).trim(),
      changes: _parseNameStatus(
        await _run('diff-tree', '--no-commit-id', '--name-status', '-r', commit),
      ),
      diff: await _run('show', commit, '--format=', '--unified=0', '--no-color'),
    );
  }

  Future<String> shortSha(String commit) async {
    return (await _run('rev-parse', '--short', commit)).trim();
  }

  Future<String> _run(String command, String arg1, [String? arg2, String? arg3, String? arg4]) async {
    final args = <String>[command, arg1];
    if (arg2 != null) args.add(arg2);
    if (arg3 != null) args.add(arg3);
    if (arg4 != null) args.add(arg4);
    final result = await Process.run('git', args, workingDirectory: repoRoot.path);
    if (result.exitCode != 0) {
      throw StateError(result.stderr.toString().trim().isEmpty
          ? 'git command failed'
          : result.stderr.toString().trim());
    }
    return result.stdout.toString();
  }

  List<FileChange> _parseNameStatus(String output) {
    final changes = <FileChange>[];
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('\t');
      if (parts.length == 2) {
        changes.add(FileChange(parts[0].trim(), parts[1].trim()));
      }
    }
    return changes;
  }
}

class LoadedCommit {
  const LoadedCommit({
    required this.subject,
    required this.body,
    required this.changes,
    required this.diff,
  });
  final String subject;
  final String body;
  final List<FileChange> changes;
  final String diff;
}
