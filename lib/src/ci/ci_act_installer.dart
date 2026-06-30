import 'dart:io';

import 'package:path/path.dart' as p;

/// Pinned [nektos/act](https://github.com/nektos/act) release for on-demand local tests.
const actPinnedVersion = '0.2.76';

/// Result of a temporary act install (removed after the test run).
class ActProvision {
  ActProvision({
    required this.binaryPath,
    required this.installDir,
  });

  final String binaryPath;
  final Directory installDir;
}

/// Whether Docker is available (required for act).
Future<bool> isDockerAvailableForAct() async {
  if (!Platform.isMacOS && !Platform.isLinux) {
    return false;
  }
  try {
    final result = await Process.run('docker', ['info']);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// GitHub release artifact name for the current OS/architecture.
String actArtifactName() {
  if (Platform.isMacOS) {
    return _isArm64() ? 'act_Darwin_arm64.tar.gz' : 'act_Darwin_x86_64.tar.gz';
  }
  if (Platform.isLinux) {
    return _isArm64() ? 'act_Linux_arm64.tar.gz' : 'act_Linux_x86_64.tar.gz';
  }
  throw UnsupportedError(
    'act local tests are supported on macOS and Linux only',
  );
}

String actDownloadUrl() {
  final artifact = actArtifactName();
  return 'https://github.com/nektos/act/releases/download/v$actPinnedVersion/$artifact';
}

/// Download and extract act into a temporary directory.
Future<ActProvision> provisionAct({
  void Function(String message)? log,
}) async {
  if (!Platform.isMacOS && !Platform.isLinux) {
    throw UnsupportedError(
      'act local tests are supported on macOS and Linux only',
    );
  }

  final installDir = Directory(
    p.join(
      Directory.systemTemp.path,
      'rtk-act-${DateTime.now().millisecondsSinceEpoch}',
    ),
  );
  await installDir.create(recursive: true);

  try {
    final tarFile = File(p.join(installDir.path, 'act.tar.gz'));
    final url = actDownloadUrl();
    log?.call('Downloading act v$actPinnedVersion from GitHub…');
    await _downloadFile(Uri.parse(url), tarFile);

    log?.call('Extracting act…');
    final tarResult = await Process.run('tar', [
      '-xzf',
      tarFile.path,
      '-C',
      installDir.path,
    ]);
    if (tarResult.exitCode != 0) {
      throw ProcessException(
        'tar',
        const [],
        tarResult.stderr.toString(),
        tarResult.exitCode,
      );
    }

    final binary = File(p.join(installDir.path, 'act'));
    if (!binary.existsSync()) {
      throw StateError('act binary not found after extract');
    }

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', binary.path]);
    }

    log?.call('act ready at ${binary.path} (temporary — removed after test)');
    return ActProvision(
      binaryPath: binary.path,
      installDir: installDir,
    );
  } on Object {
    if (installDir.existsSync()) {
      await installDir.delete(recursive: true);
    }
    rethrow;
  }
}

/// Remove a temporary act install created by [provisionAct].
Future<void> removeActProvision(ActProvision provision) async {
  if (provision.installDir.existsSync()) {
    await provision.installDir.delete(recursive: true);
  }
}

bool _isArm64() {
  final result = Process.runSync('uname', ['-m']);
  final arch = result.stdout.toString().trim();
  return arch == 'arm64' || arch == 'aarch64';
}

Future<void> _downloadFile(Uri url, File destination) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to download act: HTTP ${response.statusCode}',
        uri: url,
      );
    }
    final sink = destination.openWrite();
    try {
      await response.pipe(sink);
    } finally {
      await sink.close();
    }
  } finally {
    client.close(force: true);
  }
}
