import 'dart:io';

import 'package:path/path.dart' as p;

Directory findProjectRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File(p.join(current.path, 'pubspec.yaml')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  try {
    final result = Process.runSync(
      'git',
      ['rev-parse', '--show-toplevel'],
      workingDirectory: start.path,
    );
    if (result.exitCode == 0) {
      final root = Directory(result.stdout.toString().trim());
      if (File(p.join(root.path, 'pubspec.yaml')).existsSync()) {
        return root.absolute;
      }
    }
  } on Exception {
    // git not available
  }
  return start.absolute;
}
