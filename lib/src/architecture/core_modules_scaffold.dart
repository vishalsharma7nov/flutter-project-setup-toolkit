import 'architecture_core_modules.dart';

/// Stub Dart sources for optional `lib/core/` modules.
Map<String, String> coreModuleScaffoldFiles(ArchitectureCoreModulesConfig modules) {
  final files = <String, String>{};

  if (modules.errors) {
    files.addAll({
      'lib/core/errors/failures.dart': '''
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}
''',
      'lib/core/errors/exceptions.dart': '''
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}
''',
    });
  }

  if (modules.logging) {
    files['lib/core/logging/app_logger.dart'] = '''
class AppLogger {
  const AppLogger._();

  static void debug(String message) {
    // ignore: avoid_print
    print('[DEBUG] \$message');
  }

  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] \$message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] \$message');
    if (error != null) {
      // ignore: avoid_print
      print(error);
    }
  }
}
''';
  }

  if (modules.theme) {
    files['lib/core/theme/app_theme.dart'] = '''
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
''';
  }

  if (modules.connectivity) {
    files['lib/core/network/network_info.dart'] = '''
/// Abstract network reachability — wire to connectivity_plus in your DI layer.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoStub implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}
''';
  }

  return files;
}

List<String> coreModuleScaffoldDirectories(ArchitectureCoreModulesConfig modules) {
  final dirs = <String>[];
  if (modules.errors) {
    dirs.add('lib/core/errors');
  }
  if (modules.logging) {
    dirs.add('lib/core/logging');
  }
  if (modules.theme) {
    dirs.add('lib/core/theme');
  }
  if (modules.connectivity) {
    dirs.add('lib/core/network');
  }
  return dirs;
}
