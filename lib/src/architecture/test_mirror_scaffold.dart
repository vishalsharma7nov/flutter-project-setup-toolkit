import 'package:path/path.dart' as p;

/// Mirrors scaffolded feature files under `test/<featureRoot>/`.
List<String> testMirrorPathsForFeature({
  required String featureRoot,
  required List<String> scaffoldedPaths,
}) {
  return scaffoldedPaths
      .where((path) => path.endsWith('.dart'))
      .map((path) {
        final underFeature = p.relative(path, from: featureRoot);
        return p.join(
          'test',
          featureRoot,
          underFeature.replaceAll('.dart', '_test.dart'),
        );
      })
      .toList();
}

String testMirrorStubContent(String sourcePath) {
  return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TODO: $sourcePath', () {
    expect(true, isTrue);
  });
}
''';
}
