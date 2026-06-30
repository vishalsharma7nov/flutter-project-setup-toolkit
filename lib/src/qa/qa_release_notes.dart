import 'dart:io';

import 'package:path/path.dart' as p;

import '../architecture/micro_feature_scaffold.dart';
import '../classify.dart';
import '../git_runner.dart';
import '../models.dart';
import '../version/version_studio_service.dart';
import 'codebase_snapshot.dart';

/// How QA notes are sourced: git compare or codebase scan.
enum QaSourceMode {
  auto,
  git,
  codebase;

  static QaSourceMode parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'git':
        return QaSourceMode.git;
      case 'codebase':
        return QaSourceMode.codebase;
      default:
        return QaSourceMode.auto;
    }
  }
}

/// Audience mode for export templates.
enum QaAudience {
  qa,
  pm,
  executive;

  static QaAudience parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'pm':
        return QaAudience.pm;
      case 'executive':
        return QaAudience.executive;
      default:
        return QaAudience.qa;
    }
  }
}

class CompareInfo {
  const CompareInfo({
    required this.baseRef,
    required this.headRef,
    required this.baseSha,
    required this.headSha,
    required this.shortBase,
    required this.shortHead,
    required this.headAuthor,
    required this.headDate,
    this.compareUrl,
    this.prUrl,
    this.branch,
  });

  final String baseRef;
  final String headRef;
  final String baseSha;
  final String headSha;
  final String shortBase;
  final String shortHead;
  final String headAuthor;
  final String headDate;
  final String? compareUrl;
  final String? prUrl;
  final String? branch;

  Map<String, dynamic> toJson() => {
        'base_ref': baseRef,
        'head_ref': headRef,
        'base_sha': baseSha,
        'head_sha': headSha,
        'short_base': shortBase,
        'short_head': shortHead,
        'head_author': headAuthor,
        'head_date': headDate,
        if (compareUrl != null) 'compare_url': compareUrl,
        if (prUrl != null) 'pr_url': prUrl,
        if (branch != null) 'branch': branch,
      };
}

class QaChecklistItem {
  const QaChecklistItem({
    required this.area,
    required this.item,
    required this.priority,
    this.platform = 'All',
    this.ticketId,
  });

  final String area;
  final String item;
  final String priority;
  final String platform;
  final String? ticketId;

  Map<String, dynamic> toJson() => {
        'area': area,
        'item': item,
        'priority': priority,
        'platform': platform,
        if (ticketId != null) 'ticket_id': ticketId,
      };
}

class ManualVerificationRow {
  const ManualVerificationRow({
    required this.criterion,
    required this.steps,
    required this.expected,
  });

  final String criterion;
  final String steps;
  final String expected;

  Map<String, dynamic> toJson() => {
        'criterion': criterion,
        'steps': steps,
        'expected': expected,
      };
}

class FileChangeGroup {
  const FileChangeGroup({
    required this.label,
    required this.changes,
  });

  final String label;
  final List<FileChange> changes;

  Map<String, dynamic> toJson() => {
        'label': label,
        'changes': changes
            .map((c) => {'status': c.status, 'path': c.path})
            .toList(),
      };
}

class QaReleaseNotesResult {
  const QaReleaseNotesResult({
    required this.projectName,
    required this.compare,
    required this.summary,
    required this.commitBody,
    required this.impact,
    required this.reasons,
    required this.checklist,
    required this.manualVerification,
    required this.fileGroups,
    required this.relevantChanges,
    required this.estimatedMinutes,
    required this.goNoGoHint,
    required this.riskLevel,
    required this.platformsAffected,
    required this.testFilesChanged,
    required this.audience,
    required this.source,
    this.versionContext,
    this.codeUnderstanding,
    this.ticketIds = const [],
    this.screenshotChecklist = const [],
    this.distributionHint,
    this.quickTestUrl,
    this.latestTag,
  });

  final String projectName;
  final CompareInfo compare;
  final String summary;
  final String commitBody;
  final BumpLevel impact;
  final List<String> reasons;
  final List<QaChecklistItem> checklist;
  final List<ManualVerificationRow> manualVerification;
  final List<FileChangeGroup> fileGroups;
  final List<FileChange> relevantChanges;
  final int estimatedMinutes;
  final String goNoGoHint;
  final String riskLevel;
  final List<String> platformsAffected;
  final int testFilesChanged;
  final QaAudience audience;
  final QaSourceMode source;
  final Map<String, dynamic>? versionContext;
  final Map<String, dynamic>? codeUnderstanding;
  final List<String> ticketIds;
  final List<String> screenshotChecklist;
  final String? distributionHint;
  final String? quickTestUrl;
  final String? latestTag;

  Map<String, dynamic> toJson() => {
        'project_name': projectName,
        'compare': compare.toJson(),
        'summary': summary,
        'commit_body': commitBody,
        'impact': impact.name,
        'reasons': reasons,
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'manual_verification':
            manualVerification.map((r) => r.toJson()).toList(),
        'file_groups': fileGroups.map((g) => g.toJson()).toList(),
        'relevant_changes': relevantChanges
            .map((c) => {'status': c.status, 'path': c.path})
            .toList(),
        'estimated_minutes': estimatedMinutes,
        'go_no_go_hint': goNoGoHint,
        'risk_level': riskLevel,
        'platforms_affected': platformsAffected,
        'test_files_changed': testFilesChanged,
        'audience': audience.name,
        'source': source.name,
        if (versionContext != null) 'version_context': versionContext,
        if (codeUnderstanding != null) 'code_understanding': codeUnderstanding,
        'ticket_ids': ticketIds,
        'screenshot_checklist': screenshotChecklist,
        if (distributionHint != null) 'distribution_hint': distributionHint,
        if (quickTestUrl != null) 'quick_test_url': quickTestUrl,
        if (latestTag != null) 'latest_tag': latestTag,
      };
}

Future<QaReleaseNotesResult> generateQaReleaseNotes({
  required Directory projectRoot,
  String base = 'HEAD~1',
  String head = 'HEAD',
  QaAudience audience = QaAudience.qa,
  QaSourceMode sourceMode = QaSourceMode.auto,
}) async {
  if (sourceMode == QaSourceMode.codebase) {
    return _generateFromCodebase(
      projectRoot: projectRoot,
      audience: audience,
    );
  }

  final git = GitRunner(projectRoot);
  final canUseGit = await _canUseGitCompare(git, base);
  if (sourceMode == QaSourceMode.git && !canUseGit) {
    throw StateError(
      'Git compare unavailable — need a repo with at least 2 commits, '
      'or use source mode "codebase"',
    );
  }
  if (!canUseGit) {
    return _generateFromCodebase(
      projectRoot: projectRoot,
      audience: audience,
    );
  }

  return _generateFromGit(
    projectRoot: projectRoot,
    base: base,
    head: head,
    audience: audience,
  );
}

Future<bool> _canUseGitCompare(GitRunner git, String base) async {
  if (!await git.isGitRepository()) return false;
  try {
    await git.ensureCompareableHistory(base);
    return true;
  } on Object {
    return false;
  }
}

Future<QaReleaseNotesResult> _generateFromGit({
  required Directory projectRoot,
  required String base,
  required String head,
  required QaAudience audience,
}) async {
  final git = GitRunner(projectRoot);
  final range = await git.loadRange(base: base, head: head);

  final shortBase = await git.shortSha(range.baseSha);
  final shortHead = await git.shortSha(range.headSha);
  final relevant =
      range.changes.where((c) => !shouldIgnorePath(c.path)).toList();

  final classification = classifyCommit(
    range.headSubject,
    range.headBody,
    range.changes,
    range.diff,
  );

  final projectName = readProjectPackageName(projectRoot);
  final platforms = _detectPlatforms(relevant);
  final testFilesChanged =
      relevant.where((c) => c.path.startsWith('test/')).length;
  final ticketIds = _extractTicketIds('${range.headSubject}\n${range.headBody}');
  final fileGroups = _groupChanges(relevant);
  final checklist = _buildChecklist(
    relevant: relevant,
    classification: classification,
    platforms: platforms,
    testFilesChanged: testFilesChanged,
    ticketIds: ticketIds,
  );
  final manualVerification = _buildManualVerification(checklist);
  final estimatedMinutes = (checklist.length * 5).clamp(5, 120);
  final riskLevel = _computeRiskLevel(
    classification.level,
    relevant.length,
    platforms,
  );
  final goNoGoHint = _computeGoNoGoHint(
    classification.level,
    relevant,
    platforms,
  );
  final screenshotChecklist = _buildScreenshotChecklist(relevant);
  final distributionHint = _distributionHint(classification.level, platforms);
  final compareUrl = await _buildCompareUrl(git, range.baseSha, range.headSha);
  final prUrl = await git.tryFindPullRequestUrl();
  final branch = await git.currentBranch();
  final latestTag = await git.latestTagName();
  final quickTestUrl =
      '/quick-test?project=${Uri.encodeComponent(projectRoot.path)}&commit=$shortHead';

  Map<String, dynamic>? versionContext;
  try {
    if (File(p.join(projectRoot.path, 'release-toolkit.config.yaml'))
        .existsSync()) {
      final preview = await versionClassifyPreview(
        projectRoot: projectRoot,
        commit: head,
      );
      versionContext = {
        'bump': preview['bump'],
        'commit': preview['commit'],
        'subject': preview['subject'],
      };
    }
  } on Object {
    versionContext = null;
  }

  return QaReleaseNotesResult(
    projectName: projectName,
    compare: CompareInfo(
      baseRef: base,
      headRef: head,
      baseSha: range.baseSha,
      headSha: range.headSha,
      shortBase: shortBase,
      shortHead: shortHead,
      headAuthor: range.headAuthor,
      headDate: range.headDate,
      compareUrl: compareUrl,
      prUrl: prUrl,
      branch: branch,
    ),
    summary: range.headSubject,
    commitBody: range.headBody,
    impact: classification.level,
    reasons: classification.reasons,
    checklist: checklist,
    manualVerification: manualVerification,
    fileGroups: fileGroups,
    relevantChanges: relevant,
    estimatedMinutes: estimatedMinutes,
    goNoGoHint: goNoGoHint,
    riskLevel: riskLevel,
    platformsAffected: platforms,
    testFilesChanged: testFilesChanged,
    audience: audience,
    source: QaSourceMode.git,
    versionContext: versionContext,
    ticketIds: ticketIds,
    screenshotChecklist: screenshotChecklist,
    distributionHint: distributionHint,
    quickTestUrl: quickTestUrl,
    latestTag: latestTag,
  );
}

Future<QaReleaseNotesResult> _generateFromCodebase({
  required Directory projectRoot,
  required QaAudience audience,
}) async {
  final snapshot = analyzeCodebase(projectRoot);
  final relevant = snapshot.inventory
      .where((c) => !shouldIgnorePath(c.path))
      .toList();
  final classification = Classification(
    reasons: [
      'codebase snapshot — ${snapshot.dartFiles.length} Dart file(s) scanned',
      if (snapshot.featureModules.isNotEmpty)
        'feature modules: ${snapshot.featureModules.join(', ')}',
    ],
  );
  final checklist = _buildChecklistFromCodebase(snapshot);
  final manualVerification = _buildManualVerification(checklist);
  final estimatedMinutes = (checklist.length * 5).clamp(10, 180);
  const riskLevel = 'medium';
  const goNoGoHint =
      'Exploratory QA recommended — scope inferred from code, not git diff';
  final screenshotChecklist = snapshot.screens
      .map((s) => 'Capture screenshots for $s during exploratory pass')
      .toList();
  final fileGroups = _groupChanges(relevant);
  final now = DateTime.now().toIso8601String().split('T').first;

  return QaReleaseNotesResult(
    projectName: snapshot.projectName,
    compare: CompareInfo(
      baseRef: 'codebase',
      headRef: 'workspace',
      baseSha: '—',
      headSha: 'snapshot',
      shortBase: 'code',
      shortHead: 'scan',
      headAuthor: 'Toolkit code scan',
      headDate: now,
    ),
    summary: snapshot.roughPurpose,
    commitBody: snapshot.understandingNotes.join('\n'),
    impact: classification.level,
    reasons: classification.reasons,
    checklist: checklist,
    manualVerification: manualVerification,
    fileGroups: fileGroups,
    relevantChanges: relevant,
    estimatedMinutes: estimatedMinutes,
    goNoGoHint: goNoGoHint,
    riskLevel: riskLevel,
    platformsAffected: snapshot.platforms,
    testFilesChanged: snapshot.testFiles.length,
    audience: audience,
    source: QaSourceMode.codebase,
    codeUnderstanding: snapshot.toJson(),
    screenshotChecklist: screenshotChecklist,
    distributionHint: _distributionHint(classification.level, snapshot.platforms),
    quickTestUrl:
        '/quick-test?project=${Uri.encodeComponent(projectRoot.path)}',
  );
}

List<QaChecklistItem> _buildChecklistFromCodebase(CodebaseSnapshot snapshot) {
  final items = <QaChecklistItem>[];

  for (final feature in snapshot.featureModules) {
    items.add(QaChecklistItem(
      area: 'Features',
      item:
          'Explore and smoke test the $feature module (inferred from lib/features/)',
      priority: 'High',
      platform: 'All',
    ));
  }
  for (final screen in snapshot.screens.take(12)) {
    items.add(QaChecklistItem(
      area: 'UI',
      item: 'Open $screen and verify primary user flow',
      priority: 'High',
      platform: 'All',
    ));
  }
  if (snapshot.routes.isNotEmpty) {
    items.add(QaChecklistItem(
      area: 'Navigation',
      item:
          'Walk routes (${snapshot.routes.take(5).join(', ')}) — confirm navigation works',
      priority: 'Medium',
      platform: 'All',
    ));
  }
  if (snapshot.keyDependencies.contains('firebase_auth') ||
      snapshot.keyDependencies.contains('firebase_core')) {
    items.add(const QaChecklistItem(
      area: 'Auth',
      item: 'Verify sign-in / sign-out and session persistence',
      priority: 'High',
      platform: 'All',
    ));
  }
  if (snapshot.keyDependencies.any((d) => d == 'dio' || d == 'http')) {
    items.add(const QaChecklistItem(
      area: 'Networking',
      item: 'Exercise API-backed screens with good and poor connectivity',
      priority: 'Medium',
      platform: 'All',
    ));
  }
  for (final platform in snapshot.platforms) {
    if (platform == 'Dart/UI') continue;
    items.add(QaChecklistItem(
      area: 'Platform',
      item: 'Build, install, and smoke test on $platform',
      priority: 'High',
      platform: platform,
    ));
  }
  if (snapshot.testFiles.isNotEmpty) {
    items.add(QaChecklistItem(
      area: 'Automated tests',
      item:
          'Run `flutter test` — ${snapshot.testFiles.length} test file(s) in project',
      priority: 'Medium',
      platform: 'All',
    ));
  }
  items.add(const QaChecklistItem(
    area: 'Exploratory',
    item:
        'Record unknown behavior — no git history; purpose inferred from code layout',
    priority: 'Medium',
    platform: 'All',
  ));
  if (items.length <= 1) {
    items.insert(
      0,
      const QaChecklistItem(
        area: 'General',
        item: 'Launch app and run a full smoke pass on critical paths',
        priority: 'High',
        platform: 'All',
      ),
    );
  }
  return items;
}

List<String> _detectPlatforms(List<FileChange> changes) {
  final platforms = <String>{};
  for (final change in changes) {
    final path = change.path;
    if (path.startsWith('android/')) platforms.add('Android');
    if (path.startsWith('ios/')) platforms.add('iOS');
    if (path.startsWith('web/')) platforms.add('Web');
    if (path.startsWith('macos/') ||
        path.startsWith('windows/') ||
        path.startsWith('linux/')) {
      platforms.add('Desktop');
    }
    if (path.startsWith('lib/')) platforms.add('Dart/UI');
  }
  if (platforms.isEmpty) platforms.add('Dart/UI');
  return platforms.toList()..sort();
}

List<FileChangeGroup> _groupChanges(List<FileChange> changes) {
  final buckets = <String, List<FileChange>>{};
  for (final change in changes) {
    final label = _areaLabel(change.path);
    buckets.putIfAbsent(label, () => []).add(change);
  }
  const order = [
    'Features',
    'App / tests',
    'Platform',
    'Config & dependencies',
    'Docs',
    'Other',
  ];
  return order
      .where((label) => buckets.containsKey(label))
      .map((label) => FileChangeGroup(label: label, changes: buckets[label]!))
      .toList();
}

String _areaLabel(String path) {
  if (path.startsWith('lib/features/')) return 'Features';
  if (path.startsWith('lib/') || path.startsWith('test/')) return 'App / tests';
  if (path.startsWith('android/') ||
      path.startsWith('ios/') ||
      path.startsWith('macos/') ||
      path.startsWith('windows/') ||
      path.startsWith('linux/') ||
      path.startsWith('web/')) {
    return 'Platform';
  }
  if (path == 'pubspec.yaml' ||
      path.contains('.env') ||
      path.contains('release-toolkit') ||
      path.contains('config')) {
    return 'Config & dependencies';
  }
  if (path.startsWith('doc/') ||
      path.startsWith('docs/') ||
      path.endsWith('.md')) {
    return 'Docs';
  }
  return 'Other';
}

List<QaChecklistItem> _buildChecklist({
  required List<FileChange> relevant,
  required Classification classification,
  required List<String> platforms,
  required int testFilesChanged,
  required List<String> ticketIds,
}) {
  final items = <QaChecklistItem>[];
  final ticket = ticketIds.isNotEmpty ? ticketIds.first : null;

  final featureNames = <String>{};
  for (final change in relevant) {
    final match = RegExp(r'^lib/features/([^/]+)/').firstMatch(change.path);
    if (match != null) featureNames.add(match.group(1)!);
  }
  for (final feature in featureNames) {
    items.add(QaChecklistItem(
      area: 'Features',
      item: 'Smoke test the $feature feature flows',
      priority: 'High',
      platform: 'All',
      ticketId: ticket,
    ));
  }

  if (relevant.any((c) => c.path.startsWith('android/'))) {
    items.add(const QaChecklistItem(
      area: 'Platform',
      item: 'Build, install, and smoke test on Android',
      priority: 'High',
      platform: 'Android',
    ));
  }
  if (relevant.any((c) => c.path.startsWith('ios/'))) {
    items.add(const QaChecklistItem(
      area: 'Platform',
      item: 'Build, install, and smoke test on iOS',
      priority: 'High',
      platform: 'iOS',
    ));
  }
  if (relevant.any((c) =>
      c.path.startsWith('macos/') ||
      c.path.startsWith('windows/') ||
      c.path.startsWith('linux/'))) {
    items.add(const QaChecklistItem(
      area: 'Platform',
      item: 'Build and smoke test desktop target',
      priority: 'Medium',
      platform: 'Desktop',
    ));
  }
  if (relevant.any((c) => c.path == 'pubspec.yaml')) {
    items.add(const QaChecklistItem(
      area: 'Dependencies',
      item: 'Run app after dependency changes; check for runtime regressions',
      priority: 'High',
      platform: 'All',
    ));
  }
  if (testFilesChanged > 0) {
    items.add(QaChecklistItem(
      area: 'Automated tests',
      item: 'Run `dart test` — $testFilesChanged test file(s) changed',
      priority: 'Medium',
      platform: 'All',
    ));
  }
  if (relevant.every((c) =>
      c.path.startsWith('doc/') ||
      c.path.startsWith('docs/') ||
      c.path.endsWith('.md'))) {
    items.add(const QaChecklistItem(
      area: 'Docs',
      item: 'Documentation-only change — light smoke OK',
      priority: 'Low',
      platform: 'All',
    ));
  }
  if (classification.level == BumpLevel.major) {
    items.add(const QaChecklistItem(
      area: 'Regression',
      item: 'Extended regression — breaking change detected',
      priority: 'Critical',
      platform: 'All',
    ));
  }
  if (items.isEmpty) {
    items.add(const QaChecklistItem(
      area: 'General',
      item: 'Run standard app smoke test on affected platforms',
      priority: 'Medium',
      platform: 'All',
    ));
  }
  return items;
}

List<ManualVerificationRow> _buildManualVerification(List<QaChecklistItem> checklist) {
  return checklist
      .map(
        (item) => ManualVerificationRow(
          criterion: item.item,
          steps: 'Follow the ${item.area.toLowerCase()} path on ${item.platform}',
          expected: 'No crashes; behavior matches release intent',
        ),
      )
      .toList();
}

String _computeRiskLevel(
  BumpLevel impact,
  int fileCount,
  List<String> platforms,
) {
  if (impact == BumpLevel.major || fileCount > 15 || platforms.length > 2) {
    return 'high';
  }
  if (impact == BumpLevel.minor || fileCount > 5 || platforms.length > 1) {
    return 'medium';
  }
  return 'low';
}

String _computeGoNoGoHint(
  BumpLevel impact,
  List<FileChange> relevant,
  List<String> platforms,
) {
  final docsOnly = relevant.isNotEmpty &&
      relevant.every((c) =>
          c.path.startsWith('doc/') ||
          c.path.startsWith('docs/') ||
          c.path.endsWith('.md'));
  if (docsOnly) return 'Light smoke OK — documentation-only changes';
  if (impact == BumpLevel.major) {
    return 'Extended regression required before Go';
  }
  if (platforms.contains('Android') || platforms.contains('iOS')) {
    return 'Platform build + install smoke test recommended';
  }
  return 'Standard smoke test recommended';
}

List<String> _buildScreenshotChecklist(List<FileChange> relevant) {
  return relevant
      .where((c) =>
          c.path.startsWith('lib/') &&
          (c.path.contains('/presentation/') ||
              c.path.contains('/widgets/') ||
              c.path.contains('_page.dart')))
      .map((c) => 'Capture before/after screenshots for ${c.path}')
      .toList();
}

String? _distributionHint(BumpLevel impact, List<String> platforms) {
  if (platforms.contains('iOS')) {
    if (impact == BumpLevel.major) {
      return 'TestFlight — extended QA before wider rollout';
    }
    return 'TestFlight internal testing recommended';
  }
  if (platforms.contains('Android')) {
    if (impact.rank >= BumpLevel.minor.rank) {
      return 'Firebase App Distribution or Play internal track';
    }
    return 'Firebase App Distribution or internal APK share';
  }
  return null;
}

List<String> _extractTicketIds(String text) {
  return RegExp(r'\b[A-Z][A-Z0-9]+-\d+\b')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toSet()
      .toList();
}

Future<String?> _buildCompareUrl(
  GitRunner git,
  String baseSha,
  String headSha,
) async {
  final remote = await git.remoteUrl('origin');
  if (remote == null) return null;
  final match = RegExp(
    r'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)',
  ).firstMatch(remote);
  if (match == null) return null;
  final owner = match.namedGroup('owner');
  final repo = match.namedGroup('repo');
  return 'https://github.com/$owner/$repo/compare/$baseSha...$headSha';
}

/// Resolve compare base ref: `HEAD~1` or latest tag if requested.
Future<String> resolveCompareBase(
  Directory projectRoot, {
  String mode = 'head~1',
}) async {
  if (mode == 'last_tag') {
    final git = GitRunner(projectRoot);
    final tag = await git.latestTagName();
    if (tag == null) {
      throw StateError('No git tags found — use HEAD~1 compare instead');
    }
    return tag;
  }
  return 'HEAD~1';
}
