import 'dart:convert';
import 'dart:io';

import '../flutter_tools.dart';
import '../env/env_source.dart';

enum DevicePlatform { android, ios }

class ConnectedDevice {
  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.available = true,
    this.isSimulator = false,
  });

  final String id;
  final String name;
  final DevicePlatform platform;
  final bool available;
  final bool isSimulator;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform.name,
        'available': available,
        'is_simulator': isSimulator,
      };
}

/// Parses `flutter devices --machine` JSON output.
List<ConnectedDevice> parseFlutterDevicesMachine(String jsonText) {
  if (jsonText.trim().isEmpty) return const [];
  final dynamic decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];

  final devices = <ConnectedDevice>[];
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final id = entry['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    final name = entry['name']?.toString() ?? id;
    final platformRaw = entry['targetPlatform']?.toString().toLowerCase() ?? '';
    final platform = switch (platformRaw) {
      'android' || 'android-arm' || 'android-arm64' || 'android-x64' =>
        DevicePlatform.android,
      'ios' => DevicePlatform.ios,
      _ => null,
    };
    if (platform == null) continue;
    final available = entry['isSupported'] != false;
    final isSimulator = entry['emulator'] == true;
    devices.add(
      ConnectedDevice(
        id: id,
        name: name,
        platform: platform,
        available: available,
        isSimulator: isSimulator,
      ),
    );
  }
  return devices;
}

/// Parses `adb devices` output (fallback when flutter devices fails).
List<ConnectedDevice> parseAdbDevices(String output) {
  final devices = <ConnectedDevice>[];
  for (final line in output.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final id = parts[0];
    final state = parts[1];
    devices.add(
      ConnectedDevice(
        id: id,
        name: id,
        platform: DevicePlatform.android,
        available: state == 'device',
      ),
    );
  }
  return devices;
}

class DeviceService {
  DeviceService({FlutterCommand Function()? flutterDetector})
      : _flutterDetector = flutterDetector ?? detectFlutter;

  final FlutterCommand Function() _flutterDetector;
  Process? _activeProcess;

  Future<void> cancel() async {
    _activeProcess?.kill(ProcessSignal.sigterm);
    _activeProcess = null;
  }

  Future<List<ConnectedDevice>> listConnectedDevices() async {
    try {
      final flutter = _flutterDetector();
      final result = await Process.run(
        flutter.executable,
        flutter.buildArgs(['devices', '--machine']),
      );
      if (result.exitCode == 0) {
        final devices = parseFlutterDevicesMachine(result.stdout.toString());
        if (devices.isNotEmpty) return devices;
      }
    } on Object {
      // Fall through to adb.
    }

    if (_which('adb') == null) return const [];
    final adbResult = await Process.run('adb', ['devices']);
    if (adbResult.exitCode != 0) return const [];
    return parseAdbDevices(adbResult.stdout.toString());
  }

  Future<void> installAndroidApk({
    required String deviceId,
    required String apkPath,
    void Function(String line)? onLog,
  }) async {
    if (_which('adb') == null) {
      throw StateError('adb not found on PATH — install Android SDK platform-tools.');
    }
    final apk = File(apkPath);
    if (!apk.existsSync()) {
      throw StateError('APK not found: $apkPath');
    }
    onLog?.call('Installing APK on $deviceId…');
    final result = await Process.run(
      'adb',
      ['-s', deviceId, 'install', '-r', apk.path],
    );
    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();
    if (stdout.isNotEmpty) onLog?.call(stdout);
    if (stderr.isNotEmpty) onLog?.call('[stderr] $stderr');
    if (result.exitCode != 0) {
      throw StateError(
        stderr.isEmpty
            ? 'adb install failed (exit ${result.exitCode})'
            : stderr,
      );
    }
    onLog?.call('Installed on $deviceId');
  }

  Future<void> installIosApp({
    required Directory projectRoot,
    required String deviceId,
    File? envFile,
    String? flavor,
    bool isSimulator = false,
    void Function(String line)? onLog,
  }) async {
    if (!Platform.isMacOS) {
      throw StateError('iOS device install requires macOS.');
    }
    final flutter = _flutterDetector();
    final defineArgs = dartDefineArgsFromEnvFile(envFile);

    // Simulators need iphonesimulator builds; --release iphoneos cannot install there.
    final buildArgs = <String>[
      'build',
      'ios',
      if (isSimulator) '--simulator' else '--release',
      if (flavor != null) ...['--flavor', flavor],
      ...defineArgs,
    ];
    await _runFlutterStreaming(
      projectRoot: projectRoot,
      flutter: flutter,
      args: buildArgs,
      onLog: onLog,
    );

    final installArgs = <String>[
      'install',
      '-d',
      deviceId,
      if (!isSimulator) '--release',
      if (flavor != null) ...['--flavor', flavor],
    ];
    await _runFlutterStreaming(
      projectRoot: projectRoot,
      flutter: flutter,
      args: installArgs,
      onLog: onLog,
    );
    onLog?.call(
      'Installed on iOS ${isSimulator ? 'simulator' : 'device'} $deviceId',
    );
  }

  Future<void> _runFlutterStreaming({
    required Directory projectRoot,
    required FlutterCommand flutter,
    required List<String> args,
    void Function(String line)? onLog,
  }) async {
    onLog?.call('> ${flutter.executable} ${flutter.buildArgs(args).join(' ')}');
    final process = await Process.start(
      flutter.executable,
      flutter.buildArgs(args),
      workingDirectory: projectRoot.path,
    );
    _activeProcess = process;

    final stdoutFuture = () async {
      await for (final line in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        onLog?.call(line);
      }
    }();
    final stderrFuture = () async {
      await for (final line in process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        onLog?.call('[stderr] $line');
      }
    }();

    await Future.wait([stdoutFuture, stderrFuture]);
    final exitCode = await process.exitCode;
    _activeProcess = null;
    if (exitCode != 0) {
      throw StateError('flutter ${args.first} exited with code $exitCode');
    }
  }
}

String? _which(String name) {
  final result = Process.runSync('which', [name]);
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}

bool adbAvailable() => _which('adb') != null;
