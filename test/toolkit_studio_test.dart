import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/feature_scaffold.dart';
import 'package:flutter_project_setup_toolkit/src/feature/feature_studio_ui_html.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:flutter_project_setup_toolkit/src/studio/studio_hub_html.dart';
import 'package:test/test.dart';

void main() {
  test('hub HTML includes all workflow cards', () {
    final html = studioHubHtml();
    expect(html, contains('Flutter Project Setup Toolkit'));
    expect(html, contains('Setup flutter project'));
    expect(html, contains('Build APK'));
    expect(html, contains('Add feature'));
    expect(html, contains('/api/environment'));
    expect(html, contains('/api/project'));
  });

  test('feature studio HTML includes scaffold button', () {
    final html = featureStudioHtml();
    expect(html, contains('Feature Studio'));
    expect(html, contains('Scaffold feature'));
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
