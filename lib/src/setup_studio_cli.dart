import 'toolkit_studio_cli.dart';

Future<int> runSetupStudio(List<String> arguments) async {
  final forwarded = <String>['--view', 'setup', ...arguments];
  return runToolkitStudio(forwarded);
}
