String featureNameToFilePrefix(String raw) {
  var snake = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  snake = snake.replaceAll(RegExp(r'^_+|_+$'), '');
  snake = snake.replaceAll(RegExp(r'_+'), '_');
  if (snake.isEmpty) {
    throw ArgumentError("Invalid feature name '$raw'");
  }
  return '${snake}_';
}

String featureNameToPascalCase(String raw) {
  final snake = featureNameToFilePrefix(raw);
  final body = snake.endsWith('_') ? snake.substring(0, snake.length - 1) : snake;
  if (body.isEmpty) return 'Feature';
  return body
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}
