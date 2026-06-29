import 'dart:convert';

import 'git_auth.dart';

/// Git remote location for cloning a Flutter project.
class GitRemoteSource {
  const GitRemoteSource({
    required this.url,
    this.ref = 'main',
    this.subdir = '',
    this.auth = GitAuthMode.ssh,
    this.token,
  });

  factory GitRemoteSource.fromJson(Map<String, dynamic> json) {
    return GitRemoteSource(
      url: (json['url'] as String? ?? '').trim(),
      ref: (json['ref'] as String? ?? 'main').trim(),
      subdir: (json['subdir'] as String? ?? '').trim(),
      auth: GitAuthMode.parse(json['auth'] as String?) ?? GitAuthMode.ssh,
      token: json['token'] as String?,
    );
  }

  final String url;
  final String ref;
  final String subdir;
  final GitAuthMode auth;
  final String? token;

  void validate() {
    if (url.isEmpty) {
      throw ArgumentError('Git source url is required');
    }
    if (auth == GitAuthMode.httpsToken &&
        (token == null || token!.trim().isEmpty)) {
      throw ArgumentError(
        'Private HTTPS repository requires a token for this session',
      );
    }
  }

  /// Stable cache directory name (no secrets).
  String get cacheKey {
    final normalized = url
        .replaceAll(RegExp(r'\.git$'), '')
        .replaceAll(RegExp(r'^git@([^:]+):'), r'https://$1/')
        .toLowerCase();
    final bytes = utf8.encode('$normalized|$ref');
    var hash = 0;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

  /// URL passed to git (may embed token — never log this).
  String authenticatedUrl() {
    if (auth != GitAuthMode.httpsToken || token == null || token!.isEmpty) {
      return url;
    }
    final trimmed = url.trim();
    if (!trimmed.startsWith('https://')) {
      throw ArgumentError('HTTPS token auth requires an https:// repository URL');
    }
    final withoutScheme = trimmed.substring('https://'.length);
    return 'https://x-access-token:${token!.trim()}@$withoutScheme';
  }

  Map<String, dynamic> toJson({bool includeSecrets = false}) => {
        'type': 'git',
        'url': url,
        'ref': ref,
        if (subdir.isNotEmpty) 'subdir': subdir,
        'auth': auth.id,
        if (includeSecrets && token != null) 'token': token,
      };
}
