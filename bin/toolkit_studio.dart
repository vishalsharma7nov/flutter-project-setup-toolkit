// Entry point for Toolkit Studio hub.
//
// Run from toolkit repo:
//   dart run :toolkit_studio
//   dart run :toolkit_studio --view quick-test --project /path/to/app
//
// Help: dart run :toolkit_studio --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/toolkit_studio_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runToolkitStudio(arguments));
}
