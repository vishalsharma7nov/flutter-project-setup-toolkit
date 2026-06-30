import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../git_runner.dart';
import '../qa/qa_release_notes.dart';
import '../qa/qa_release_notes_export.dart';
import '../qa/qa_release_notes_ui_html.dart';
import 'studio_http.dart';
import 'studio_nav.dart';
import 'studio_project_state.dart';

class QaStudioRoutes {
  QaStudioRoutes({StudioProjectState? projectState})
      : projectState = projectState ?? StudioProjectState();

  final StudioProjectState projectState;

  Future<bool> handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/qa') {
      StudioHttp.respondHtml(
        request.response,
        wrapStudioPage(qaReleaseNotesStudioHtml()),
      );
      await request.response.close();
      return true;
    }

    if (request.method == 'POST' && path == '/api/qa/preview') {
      try {
        final body = await StudioHttp.readJsonBody(request);
        final projectPath = body['project'] as String?;
        if (projectPath == null) {
          throw ArgumentError('project is required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        final baseMode = body['base_mode'] as String? ?? 'head~1';
        final sourceMode = QaSourceMode.parse(
          baseMode == 'codebase' ? 'codebase' : (body['source'] as String? ?? 'auto'),
        );
        final base = baseMode == 'codebase'
            ? 'HEAD~1'
            : await resolveCompareBase(root, mode: baseMode);
        final audience = QaAudience.parse(body['audience'] as String?);
        final result = await generateQaReleaseNotes(
          projectRoot: root,
          base: base,
          audience: audience,
          sourceMode: sourceMode,
        );
        StudioHttp.respondJson(request.response, 200, {
          ...result.toJson(),
          'markdown': exportQaMarkdown(result),
          'html_preview': exportQaHtml(result),
        });
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/qa/download') {
      try {
        final projectPath =
            request.uri.queryParameters['project'] ?? projectState.path;
        if (projectPath == null || projectPath.trim().isEmpty) {
          throw ArgumentError('project is required');
        }
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        final format = request.uri.queryParameters['format'] ?? 'md';
        final baseMode = request.uri.queryParameters['base_mode'] ?? 'head~1';
        final sourceMode = QaSourceMode.parse(
          baseMode == 'codebase'
              ? 'codebase'
              : (request.uri.queryParameters['source'] ?? 'auto'),
        );
        final base = baseMode == 'codebase'
            ? 'HEAD~1'
            : await resolveCompareBase(root, mode: baseMode);
        final audience =
            QaAudience.parse(request.uri.queryParameters['audience']);
        final result = await generateQaReleaseNotes(
          projectRoot: root,
          base: base,
          audience: audience,
          sourceMode: sourceMode,
        );
        final (contentType, bytes) = encodeQaDownload(result, format);
        final filename = qaDownloadFilename(result, format);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.parse(contentType)
          ..headers.set(
            'Content-Disposition',
            'attachment; filename="${filename.replaceAll('"', '')}"',
          )
          ..headers.set('Content-Length', '${bytes.length}')
          ..add(bytes);
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    if (request.method == 'GET' && path == '/api/qa/compare-options') {
      try {
        final projectPath =
            request.uri.queryParameters['project'] ?? projectState.path;
        if (projectPath == null || projectPath.trim().isEmpty) {
          StudioHttp.respondJson(request.response, 200, {'options': []});
          await request.response.close();
          return true;
        }
        final root = Directory(p.normalize(projectPath.trim()));
        validateFlutterProject(root);
        final git = GitRunner(root);
        final latestTag = await git.latestTagName();
        final canGit = await git.isGitRepository();
        final options = <Map<String, String>>[
          {
            'id': 'codebase',
            'label': 'Codebase scan (no git / exploratory QA)',
          },
        ];
        if (canGit) {
          options.add({'id': 'head~1', 'label': 'HEAD~1 → HEAD'});
          if (latestTag != null) {
            options.add({
              'id': 'last_tag',
              'label': '$latestTag → HEAD',
            });
          }
        }
        StudioHttp.respondJson(request.response, 200, {
          'options': options,
          'latest_tag': latestTag,
        });
      } on Object catch (e) {
        StudioHttp.respondJson(request.response, 400, {'error': '$e'});
      }
      await request.response.close();
      return true;
    }

    return false;
  }
}
