import 'dart:io';

import 'package:path/path.dart' as p;

/// On-disk cache for cloned Git repositories.
class GitCache {
  GitCache({String? root}) : _root = root ?? _defaultRoot();

  final String _root;

  static String _defaultRoot() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return p.join(home, '.cache', 'flutter-project-setup-toolkit', 'git');
    }
    return p.join(Directory.systemTemp.path, 'fpst-git-cache');
  }

  String pathForKey(String cacheKey) => p.join(_root, cacheKey);

  Directory directoryForKey(String cacheKey) {
    final dir = Directory(pathForKey(cacheKey));
    dir.createSync(recursive: true);
    return dir;
  }
}
