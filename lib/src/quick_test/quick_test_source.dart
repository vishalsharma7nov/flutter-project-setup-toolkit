import 'dart:io';

import 'package:path/path.dart' as p;

import '../git/git_clone_service.dart';
import '../git/git_remote_source.dart';

/// Git clone or local folder for Quick Test.
class QuickTestSource {
  const QuickTestSource._({
    required this.isLocal,
    this.git,
    this.localPath,
  });

  const QuickTestSource.git(GitRemoteSource source)
      : this._(isLocal: false, git: source);

  const QuickTestSource.local(String path)
      : this._(isLocal: true, localPath: path);

  factory QuickTestSource.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'git').trim().toLowerCase();
    if (type == 'local') {
      return QuickTestSource.local((json['path'] as String? ?? '').trim());
    }
    return QuickTestSource.git(GitRemoteSource.fromJson(json));
  }

  final bool isLocal;
  final GitRemoteSource? git;
  final String? localPath;

  void validate() {
    if (isLocal) {
      final path = localPath?.trim() ?? '';
      if (path.isEmpty) {
        throw ArgumentError('Local project path is required');
      }
      return;
    }
    git!.validate();
  }

  Map<String, dynamic> toJson({bool includeSecrets = false}) {
    if (isLocal) {
      return {
        'type': 'local',
        'path': localPath ?? '',
      };
    }
    return git!.toJson(includeSecrets: includeSecrets);
  }

  Future<Directory> resolve({GitCloneService? gitClone}) async {
    validate();
    if (isLocal) {
      final root = Directory(p.normalize(localPath!.trim()));
      if (!root.existsSync()) {
        throw ArgumentError('Project path does not exist: ${localPath!.trim()}');
      }
      return root;
    }
    final service = gitClone ?? GitCloneService();
    await service.verifyAccess(git!);
    return service.cloneOrUpdate(git!);
  }
}
