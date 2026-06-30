import 'project_docs_context.dart';
import 'project_docs_marker.dart';
import 'project_docs_spec.dart';

/// Generate all documentation files for [ctx] according to [spec].
Map<String, String> generateProjectDocsFiles({
  required ProjectDocsContext ctx,
  required ProjectDocsSpec spec,
}) {
  final files = <String, String>{};
  for (final path in spec.selectedPaths) {
    files[path] = _generateFile(ctx, path);
  }
  return files;
}

String _generateFile(ProjectDocsContext ctx, String path) {
  return switch (path) {
    ProjectDocsPaths.readme => generateReadme(ctx),
    ProjectDocsPaths.docIndex => generateDocIndex(ctx),
    ProjectDocsPaths.gettingStarted => generateGettingStarted(ctx),
    ProjectDocsPaths.architecture => generateArchitectureDoc(ctx),
    ProjectDocsPaths.features => generateFeaturesDoc(ctx),
    ProjectDocsPaths.configuration => generateConfigurationDoc(ctx),
    ProjectDocsPaths.development => generateDevelopmentDoc(ctx),
    ProjectDocsPaths.building => generateBuildingDoc(ctx),
    ProjectDocsPaths.testing => generateTestingDoc(ctx),
    _ => throw ArgumentError('Unknown doc path: $path'),
  };
}

String generateReadme(ProjectDocsContext ctx) {
  final name = ctx.snapshot.projectName;
  final purpose = ctx.snapshot.roughPurpose;
  final platforms = ctx.snapshot.platforms.join(', ');
  final buf = StringBuffer()
    ..writeln('# $name')
    ..writeln()
    ..writeln(purpose)
    ..writeln()
    ..writeln('## Quick start')
    ..writeln()
    ..writeln('### Prerequisites')
    ..writeln()
    ..writeln('- [Flutter SDK](https://docs.flutter.dev/get-started/install)')
    ..writeln('- Dart SDK (bundled with Flutter)')
    ..writeln();

  if (ctx.hasToolkitConfig) {
    final defaultEnv = ctx.config?.defaultEnvironment ?? 'dev';
    buf
      ..writeln('### Run locally')
      ..writeln()
      ..writeln('```bash')
      ..writeln('flutter pub get')
      ..writeln('flutter run')
      ..writeln('```')
      ..writeln()
      ..writeln(
        'Environment files are configured in `release-toolkit.config.json`. '
        'Default environment: **$defaultEnv**.',
      );
  } else {
    buf
      ..writeln('### Run locally')
      ..writeln()
      ..writeln('```bash')
      ..writeln('flutter pub get')
      ..writeln('flutter run')
      ..writeln('```');
  }

  buf
    ..writeln()
    ..writeln('## Platforms')
    ..writeln()
    ..writeln(platforms)
    ..writeln();

  if (ctx.snapshot.featureModules.isNotEmpty) {
    buf
      ..writeln('## Features')
      ..writeln()
      ..writeln(
        ctx.snapshot.featureModules.map((module) => '- $module').join('\n'),
      )
      ..writeln();
  }

  if (ctx.snapshot.keyDependencies.isNotEmpty) {
    buf
      ..writeln('## Stack')
      ..writeln()
      ..writeln(
        ctx.snapshot.keyDependencies.map((dep) => '- `$dep`').join('\n'),
      )
      ..writeln();
  }

  buf
    ..writeln('## Documentation')
    ..writeln()
    ..writeln('See [doc/README.md](doc/README.md) for full guides.')
    ..writeln()
    ..writeln('| Guide | Topic |')
    ..writeln('|-------|-------|')
    ..writeln('| [Getting started](doc/getting-started.md) | Setup and first run |')
    ..writeln('| [Architecture](doc/architecture.md) | Layout and conventions |')
    ..writeln('| [Features](doc/features.md) | Modules and screens |')
    ..writeln('| [Configuration](doc/configuration.md) | `release-toolkit.config.json` |')
    ..writeln('| [Development](doc/development.md) | Day-to-day workflow |')
    ..writeln('| [Building](doc/building.md) | Release builds |')
    ..writeln('| [Testing](doc/testing.md) | Tests and QA |');

  return withProjectDocsMarker(buf.toString());
}

String generateDocIndex(ProjectDocsContext ctx) {
  final name = ctx.snapshot.projectName;
  final buf = StringBuffer()
    ..writeln('# Documentation')
    ..writeln()
    ..writeln('Complete guides for **$name**.')
    ..writeln()
    ..writeln('## Getting started')
    ..writeln()
    ..writeln('| Guide | Description |')
    ..writeln('|-------|-------------|')
    ..writeln(
      '| [Getting started](getting-started.md) | Prerequisites, env files, first run |',
    )
    ..writeln(
      '| [Configuration](configuration.md) | `release-toolkit.config.json` reference |',
    )
    ..writeln()
    ..writeln('## Architecture & features')
    ..writeln()
    ..writeln('| Guide | Description |')
    ..writeln('|-------|-------------|')
    ..writeln(
      '| [Architecture](architecture.md) | Preset, layers, folder layout |',
    )
    ..writeln(
      '| [Features](features.md) | Feature modules, screens, routes |',
    )
    ..writeln()
    ..writeln('## Development & release')
    ..writeln()
    ..writeln('| Guide | Description |')
    ..writeln('|-------|-------------|')
    ..writeln(
      '| [Development](development.md) | Analyze, test, scaffold features |',
    )
    ..writeln('| [Building](building.md) | APK, AAB, IPA release builds |')
    ..writeln('| [Testing](testing.md) | Test layout and smoke paths |');

  return withProjectDocsMarker(buf.toString());
}

String generateGettingStarted(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Getting started')
    ..writeln()
    ..writeln(
      'First-time setup for **${ctx.snapshot.projectName}**.',
    )
    ..writeln()
    ..writeln('## Prerequisites')
    ..writeln()
    ..writeln('- Flutter SDK (`flutter doctor`)')
    ..writeln('- Dart SDK')
    ..writeln('- Platform tooling (Xcode for iOS, Android Studio for Android)')
    ..writeln()
    ..writeln('## Clone and install')
    ..writeln()
    ..writeln('```bash')
    ..writeln('flutter pub get')
    ..writeln('```')
    ..writeln()
    ..writeln('## Run the app')
    ..writeln()
    ..writeln('```bash')
    ..writeln('flutter run')
    ..writeln('```');

  if (ctx.hasToolkitConfig && ctx.config != null) {
    final config = ctx.config!;
    buf
      ..writeln()
      ..writeln('## Environments')
      ..writeln()
      ..writeln(
        'This project uses `release-toolkit.config.json`. '
        'Default environment: **${config.defaultEnvironment ?? 'dev'}**.',
      )
      ..writeln()
      ..writeln('| Environment | Env file |')
      ..writeln('|-------------|----------|');
    for (final entry in config.environments.entries) {
      buf.writeln('| `${entry.key}` | `${entry.value}` |');
    }
  } else {
    buf
      ..writeln()
      ..writeln('## Toolkit setup (optional)')
      ..writeln()
      ..writeln(
        'No `release-toolkit.config.json` found. Run the setup wizard to '
        'generate config, env templates, and build scripts:',
      )
      ..writeln()
      ..writeln('```bash')
      ..writeln('dart run flutter_project_setup_toolkit:setup_project --project .')
      ..writeln('```');
  }

  if (ctx.doctor.checks.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Project health checks')
      ..writeln();
    for (final check in ctx.doctor.checks) {
      buf.writeln('- **[${check.severity}]** ${check.message}');
      if (check.fix != null) {
        buf.writeln('  - Fix: ${check.fix}');
      }
    }
  }

  return withProjectDocsMarker(buf.toString());
}

String generateArchitectureDoc(ProjectDocsContext ctx) {
  final configured = ctx.audit.configuredPreset;
  final detected = ctx.audit.detection.suggestedPreset;
  final confidence =
      (ctx.audit.detection.confidence * 100).toStringAsFixed(0);

  final buf = StringBuffer()
    ..writeln('# Architecture')
    ..writeln()
    ..writeln(
      'How **${ctx.snapshot.projectName}** is structured.',
    )
    ..writeln()
    ..writeln('## Preset')
    ..writeln()
    ..writeln(
      '| | Preset |',
    )
    ..writeln('|---|--------|')
    ..writeln(
      '| Configured | ${configured?.label ?? '(none)'} `${configured?.id ?? ''}` |',
    )
    ..writeln(
      '| Detected | ${detected.label} `${detected.id}` ($confidence% confidence) |',
    );

  if (ctx.audit.detection.drift) {
    buf
      ..writeln()
      ..writeln(
        '> **Drift:** configured preset differs from detected folder layout. '
        'Run `dart run :architecture_audit --project .` for details.',
      );
  }

  if (ctx.snapshot.layers.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Layers detected')
      ..writeln()
      ..writeln(
        ctx.snapshot.layers.map((layer) => '- $layer').join('\n'),
      );
  }

  if (ctx.snapshot.featureModules.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Feature modules')
      ..writeln()
      ..writeln(
        ctx.snapshot.featureModules.map((m) => '- `$m`').join('\n'),
      );
  }

  if (ctx.config != null) {
    final arch = ctx.config!.architecture;
    buf
      ..writeln()
      ..writeln('## Configuration')
      ..writeln()
      ..writeln('- Feature base path: `${arch.featureBasePath}`')
      ..writeln('- Routing: `${arch.routing.id}`')
      ..writeln('- State management: `${ctx.config!.stateManagement.name}`')
      ..writeln('- API protocol: `${ctx.config!.api.protocol.name}`');
  }

  if (ctx.audit.issues.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Audit issues')
      ..writeln();
    for (final issue in ctx.audit.issues) {
      final location = issue.file == null ? '' : ' (`${issue.file}`)';
      buf.writeln(
        '- **[${issue.severity}]** ${issue.code}: ${issue.message}$location',
      );
    }
  } else {
    buf
      ..writeln()
      ..writeln('## Audit')
      ..writeln()
      ..writeln('No architecture compliance issues detected.');
  }

  return withProjectDocsMarker(buf.toString());
}

String generateFeaturesDoc(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Features')
    ..writeln()
    ..writeln(
      'Feature inventory for **${ctx.snapshot.projectName}** '
      '(${ctx.snapshot.dartFiles.length} Dart files, '
      '${ctx.snapshot.testFiles.length} test files).',
    );

  if (ctx.snapshot.featureModules.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Modules')
      ..writeln()
      ..writeln('| Module |')
      ..writeln('|--------|');
    for (final module in ctx.snapshot.featureModules) {
      buf.writeln('| `$module` |');
    }
  } else {
    buf
      ..writeln()
      ..writeln('## Modules')
      ..writeln()
      ..writeln(
        'No `lib/features/` modules detected. Use Feature Studio or '
        '`make_feature` to scaffold new features.',
      );
  }

  if (ctx.snapshot.screens.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Screens')
      ..writeln()
      ..writeln(
        ctx.snapshot.screens.map((screen) => '- $screen').join('\n'),
      );
  }

  if (ctx.snapshot.routes.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Routes')
      ..writeln()
      ..writeln('```')
      ..writeln(ctx.snapshot.routes.take(30).join('\n'))
      ..writeln('```');
  }

  if (ctx.snapshot.understandingNotes.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Notes')
      ..writeln();
    for (final note in ctx.snapshot.understandingNotes) {
      buf.writeln('- $note');
    }
  }

  return withProjectDocsMarker(buf.toString());
}

String generateConfigurationDoc(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Configuration')
    ..writeln()
    ..writeln('Reference for `release-toolkit.config.json`.')
    ..writeln();

  if (ctx.config == null) {
    buf
      ..writeln('## Status')
      ..writeln()
      ..writeln('No toolkit config found in this project.')
      ..writeln()
      ..writeln('Generate one with:')
      ..writeln()
      ..writeln('```bash')
      ..writeln('dart run flutter_project_setup_toolkit:setup_project --project .')
      ..writeln('```');
    if (ctx.configError != null) {
      buf
        ..writeln()
        ..writeln('Parse error: ${ctx.configError}');
    }
    return withProjectDocsMarker(buf.toString());
  }

  final config = ctx.config!;
  buf
    ..writeln('## Overview')
    ..writeln()
    ..writeln(
      '- Default environment: `${config.defaultEnvironment ?? 'dev'}`',
    )
    ..writeln('- State management: `${config.stateManagement.name}`')
    ..writeln('- Architecture preset: `${config.architecture.preset.id}`')
    ..writeln('- API protocol: `${config.api.protocol.name}`')
    ..writeln()
    ..writeln('## Environments')
    ..writeln()
    ..writeln('| Name | Path |')
    ..writeln('|------|------|');
  for (final entry in config.environments.entries) {
    buf.writeln('| `${entry.key}` | `${entry.value}` |');
  }

  buf
    ..writeln()
    ..writeln('## Version keys')
    ..writeln()
    ..writeln('| Key | Env variable |')
    ..writeln('|-----|--------------|')
    ..writeln(
      '| Android version name | `${config.androidNameKey}` |',
    )
    ..writeln(
      '| Android version code | `${config.androidCodeKey}` |',
    )
    ..writeln(
      '| iOS marketing version | `${config.iosMarketingKey}` |',
    )
    ..writeln('| iOS build number | `${config.iosBuildKey}` |');

  buf
    ..writeln()
    ..writeln('## Architecture')
    ..writeln()
    ..writeln('- Feature base: `${config.architecture.featureBasePath}`')
    ..writeln('- Routing: `${config.architecture.routing.id}`')
    ..writeln(
      '- DI: `${config.architecture.dependencyInjection.id}`',
    );

  return withProjectDocsMarker(buf.toString());
}

String generateDevelopmentDoc(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Development')
    ..writeln()
    ..writeln('Day-to-day workflow for **${ctx.snapshot.projectName}**.')
    ..writeln()
    ..writeln('## Analyze and format')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart analyze')
    ..writeln('dart format .')
    ..writeln('```')
    ..writeln()
    ..writeln('## Run tests')
    ..writeln()
    ..writeln('```bash')
    ..writeln('flutter test')
    ..writeln('```')
    ..writeln()
    ..writeln('## Scaffold a feature')
    ..writeln()
    ..writeln('```bash')
    ..writeln(
      'dart run flutter_project_setup_toolkit:make_feature --project . --feature my_feature',
    )
    ..writeln('```');

  if (ctx.scripts.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Project scripts')
      ..writeln()
      ..writeln('Scripts in `scripts/`:')
      ..writeln()
      ..writeln(
        ctx.scripts.map((script) => '- `scripts/$script`').join('\n'),
      );
  }

  buf
    ..writeln()
    ..writeln('## Architecture audit')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run flutter_project_setup_toolkit:architecture_audit --project .')
    ..writeln('```');

  return withProjectDocsMarker(buf.toString());
}

String generateBuildingDoc(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Building')
    ..writeln()
    ..writeln('Release builds for **${ctx.snapshot.projectName}**.')
    ..writeln()
    ..writeln('## Platforms')
    ..writeln()
    ..writeln(ctx.snapshot.platforms.map((p) => '- $p').join('\n'));

  if (ctx.hasToolkitConfig) {
    final defaultEnv = ctx.config?.defaultEnvironment ?? 'prod';
    buf
      ..writeln()
      ..writeln('## Android')
      ..writeln()
      ..writeln('```bash')
      ..writeln(
        'dart run flutter_project_setup_toolkit:build_android --project . --env $defaultEnv --aab',
      )
      ..writeln('```')
      ..writeln()
      ..writeln('## iOS (macOS)')
      ..writeln()
      ..writeln('```bash')
      ..writeln(
        'dart run flutter_project_setup_toolkit:build_ios_ipa --project . --env $defaultEnv',
      )
      ..writeln('```');
  } else {
    buf
      ..writeln()
      ..writeln('## Flutter builds')
      ..writeln()
      ..writeln('```bash')
      ..writeln('flutter build apk --release')
      ..writeln('flutter build appbundle --release')
      ..writeln('flutter build ipa --release  # macOS + Xcode')
      ..writeln('```')
      ..writeln()
      ..writeln(
        'Run `setup_project` first to generate env-aware build wrappers.',
      );
  }

  if (ctx.hasCiWorkflow) {
    buf
      ..writeln()
      ..writeln('## CI')
      ..writeln()
      ..writeln(
        'GitHub Actions workflows are present in `.github/workflows/`.',
      );
  } else {
    buf
      ..writeln()
      ..writeln('## CI')
      ..writeln()
      ..writeln(
        'Generate CI workflows with CI Studio: '
        '`dart run :toolkit_studio --view ci --project .`',
      );
  }

  return withProjectDocsMarker(buf.toString());
}

String generateTestingDoc(ProjectDocsContext ctx) {
  final buf = StringBuffer()
    ..writeln('# Testing')
    ..writeln()
    ..writeln(
      'Test layout for **${ctx.snapshot.projectName}** '
      '(${ctx.snapshot.testFiles.length} test file(s)).',
    )
    ..writeln()
    ..writeln('## Run all tests')
    ..writeln()
    ..writeln('```bash')
    ..writeln('flutter test')
    ..writeln('```');

  if (ctx.snapshot.testFiles.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## Test files')
      ..writeln()
      ..writeln('```')
      ..writeln(ctx.snapshot.testFiles.take(40).join('\n'));
    if (ctx.snapshot.testFiles.length > 40) {
      buf.writeln('... and ${ctx.snapshot.testFiles.length - 40} more');
    }
    buf.writeln('```');
  }

  buf
    ..writeln()
    ..writeln('## Suggested smoke paths')
    ..writeln();

  if (ctx.snapshot.screens.isNotEmpty) {
    for (final screen in ctx.snapshot.screens.take(10)) {
      buf.writeln('- [ ] Open **$screen** and verify layout');
    }
  } else if (ctx.snapshot.featureModules.isNotEmpty) {
    for (final module in ctx.snapshot.featureModules.take(10)) {
      buf.writeln('- [ ] Smoke test **$module** flow end-to-end');
    }
  } else {
    buf.writeln('- [ ] App launches without errors');
    buf.writeln('- [ ] Core navigation works');
    buf.writeln('- [ ] No regressions in `flutter test`');
  }

  buf
    ..writeln()
    ..writeln('## QA handoff')
    ..writeln()
    ..writeln(
      'Generate release notes for QA with '
      '`dart run :toolkit_studio --view qa --project .`',
    );

  return withProjectDocsMarker(buf.toString());
}
