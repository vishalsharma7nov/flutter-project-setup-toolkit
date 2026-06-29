import 'api_protocol.dart';

class ApiCodegenConfig {
  const ApiCodegenConfig({
    this.jsonSerializable = true,
    this.freezed = false,
  });

  factory ApiCodegenConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApiCodegenConfig();
    return ApiCodegenConfig(
      jsonSerializable: json['json_serializable'] as bool? ?? true,
      freezed: json['freezed'] as bool? ?? false,
    );
  }

  final bool jsonSerializable;
  final bool freezed;

  Map<String, dynamic> toJson() => {
        'json_serializable': jsonSerializable,
        'freezed': freezed,
      };
}

class ExternalSdkGitSource {
  const ExternalSdkGitSource({
    required this.url,
    this.ref,
    this.path,
  });

  factory ExternalSdkGitSource.fromJson(Map<String, dynamic> json) {
    return ExternalSdkGitSource(
      url: json['url'] as String? ?? '',
      ref: json['ref'] as String?,
      path: json['path'] as String?,
    );
  }

  final String url;
  final String? ref;
  final String? path;

  Map<String, dynamic> toJson() => {
        'url': url,
        if (ref != null) 'ref': ref,
        if (path != null) 'path': path,
      };

  bool get isValid => url.isNotEmpty;
}

class ExternalSdkHostedSource {
  const ExternalSdkHostedSource({
    required this.url,
    required this.version,
  });

  factory ExternalSdkHostedSource.fromJson(Map<String, dynamic> json) {
    return ExternalSdkHostedSource(
      url: json['url'] as String? ?? '',
      version: json['version'] as String? ?? '^1.0.0',
    );
  }

  final String url;
  final String version;

  Map<String, dynamic> toJson() => {
        'url': url,
        'version': version,
      };

  bool get isValid => url.isNotEmpty;
}

class ExternalSdkConfig {
  const ExternalSdkConfig({
    required this.packageName,
    this.source = 'git',
    this.git,
    this.path,
    this.hosted,
    this.initHint,
    this.contractUrl,
  });

  factory ExternalSdkConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ExternalSdkConfig(packageName: '');
    }
    return ExternalSdkConfig(
      packageName: json['package_name'] as String? ?? '',
      source: json['source'] as String? ?? 'git',
      git: json['git'] is Map<String, dynamic>
          ? ExternalSdkGitSource.fromJson(
              json['git'] as Map<String, dynamic>,
            )
          : null,
      path: json['path'] as String?,
      hosted: json['hosted'] is Map<String, dynamic>
          ? ExternalSdkHostedSource.fromJson(
              json['hosted'] as Map<String, dynamic>,
            )
          : null,
      initHint: json['init_hint'] as String?,
      contractUrl: json['contract_url'] as String?,
    );
  }

  final String packageName;
  final String source;
  final ExternalSdkGitSource? git;
  final String? path;
  final ExternalSdkHostedSource? hosted;
  final String? initHint;
  final String? contractUrl;

  bool get isConfigured => packageName.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'package_name': packageName,
        'source': source,
        if (git != null) 'git': git!.toJson(),
        if (path != null) 'path': path,
        if (hosted != null) 'hosted': hosted!.toJson(),
        if (initHint != null) 'init_hint': initHint,
        if (contractUrl != null) 'contract_url': contractUrl,
      };
}

class ApiConfig {
  const ApiConfig({
    this.protocol = ApiProtocol.rest,
    this.secondaryProtocol,
    this.clientSource = ApiClientSource.pubDev,
    this.restClient = RestClientStyle.dio,
    this.useRetrofit = true,
    this.codegen = const ApiCodegenConfig(),
    this.localCache = LocalCacheStyle.none,
    this.realtime = RealtimeStyle.none,
    this.baseUrlEnvKey = 'API_BASE_URL',
    this.websocketUrlEnvKey = 'WS_BASE_URL',
    this.authInterceptor = false,
    this.externalSdk,
  });

  factory ApiConfig.defaults() => const ApiConfig();

  factory ApiConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ApiConfig.defaults();
    final clientSource =
        ApiClientSource.parse(json['client_source'] as String?) ??
            ApiClientSource.pubDev;
    var protocol =
        ApiProtocol.parse(json['protocol'] as String?) ?? ApiProtocol.rest;
    if (clientSource == ApiClientSource.externalSdk &&
        protocol == ApiProtocol.rest) {
      protocol = ApiProtocol.externalSdk;
    }
    return ApiConfig(
      protocol: protocol,
      secondaryProtocol:
          ApiProtocol.parse(json['secondary_protocol'] as String?),
      clientSource: clientSource,
      restClient:
          RestClientStyle.parse(json['rest_client'] as String?) ??
              RestClientStyle.dio,
      useRetrofit: json['use_retrofit'] as bool? ?? true,
      codegen: ApiCodegenConfig.fromJson(
        json['codegen'] as Map<String, dynamic>?,
      ),
      localCache:
          LocalCacheStyle.parse(json['local_cache'] as String?) ??
              LocalCacheStyle.none,
      realtime:
          RealtimeStyle.parse(json['realtime'] as String?) ??
              RealtimeStyle.none,
      baseUrlEnvKey: json['base_url_env_key'] as String? ?? 'API_BASE_URL',
      websocketUrlEnvKey:
          json['websocket_url_env_key'] as String? ?? 'WS_BASE_URL',
      authInterceptor: json['auth_interceptor'] as bool? ?? false,
      externalSdk: json['external_sdk'] is Map<String, dynamic>
          ? ExternalSdkConfig.fromJson(
              json['external_sdk'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final ApiProtocol protocol;
  final ApiProtocol? secondaryProtocol;
  final ApiClientSource clientSource;
  final RestClientStyle restClient;
  final bool useRetrofit;
  final ApiCodegenConfig codegen;
  final LocalCacheStyle localCache;
  final RealtimeStyle realtime;
  final String baseUrlEnvKey;
  final String websocketUrlEnvKey;
  final bool authInterceptor;
  final ExternalSdkConfig? externalSdk;

  bool get usesExternalSdk =>
      clientSource == ApiClientSource.externalSdk ||
      protocol == ApiProtocol.externalSdk ||
      (externalSdk?.isConfigured ?? false);

  Map<String, dynamic> toJson() => {
        'protocol': protocol.id,
        if (secondaryProtocol != null)
          'secondary_protocol': secondaryProtocol!.id,
        'client_source': clientSource.idValue,
        'rest_client': restClient.id,
        'use_retrofit': useRetrofit,
        'codegen': codegen.toJson(),
        'local_cache': localCache.id,
        'realtime': realtime.id,
        'base_url_env_key': baseUrlEnvKey,
        if (realtime == RealtimeStyle.websocket)
          'websocket_url_env_key': websocketUrlEnvKey,
        'auth_interceptor': authInterceptor,
        if (externalSdk != null && externalSdk!.isConfigured)
          'external_sdk': externalSdk!.toJson(),
      };

  String? envLineForProtocol() {
    if (usesExternalSdk) return null;
    return switch (protocol) {
      ApiProtocol.rest ||
      ApiProtocol.mixed ||
      ApiProtocol.graphql ||
      ApiProtocol.grpc =>
        '$baseUrlEnvKey=',
      _ => null,
    };
  }
}
