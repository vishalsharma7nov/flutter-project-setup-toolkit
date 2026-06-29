import 'models.dart';

final _ignoredPathPrefixes = [
  '.cursor/',
  '.vscode/',
  '.idea/',
  'macos/',
  'linux/',
  'windows/',
  'web/',
];
const _ignoredExactPaths = {'ios/Podfile.lock', 'pubspec.lock', '.metadata'};
const _generatedSuffixes = ['.g.dart', '.freezed.dart', '.mocks.dart'];

final _majorMessagePatterns = [
  RegExp(r'\bBREAKING[\s_-]?CHANGE\b', caseSensitive: false),
  RegExp(r'\bbreaking\b', caseSensitive: false),
  RegExp(r'^major[!:]', caseSensitive: false),
  RegExp(r'!\s*:\s*'),
  RegExp(r'\bremove(?:d)?\s+(?:api|endpoint|route|screen)\b', caseSensitive: false),
];
final _minorMessagePatterns = [
  RegExp(r'^feat(?:ure)?[!:]', caseSensitive: false),
  RegExp(r'\bfeat(?:ure)?\b', caseSensitive: false),
  RegExp(r'^add[!:]', caseSensitive: false),
  RegExp(r'\bnew\s+(?:feature|screen|flow|page)\b', caseSensitive: false),
];
final _patchMessagePatterns = [
  RegExp(r'^fix[!:]', caseSensitive: false),
  RegExp(r'\bbugfix\b', caseSensitive: false),
  RegExp(r'\bhotfix\b', caseSensitive: false),
  RegExp(r'^patch[!:]', caseSensitive: false),
  RegExp(r'^chore[!:]', caseSensitive: false),
  RegExp(r'^refactor[!:]', caseSensitive: false),
  RegExp(r'^docs?[!:]', caseSensitive: false),
  RegExp(r'^test[!:]', caseSensitive: false),
];

bool shouldIgnorePath(String path) {
  if (_ignoredExactPaths.contains(path)) return true;
  if (_ignoredPathPrefixes.any(path.startsWith)) return true;
  if (_generatedSuffixes.any(path.endsWith)) return true;
  return false;
}

Classification classifyCommit(
  String subject,
  String body,
  List<FileChange> changes,
  String diff,
) {
  final relevant = changes.where((c) => !shouldIgnorePath(c.path)).toList();
  final result = Classification();
  if (relevant.isEmpty && subject.isEmpty && body.isEmpty) {
    result.reasons.add('no relevant file changes detected');
    return result;
  }

  final text = '$subject\n$body'.trim();
  if (text.isNotEmpty) {
    for (final pattern in _majorMessagePatterns) {
      if (pattern.hasMatch(text)) {
        result.merge(BumpLevel.major, 'commit message matches `${pattern.pattern}`');
        return result;
      }
    }
    for (final pattern in _minorMessagePatterns) {
      if (pattern.hasMatch(text)) {
        result.merge(BumpLevel.minor, 'commit message matches `${pattern.pattern}`');
        break;
      }
    }
    for (final pattern in _patchMessagePatterns) {
      if (pattern.hasMatch(text)) {
        result.merge(BumpLevel.patch, 'commit message matches `${pattern.pattern}`');
        break;
      }
    }
  }

  if (relevant.isNotEmpty) {
    final allDocs = relevant.every((c) {
      return c.path.startsWith('docs/') ||
          c.path.startsWith('doc/') ||
          c.path.endsWith('.md') ||
          c.path.endsWith('.txt') ||
          c.path.endsWith('.rst') ||
          (c.path.startsWith('test/') && c.status.startsWith('M'));
    });
    if (allDocs) {
      result.merge(BumpLevel.patch, 'documentation or test-only changes');
    } else {
      final deletedLib = relevant
          .where((c) => c.status.startsWith('D') && c.path.startsWith('lib/'))
          .toList();
      if (deletedLib.isNotEmpty) {
        result.merge(
          BumpLevel.major,
          'deleted Dart source under lib/ (${deletedLib.length} file(s))',
        );
      }
      final deletedNative = relevant.where((c) {
        return c.status.startsWith('D') &&
            (c.path.startsWith('android/') || c.path.startsWith('ios/')) &&
            (c.path.endsWith('.kt') ||
                c.path.endsWith('.swift') ||
                c.path.endsWith('.java'));
      }).toList();
      if (deletedNative.isNotEmpty) {
        final level = deletedLib.isEmpty ? BumpLevel.minor : BumpLevel.major;
        final label =
            deletedLib.isEmpty ? 'native refactor' : 'breaking native removal';
        result.merge(
          level,
          '$label (${deletedNative.length} native file(s) deleted)',
        );
      }
      if (relevant.any((c) =>
          c.status.startsWith('A') && c.path.contains('/presentation/pages/'))) {
        result.merge(BumpLevel.minor, 'added presentation page(s)');
      }
      if (relevant.any((c) =>
          c.path.endsWith('lib/app/router/routes.dart') &&
          c.status.startsWith('M'))) {
        result.merge(BumpLevel.minor, 'modified app router (routes.dart)');
      }
      if (relevant.any(
          (c) => c.path.startsWith('lib/l10n/') && c.path.endsWith('.arb'))) {
        result.merge(BumpLevel.minor, 'updated localization ARB file(s)');
      }
      if (relevant.any((c) => c.path == 'pubspec.yaml')) {
        result.merge(BumpLevel.minor, 'pubspec.yaml changed');
      }
    }
  }

  if (diff.trim().isNotEmpty) {
    for (final entry in _iterDiffFiles(diff)) {
      if (RegExp(r'^-\s*RoutesName\.', multiLine: true).hasMatch(entry.value)) {
        result.merge(BumpLevel.major, 'removed route name in ${entry.key}');
      }
      if (RegExp(r'^\+\s*RoutesName\.', multiLine: true).hasMatch(entry.value)) {
        result.merge(BumpLevel.minor, 'added route name in ${entry.key}');
      }
    }
  }

  if (result.reasons.isEmpty) {
    result.reasons.add('default patch bump for maintenance change');
  }
  return result;
}

Iterable<MapEntry<String, String>> _iterDiffFiles(String diff) sync* {
  var currentPath = '';
  final chunks = <String>[];
  for (final line in diff.split('\n')) {
    if (line.startsWith('diff --git ')) {
      if (currentPath.isNotEmpty && chunks.isNotEmpty) {
        yield MapEntry(currentPath, chunks.join('\n'));
      }
      final match = RegExp(r'diff --git a/.+ b/(.+)$').firstMatch(line);
      currentPath = match?.group(1) ?? '';
      chunks.clear();
      continue;
    }
    chunks.add(line);
  }
  if (currentPath.isNotEmpty && chunks.isNotEmpty) {
    yield MapEntry(currentPath, chunks.join('\n'));
  }
}
