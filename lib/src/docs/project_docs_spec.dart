import 'project_docs_context.dart';

/// Which documentation files to generate and how to handle existing files.
enum ProjectDocsOverwritePolicy {
  skipExisting,
  overwriteAll,
  refreshGenerated;

  static ProjectDocsOverwritePolicy parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'overwriteall':
      case 'overwrite_all':
      case 'all':
        return ProjectDocsOverwritePolicy.overwriteAll;
      case 'refreshgenerated':
      case 'refresh_generated':
      case 'refresh':
        return ProjectDocsOverwritePolicy.refreshGenerated;
      default:
        return ProjectDocsOverwritePolicy.skipExisting;
    }
  }

  String get id => switch (this) {
        ProjectDocsOverwritePolicy.skipExisting => 'skipExisting',
        ProjectDocsOverwritePolicy.overwriteAll => 'overwriteAll',
        ProjectDocsOverwritePolicy.refreshGenerated => 'refreshGenerated',
      };
}

class ProjectDocsSpec {
  ProjectDocsSpec({
    this.includeReadme = true,
    this.includeDocIndex = true,
    this.includeGettingStarted = true,
    this.includeArchitecture = true,
    this.includeFeatures = true,
    this.includeConfiguration = true,
    this.includeDevelopment = true,
    this.includeBuilding = true,
    this.includeTesting = true,
    this.overwritePolicy = ProjectDocsOverwritePolicy.skipExisting,
  });

  final bool includeReadme;
  final bool includeDocIndex;
  final bool includeGettingStarted;
  final bool includeArchitecture;
  final bool includeFeatures;
  final bool includeConfiguration;
  final bool includeDevelopment;
  final bool includeBuilding;
  final bool includeTesting;
  final ProjectDocsOverwritePolicy overwritePolicy;

  Map<String, bool> get fileToggles => {
        ProjectDocsPaths.readme: includeReadme,
        ProjectDocsPaths.docIndex: includeDocIndex,
        ProjectDocsPaths.gettingStarted: includeGettingStarted,
        ProjectDocsPaths.architecture: includeArchitecture,
        ProjectDocsPaths.features: includeFeatures,
        ProjectDocsPaths.configuration: includeConfiguration,
        ProjectDocsPaths.development: includeDevelopment,
        ProjectDocsPaths.building: includeBuilding,
        ProjectDocsPaths.testing: includeTesting,
      };

  Iterable<String> get selectedPaths =>
      fileToggles.entries.where((e) => e.value).map((e) => e.key);

  Map<String, dynamic> toJson() => {
        'include_readme': includeReadme,
        'include_doc_index': includeDocIndex,
        'include_getting_started': includeGettingStarted,
        'include_architecture': includeArchitecture,
        'include_features': includeFeatures,
        'include_configuration': includeConfiguration,
        'include_development': includeDevelopment,
        'include_building': includeBuilding,
        'include_testing': includeTesting,
        'overwrite_policy': overwritePolicy.id,
      };

  factory ProjectDocsSpec.fromJson(Map<String, dynamic> json) {
    return ProjectDocsSpec(
      includeReadme: json['include_readme'] as bool? ?? true,
      includeDocIndex: json['include_doc_index'] as bool? ?? true,
      includeGettingStarted: json['include_getting_started'] as bool? ?? true,
      includeArchitecture: json['include_architecture'] as bool? ?? true,
      includeFeatures: json['include_features'] as bool? ?? true,
      includeConfiguration: json['include_configuration'] as bool? ?? true,
      includeDevelopment: json['include_development'] as bool? ?? true,
      includeBuilding: json['include_building'] as bool? ?? true,
      includeTesting: json['include_testing'] as bool? ?? true,
      overwritePolicy: ProjectDocsOverwritePolicy.parse(
        json['overwrite_policy'] as String?,
      ),
    );
  }

  static ProjectDocsSpec defaults() => ProjectDocsSpec();
}
