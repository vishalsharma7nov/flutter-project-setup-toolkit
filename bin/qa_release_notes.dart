// Entry point for QA release notes export (CI artifact / local).
//
// Run: dart run :qa_release_notes --project . --format json --output qa-handoff.json
// Help: dart run :qa_release_notes --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/qa/qa_release_notes_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runQaReleaseNotes(arguments));
}
