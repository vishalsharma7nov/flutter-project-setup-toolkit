// Entry point for Distribution Studio GUI.
//
// Run: dart run :build_distribution --project .
// Help: dart run :build_distribution --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/distribution_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runBuildDistribution(arguments));
}
