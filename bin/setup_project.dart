// Entry point for interactive project setup wizard.
//
// Run: dart run :setup_project --project /path/to/flutter_app
// Help: dart run :setup_project --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/setup_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runSetupProject(arguments));
}
