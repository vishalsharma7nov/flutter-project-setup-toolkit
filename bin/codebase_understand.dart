// Rough codebase understanding for QA when git history is missing.
//
// Run: dart run :codebase_understand --project .
// JSON: dart run :codebase_understand --project . --format json
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/qa/codebase_understand_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runCodebaseUnderstand(arguments));
}
