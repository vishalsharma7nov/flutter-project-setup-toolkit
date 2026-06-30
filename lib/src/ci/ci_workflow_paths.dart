/// Standard workflow file paths relative to project root.
class CiWorkflowPaths {
  static const ciWorkflow = '.github/workflows/flutter-ci.yml';
  static const releaseWorkflow = '.github/workflows/flutter-release.yml';
  static const actSecretsExample = '.act.secrets.example';
  static const ciSetupDoc = 'CI_SETUP.md';

  static List<String> workflowFilesFor({
    required bool split,
    required bool hasCiJobs,
    required bool hasReleaseJobs,
  }) {
    if (split && hasCiJobs && hasReleaseJobs) {
      return [ciWorkflow, releaseWorkflow];
    }
    if (split && hasCiJobs && !hasReleaseJobs) {
      return [ciWorkflow];
    }
    return [releaseWorkflow];
  }
}
