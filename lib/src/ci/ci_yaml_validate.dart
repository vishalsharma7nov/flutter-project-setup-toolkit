import 'ci_provider.dart';

/// Basic YAML structure validation without external dependencies.
String? validateWorkflowYaml(String yaml) {
  return validatePipelineYaml(yaml, provider: CiProvider.githubActions);
}

String? validatePipelineYaml(
  String yaml, {
  CiProvider provider = CiProvider.githubActions,
}) {
  final basic = _basicYamlChecks(yaml);
  if (basic != null) return basic;

  return switch (provider) {
    CiProvider.githubActions => _validateGitHubActions(yaml),
    CiProvider.gitLabCi =>
      yaml.contains('stages:') ? null : 'Missing GitLab CI stages: block',
    CiProvider.codemagic =>
      yaml.contains('workflows:') ? null : 'Missing Codemagic workflows: block',
    CiProvider.circleCi =>
      yaml.contains('version:') && yaml.contains('jobs:')
          ? null
          : 'Missing CircleCI version: or jobs: block',
    CiProvider.azurePipelines =>
      yaml.contains('stages:') || yaml.contains('jobs:')
          ? null
          : 'Missing Azure Pipelines stages: or jobs: block',
    CiProvider.bitbucketPipelines =>
      yaml.contains('pipelines:') ? null : 'Missing Bitbucket pipelines: block',
  };
}

String? _basicYamlChecks(String yaml) {
  if (yaml.trim().isEmpty) {
    return 'Workflow YAML is empty';
  }
  final lines = yaml.split('\n');
  var sawContent = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) {
      continue;
    }
    sawContent = true;
    if (line.contains('\t')) {
      return 'Line ${i + 1}: tabs are not allowed in YAML';
    }
    if (RegExp(r'^\s*-[^\s]').hasMatch(line)) {
      return 'Line ${i + 1}: list item needs a space after "-"';
    }
  }
  if (!sawContent) {
    return 'Workflow YAML has no content';
  }
  return null;
}

String? _validateGitHubActions(String yaml) {
  if (!yaml.contains('jobs:')) {
    return 'Missing top-level jobs: key';
  }
  if (!yaml.contains('on:')) {
    return 'Missing top-level on: trigger block';
  }
  return null;
}
