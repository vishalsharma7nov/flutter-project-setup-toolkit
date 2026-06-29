// Entry point for release Android APK/AAB builds.
//
// Run: dart run :build_android --project . --env prod --aab
// Help: dart run :build_android --help
import 'dart:io';

import 'package:flutter_project_setup_toolkit/src/build_android_cli.dart';

Future<void> main(List<String> arguments) async {
  exit(await runBuildAndroid(arguments));
}
