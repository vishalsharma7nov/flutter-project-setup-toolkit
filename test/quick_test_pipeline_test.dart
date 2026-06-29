import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/devices/device_service.dart';
import 'package:flutter_project_setup_toolkit/src/git/git_clone_service.dart';
import 'package:flutter_project_setup_toolkit/src/git/git_remote_source.dart';
import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_pipeline.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakeGitClone extends GitCloneService {
  _FakeGitClone(this.root);

  final Directory root;

  @override
  Future<void> verifyAccess(GitRemoteSource source) async {}

  @override
  Future<Directory> cloneOrUpdate(GitRemoteSource source) async => root;
}

class _FakeDeviceService extends DeviceService {
  _FakeDeviceService(this.devices);

  final List<ConnectedDevice> devices;

  @override
  Future<List<ConnectedDevice>> listConnectedDevices() async => devices;

  @override
  Future<void> installAndroidApk({
    required String deviceId,
    required String apkPath,
    void Function(String line)? onLog,
  }) async {
    onLog?.call('fake install android $deviceId');
  }
}

void main() {
  group('runQuickTestPreflight', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('qt_preflight_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('rejects non-Flutter repo', () async {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: plain_dart
environment:
  sdk: ">=3.0.0 <4.0.0"
''');

      await expectLater(
        runQuickTestPreflight(
          source: const GitRemoteSource(url: 'https://example.com/repo.git'),
          envName: 'dev',
          gitClone: _FakeGitClone(tempDir),
          deviceService: _FakeDeviceService(const []),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.toString(),
          'message',
          contains('not a Flutter app or plugin'),
        )),
      );
    });

    test('passes structure check for minimal Flutter app', () async {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
''');
      Directory(p.join(tempDir.path, 'lib')).createSync();
      File(p.join(tempDir.path, 'lib', 'main.dart')).writeAsStringSync('void main() {}');
      Directory(p.join(tempDir.path, 'android')).createSync();
      Directory(p.join(tempDir.path, 'ios')).createSync();
      File(p.join(tempDir.path, 'release-toolkit.config.json')).writeAsStringSync('''
{
  "environments": { "dev": ".env/dev.env" },
  "defaultEnvironment": "dev",
  "versionKeys": { "versionName": "VERSION_NAME", "versionCode": "VERSION_CODE" },
  "api": { "protocol": "rest", "baseUrlEnvKey": "API_BASE_URL" },
  "build": {}
}
''');
      File(p.join(tempDir.path, '.env', 'dev.env')).createSync(recursive: true);
      File(p.join(tempDir.path, '.env', 'dev.env')).writeAsStringSync('API_BASE_URL=https://api.test\n');

      final result = await runQuickTestPreflight(
        source: const GitRemoteSource(url: 'https://example.com/repo.git'),
        envName: 'dev',
        gitClone: _FakeGitClone(tempDir),
        deviceService: _FakeDeviceService(const [
          ConnectedDevice(
            id: 'emulator-5554',
            name: 'Emulator',
            platform: DevicePlatform.android,
          ),
        ]),
      );

      expect(result['flutter_ok'], isTrue);
      expect(result['env_ready'], isTrue);
      expect(result['devices'], hasLength(1));
    });

    test('preflight succeeds without env file or toolkit config', () async {
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
''');
      Directory(p.join(tempDir.path, 'lib')).createSync();
      File(p.join(tempDir.path, 'lib', 'main.dart')).writeAsStringSync('void main() {}');
      Directory(p.join(tempDir.path, 'android')).createSync();
      Directory(p.join(tempDir.path, 'ios')).createSync();

      final result = await runQuickTestPreflight(
        source: const GitRemoteSource(url: 'https://example.com/repo.git'),
        envName: 'dev',
        gitClone: _FakeGitClone(tempDir),
        deviceService: _FakeDeviceService(const []),
      );

      expect(result['flutter_ok'], isTrue);
      expect(result['env_ready'], isFalse);
      expect(result['can_run_without_env'], isTrue);
    });
  });
}
