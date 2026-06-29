import 'dart:io';

import 'package:path/path.dart' as p;

import 'architecture_config.dart';
import 'micro_feature_scaffold.dart' show readProjectPackageName;

class FeatureWiringResult {
  FeatureWiringResult({
    required this.patchedPaths,
    required this.skipped,
    required this.dryRun,
  });

  final List<String> patchedPaths;
  final List<String> skipped;
  final bool dryRun;
}

/// Optionally patch go_router and get_it after feature scaffold (opt-in via bootstrap.auto_wire).
FeatureWiringResult wireFeatureIntoProject({
  required Directory projectRoot,
  required String featureName,
  required ArchitectureConfig architecture,
  bool dryRun = false,
}) {
  if (!architecture.bootstrap.autoWire) {
    return FeatureWiringResult(patchedPaths: [], skipped: ['auto_wire disabled'], dryRun: dryRun);
  }

  final patched = <String>[];
  final skipped = <String>[];
  final className = _pascalCase(featureName);

  if (architecture.routing == ProjectRouting.goRouter) {
    final routerFile = File(p.join(projectRoot.path, 'lib/app/router/app_router.dart'));
    if (!routerFile.existsSync()) {
      skipped.add('lib/app/router/app_router.dart not found');
    } else {
      final routePath = '/$featureName';
      final importPath =
          'package:${readProjectPackageName(projectRoot)}/features/$featureName/presentation/pages/${_snakeCase(featureName)}_page.dart';
      final content = routerFile.readAsStringSync();
      if (content.contains(routePath)) {
        skipped.add('route $routePath already present');
      } else if (dryRun) {
        patched.add('lib/app/router/app_router.dart');
      } else {
        final updated = _patchGoRouter(
          content: content,
          routePath: routePath,
          className: className,
          importPath: importPath,
          pageWidget: '${className}Page',
        );
        if (updated != null) {
          routerFile.writeAsStringSync(updated);
          patched.add('lib/app/router/app_router.dart');
        } else {
          skipped.add('could not patch go_router routes block');
        }
      }
    }
  } else {
    skipped.add('routing ${architecture.routing.id} not auto-wired yet');
  }

  if (architecture.dependencyInjection == DependencyInjectionStyle.getIt) {
    final locator = File(p.join(projectRoot.path, 'lib/core/di/locator.dart'));
    if (!locator.existsSync()) {
      skipped.add('lib/core/di/locator.dart not found');
    } else if (dryRun) {
      patched.add('lib/core/di/locator.dart');
    } else {
      final content = locator.readAsStringSync();
      final marker = '// feature: $featureName';
      if (content.contains(marker)) {
        skipped.add('locator already has $featureName');
      } else {
        locator.writeAsStringSync(
          '$content\n$marker\n// TODO: register ${className}Repository\n',
        );
        patched.add('lib/core/di/locator.dart');
      }
    }
  }

  return FeatureWiringResult(
    patchedPaths: patched,
    skipped: skipped,
    dryRun: dryRun,
  );
}

String? _patchGoRouter({
  required String content,
  required String routePath,
  required String className,
  required String importPath,
  required String pageWidget,
}) {
  if (!content.contains('routes: [')) return null;
  if (!content.contains(importPath)) {
    final importLine = "import '$importPath';\n";
    content = importLine + content;
  }
  final insertion = '''
      GoRoute(
        path: '$routePath',
        builder: (context, state) => const $pageWidget(),
      ),
''';
  final index = content.indexOf('routes: [');
  if (index < 0) return null;
  final afterBracket = content.indexOf('[', index) + 1;
  return content.substring(0, afterBracket) + insertion + content.substring(afterBracket);
}

String _pascalCase(String value) {
  final parts = value
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .split('_')
      .where((p) => p.isNotEmpty);
  return parts.map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join();
}

String _snakeCase(String value) =>
    value.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
