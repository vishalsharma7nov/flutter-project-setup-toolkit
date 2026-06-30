import 'dart:io';

import 'ci_act_installer.dart';
import 'ci_features.dart';

Future<Map<String, dynamic>> detectCiTooling() async {
  final git = _which('git');
  final gh = _which('gh');
  final dockerForAct =
      ciActStudioEnabled ? await isDockerAvailableForAct() : false;

  var ghAuthOk = false;
  String? ghAuthHint;
  if (gh != null) {
    final result = await Process.run('gh', ['auth', 'status']);
    ghAuthOk = result.exitCode == 0;
    if (!ghAuthOk) {
      ghAuthHint = 'Run `gh auth login` to publish workflows via pull request';
    }
  } else {
    ghAuthHint = 'Install GitHub CLI: https://cli.github.com/';
  }

  return {
    'git': {'installed': git != null, 'path': git},
    'gh': {
      'installed': gh != null,
      'authenticated': ghAuthOk,
      'hint': ghAuthHint,
    },
    'act': {
      'enabled': ciActStudioEnabled,
      'installed': false,
      'on_demand': ciActStudioEnabled,
      'docker_available': dockerForAct,
      'version': actPinnedVersion,
      if (ciActStudioEnabled)
        'hint': dockerForAct
            ? 'act is downloaded automatically when you run Test with act, then removed'
            : 'Start Docker Desktop to run act tests (act is installed temporarily per test)',
    },
  };
}

Future<Map<String, dynamic>?> detectGitHubRemote(Directory projectRoot) async {
  final result = await Process.run(
    'git',
    ['remote', 'get-url', 'origin'],
    workingDirectory: projectRoot.path,
  );
  if (result.exitCode != 0) return null;
  final url = result.stdout.toString().trim();
  if (url.isEmpty) return null;

  final parsed = _parseGitHubRemote(url);
  if (parsed == null) {
    return {'url': url, 'is_github': false};
  }
  return {
    'url': url,
    'is_github': true,
    'owner': parsed.$1,
    'repo': parsed.$2,
  };
}

(String owner, String repo)? _parseGitHubRemote(String url) {
  final ssh = RegExp(r'git@github\.com:([^/]+)/(.+?)(?:\.git)?$');
  final https = RegExp(r'https://github\.com/([^/]+)/(.+?)(?:\.git)?$');
  RegExpMatch? match = ssh.firstMatch(url) ?? https.firstMatch(url);
  if (match == null) return null;
  var repo = match.group(2)!;
  if (repo.endsWith('.git')) {
    repo = repo.substring(0, repo.length - 4);
  }
  return (match.group(1)!, repo);
}

String? _which(String name) {
  final result = Process.runSync('which', [name]);
  if (result.exitCode != 0) return null;
  final path = result.stdout.toString().trim();
  return path.isEmpty ? null : path;
}
