/// Simple unified diff for workflow preview (no external deps).
String unifiedDiff({
  required String oldText,
  required String newText,
  String oldLabel = 'existing',
  String newLabel = 'generated',
}) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');
  final buffer = StringBuffer()
    ..writeln('--- $oldLabel')
    ..writeln('+++ $newLabel');

  final max = oldLines.length > newLines.length ? oldLines.length : newLines.length;
  for (var i = 0; i < max; i++) {
    final oldLine = i < oldLines.length ? oldLines[i] : null;
    final newLine = i < newLines.length ? newLines[i] : null;
    if (oldLine == newLine) continue;
    if (oldLine != null) {
      buffer.writeln('-${oldLine.isEmpty ? '' : ' $oldLine'}');
    }
    if (newLine != null) {
      buffer.writeln('+${newLine.isEmpty ? '' : ' $newLine'}');
    }
  }
  return buffer.toString().trimRight();
}
