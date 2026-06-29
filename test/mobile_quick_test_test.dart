import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_models.dart';
import 'package:flutter_project_setup_toolkit/src/studio/studio_bind.dart';
import 'package:test/test.dart';

void main() {
  group('parseStudioBindMode', () {
    test('defaults to loopback', () {
      expect(parseStudioBindMode(null), StudioBindMode.loopback);
      expect(parseStudioBindMode('loopback'), StudioBindMode.loopback);
    });

    test('parses lan aliases', () {
      expect(parseStudioBindMode('lan'), StudioBindMode.lan);
      expect(parseStudioBindMode('any'), StudioBindMode.lan);
    });
  });

  group('QuickTestRunOptions install_mode', () {
    test('defaults to host_adb', () {
      final options = QuickTestRunOptions.fromJson(const {});
      expect(options.installMode, QuickTestInstallMode.hostAdb);
    });

    test('parses client_download', () {
      final options = QuickTestRunOptions.fromJson(const {
        'install_mode': 'client_download',
        'platform': 'android',
      });
      expect(options.installMode, QuickTestInstallMode.clientDownload);
      expect(options.platform, QuickTestPlatform.android);
    });
  });

  group('quickTestArtifactPathAllowed', () {
    test('allows only listed artifact paths', () {
      final allowed = ['/tmp/build/app.apk'];
      expect(
        quickTestArtifactPathAllowed('/tmp/build/app.apk', allowed),
        isTrue,
      );
      expect(
        quickTestArtifactPathAllowed('/etc/passwd', allowed),
        isFalse,
      );
    });
  });

  group('QuickTestJobState artifact_urls', () {
    test('includes download urls in status json', () {
      final state = QuickTestJobState(
        artifactPaths: const ['/tmp/sample.apk'],
      );
      final json = state.toJson();
      expect(json['artifact_urls'], hasLength(1));
      expect(json['artifact_urls'][0], contains('/api/quick-test/artifacts/download'));
    });
  });

  group('quickTestArtifactContentType', () {
    test('maps apk and ipa', () {
      expect(
        quickTestArtifactContentType('/tmp/app.apk'),
        'application/vnd.android.package-archive',
      );
      expect(quickTestArtifactContentType('/tmp/app.ipa'), 'application/octet-stream');
    });
  });
}
