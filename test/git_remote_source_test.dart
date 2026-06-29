import 'package:flutter_project_setup_toolkit/src/git/git_auth.dart';
import 'package:flutter_project_setup_toolkit/src/git/git_remote_source.dart';
import 'package:test/test.dart';

void main() {
  test('GitRemoteSource cacheKey is stable for same url', () {
    const a = GitRemoteSource(url: 'git@github.com:org/app.git', ref: 'main');
    const b = GitRemoteSource(url: 'git@github.com:org/app.git', ref: 'main');
    expect(a.cacheKey, b.cacheKey);
  });

  test('GitRemoteSource validates empty url', () {
    const source = GitRemoteSource(url: '');
    expect(() => source.validate(), throwsArgumentError);
  });

  test('https token auth requires token', () {
    const source = GitRemoteSource(
      url: 'https://github.com/org/private.git',
      auth: GitAuthMode.httpsToken,
    );
    expect(() => source.validate(), throwsArgumentError);
  });

  test('authenticatedUrl embeds token for https', () {
    const source = GitRemoteSource(
      url: 'https://github.com/org/repo.git',
      auth: GitAuthMode.httpsToken,
      token: 'ghp_test',
    );
    expect(
      source.authenticatedUrl(),
      'https://x-access-token:ghp_test@github.com/org/repo.git',
    );
  });

  test('fromJson round trip without secrets', () {
    final json = GitRemoteSource(
      url: 'git@github.com:org/app.git',
      ref: 'develop',
      subdir: 'apps/mobile',
    ).toJson();
    final parsed = GitRemoteSource.fromJson(json);
    expect(parsed.url, 'git@github.com:org/app.git');
    expect(parsed.ref, 'develop');
    expect(parsed.subdir, 'apps/mobile');
  });
}
