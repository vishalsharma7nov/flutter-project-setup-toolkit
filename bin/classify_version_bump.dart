// Entry point for semver classification from git.
//
// Run: dart run :classify_version_bump --project . --env prod --suggest
// Help: dart run :classify_version_bump --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/classify_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runClassifyVersionBump(arguments));
}
