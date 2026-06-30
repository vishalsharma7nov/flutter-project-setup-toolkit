import 'package:flutter_project_setup_toolkit/src/packages/git_package_validator.dart';
import 'package:flutter_project_setup_toolkit/src/packages/pub_package_service.dart';
import 'package:test/test.dart';

void main() {
  group('parseGitPackageInput', () {
    test('parses GitHub HTTPS URL', () {
      final parsed = parseGitPackageInput('https://github.com/flutter/flutter');
      expect(parsed?.url, 'https://github.com/flutter/flutter.git');
      expect(parsed?.ref, 'main');
      expect(parsed?.suggestedName, 'flutter');
    });

    test('parses GitHub URL with branch and monorepo path', () {
      final parsed = parseGitPackageInput(
        'https://github.com/org/repo/tree/develop/packages/foo',
      );
      expect(parsed?.url, 'https://github.com/org/repo.git');
      expect(parsed?.ref, 'develop');
      expect(parsed?.path, 'packages/foo');
      expect(parsed?.suggestedName, 'repo');
    });

    test('parses GitHub SSH URL', () {
      final parsed = parseGitPackageInput('git@github.com:org/my_pkg.git');
      expect(parsed?.url, 'https://github.com/org/my_pkg.git');
      expect(parsed?.suggestedName, 'my_pkg');
    });

    test('returns null for non-git input', () {
      expect(parseGitPackageInput('http'), isNull);
      expect(parseGitPackageInput(''), isNull);
    });
  });

  group('validatePubspecStructure', () {
    test('passes valid Dart package pubspec', () {
      final checks = validatePubspecStructure('''
name: my_package
description: A test package
environment:
  sdk: ">=3.5.0 <4.0.0"
''');
      expect(checks.every((c) => c.ok), isTrue);
      expect(checks.any((c) => c.id == 'package_name' && c.ok), isTrue);
    });

    test('fails when sdk constraint is missing', () {
      final checks = validatePubspecStructure('''
name: broken_pkg
description: no sdk
''');
      expect(checks.any((c) => c.id == 'sdk_constraint' && !c.ok), isTrue);
    });
  });

  group('buildGitPubAddArgs', () {
    test('includes git flags', () {
      expect(
        buildGitPubAddArgs(
          packageName: 'vendor_sdk',
          gitUrl: 'https://github.com/org/sdk.git',
          gitRef: 'v1.0.0',
          gitPath: 'packages/sdk',
        ),
        [
          'pub',
          'add',
          'vendor_sdk',
          '--git-url',
          'https://github.com/org/sdk.git',
          '--git-ref',
          'v1.0.0',
          '--git-path',
          'packages/sdk',
        ],
      );
    });
  });
}
