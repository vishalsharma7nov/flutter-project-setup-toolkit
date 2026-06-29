import 'architecture_config.dart';

Map<String, String> routingScaffoldFiles({
  required ProjectRouting routing,
  required List<String> environmentNames,
  required bool flavorMains,
}) {
  final files = <String, String>{};

  if (routing == ProjectRouting.goRouter) {
    files['lib/app/router/app_router.dart'] = '''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home'))),
      ),
    ],
  );
}
''';
  } else if (routing == ProjectRouting.autoRoute) {
    files['lib/app/router/app_router.dart'] = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
      ];
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
}
''';
  }

  if (flavorMains) {
    for (final env in environmentNames) {
      final fileName = _flavorMainFileName(env);
      files['lib/$fileName'] = _flavorMainStub(env);
    }
  }

  return files;
}

String _flavorMainFileName(String env) {
  final safe = env.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  return 'main_$safe.dart';
}

String _flavorMainStub(String environment) {
  return '''
import 'package:flutter/material.dart';

/// $environment flavor entrypoint.
/// Run: flutter run -t lib/${_flavorMainFileName(environment)} --dart-define=APP_ENV=$environment
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: true,
      home: Scaffold(
        body: Center(child: Text('$environment')),
      ),
    ),
  );
}
''';
}
