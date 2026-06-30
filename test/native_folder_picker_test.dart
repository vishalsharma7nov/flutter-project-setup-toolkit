import 'package:flutter_project_setup_toolkit/src/studio/native_folder_picker.dart';
import 'package:test/test.dart';

void main() {
  test('nativeFolderPickerAvailable returns bool without throwing', () {
    expect(nativeFolderPickerAvailable(), isA<bool>());
  });
}
