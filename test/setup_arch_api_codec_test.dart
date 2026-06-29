import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/setup/setup_arch_api_codec.dart';
import 'package:flutter_project_setup_toolkit/src/setup/setup_plan_codec.dart';
import 'package:test/test.dart';

void main() {
  test('architectureConfigFromBody uses preset id', () {
    final arch = architectureConfigFromBody({
      'architecture_preset': 'layer_first_clean',
    });
    expect(arch.preset.id, 'layer_first_clean');
  });

  test('apiConfigFromBody parses external sdk', () {
    final api = apiConfigFromBody({
      'api_protocol': 'external_sdk',
      'external_sdk': {
        'package_name': 'vendor_sdk',
        'git': {'url': 'https://github.com/example/sdk.git'},
      },
    });
    expect(api.protocol.id, 'external_sdk');
    expect(api.externalSdk?.packageName, 'vendor_sdk');
  });

  test('setupPlanFromGuiMap includes architecture and api', () {
    final dir = Directory.systemTemp.createTempSync('fpst_setup_codec_');
    try {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      final plan = setupPlanFromGuiMap(dir, {
        'env_preset': 'dev-prod',
        'default_environment': 'dev',
        'architecture_preset': 'compass_mvvm',
        'api_protocol': 'graphql',
        'state_management': 'bloc',
      });
      expect(plan.architecture.preset.id, 'compass_mvvm');
      expect(plan.api.protocol.id, 'graphql');
      expect(plan.stateManagement.name, 'bloc');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
