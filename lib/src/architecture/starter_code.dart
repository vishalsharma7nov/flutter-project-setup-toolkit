import '../models.dart';
import 'architecture_config.dart';
import 'architecture_preset.dart';

/// Starter Dart stubs for scaffolded feature files (non-destructive: only empty files).
String starterCodeForPath({
  required String relativePath,
  required String featureName,
  required String filePrefix,
  required ArchitecturePreset preset,
  required StateManagement stateManagement,
  required ArchitectureLayersConfig layers,
}) {
  final fileName = relativePath.split('/').last;
  final className = _pascalCase(featureName);

  if (relativePath.contains('/domain/repositories/')) {
    return '''
abstract class ${className}Repository {
  Future<void> fetch();
}
''';
  }

  if (relativePath.contains('/domain/entities/')) {
    return '''
class ${className}Entity {
  const ${className}Entity();
}
''';
  }

  if (relativePath.contains('/domain/usecases/')) {
    return '''
class Get${className}UseCase {
  const Get${className}UseCase();

  Future<void> call() async {}
}
''';
  }

  if (relativePath.contains('/data/repositories/')) {
    return '''
import '../../domain/repositories/${filePrefix}repository.dart';

class ${className}RepositoryImpl implements ${className}Repository {
  @override
  Future<void> fetch() async {}
}
''';
  }

  if (relativePath.contains('/data/datasources/')) {
    return '''
class ${className}RemoteDataSource {
  Future<Map<String, dynamic>> fetch() async => {};
}
''';
  }

  if (relativePath.contains('/presentation/pages/')) {
    return '''
import 'package:flutter/material.dart';

class ${className}Page extends StatelessWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: const Center(child: Text('$className')),
    );
  }
}
''';
  }

  if (relativePath.contains('/presentation/bloc/') && fileName.endsWith('_bloc.dart')) {
    return '''
import 'package:flutter_bloc/flutter_bloc.dart';

class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
  ${className}Bloc() : super(const ${className}Initial()) {
    on<${className}Started>((event, emit) {});
  }
}

abstract class ${className}Event {}

class ${className}Started extends ${className}Event {}

abstract class ${className}State {
  const ${className}State();
}

class ${className}Initial extends ${className}State {
  const ${className}Initial();
}
''';
  }

  if (relativePath.contains('/presentation/providers/')) {
    return '''
// TODO: wire ${className} provider (${stateManagement.name})
''';
  }

  if (relativePath.contains('/screens/')) {
    return '''
import 'package:flutter/material.dart';

class ${className}Screen extends StatelessWidget {
  const ${className}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('$className')));
  }
}
''';
  }

  return '';
}

String _pascalCase(String value) {
  final parts = value
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .split('_')
      .where((p) => p.isNotEmpty);
  return parts.map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join();
}
