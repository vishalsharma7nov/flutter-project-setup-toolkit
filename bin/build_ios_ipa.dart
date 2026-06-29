// Entry point for release iOS IPA builds (macOS only).
//
// Run: dart run :build_ios_ipa --project . --env prod
// Help: dart run :build_ios_ipa --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/build_ios_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runBuildIosIpa(arguments));
}
