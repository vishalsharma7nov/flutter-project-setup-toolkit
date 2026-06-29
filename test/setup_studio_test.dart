import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/setup/setup_plan_codec.dart';
import 'package:flutter_project_setup_toolkit/src/setup/setup_studio_ui_html.dart';
import 'package:test/test.dart';

void main() {
  test('computeEnvPathsFromGui returns dev-prod paths', () {
    final paths = computeEnvPathsFromGui({
      'env_preset': 'dev-prod',
      'env_dir_style': 'dotEnv',
    });
    expect(paths.keys, containsAll(['dev', 'prod']));
    expect(paths['dev'], '.env/development.env');
    expect(paths['prod'], '.env/production.env');
  });

  test('setupPlanFromGuiMap builds a valid plan', () {
    final dir = Directory.systemTemp.createTempSync('rtk_setup_gui_');
    File('${dir.path}/pubspec.yaml').writeAsStringSync('name: test_app\n');
    addTearDown(() => dir.deleteSync(recursive: true));

    final plan = setupPlanFromGuiMap(dir, {
      'env_preset': 'dev-prod',
      'env_dir_style': 'dotEnv',
      'default_environment': 'dev',
      'toolkit_mode': 'devDependency',
      'create_env_templates': true,
      'create_scripts': true,
      'state_management': 'none',
    });

    expect(plan.defaultEnvironment, 'dev');
    expect(plan.environments['prod'], '.env/production.env');
    expect(plan.toolkitMode.name, 'devDependency');
  });

  test('setup studio HTML includes wizard steps', () {
    final html = setupStudioHtml();
    expect(html, contains('Setup Studio'));
    expect(html, contains('Environments'));
    expect(html, contains('Review &amp; apply'));
  });
}
