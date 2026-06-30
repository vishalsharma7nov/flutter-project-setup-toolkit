import 'package:flutter_project_setup_toolkit/src/git/git_remote_source.dart';
import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_source.dart';
import 'package:test/test.dart';

void main() {
  group('QuickTestSource', () {
    test('fromJson parses local source', () {
      final source = QuickTestSource.fromJson({
        'type': 'local',
        'path': '/Users/me/app',
      });
      expect(source.isLocal, isTrue);
      expect(source.toJson(), {
        'type': 'local',
        'path': '/Users/me/app',
      });
    });

    test('fromJson parses git source', () {
      final source = QuickTestSource.fromJson({
        'type': 'git',
        'url': 'https://github.com/org/app.git',
        'ref': 'main',
      });
      expect(source.isLocal, isFalse);
      expect(source.git?.url, 'https://github.com/org/app.git');
    });

    test('validate requires local path', () {
      const source = QuickTestSource.local('');
      expect(() => source.validate(), throwsArgumentError);
    });

    test('validate requires git url', () {
      const source = QuickTestSource.git(GitRemoteSource(url: ''));
      expect(() => source.validate(), throwsArgumentError);
    });
  });
}
