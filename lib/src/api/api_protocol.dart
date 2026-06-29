enum ApiProtocol {
  rest('rest'),
  grpc('grpc'),
  graphql('graphql'),
  websocket('websocket'),
  sse('sse'),
  firebase('firebase'),
  supabase('supabase'),
  localOnly('local_only'),
  mixed('mixed'),
  externalSdk('external_sdk');

  const ApiProtocol(this.id);

  final String id;

  static ApiProtocol get defaultProtocol => rest;

  static ApiProtocol? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final protocol in ApiProtocol.values) {
      if (protocol.id == value || protocol.name == value) {
        return protocol;
      }
    }
    return null;
  }

  String get label => switch (this) {
        rest => 'REST API',
        grpc => 'gRPC',
        graphql => 'GraphQL',
        websocket => 'WebSocket',
        sse => 'Server-Sent Events',
        firebase => 'Firebase',
        supabase => 'Supabase',
        localOnly => 'Local / offline only',
        mixed => 'Mixed backends',
        externalSdk => 'External vendor SDK',
      };
}

enum ApiClientSource {
  pubDev('pub_dev'),
  externalSdk('external_sdk');

  const ApiClientSource(this.id);

  final String id;

  static ApiClientSource? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'pub_dev' => pubDev,
      'external_sdk' => externalSdk,
      _ => null,
    };
  }

  String get idValue => id;
}

enum RestClientStyle {
  dio,
  http;

  static RestClientStyle? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'dio' => dio,
      'http' => http,
      _ => null,
    };
  }

  String get id => name;
}

enum LocalCacheStyle {
  none,
  sharedPreferences,
  hive,
  drift,
  isar;

  static LocalCacheStyle? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'none' => none,
      'shared_preferences' => sharedPreferences,
      'hive' => hive,
      'drift' => drift,
      'isar' => isar,
      _ => null,
    };
  }

  String get id => switch (this) {
        none => 'none',
        sharedPreferences => 'shared_preferences',
        hive => 'hive',
        drift => 'drift',
        isar => 'isar',
      };
}

enum RealtimeStyle {
  none,
  websocket,
  sse;

  static RealtimeStyle? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'none' => none,
      'websocket' => websocket,
      'sse' => sse,
      _ => null,
    };
  }

  String get id => name;
}
