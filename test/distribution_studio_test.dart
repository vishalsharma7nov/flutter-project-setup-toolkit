import 'package:flutter_project_setup_toolkit/src/distribution/distribution_models.dart';
import 'package:flutter_project_setup_toolkit/src/distribution/distribution_ui_html.dart';
import 'package:test/test.dart';

void main() {
  test('DistributionJobState serializes logs with offset', () {
    final state = DistributionJobState(
      status: DistributionJobStatus.running,
      target: DistributionTarget.both,
      logs: ['line1', 'line2', 'line3'],
    );

    final json = state.toJson(logOffset: 1);
    expect(json['status'], 'running');
    expect(json['target'], 'both');
    expect(json['logs'], ['line2', 'line3']);
    expect(json['log_total'], 3);
  });

  test('distribution studio HTML includes core UI labels', () {
    final html = distributionStudioHtml();
    expect(html, contains('Distribution Studio'));
    expect(html, contains('Android APK'));
    expect(html, contains('Android AAB'));
    expect(html, contains('iOS TestFlight'));
    expect(html, contains('Cancel build'));
    expect(html, contains('Build both platforms'));
    expect(html, contains('release-toolkit.config.json'));
    expect(html, contains('Save config before build'));
  });
}
