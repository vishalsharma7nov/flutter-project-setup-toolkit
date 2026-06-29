import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_target.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('isFlutterPluginProject', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('qt_plugin_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('detects flutter plugin pubspec', () {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: my_plugin
environment:
  sdk: ^3.0.0
  flutter: ">=3.0.0"
dependencies:
  flutter:
    sdk: flutter
flutter:
  plugin:
    platforms:
      android:
        package: com.example.my_plugin
        pluginClass: MyPlugin
      ios:
        pluginClass: MyPlugin
''');
      expect(isFlutterPluginProject(tempDir), isTrue);
    });

    test('returns false for plain Flutter app', () {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
''');
      expect(isFlutterPluginProject(tempDir), isFalse);
    });
  });

  group('resolveQuickTestTarget', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('qt_plugin_target_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('uses example/ app for plugins', () {
      _writePluginRoot(tempDir);
      _writeExampleApp(Directory(p.join(tempDir.path, 'example')), 'my_plugin');

      final target = resolveQuickTestTarget(tempDir);
      expect(target.isPlugin, isTrue);
      expect(
        target.buildRoot.path,
        p.join(tempDir.path, 'example'),
      );
    });

    test('throws when plugin has no example app', () {
      _writePluginRoot(tempDir);

      expect(
        () => resolveQuickTestTarget(tempDir),
        throwsA(isA<StateError>().having(
          (e) => e.toString(),
          'message',
          contains('example'),
        )),
      );
    });

    test('uses repo root for Flutter apps', () {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
''');
      Directory(p.join(tempDir.path, 'lib')).createSync();
      File(p.join(tempDir.path, 'lib', 'main.dart')).writeAsStringSync('void main() {}');

      final target = resolveQuickTestTarget(tempDir);
      expect(target.isPlugin, isFalse);
      expect(target.buildRoot.path, tempDir.path);
    });
  });
}

void _writePluginRoot(Directory dir) {
  File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: my_plugin
environment:
  sdk: ^3.0.0
  flutter: ">=3.0.0"
dependencies:
  flutter:
    sdk: flutter
flutter:
  plugin:
    platforms:
      android:
        package: com.example.my_plugin
        pluginClass: MyPlugin
      ios:
        pluginClass: MyPlugin
''');
  Directory(p.join(dir.path, 'lib')).createSync();
}

void _writeExampleApp(Directory exampleDir, String pluginName) {
  exampleDir.createSync();
  File(p.join(exampleDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: ${pluginName}_example
environment:
  sdk: ^3.0.0
  flutter: ">=3.0.0"
dependencies:
  flutter:
    sdk: flutter
  $pluginName:
    path: ../
flutter:
  uses-material-design: true
''');
  Directory(p.join(exampleDir.path, 'lib')).createSync();
  File(p.join(exampleDir.path, 'lib', 'main.dart')).writeAsStringSync('void main() {}');
  Directory(p.join(exampleDir.path, 'android')).createSync();
  Directory(p.join(exampleDir.path, 'ios')).createSync();
}
