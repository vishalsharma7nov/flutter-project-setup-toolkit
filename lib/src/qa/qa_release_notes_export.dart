import 'dart:convert';

import 'package:excel/excel.dart';

import 'qa_release_notes.dart';

String exportQaMarkdown(QaReleaseNotesResult result) {
  switch (result.audience) {
    case QaAudience.pm:
      return _pmMarkdown(result);
    case QaAudience.executive:
      return _executiveMarkdown(result);
    case QaAudience.qa:
      return _qaMarkdown(result);
  }
}

String _qaMarkdown(QaReleaseNotesResult r) {
  final buf = StringBuffer();
  buf.writeln('# QA handoff — ${r.projectName}');
  buf.writeln();
  if (r.source == QaSourceMode.codebase) {
    buf.writeln('**Source:** Codebase scan (no git compare)  ');
  }
  buf.writeln(
    '**Compare:** `${r.compare.shortBase}` → `${r.compare.shortHead}`  ',
  );
  buf.writeln('**Date:** ${r.compare.headDate}  ');
  buf.writeln('**Author:** ${r.compare.headAuthor}  ');
  if (r.compare.branch != null) {
    buf.writeln('**Branch:** ${r.compare.branch}  ');
  }
  if (r.compare.compareUrl != null) {
    buf.writeln('**Compare:** ${r.compare.compareUrl}  ');
  }
  if (r.compare.prUrl != null) {
    buf.writeln('**PR:** ${r.compare.prUrl}  ');
  }
  buf.writeln();
  buf.writeln('## At a glance');
  buf.writeln('- **QA time estimate:** ~${r.estimatedMinutes} min');
  buf.writeln('- **Risk:** ${r.riskLevel}');
  buf.writeln('- **Go/No-Go:** ${r.goNoGoHint}');
  buf.writeln('- **Platforms:** ${r.platformsAffected.join(', ')}');
  buf.writeln('- **Impact:** ${r.impact.name}');
  if (r.distributionHint != null) {
    buf.writeln('- **Distribution:** ${r.distributionHint}');
  }
  if (r.quickTestUrl != null) {
    buf.writeln('- **Quick Test:** ${r.quickTestUrl}');
  }
  buf.writeln();
  buf.writeln('## Summary');
  buf.writeln(r.summary);
  if (r.commitBody.isNotEmpty) {
    buf.writeln();
    buf.writeln(r.commitBody);
  }
  if (r.codeUnderstanding != null) {
    buf.writeln();
    buf.writeln('## Code understanding (inferred)');
    final notes = r.codeUnderstanding!['understanding_notes'];
    if (notes is List) {
      for (final note in notes) {
        buf.writeln('- $note');
      }
    }
    final modules = r.codeUnderstanding!['feature_modules'];
    if (modules is List && modules.isNotEmpty) {
      buf.writeln();
      buf.writeln('**Modules:** ${modules.join(', ')}');
    }
    final screens = r.codeUnderstanding!['screens'];
    if (screens is List && screens.isNotEmpty) {
      buf.writeln('**Screens:** ${screens.join(', ')}');
    }
    final deps = r.codeUnderstanding!['key_dependencies'];
    if (deps is List && deps.isNotEmpty) {
      buf.writeln('**Dependencies:** ${deps.join(', ')}');
    }
  }
  buf.writeln();
  buf.writeln('## Impact');
  for (final reason in r.reasons) {
    buf.writeln('- $reason');
  }
  if (r.versionContext != null) {
    buf.writeln();
    buf.writeln(
      '_Version context: ${r.versionContext!['bump']} bump '
      '(${r.versionContext!['commit']})_',
    );
  }
  buf.writeln();
  buf.writeln('## Suggested QA checklist');
  for (final item in r.checklist) {
  buf.writeln(
      '- [ ] **${item.priority}** (${item.area}/${item.platform}) ${item.item}',
    );
  }
  buf.writeln();
  buf.writeln('## Manual verification');
  buf.writeln('| Criterion | Steps | Expected |');
  buf.writeln('| --- | --- | --- |');
  for (final row in r.manualVerification) {
    buf.writeln(
      '| ${_escapeMd(row.criterion)} | ${_escapeMd(row.steps)} | ${_escapeMd(row.expected)} |',
    );
  }
  if (r.screenshotChecklist.isNotEmpty) {
    buf.writeln();
    buf.writeln('## Screenshot checklist');
    for (final line in r.screenshotChecklist) {
      buf.writeln('- [ ] $line');
    }
  }
  if (r.ticketIds.isNotEmpty) {
    buf.writeln();
    buf.writeln('## Ticket traceability');
    buf.writeln(r.ticketIds.map((t) => '- $t').join('\n'));
  }
  buf.writeln();
  buf.writeln(
    r.source == QaSourceMode.codebase ? '## Project inventory' : '## Files changed',
  );
  for (final group in r.fileGroups) {
    buf.writeln();
    buf.writeln('### ${group.label}');
    buf.writeln('| Status | Path |');
    buf.writeln('| --- | --- |');
    for (final change in group.changes) {
      buf.writeln('| ${_statusLetter(change.status)} | `${change.path}` |');
    }
  }
  buf.writeln();
  buf.writeln('## Sign-off');
  buf.writeln('| Tester | Date | Result | Notes |');
  buf.writeln('| --- | --- | --- | --- |');
  buf.writeln('|  |  | Pass / Fail |  |');
  return buf.toString();
}

String _pmMarkdown(QaReleaseNotesResult r) {
  final buf = StringBuffer();
  buf.writeln('# Release summary — ${r.projectName}');
  buf.writeln();
  buf.writeln('`${r.compare.shortBase}` → `${r.compare.shortHead}` — ${r.summary}');
  buf.writeln();
  buf.writeln('**Impact:** ${r.impact.name} · **Risk:** ${r.riskLevel}');
  buf.writeln('**QA estimate:** ~${r.estimatedMinutes} min');
  buf.writeln('**Recommendation:** ${r.goNoGoHint}');
  buf.writeln();
  buf.writeln('### What changed');
  for (final group in r.fileGroups) {
    buf.writeln('- **${group.label}:** ${group.changes.length} file(s)');
  }
  buf.writeln();
  buf.writeln('### QA focus');
  for (final item in r.checklist.take(6)) {
    buf.writeln('- ${item.item}');
  }
  return buf.toString();
}

String _executiveMarkdown(QaReleaseNotesResult r) {
  return '''
# ${r.projectName} — release checkpoint

**Change:** ${r.summary}

**Verdict:** ${r.goNoGoHint}

**Risk:** ${r.riskLevel.toUpperCase()} · **Impact:** ${r.impact.name}

**Platforms:** ${r.platformsAffected.join(', ')}

**QA effort:** ~${r.estimatedMinutes} minutes
''';
}

String exportQaCsv(QaReleaseNotesResult result) {
  final rows = <List<String>>[
    ['#', 'Area', 'Checklist item', 'Priority', 'Platform', 'Status', 'Ticket'],
  ];
  var i = 1;
  for (final item in result.checklist) {
    rows.add([
      '$i',
      item.area,
      item.item,
      item.priority,
      item.platform,
      'Pending',
      item.ticketId ?? '',
    ]);
    i++;
  }
  return rows.map(_csvRow).join('\n');
}

String exportRegressionMatrixCsv(QaReleaseNotesResult result) {
  final features = <String>{'Core app'};
  for (final change in result.relevantChanges) {
    final match =
        RegExp(r'^lib/features/([^/]+)/').firstMatch(change.path);
    if (match != null) features.add(match.group(1)!);
  }
  final platforms = result.platformsAffected.isEmpty
      ? ['All']
      : result.platformsAffected;
  final rows = <List<String>>[
    ['Feature', ...platforms, 'Priority'],
  ];
  final priority = result.riskLevel == 'high' ? 'High' : 'Medium';
  for (final feature in features) {
    rows.add([feature, ...platforms.map((_) => 'Pending'), priority]);
  }
  return rows.map(_csvRow).join('\n');
}

String exportQaJson(QaReleaseNotesResult result) {
  return const JsonEncoder.withIndent('  ').convert(result.toJson());
}

String exportQaHtml(QaReleaseNotesResult result) {
  final riskColor = switch (result.riskLevel) {
    'high' => '#ff6b6b',
    'medium' => '#fdcb6e',
    _ => '#4ecdc4',
  };
  final checklistRows = result.checklist
      .map(
        (item) => '<tr><td>${_escapeHtml(item.area)}</td>'
            '<td>${_escapeHtml(item.item)}</td>'
            '<td>${_escapeHtml(item.priority)}</td>'
            '<td>${_escapeHtml(item.platform)}</td>'
            '<td>Pending</td></tr>',
      )
      .join();
  final fileRows = result.relevantChanges
      .map(
        (c) => '<tr><td>${_statusLetter(c.status)}</td>'
            '<td><code>${_escapeHtml(c.path)}</code></td></tr>',
      )
      .join();
  final manualRows = result.manualVerification
      .map(
        (r) => '<tr><td>${_escapeHtml(r.criterion)}</td>'
            '<td>${_escapeHtml(r.steps)}</td>'
            '<td>${_escapeHtml(r.expected)}</td></tr>',
      )
      .join();

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>QA handoff — ${_escapeHtml(result.projectName)}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      max-width: 960px; margin: 2rem auto; padding: 0 1rem; color: #1a1a2e; }
    h1 { font-size: 1.6rem; }
    .badges { display: flex; gap: 0.5rem; flex-wrap: wrap; margin: 1rem 0; }
    .badge { padding: 0.25rem 0.65rem; border-radius: 999px; font-size: 0.8rem; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }
    th, td { border: 1px solid #ddd; padding: 0.5rem; text-align: left; }
    th { background: #f4f6fb; }
    @media print { body { margin: 0; } }
  </style>
</head>
<body>
  <h1>QA handoff — ${_escapeHtml(result.projectName)}</h1>
  <p><strong>${result.compare.shortBase}</strong> → <strong>${result.compare.shortHead}</strong>
     · ${result.compare.headDate} · ${result.compare.headAuthor}</p>
  <div class="badges">
    <span class="badge" style="background:#e8f4ff">~${result.estimatedMinutes} min</span>
    <span class="badge" style="background:${riskColor}33;color:#333">Risk: ${result.riskLevel}</span>
    <span class="badge" style="background:#f0f0f0">${result.impact.name} impact</span>
  </div>
  <p><strong>Go/No-Go:</strong> ${_escapeHtml(result.goNoGoHint)}</p>
  <p><strong>Summary:</strong> ${_escapeHtml(result.summary)}</p>
  <h2>Checklist</h2>
  <table><thead><tr><th>Area</th><th>Item</th><th>Priority</th><th>Platform</th><th>Status</th></tr></thead>
  <tbody>$checklistRows</tbody></table>
  <h2>Manual verification</h2>
  <table><thead><tr><th>Criterion</th><th>Steps</th><th>Expected</th></tr></thead>
  <tbody>$manualRows</tbody></table>
  <h2>Files changed</h2>
  <table><thead><tr><th>Status</th><th>Path</th></tr></thead><tbody>$fileRows</tbody></table>
  <h2>Sign-off</h2>
  <table><thead><tr><th>Tester</th><th>Date</th><th>Result</th><th>Notes</th></tr></thead>
  <tbody><tr><td></td><td></td><td>Pass / Fail</td><td></td></tr></tbody></table>
</body>
</html>''';
}

List<int> exportQaXlsx(QaReleaseNotesResult result) {
  final excel = Excel.createExcel();
  final checklistSheet = excel['Checklist'];
  excel.delete('Sheet1');

  const checklistHeaders = [
    '#',
    'Area',
    'Checklist item',
    'Priority',
    'Platform',
    'Status',
    'Ticket',
  ];
  for (var c = 0; c < checklistHeaders.length; c++) {
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
        .value = TextCellValue(checklistHeaders[c]);
  }
  for (var i = 0; i < result.checklist.length; i++) {
    final item = result.checklist[i];
    final row = i + 1;
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = IntCellValue(i + 1);
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(item.area);
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        .value = TextCellValue(item.item);
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        .value = TextCellValue(item.priority);
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = TextCellValue(item.platform);
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        .value = TextCellValue('Pending');
    checklistSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
        .value = TextCellValue(item.ticketId ?? '');
  }

  final filesSheet = excel['Files changed'];
  filesSheet
      .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue('Status');
  filesSheet
      .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
      .value = TextCellValue('Path');
  filesSheet
      .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
      .value = TextCellValue('Area');
  for (var i = 0; i < result.relevantChanges.length; i++) {
    final change = result.relevantChanges[i];
    final row = i + 1;
    filesSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(_statusLetter(change.status));
    filesSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(change.path);
    filesSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        .value = TextCellValue(_areaLabelForExport(change.path));
  }

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('Failed to encode XLSX workbook');
  }
  return encoded;
}

String exportConfluenceWiki(QaReleaseNotesResult result) {
  final buf = StringBuffer();
  buf.writeln('h1. QA handoff — ${result.projectName}');
  buf.writeln();
  buf.writeln(
    '*Compare:* ${result.compare.shortBase} → ${result.compare.shortHead}',
  );
  buf.writeln('*Risk:* ${result.riskLevel} || *Impact:* ${result.impact.name}');
  buf.writeln('*Go/No-Go:* ${result.goNoGoHint}');
  buf.writeln();
  buf.writeln('h2. Summary');
  buf.writeln(result.summary);
  buf.writeln();
  buf.writeln('h2. Checklist');
  buf.writeln('||#||Area||Item||Priority||Platform||');
  var i = 1;
  for (final item in result.checklist) {
    buf.writeln(
      '|$i|${item.area}|${item.item}|${item.priority}|${item.platform}|',
    );
    i++;
  }
  return buf.toString();
}

String exportJiraComment(QaReleaseNotesResult result) {
  final buf = StringBuffer();
  buf.writeln('h3. QA handoff — ${result.projectName}');
  buf.writeln(
    '{color:grey}${result.compare.shortBase} → ${result.compare.shortHead}{color}',
  );
  buf.writeln();
  buf.writeln('*Summary:* ${result.summary}');
  buf.writeln('*Risk:* ${result.riskLevel} · *Impact:* ${result.impact.name}');
  buf.writeln('*Go/No-Go:* ${result.goNoGoHint}');
  buf.writeln();
  buf.writeln('*Checklist:*');
  for (final item in result.checklist) {
    buf.writeln('* (${item.priority}) ${item.item}');
  }
  return buf.toString();
}

/// TestRail test case import template (Title, Section, Steps, Expected Result).
String exportTestRailCsv(QaReleaseNotesResult result) {
  final rows = <List<String>>[
    ['Title', 'Section', 'Steps', 'Expected Result', 'Priority'],
  ];
  for (final item in result.checklist) {
    final manual = result.manualVerification
        .where((r) => r.criterion == item.item)
        .firstOrNull;
    rows.add([
      item.item,
      item.area,
      manual?.steps ?? item.item,
      manual?.expected ?? 'Pass',
      item.priority,
    ]);
  }
  return rows.map(_csvRow).join('\n');
}

/// Tuskr test case import template.
String exportTuskrCsv(QaReleaseNotesResult result) {
  final rows = <List<String>>[
    ['Name', 'Folder', 'Steps', 'Expected result', 'Priority'],
  ];
  for (final item in result.checklist) {
    rows.add([
      item.item,
      item.area,
      item.item,
      'No regressions',
      item.priority,
    ]);
  }
  return rows.map(_csvRow).join('\n');
}

String exportQaEml(QaReleaseNotesResult result) {
  final subject =
      'QA handoff: ${result.projectName} ${result.compare.shortHead}';
  final body = exportQaMarkdown(result);
  return '''
From: release-toolkit@local
To: qa-team@local
Subject: $subject
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

$body''';
}

String qaDownloadFilename(QaReleaseNotesResult result, String format) {
  final slug = result.projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final sha = result.compare.shortHead;
  final ext = switch (format) {
    'csv' => 'csv',
    'json' => 'json',
    'html' => 'html',
    'xlsx' => 'xlsx',
    'confluence' => 'wiki',
    'jira' => 'txt',
    'testrail' => 'csv',
    'tuskr' => 'csv',
    'regression' => 'csv',
    'eml' => 'eml',
    _ => 'md',
  };
  final suffix = format == 'testrail'
      ? 'testrail'
      : format == 'tuskr'
          ? 'tuskr'
          : format == 'regression'
              ? 'regression-matrix'
              : 'qa-handoff';
  return '${slug}_${suffix}_$sha.$ext';
}

(String contentType, List<int> bytes) encodeQaDownload(
  QaReleaseNotesResult result,
  String format,
) {
  switch (format) {
    case 'csv':
      return ('text/csv; charset=utf-8', utf8.encode(exportQaCsv(result)));
    case 'json':
      return (
        'application/json; charset=utf-8',
        utf8.encode(exportQaJson(result)),
      );
    case 'html':
      return ('text/html; charset=utf-8', utf8.encode(exportQaHtml(result)));
    case 'xlsx':
      return (
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        exportQaXlsx(result),
      );
    case 'confluence':
      return (
        'text/plain; charset=utf-8',
        utf8.encode(exportConfluenceWiki(result)),
      );
    case 'jira':
      return (
        'text/plain; charset=utf-8',
        utf8.encode(exportJiraComment(result)),
      );
    case 'testrail':
      return (
        'text/csv; charset=utf-8',
        utf8.encode(exportTestRailCsv(result)),
      );
    case 'tuskr':
      return (
        'text/csv; charset=utf-8',
        utf8.encode(exportTuskrCsv(result)),
      );
    case 'regression':
      return (
        'text/csv; charset=utf-8',
        utf8.encode(exportRegressionMatrixCsv(result)),
      );
    case 'eml':
      return (
        'message/rfc822',
        utf8.encode(exportQaEml(result)),
      );
    default:
      return ('text/markdown; charset=utf-8', utf8.encode(exportQaMarkdown(result)));
  }
}

String _statusLetter(String status) {
  if (status.isEmpty) return '?';
  return status[0].toUpperCase();
}

String _areaLabelForExport(String path) {
  if (path.startsWith('lib/features/')) return 'Features';
  if (path.startsWith('lib/') || path.startsWith('test/')) return 'App / tests';
  if (path.startsWith('android/') ||
      path.startsWith('ios/') ||
      path.startsWith('macos/') ||
      path.startsWith('windows/')) {
    return 'Platform';
  }
  return 'Other';
}

String _csvRow(List<String> cells) {
  return cells.map(_csvEscape).join(',');
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _escapeMd(String value) =>
    value.replaceAll('|', '\\|').replaceAll('\n', ' ');

String _escapeHtml(String value) => const HtmlEscape().convert(value);

class HtmlEscape {
  const HtmlEscape();
  String convert(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
