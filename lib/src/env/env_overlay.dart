import 'dart:io';

import 'package:path/path.dart' as p;

import 'env_security.dart';

/// Session-scoped env file used for a single build.
class EnvOverlayFile {
  EnvOverlayFile(this.file, {required this.cleanup});

  final File file;
  final void Function() cleanup;
}

/// Writes env overlays under the toolkit cache (never into the project repo).
class EnvOverlayWriter {
  EnvOverlayWriter({String? root}) : _root = root ?? _defaultRoot();

  final String _root;

  static String _defaultRoot() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, '.cache', 'flutter-project-setup-toolkit', 'sessions');
    }
    return p.join(Directory.systemTemp.path, 'fpst-sessions');
  }

  EnvOverlayFile writeSessionOverlay({
    Map<String, String>? values,
    String? localFilePath,
    String? pasteContent,
  }) {
    if (values == null && localFilePath == null && pasteContent == null) {
      throw ArgumentError('env overlay requires values, local file, or paste content');
    }

    final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    final sessionDir = Directory(p.join(_root, sessionId));
    sessionDir.createSync(recursive: true);
    final overlay = File(p.join(sessionDir.path, 'overlay.env'));

    if (localFilePath != null && localFilePath.trim().isNotEmpty) {
      final source = File(localFilePath.trim());
      if (!source.existsSync()) {
        throw StateError('Env source file not found: ${source.path}');
      }
      overlay.writeAsStringSync(source.readAsStringSync());
    } else if (pasteContent != null && pasteContent.trim().isNotEmpty) {
      overlay.writeAsStringSync('${pasteContent.trim()}\n');
    } else if (values != null) {
      final buffer = StringBuffer();
      for (final entry in values.entries) {
        buffer.writeln('${entry.key}=${entry.value}');
      }
      overlay.writeAsStringSync(buffer.toString());
    }

    chmodPrivateFile(overlay);

    return EnvOverlayFile(
      overlay,
      cleanup: () {
        if (sessionDir.existsSync()) {
          sessionDir.deleteSync(recursive: true);
        }
      },
    );
  }
}
