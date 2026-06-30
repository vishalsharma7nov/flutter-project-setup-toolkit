// CI Studio — generate, test, and publish GitHub Actions workflows.
//
// Run: dart run :ci_studio --project .
// Help: dart run :ci_studio --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/ci_studio_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runCiStudio(arguments));
}
