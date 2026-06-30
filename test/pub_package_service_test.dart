import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/config.dart';
import 'package:flutter_project_setup_toolkit/src/packages/pub_package_service.dart';
import 'package:test/test.dart';

void main() {
  group('parsePackageInput', () {
    test('parses plain package name', () {
      final parsed = parsePackageInput('http');
      expect(parsed?.name, 'http');
      expect(parsed?.version, isNull);
    });

    test('parses name:version', () {
      final parsed = parsePackageInput('dio:5.4.0');
      expect(parsed?.name, 'dio');
      expect(parsed?.version, '5.4.0');
    });

    test('parses pub.dev package URL', () {
      final parsed = parsePackageInput('https://pub.dev/packages/flutter_bloc');
      expect(parsed?.name, 'flutter_bloc');
      expect(parsed?.version, isNull);
    });

    test('parses pub.dev URL without scheme', () {
      final parsed = parsePackageInput('pub.dev/packages/provider');
      expect(parsed?.name, 'provider');
    });

    test('parses versioned pub.dev URL', () {
      final parsed = parsePackageInput(
        'https://pub.dev/packages/http/versions/1.2.0',
      );
      expect(parsed?.name, 'http');
      expect(parsed?.version, '1.2.0');
    });

    test('returns null for invalid input', () {
      expect(parsePackageInput(''), isNull);
      expect(parsePackageInput('Not-A-Package'), isNull);
      expect(parsePackageInput('https://example.com/foo'), isNull);
    });
  });

  group('resolvePackageInput', () {
    test('resolves pub.dev package', () {
      final resolved = resolvePackageInput('http');
      expect(resolved?['source'], 'pub');
      expect(resolved?['name'], 'http');
    });

    test('resolves GitHub URL', () {
      final resolved = resolvePackageInput('https://github.com/org/my_pkg');
      expect(resolved?['source'], 'git');
      expect(resolved?['git_url'], 'https://github.com/org/my_pkg.git');
    });
  });

  group('buildPubAddArgs', () {
    test('regular dependency without version', () {
      expect(
        buildPubAddArgs(packageName: 'http'),
        ['pub', 'add', 'http'],
      );
    });

    test('dev dependency with version', () {
      expect(
        buildPubAddArgs(packageName: 'mockito', version: '5.4.0', dev: true),
        ['pub', 'add', '--dev', 'mockito:5.4.0'],
      );
    });
  });

  group('formatPubAddCommand', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('pub_pkg_test_');
      File('${project.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.5.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
''');
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('uses dart pub add for pure Dart project', () {
      File('${project.path}/pubspec.yaml').writeAsStringSync('''
name: sample_pkg
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      final command = formatPubAddCommand(
        projectRoot: project,
        packageName: 'http',
        dev: true,
      );
      expect(command, 'dart pub add --dev http');
    });

    test('uses flutter pub add for Flutter project when flutter is available', () {
      final which = Process.runSync('which', ['flutter']);
      if (which.exitCode != 0) {
        return;
      }
      expect(isFlutterSdkProject(project), isTrue);
      final command = formatPubAddCommand(
        projectRoot: project,
        packageName: 'provider',
      );
      expect(command, contains('pub add provider'));
    });
  });
}
