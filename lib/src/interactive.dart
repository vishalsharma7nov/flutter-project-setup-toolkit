import 'dart:io';

bool isInteractiveTerminal() => stdin.hasTerminal && stdout.hasTerminal;

String promptLine(String message, {String? defaultValue}) {
  final suffix = defaultValue == null || defaultValue.isEmpty
      ? ': '
      : ' (default: $defaultValue): ';
  stdout.write('$message$suffix');
  final reply = stdin.readLineSync()?.trim() ?? '';
  if (reply.isEmpty && defaultValue != null) {
    return defaultValue;
  }
  return reply;
}

bool promptYesNo(String message, {bool defaultYes = false}) {
  final hint = defaultYes ? '[Y/n]' : '[y/N]';
  while (true) {
    stdout.write('$message $hint: ');
    final reply = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (reply.isEmpty) return defaultYes;
    if (reply == 'y' || reply == 'yes') return true;
    if (reply == 'n' || reply == 'no') return false;
    print('Please answer y (yes) or n (no).');
  }
}

int promptChoice(String message, List<String> options, {int defaultIndex = 0}) {
  if (options.isEmpty) {
    throw ArgumentError('promptChoice requires at least one option');
  }
  print(message);
  for (var i = 0; i < options.length; i++) {
    print('  ${i + 1}. ${options[i]}');
  }
  while (true) {
    stdout.write('Choose [1-${options.length}] (default: ${defaultIndex + 1}): ');
    final reply = stdin.readLineSync()?.trim() ?? '';
    if (reply.isEmpty) return defaultIndex;
    final index = int.tryParse(reply);
    if (index != null && index >= 1 && index <= options.length) {
      return index - 1;
    }
    print('Enter a number between 1 and ${options.length}.');
  }
}

String promptChoiceValue(
  String message,
  List<String> options, {
  int defaultIndex = 0,
}) {
  return options[promptChoice(message, options, defaultIndex: defaultIndex)];
}

List<String> promptMultiChoice(String message, List<String> options) {
  print(message);
  print('Enter numbers separated by commas (e.g. 1,2).');
  for (var i = 0; i < options.length; i++) {
    print('  ${i + 1}. ${options[i]}');
  }
  while (true) {
    stdout.write('Choose: ');
    final reply = stdin.readLineSync()?.trim() ?? '';
    if (reply.isEmpty) {
      return [options.first];
    }
    final parts = reply.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty);
    final selected = <String>[];
    for (final part in parts) {
      final index = int.tryParse(part);
      if (index == null || index < 1 || index > options.length) {
        print('Invalid selection: $part');
        selected.clear();
        break;
      }
      final value = options[index - 1];
      if (!selected.contains(value)) {
        selected.add(value);
      }
    }
    if (selected.isNotEmpty) {
      return selected;
    }
  }
}
