/// Basic YAML structure validation without external dependencies.
String? validateWorkflowYaml(String yaml) {
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
  if (!yaml.contains('jobs:')) {
    return 'Missing top-level jobs: key';
  }
  if (!yaml.contains('on:')) {
    return 'Missing top-level on: trigger block';
  }
  return null;
}
