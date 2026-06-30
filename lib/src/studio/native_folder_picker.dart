import 'dart:io';

/// Whether a native folder picker can be launched on this host OS.
bool nativeFolderPickerAvailable() {
  if (Platform.isMacOS) return true;
  if (Platform.isLinux) {
    return _which('zenity') != null || _which('kdialog') != null;
  }
  if (Platform.isWindows) return true;
  return false;
}

/// Opens the OS folder picker. Returns `null` when cancelled or unavailable.
Future<String?> pickNativeFolder({
  String prompt = 'Select Flutter project folder',
  String? initialDirectory,
}) async {
  if (Platform.isMacOS) {
    return _pickMacos(prompt: prompt, initialDirectory: initialDirectory);
  }
  if (Platform.isLinux) {
    return _pickLinux(prompt: prompt, initialDirectory: initialDirectory);
  }
  if (Platform.isWindows) {
    return _pickWindows(prompt: prompt, initialDirectory: initialDirectory);
  }
  return null;
}

Future<String?> _pickMacos({
  required String prompt,
  String? initialDirectory,
}) async {
  final escapedPrompt = prompt.replaceAll('"', '\\"');
  final initial = initialDirectory?.trim();
  final initialClause = initial != null && initial.isNotEmpty
      ? ' default location (POSIX file "$initial")'
      : '';
  final script = '''
tell application "Finder"
  activate
end tell
delay 0.2
set chosenFolder to choose folder with prompt "$escapedPrompt"$initialClause
return POSIX path of chosenFolder
''';
  final result = await Process.run('osascript', ['-e', script]);
  if (result.exitCode != 0) {
    final err = result.stderr.toString().trim();
    if (err.contains('User canceled') || err.contains('(-128)')) {
      return null;
    }
    throw StateError(
      err.isEmpty ? 'Folder picker failed (exit ${result.exitCode})' : err,
    );
  }
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}

Future<String?> _pickLinux({
  required String prompt,
  String? initialDirectory,
}) async {
  if (_which('zenity') != null) {
    final args = ['--file-selection', '--directory', '--title=$prompt'];
    final initial = initialDirectory?.trim();
    if (initial != null && initial.isNotEmpty) {
      args.add('--filename=$initial/');
    }
    final result = await Process.run('zenity', args);
    if (result.exitCode != 0) return null;
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }
  if (_which('kdialog') != null) {
    final args = ['--getexistingdirectory', initialDirectory ?? '.', '--title', prompt];
    final result = await Process.run('kdialog', args);
    if (result.exitCode != 0) return null;
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }
  return null;
}

Future<String?> _pickWindows({
  required String prompt,
  String? initialDirectory,
}) async {
  final escapedPrompt = prompt.replaceAll("'", "''");
  final initial = initialDirectory?.trim().replaceAll("'", "''") ?? '';
  final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
\$dialog.Description = '$escapedPrompt'
\$dialog.ShowNewFolderButton = \$false
if ('$initial' -ne '') { \$dialog.SelectedPath = '$initial' }
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output \$dialog.SelectedPath
}
''';
  final result = await Process.run(
    'powershell',
    ['-NoProfile', '-STA', '-Command', script],
    runInShell: true,
  );
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}

String? _which(String name) {
  final result = Process.runSync('which', [name]);
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}
