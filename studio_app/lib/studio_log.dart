import 'dart:developer' as developer;

/// Flutter Project Setup Toolkit — macOS desktop log tag.
const studioLogTag = 'FPST';

void studioLog(String message) {
  final line = '[$studioLogTag] $message';
  // Visible in the terminal when launched via `flutter run -d macos`.
  // ignore: avoid_print
  print(line);
  developer.log(message, name: studioLogTag);
}

void studioLogError(
  String message,
  Object error, [
  StackTrace? stackTrace,
]) {
  final line = '[$studioLogTag] ERROR $message: $error';
  // ignore: avoid_print
  print(line);
  if (stackTrace != null) {
    // ignore: avoid_print
    print(stackTrace);
  }
  developer.log(
    '$message: $error',
    name: studioLogTag,
    error: error,
    stackTrace: stackTrace,
  );
}

String studioLogPreview(String? text, {int maxLength = 320}) {
  if (text == null || text.isEmpty) return '<empty>';
  final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (singleLine.length <= maxLength) return singleLine;
  return '${singleLine.substring(0, maxLength)}…';
}
