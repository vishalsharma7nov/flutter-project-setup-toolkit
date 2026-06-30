import 'dart:io';

import 'models.dart';

class GitRunner {
  GitRunner(this.repoRoot);
  final Directory repoRoot;

  Future<LoadedCommit> loadCommit(String commit) async {
    return LoadedCommit(
      subject: (await _runGit(['log', '-1', '--format=%s', commit])).trim(),
      body: (await _runGit(['log', '-1', '--format=%b', commit])).trim(),
      changes: _parseNameStatus(
        await _runGit([
          'diff-tree',
          '--no-commit-id',
          '--name-status',
          '-r',
          commit,
        ]),
      ),
      diff: await _runGit(['show', commit, '--format=', '--unified=0', '--no-color']),
    );
  }

  Future<String> shortSha(String commit) async {
    return (await _runGit(['rev-parse', '--short', commit])).trim();
  }

  Future<String> resolveRef(String ref) async {
    return (await _runGit(['rev-parse', '--verify', ref])).trim();
  }

  Future<int> commitCount(String base, String head) async {
    final out = (await _runGit(['rev-list', '--count', '$base..$head'])).trim();
    return int.parse(out);
  }

  Future<CommitRange> loadRange({
    required String base,
    required String head,
  }) async {
    final baseSha = await resolveRef(base);
    final headSha = await resolveRef(head);
    final count = await commitCount(baseSha, headSha);
    if (count == 0) {
      throw StateError('No commits between $base and $head');
    }

    final headSubject =
        (await _runGit(['log', '-1', '--format=%s', head])).trim();
    final headBody = (await _runGit(['log', '-1', '--format=%b', head])).trim();
    final headAuthor =
        (await _runGit(['log', '-1', '--format=%an', head])).trim();
    final headDate =
        (await _runGit(['log', '-1', '--format=%ci', head])).trim();

    final changes = _parseNameStatus(
      await _runGit(['diff', '--name-status', '$baseSha..$headSha']),
    );
    final diff = await _runGit([
      'diff',
      '$baseSha..$headSha',
      '--unified=3',
      '--no-color',
    ]);

    return CommitRange(
      baseRef: base,
      headRef: head,
      baseSha: baseSha,
      headSha: headSha,
      headSubject: headSubject,
      headBody: headBody,
      headAuthor: headAuthor,
      headDate: headDate,
      changes: changes,
      diff: diff,
    );
  }

  Future<void> ensureCompareableHistory(String base) async {
    if (!await isGitRepository()) {
      throw StateError('Not a git repository: ${repoRoot.path}');
    }
    try {
      await resolveRef(base);
    } on Object {
      if (base == 'HEAD~1') {
        throw StateError(
          'Need at least 2 commits to compare HEAD~1..HEAD',
        );
      }
      rethrow;
    }
  }

  Future<bool> isGitRepository() async {
    final gitDir = Directory('${repoRoot.path}/.git');
    return gitDir.existsSync();
  }

  Future<String?> latestTagName() async {
    try {
      final tag =
          (await _runGit(['describe', '--tags', '--abbrev=0'])).trim();
      return tag.isEmpty ? null : tag;
    } on StateError {
      return null;
    }
  }

  Future<String?> currentBranch() async {
    try {
      final branch =
          (await _runGit(['rev-parse', '--abbrev-ref', 'HEAD'])).trim();
      return branch == 'HEAD' ? null : branch;
    } on StateError {
      return null;
    }
  }

  Future<String?> remoteUrl(String remoteName) async {
    try {
      return (await _runGit(['remote', 'get-url', remoteName])).trim();
    } on StateError {
      return null;
    }
  }

  Future<String?> tryFindPullRequestUrl() async {
    final branch = await currentBranch();
    if (branch == null || branch.isEmpty) return null;
    try {
      final result = await Process.run(
        'gh',
        [
          'pr',
          'list',
          '--head',
          branch,
          '--state',
          'all',
          '--json',
          'url',
          '--limit',
          '1',
        ],
        workingDirectory: repoRoot.path,
      );
      if (result.exitCode != 0) return null;
      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty || stdout == '[]') return null;
      final match = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(stdout);
      return match?.group(1);
    } on Object {
      return null;
    }
  }

  Future<String> _runGit(List<String> args) async {
    final ProcessResult result;
    try {
      result = await Process.run('git', args, workingDirectory: repoRoot.path);
    } on ProcessException catch (e) {
      throw StateError(e.message);
    }
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
      if (parts.length >= 2) {
        changes.add(FileChange(parts[0].trim(), parts.last.trim()));
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

class CommitRange {
  const CommitRange({
    required this.baseRef,
    required this.headRef,
    required this.baseSha,
    required this.headSha,
    required this.headSubject,
    required this.headBody,
    required this.headAuthor,
    required this.headDate,
    required this.changes,
    required this.diff,
  });

  final String baseRef;
  final String headRef;
  final String baseSha;
  final String headSha;
  final String headSubject;
  final String headBody;
  final String headAuthor;
  final String headDate;
  final List<FileChange> changes;
  final String diff;
}
