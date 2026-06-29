// Entry point for architecture compliance audit.
//
// Run: dart run :architecture_audit --project .
//      dart run :architecture_audit --project . --json
// Exit codes: 0 = clean, 1 = errors, 64 = invalid project
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/architecture_audit_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runArchitectureAuditCli(arguments));
}
