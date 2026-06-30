/// Marker appended to generated documentation for idempotent refresh.
const projectDocsGeneratedMarker =
    '<!-- generated-by: flutter-project-setup-toolkit docs-studio -->';

bool isProjectDocsGenerated(String content) =>
    content.contains(projectDocsGeneratedMarker);

/// True when README has substantial custom content and should not be overwritten
/// by default.
bool isSubstantialCustomReadme(String? content) {
  if (content == null || content.trim().isEmpty) return false;
  if (isProjectDocsGenerated(content)) return false;
  final nonEmptyLines =
      content.split('\n').where((line) => line.trim().isNotEmpty).length;
  return nonEmptyLines > 40;
}

String withProjectDocsMarker(String markdown) {
  final trimmed = markdown.trimRight();
  if (trimmed.contains(projectDocsGeneratedMarker)) return trimmed;
  return '$trimmed\n\n$projectDocsGeneratedMarker\n';
}
