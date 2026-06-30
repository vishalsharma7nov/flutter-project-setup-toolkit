/// Supported CI/CD platforms for CI Studio pipeline generation.
enum CiProvider {
  githubActions,
  gitLabCi,
  codemagic,
  circleCi,
  azurePipelines,
  bitbucketPipelines,
}

class CiProviderField {
  const CiProviderField({
    required this.id,
    required this.label,
    this.placeholder,
    this.defaultValue,
    this.type = 'text',
    this.help,
  });

  final String id;
  final String label;
  final String? placeholder;
  final String? defaultValue;
  final String type;
  final String? help;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (placeholder != null) 'placeholder': placeholder,
        if (defaultValue != null) 'default_value': defaultValue,
        'type': type,
        if (help != null) 'help': help,
      };
}

class CiProviderInfo {
  const CiProviderInfo({
    required this.provider,
    required this.label,
    required this.description,
    required this.docsUrl,
    required this.outputPaths,
    required this.supportsSplitPipeline,
    required this.supportsGhPublish,
    this.configFields = const [],
  });

  final CiProvider provider;
  final String label;
  final String description;
  final String docsUrl;
  final List<String> outputPaths;
  final bool supportsSplitPipeline;
  final bool supportsGhPublish;
  final List<CiProviderField> configFields;

  Map<String, dynamic> toJson() => {
        'id': provider.name,
        'label': label,
        'description': description,
        'docs_url': docsUrl,
        'output_paths': outputPaths,
        'supports_split_pipeline': supportsSplitPipeline,
        'supports_gh_publish': supportsGhPublish,
        'config_fields': configFields.map((f) => f.toJson()).toList(),
      };
}

CiProvider parseCiProvider(String? raw) {
  if (raw == null || raw.isEmpty) return CiProvider.githubActions;
  return CiProvider.values.firstWhere(
    (p) => p.name == raw,
    orElse: () => CiProvider.githubActions,
  );
}

List<CiProviderInfo> ciProviderCatalog() => [
      const CiProviderInfo(
        provider: CiProvider.githubActions,
        label: 'GitHub Actions',
        description:
            'Native GitHub CI — split PR checks + release workflows, PR publish via gh',
        docsUrl: 'https://docs.github.com/en/actions',
        outputPaths: [
          '.github/workflows/flutter-ci.yml',
          '.github/workflows/flutter-release.yml',
        ],
        supportsSplitPipeline: true,
        supportsGhPublish: true,
      ),
      CiProviderInfo(
        provider: CiProvider.gitLabCi,
        label: 'GitLab CI',
        description: 'Single .gitlab-ci.yml — popular for self-hosted GitLab',
        docsUrl: 'https://docs.gitlab.com/ee/ci/',
        outputPaths: ['.gitlab-ci.yml'],
        supportsSplitPipeline: false,
        supportsGhPublish: false,
        configFields: [
          const CiProviderField(
            id: 'flutter_image',
            label: 'Flutter Docker image',
            defaultValue: 'ghcr.io/cirruslabs/flutter:stable',
            help: 'CI job image with Flutter SDK preinstalled',
          ),
          const CiProviderField(
            id: 'default_branch',
            label: 'Default branch',
            defaultValue: 'main',
          ),
        ],
      ),
      const CiProviderInfo(
        provider: CiProvider.codemagic,
        label: 'Codemagic',
        description:
            'Managed Flutter CI — strong iOS/macOS minutes, codemagic.yaml',
        docsUrl: 'https://docs.codemagic.io/yaml/yaml-getting-started/',
        outputPaths: ['codemagic.yaml'],
        supportsSplitPipeline: false,
        supportsGhPublish: false,
        configFields: [
          CiProviderField(
            id: 'workflow_name',
            label: 'Workflow name',
            defaultValue: 'Flutter CI',
          ),
          CiProviderField(
            id: 'instance_type',
            label: 'macOS instance',
            type: 'select',
            defaultValue: 'mac_mini_m2',
            help: 'mac_mini_m1 | mac_mini_m2 | mac_pro',
          ),
        ],
      ),
      CiProviderInfo(
        provider: CiProvider.circleCi,
        label: 'CircleCI',
        description: 'Docker-based pipelines with Flutter orb patterns',
        docsUrl: 'https://circleci.com/docs/',
        outputPaths: ['.circleci/config.yml'],
        supportsSplitPipeline: false,
        supportsGhPublish: false,
        configFields: [
          const CiProviderField(
            id: 'flutter_image',
            label: 'Flutter Docker image',
            defaultValue: 'cirrusci/flutter:stable',
          ),
          const CiProviderField(
            id: 'resource_class',
            label: 'Resource class (optional)',
            placeholder: 'medium',
            help: 'CircleCI resource class for Android jobs',
          ),
        ],
      ),
      CiProviderInfo(
        provider: CiProvider.azurePipelines,
        label: 'Azure Pipelines',
        description: 'Microsoft Azure DevOps YAML — enterprise teams',
        docsUrl:
            'https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema',
        outputPaths: ['azure-pipelines.yml'],
        supportsSplitPipeline: false,
        supportsGhPublish: false,
        configFields: [
          const CiProviderField(
            id: 'ubuntu_vm_image',
            label: 'Ubuntu VM image',
            defaultValue: 'ubuntu-latest',
          ),
          const CiProviderField(
            id: 'macos_vm_image',
            label: 'macOS VM image',
            defaultValue: 'macOS-latest',
          ),
        ],
      ),
      CiProviderInfo(
        provider: CiProvider.bitbucketPipelines,
        label: 'Bitbucket Pipelines',
        description: 'Atlassian Bitbucket cloud pipelines',
        docsUrl:
            'https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/',
        outputPaths: ['bitbucket-pipelines.yml'],
        supportsSplitPipeline: false,
        supportsGhPublish: false,
        configFields: [
          const CiProviderField(
            id: 'size',
            label: 'Pipeline size',
            defaultValue: '2x',
            help: '1x | 2x | 4x — larger for Android/iOS builds',
          ),
        ],
      ),
    ];

CiProviderInfo ciProviderInfo(CiProvider provider) {
  return ciProviderCatalog().firstWhere((p) => p.provider == provider);
}

String providerConfigString(
  Map<String, dynamic> config,
  String key, {
  String fallback = '',
}) {
  final value = config[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
