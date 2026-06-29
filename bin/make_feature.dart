// Entry point for feature scaffolding.
//
// Run: dart run :make_feature --project /path/to/app --feature auth
// Help: dart run :make_feature --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/make_feature_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runMakeFeature(arguments));
}
