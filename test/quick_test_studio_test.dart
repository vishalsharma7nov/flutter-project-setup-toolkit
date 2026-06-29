import 'package:flutter_project_setup_toolkit/src/devices/device_service.dart';
import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_models.dart';
import 'package:flutter_project_setup_toolkit/src/quick_test/quick_test_ui_html.dart';
import 'package:test/test.dart';

void main() {
  group('parseFlutterDevicesMachine', () {
    test('parses android and ios devices', () {
      const json = '''
[
  {
    "name": "Pixel 7",
    "id": "emulator-5554",
    "targetPlatform": "android-arm64",
    "isSupported": true
  },
  {
    "name": "iPhone 17",
    "id": "343FA570-2A28-46C0-B9EF-43640D54A122",
    "targetPlatform": "ios",
    "emulator": true,
    "isSupported": true
  }
]
''';
      final devices = parseFlutterDevicesMachine(json);
      expect(devices, hasLength(2));
      expect(devices[0].platform, DevicePlatform.android);
      expect(devices[0].id, 'emulator-5554');
      expect(devices[1].platform, DevicePlatform.ios);
      expect(devices[1].isSimulator, isTrue);
    });

    test('returns empty for invalid json', () {
      expect(parseFlutterDevicesMachine('not json'), isEmpty);
      expect(parseFlutterDevicesMachine('{}'), isEmpty);
    });
  });

  group('parseAdbDevices', () {
    test('parses adb devices output', () {
      const output = '''
List of devices attached
emulator-5554\tdevice
offline-device\toffline
''';
      final devices = parseAdbDevices(output);
      expect(devices, hasLength(2));
      expect(devices[0].available, isTrue);
      expect(devices[1].available, isFalse);
    });
  });

  group('QuickTestJobState', () {
    test('serializes logs with offset', () {
      final state = QuickTestJobState(
        status: QuickTestJobStatus.running,
        logs: ['a', 'b', 'c'],
      );
      final json = state.toJson(logOffset: 1);
      expect(json['logs'], ['b', 'c']);
      expect(json['log_total'], 3);
    });
  });

  test('quick test studio HTML includes Git URL input and Run button', () {
    final html = quickTestStudioHtml();
    expect(html, contains('Quick Test Studio'));
    expect(html, contains('id="gitUrl"'));
    expect(html, contains('Install into Android'));
    expect(html, contains('Install into iOS'));
    expect(html, contains('Run quick test'));
    expect(html, contains('Check repo'));
    expect(html, contains('TestFlight IPA'));
  });
}
