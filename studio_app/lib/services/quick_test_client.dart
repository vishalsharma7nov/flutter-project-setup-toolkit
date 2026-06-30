import 'dart:io';

import 'studio_client.dart';

class QuickTestClient {
  QuickTestClient(this._client);

  final StudioClient _client;

  StudioClient get studioClient => _client;

  Future<Map<String, dynamic>> preflight({
    required Map<String, dynamic> source,
    String env = 'dev',
    Map<String, dynamic>? envSource,
  }) {
    return _client.postJson('/api/quick-test/preflight', {
      'source': source,
      'env': env,
      'env_source': ?envSource,
    });
  }

  Future<Map<String, dynamic>> run({
    required Map<String, dynamic> source,
    required String platform,
    String env = 'dev',
    Map<String, dynamic>? envSource,
    bool includeTestflightIpa = false,
  }) {
    return _client.postJson('/api/quick-test/run', {
      'source': source,
      'env': env,
      'platform': platform,
      'install_mode': 'client_download',
      'install_to_devices': false,
      'include_testflight_ipa': includeTestflightIpa,
      'env_source': ?envSource,
    });
  }

  Future<Map<String, dynamic>> pollStatus({int offset = 0}) {
    return _client.getJson(
      '/api/quick-test/status',
      queryParameters: {'offset': '$offset'},
    );
  }

  Future<void> cancel() async {
    await _client.postJson('/api/quick-test/cancel', {});
  }

  Future<File> downloadArtifact({
    required String relativeUrl,
    required File destination,
  }) {
    return _client.downloadFile(relativeUrl, destination);
  }
}

String quickTestPlatformForDevice() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'all';
}

Map<String, dynamic> localSourcePayload(String path) {
  return {
    'type': 'local',
    'path': path.trim(),
  };
}

Map<String, dynamic> gitSourcePayload({
  required String url,
  String ref = 'main',
  String subdir = '',
  String auth = 'none',
  String? token,
}) {
  return {
    'type': 'git',
    'url': url.trim(),
    'ref': ref.trim().isEmpty ? 'main' : ref.trim(),
    'subdir': subdir.trim(),
    'auth': auth,
    if (auth == 'https_token' && token != null && token.isNotEmpty) 'token': token,
  };
}
