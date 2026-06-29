/// Toggleable cross-cutting modules under `lib/core/`.
class ArchitectureCoreModulesConfig {
  const ArchitectureCoreModulesConfig({
    this.errors = false,
    this.logging = false,
    this.theme = false,
    this.connectivity = false,
  });

  factory ArchitectureCoreModulesConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ArchitectureCoreModulesConfig();
    return ArchitectureCoreModulesConfig(
      errors: json['errors'] as bool? ?? false,
      logging: json['logging'] as bool? ?? false,
      theme: json['theme'] as bool? ?? false,
      connectivity: json['connectivity'] as bool? ?? false,
    );
  }

  final bool errors;
  final bool logging;
  final bool theme;
  final bool connectivity;

  bool get anyEnabled => errors || logging || theme || connectivity;

  Map<String, dynamic> toJson() => {
        'errors': errors,
        'logging': logging,
        'theme': theme,
        'connectivity': connectivity,
      };

  ArchitectureCoreModulesConfig copyWith({
    bool? errors,
    bool? logging,
    bool? theme,
    bool? connectivity,
  }) {
    return ArchitectureCoreModulesConfig(
      errors: errors ?? this.errors,
      logging: logging ?? this.logging,
      theme: theme ?? this.theme,
      connectivity: connectivity ?? this.connectivity,
    );
  }
}
