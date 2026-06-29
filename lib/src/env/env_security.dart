import 'dart:io';

/// Redact sensitive values for logs and API responses.
String redactEnvValue(String key, String value) {
  if (RegExp(r'KEY|SECRET|TOKEN|PASSWORD', caseSensitive: false).hasMatch(key)) {
    return '***';
  }
  return value;
}

String redactEnvLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty || trimmed.startsWith('#')) return line;
  final eq = trimmed.indexOf('=');
  if (eq <= 0) return line;
  final key = trimmed.substring(0, eq).trim();
  final value = trimmed.substring(eq + 1).trim();
  return '$key=${redactEnvValue(key, value)}';
}

bool isEnvPathTrackedByGit(Directory projectRoot, String relativeEnvPath) {
  final gitDir = Directory('${projectRoot.path}/.git');
  if (!gitDir.existsSync()) return false;
  final result = Process.runSync(
    'git',
    ['ls-files', '--error-unmatch', relativeEnvPath],
    workingDirectory: projectRoot.path,
  );
  return result.exitCode == 0;
}

void chmodPrivateFile(File file) {
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['600', file.path]);
  }
}
