// Project Docs Studio — generate README and doc/ guides for a Flutter app.
//
// Run: dart run :project_docs --project .
// Help: dart run :project_docs --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/project_docs_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runProjectDocs(arguments));
}
