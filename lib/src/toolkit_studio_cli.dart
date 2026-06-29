import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'browser_util.dart';
import 'config.dart';
import 'studio/toolkit_studio_server.dart';
import 'studio/studio_branding.dart';
import 'toolkit_install.dart';

Future<int> runToolkitStudio(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', abbr: 'p', help: 'Flutter project root (pre-filled in UI)')
    ..addOption('port', help: 'Local web server port (default: 8765)')
    ..addOption('view', help: 'Deep link: setup | build | feature | version | quick-test')
    ..addFlag(
      'desktop',
      negatable: false,
      help: 'Launch macOS desktop app (default on macOS)',
    )
    ..addFlag(
      'browser',
      negatable: false,
      help: 'Open in web browser instead of the desktop app',
    )
    ..addFlag('no-browser', negatable: false, help: 'Do not open the browser automatically');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    return 64;
  }

  if (_shouldUseDesktop(args)) {
    return _launchDesktopApp(args);
  }

  final port = await _resolvePort(args['port'] as String?);
  if (port == null) {
    return 1;
  }

  Directory? projectRoot;
  final projectArg = args['project'] as String?;
  if (projectArg != null && projectArg.trim().isNotEmpty) {
    projectRoot = resolveProjectRoot(projectArg);
  }

  final server = ToolkitStudioServer(projectRoot: projectRoot, port: port);
  final view = args['view'] as String?;
  final viewPath = switch (view) {
    'setup' => '/setup',
    'build' => '/build',
    'feature' => '/feature',
    'version' => '/version',
    'quick-test' => '/quick-test',
    _ => '/',
  };
  final url = 'http://127.0.0.1:$port$viewPath';

  _printBanner(url, projectRoot?.path, desktop: false);

  if (!(args['no-browser'] as bool)) {
    await openBrowser(url);
  }

  final shutdown = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down $studioProductName…');
    await server.stop();
    if (!shutdown.isCompleted) {
      shutdown.complete();
    }
  });

  try {
    await server.start();
  } on SocketException catch (e) {
    stderr.writeln('Could not start server on port $port: $e');
    stderr.writeln('Try --port 8766 or stop the other studio process.');
    return 1;
  }

  await shutdown.future;
  return 0;
}

bool _shouldUseDesktop(ArgResults args) {
  if (args['browser'] as bool) {
    return false;
  }
  if (args['desktop'] as bool) {
    return true;
  }
  if (!Platform.isMacOS) {
    return false;
  }
  return _resolveStudioAppDir().existsSync();
}

Directory _resolveStudioAppDir() {
  final toolkitRoot = detectRunningToolkitRoot() ?? Directory.current.absolute;
  return Directory(p.join(toolkitRoot.path, 'studio_app'));
}

Future<int?> _resolvePort(String? portArg) async {
  final preferred = int.tryParse(portArg ?? '') ?? 8765;
  if (preferred < 1024 || preferred > 65535) {
    stderr.writeln('Invalid port: $preferred');
    return null;
  }
  final available = await _findAvailablePort(preferred);
  if (available == null) {
    stderr.writeln(
      'No free port found near $preferred. Stop other studio instances or pass --port.',
    );
    return null;
  }
  if (available != preferred) {
    print('Port $preferred is in use; using $available instead.');
  }
  return available;
}

Future<int?> _findAvailablePort(int preferred) async {
  for (var port = preferred; port < preferred + 20; port++) {
    try {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return port;
    } on SocketException {
      continue;
    }
  }
  return null;
}

Future<int> _launchDesktopApp(ArgResults args) async {
  final studioAppDir = _resolveStudioAppDir();
  if (!studioAppDir.existsSync()) {
    stderr.writeln(
      'Desktop app not found at ${studioAppDir.path}. '
      'Use --browser or run from the flutter-project-setup-toolkit repository.',
    );
    return 1;
  }

  final port = await _resolvePort(args['port'] as String?);
  if (port == null) {
    return 1;
  }

  Directory? projectRoot;
  final projectArg = args['project'] as String?;
  if (projectArg != null && projectArg.trim().isNotEmpty) {
    projectRoot = resolveProjectRoot(projectArg);
  }

  final server = ToolkitStudioServer(projectRoot: projectRoot, port: port);
  try {
    await server.start();
  } on SocketException catch (e) {
    stderr.writeln('Could not start server on port $port: $e');
    return 1;
  }

  final view = args['view'] as String?;
  final viewPath = switch (view) {
    'setup' => '/setup',
    'build' => '/build',
    'feature' => '/feature',
    'version' => '/version',
    'quick-test' => '/quick-test',
    _ => '/',
  };
  final url = 'http://127.0.0.1:$port$viewPath';
  _printBanner(url, projectRoot?.path, desktop: true);
  print('  Desktop shell:    ${studioAppDir.path}');
  print('');

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down $studioProductName…');
    await server.stop();
    exit(0);
  });

  final flutterArgs = <String>['run', '-d', 'macos', '-t', 'lib/main_darwin.dart'];
  if (view != null && view.isNotEmpty) {
    flutterArgs.add('--dart-define=RTK_VIEW=$view');
  }
  flutterArgs.add('--dart-define=RTK_PORT=$port');

  final process = await Process.start(
    'flutter',
    flutterArgs,
    workingDirectory: studioAppDir.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  await server.stop();
  return exitCode;
}

void _printBanner(String url, String? projectPath, {required bool desktop}) {
  print('');
  print('╔══════════════════════════════════════════════════════════╗');
  print(studioBannerCenterLine());
  print('╚══════════════════════════════════════════════════════════╝');
  print('');
  if (desktop) {
    print('  Studio server:    $url');
    print('  UI:               macOS desktop app');
  } else {
    print('  Open in browser:  $url');
  }
  if (projectPath != null) {
    print('  Project:          $projectPath');
  }
  print('');
  print('  Press Ctrl+C to stop the server.');
  print('');
}
