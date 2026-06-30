import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/feature_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/feature/feature_studio_ui_html.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/qa/qa_release_notes_ui_html.dart';
import 'package:flutter_project_setup_toolkit/src/studio/environment_detect.dart';
import 'package:flutter_project_setup_toolkit/src/studio/studio_hub_html.dart';
import 'package:test/test.dart';

void main() {
  test('hub HTML includes all workflow cards', () {
    final html = studioHubHtml();
    expect(html, contains('Flutter Project Setup Toolkit'));
    expect(html, contains('Setup flutter project'));
    expect(html, contains('Build APK'));
    expect(html, contains('Add feature'));
    expect(html, contains('QA release notes'));
    expect(html, contains('Project documentation'));
    expect(html, contains('/docs'));
    expect(html, contains('/api/environment'));
    expect(html, contains('/api/project'));
  });

  test('feature studio HTML includes scaffold button', () {
    final html = featureStudioHtml();
    expect(html, contains('Feature Studio'));
    expect(html, contains('Scaffold feature'));
  });

  test('qa release notes studio HTML includes generate and download', () {
    final html = qaReleaseNotesStudioHtml();
    expect(html, contains('QA release notes'));
    expect(html, contains('/api/qa/preview'));
    expect(html, contains('downloadFormat'));
    expect(html, contains('Codebase scan'));
  });

  test('detectStudioEnvironment completes when docker is absent', () async {
    final env = await detectStudioEnvironment();
    expect(env['dart'], isA<Map<String, dynamic>>());
    expect(env['capabilities'], isA<Map<String, dynamic>>());
    expect(env['capabilities']!['ci_act'], isA<bool>());
  });

  test('previewFeatureScaffold lists bloc files', () {
    final dir = Directory.systemTemp.createTempSync('rtk_feature_preview_');
    File('${dir.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
    addTearDown(() => dir.deleteSync(recursive: true));

    final preview = previewFeatureScaffold(
      projectRoot: dir,
      featureName: 'auth',
      basePath: 'lib/features',
      stateManagement: StateManagement.bloc,
    );
    expect(preview['files'], isNotEmpty);
    expect(
      (preview['files'] as List).any((f) => '$f'.contains('bloc')),
      isTrue,
    );
  });
}
