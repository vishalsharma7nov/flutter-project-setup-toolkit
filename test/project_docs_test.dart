import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/docs/project_docs_context.dart';
import 'package:flutter_project_setup_toolkit/src/docs/project_docs_generators.dart';
import 'package:flutter_project_setup_toolkit/src/docs/project_docs_marker.dart';
import 'package:flutter_project_setup_toolkit/src/docs/project_docs_service.dart';
import 'package:flutter_project_setup_toolkit/src/docs/project_docs_spec.dart';
import 'package:flutter_project_setup_toolkit/src/docs/project_docs_ui_html.dart';
import 'package:flutter_project_setup_toolkit/src/studio/studio_hub_html.dart';
import 'package:test/test.dart';

Directory _createSampleProject() {
  final dir = Directory.systemTemp.createTempSync('rtk_docs_test_');
  File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
description: A sample Flutter app for documentation tests.
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.0.0
  go_router: ^14.0.0
''');
  File('${dir.path}/release-toolkit.config.json').writeAsStringSync('''
{
  "default_environment": "dev",
  "environments": {
    "dev": ".env/development.env"
  },
  "architecture": { "preset": "feature_first_clean" }
}
''');
  final featureDir = Directory('${dir.path}/lib/features/auth/presentation')
    ..createSync(recursive: true);
  File('${featureDir.path}/login_page.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold();
}
''');
  File('${dir.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
void main() => runApp(const MaterialApp(home: Text('hi')));
''');
  Directory('${dir.path}/test').createSync();
  File('${dir.path}/test/widget_test.dart')
      .writeAsStringSync("void main() {}");
  return dir;
}

void main() {
  test('generateReadme includes project name and quick start', () {
    final dir = _createSampleProject();
    addTearDown(() => dir.deleteSync(recursive: true));

    final ctx = gatherProjectDocsContext(dir);
    final readme = generateReadme(ctx);

    expect(readme, contains('# sample_app'));
    expect(readme, contains('flutter pub get'));
    expect(readme, contains(projectDocsGeneratedMarker));
  });

  test('generateArchitectureDoc mentions layers and preset', () {
    final dir = _createSampleProject();
    addTearDown(() => dir.deleteSync(recursive: true));

    final ctx = gatherProjectDocsContext(dir);
    final doc = generateArchitectureDoc(ctx);

    expect(doc, contains('Architecture'));
    expect(doc, contains('feature_first_clean'));
    expect(doc, contains('presentation'));
  });

  test('skipExisting does not overwrite pre-seeded README', () {
    final dir = _createSampleProject();
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/README.md').writeAsStringSync('# Custom README\n\nHand written.');

    final service = ProjectDocsService();
    final result = service.write(
      projectRoot: dir,
      spec: ProjectDocsSpec(
        overwritePolicy: ProjectDocsOverwritePolicy.skipExisting,
      ),
    );

    final written = result['written'] as List<dynamic>;
    expect(written, isNot(contains('README.md')));
    expect(File('${dir.path}/README.md').readAsStringSync(), contains('Custom README'));
    expect(written, contains('doc/architecture.md'));
  });

  test('overwriteAll replaces README', () {
    final dir = _createSampleProject();
    addTearDown(() => dir.deleteSync(recursive: true));

    File('${dir.path}/README.md').writeAsStringSync('# Old README');

    final service = ProjectDocsService();
    final result = service.write(
      projectRoot: dir,
      spec: ProjectDocsSpec(
        overwritePolicy: ProjectDocsOverwritePolicy.overwriteAll,
      ),
    );

    final written = result['written'] as List<dynamic>;
    expect(written, contains('README.md'));
    expect(
      File('${dir.path}/README.md').readAsStringSync(),
      contains('sample_app'),
    );
    expect(
      File('${dir.path}/README.md').readAsStringSync(),
      contains(projectDocsGeneratedMarker),
    );
  });

  test('refreshGenerated overwrites toolkit-generated files only', () {
    final dir = _createSampleProject();
    addTearDown(() => dir.deleteSync(recursive: true));

    final service = ProjectDocsService();
    service.write(projectRoot: dir, spec: ProjectDocsSpec.defaults());

    File('${dir.path}/doc/architecture.md')
        .writeAsStringSync('# Manual edit\n\nNo marker.');

    final result = service.write(
      projectRoot: dir,
      spec: ProjectDocsSpec(
        overwritePolicy: ProjectDocsOverwritePolicy.refreshGenerated,
      ),
    );

    final skipped = result['skipped'] as Map<String, dynamic>;
    expect(skipped.keys, contains('doc/architecture.md'));
    expect(
      File('${dir.path}/doc/README.md').readAsStringSync(),
      contains(projectDocsGeneratedMarker),
    );
  });

  test('hub HTML includes docs studio card', () {
    final html = studioHubHtml();
    expect(html, contains('Project documentation'));
    expect(html, contains('/docs'));
  });

  test('docs studio HTML includes preview and write APIs', () {
    final html = projectDocsStudioHtml();
    expect(html, contains('/api/docs/preview'));
    expect(html, contains('/api/docs/write'));
    expect(html, contains('Overwrite policy'));
  });
}
