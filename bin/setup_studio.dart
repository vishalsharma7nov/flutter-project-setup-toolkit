// Entry point for Setup Studio GUI (legacy; prefer toolkit_studio hub).
//
// Run: dart run :setup_studio --project .
// Help: dart run :setup_studio --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/setup_studio_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runSetupStudio(arguments));
}
