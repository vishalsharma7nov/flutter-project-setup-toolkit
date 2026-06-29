import 'dart:io';

import 'package:open_filex/open_filex.dart';

class ApkInstallService {
  Future<OpenResult> installApk(File apkFile) async {
    if (!Platform.isAndroid) {
      throw StateError('APK install is only supported on Android.');
    }
    if (!apkFile.existsSync()) {
      throw StateError('APK not found: ${apkFile.path}');
    }
    return OpenFilex.open(apkFile.path, type: 'application/vnd.android.package-archive');
  }
}
