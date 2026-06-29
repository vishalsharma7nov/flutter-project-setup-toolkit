import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/ios_xcode.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

IosXcodeProjectInfo _info(List<String> schemes) =>
    IosXcodeProjectInfo(schemes: schemes);

void main() {
  group('resolveIosFlutterFlavor', () {
    test('uses configured flavor when it matches an Xcode scheme', () {
      final resolution = resolveIosFlutterFlavor(
        info: _info(['Runner', 'staging']),
        configuredFlavor: 'staging',
        archiveScheme: 'Runner',
      );

      expect(resolution.flutterFlavor, 'staging');
      expect(resolution.error, isNull);
    });

    test('ignores invalid flavor when Runner scheme exists', () {
      final resolution = resolveIosFlutterFlavor(
        info: _info(['FlutterGeneratedPluginSwiftPackage', 'Runner']),
        configuredFlavor: 'UnknownFlavor',
        archiveScheme: 'Runner',
      );

      expect(resolution.flutterFlavor, isNull);
      expect(resolution.archiveScheme, 'Runner');
      expect(resolution.warning, contains('UnknownFlavor'));
      expect(resolution.error, isNull);
    });

    test('uses sole app scheme when Runner is absent', () {
      final resolution = resolveIosFlutterFlavor(
        info: _info(['staging']),
        configuredFlavor: 'UnknownFlavor',
        archiveScheme: 'staging',
      );

      expect(resolution.flutterFlavor, 'staging');
      expect(resolution.archiveScheme, 'staging');
    });

    test('uses archive scheme for multi-scheme projects without Runner', () {
      final resolution = resolveIosFlutterFlavor(
        info: _info(['staging', 'production']),
        configuredFlavor: null,
        archiveScheme: 'production',
      );

      expect(resolution.flutterFlavor, 'production');
      expect(resolution.error, isNull);
    });
  });

  group('resolveIosArchiveScheme', () {
    test('falls back to the only app scheme when configured scheme is missing', () {
      final resolution = resolveIosArchiveScheme(
        info: _info(['FlutterGeneratedPluginSwiftPackage', 'Runner']),
        configuredScheme: 'MissingScheme',
      );

      expect(resolution.scheme, 'Runner');
      expect(resolution.warning, contains('MissingScheme'));
      expect(resolution.error, isNull);
    });

    test('reports error when scheme is missing and multiple app schemes exist', () {
      final resolution = resolveIosArchiveScheme(
        info: _info(['staging', 'production']),
        configuredScheme: 'Runner',
      );

      expect(resolution.error, isNotNull);
    });
  });

  group('matchScheme', () {
    test('matches case-insensitively', () {
      final info = _info(['Runner', 'Release-Staging']);
      expect(info.matchScheme('runner'), 'Runner');
      expect(info.matchScheme('Staging'), isNull);
    });
  });

  group('detectIosBuildSettings', () {
    test('reads archive name from scheme file', () async {
      final temp = await Directory.systemTemp.createTemp('rtk_ios_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final xcodeproj = Directory(p.join(temp.path, 'ios', 'Demo.xcodeproj'));
      final schemesDir = Directory(
        p.join(xcodeproj.path, 'xcshareddata', 'xcschemes'),
      );
      await schemesDir.create(recursive: true);
      await File(p.join(schemesDir.path, 'Demo.xcscheme')).writeAsString('''
<Scheme>
  <ArchiveAction customArchiveName = "MyApp" buildConfiguration = "Release" />
</Scheme>
''');

      final detection = detectIosBuildSettings(temp);
      expect(detection?.suggestedScheme, 'Demo');
      expect(detection?.archiveName, 'MyApp');
    });
  });

  group('resolveConfiguredIosScheme', () {
    test('falls back to detected scheme when config is missing', () async {
      final temp = await Directory.systemTemp.createTemp('rtk_ios_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final xcodeproj = Directory(p.join(temp.path, 'ios', 'Custom.xcodeproj'));
      final schemesDir = Directory(
        p.join(xcodeproj.path, 'xcshareddata', 'xcschemes'),
      );
      await schemesDir.create(recursive: true);
      await File(p.join(schemesDir.path, 'Custom.xcscheme')).writeAsString('<Scheme/>');

      expect(
        resolveConfiguredIosScheme(projectRoot: temp, configuredScheme: 'Runner'),
        'Custom',
      );
    });
  });

  group('iosArchiveCandidateNames', () {
    test('prefers custom archive name', () {
      expect(
        iosArchiveCandidateNames(
          archiveScheme: 'Runner',
          customArchiveName: 'MyApp',
        ),
        contains('MyApp.xcarchive'),
      );
    });
  });
}
