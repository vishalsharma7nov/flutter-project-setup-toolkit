import '../config.dart';
import 'azure_pipelines_template.dart';
import 'bitbucket_pipelines_template.dart';
import 'circleci_template.dart';
import 'codemagic_template.dart';
import 'ci_provider.dart';
import 'ci_workflow_paths.dart';
import 'ci_workflow_spec.dart';
import 'github_actions_template.dart';
import 'gitlab_ci_template.dart';

/// Generates CI/CD pipeline files for the selected provider.
Map<String, String> generateWorkflowFiles({
  required CiWorkflowSpec spec,
  required ToolkitConfig config,
}) {
  final normalized = _normalizeSpecForProvider(spec);
  return switch (normalized.provider) {
    CiProvider.githubActions =>
      generateGitHubWorkflowFiles(spec: normalized, config: config),
    CiProvider.gitLabCi =>
      generateGitLabCiFiles(spec: normalized, config: config),
    CiProvider.codemagic =>
      generateCodemagicFiles(spec: normalized, config: config),
    CiProvider.circleCi =>
      generateCircleCiFiles(spec: normalized, config: config),
    CiProvider.azurePipelines =>
      generateAzurePipelinesFiles(spec: normalized, config: config),
    CiProvider.bitbucketPipelines =>
      generateBitbucketPipelinesFiles(spec: normalized, config: config),
  };
}

List<String> workflowPathsForSpec(CiWorkflowSpec spec) {
  final normalized = _normalizeSpecForProvider(spec);
  if (normalized.provider == CiProvider.githubActions) {
    return CiWorkflowPaths.workflowFilesFor(
      split: normalized.pipelineMode == CiPipelineMode.split,
      hasCiJobs: normalized.hasCiJobs,
      hasReleaseJobs: normalized.hasReleaseJobs,
    );
  }
  return ciProviderInfo(normalized.provider).outputPaths;
}

CiWorkflowSpec _normalizeSpecForProvider(CiWorkflowSpec spec) {
  final info = ciProviderInfo(spec.provider);
  if (!info.supportsSplitPipeline &&
      spec.pipelineMode == CiPipelineMode.split) {
    return spec.copyWith(pipelineMode: CiPipelineMode.single);
  }
  return spec;
}

/// All known CI config paths CI Studio can detect or write.
List<String> allKnownWorkflowPaths() {
  final paths = <String>{
    CiWorkflowPaths.ciWorkflow,
    CiWorkflowPaths.releaseWorkflow,
  };
  for (final provider in ciProviderCatalog()) {
    paths.addAll(provider.outputPaths);
  }
  return paths.toList();
}
