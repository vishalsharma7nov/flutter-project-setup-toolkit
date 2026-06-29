import 'package:flutter_project_setup_toolkit/src/api/api_config.dart';
import 'package:flutter_project_setup_toolkit/src/api/api_protocol.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_config.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_layers.dart';
import 'package:flutter_project_setup_toolkit/src/architecture/architecture_preset.dart';
import 'package:flutter_project_setup_toolkit/src/models.dart';
import 'package:test/test.dart';

void main() {
  test('ArchitectureConfig round-trips JSON', () {
    const config = ArchitectureConfig(
      preset: ArchitecturePreset.compassMvvm,
      featureBasePath: 'lib/ui',
    );
    final restored = ArchitectureConfig.fromJson(config.toJson());
    expect(restored.preset, ArchitecturePreset.compassMvvm);
    expect(restored.featureBasePath, 'lib/ui');
  });

  test('ApiConfig round-trips external SDK', () {
    final config = ApiConfig(
      protocol: ApiProtocol.externalSdk,
      clientSource: ApiClientSource.externalSdk,
      externalSdk: ExternalSdkConfig(
        packageName: 'acme_mobile_sdk',
        source: 'git',
        git: ExternalSdkGitSource(
          url: 'https://github.com/example/sdk.git',
          ref: 'v1.0.0',
        ),
      ),
    );
    final restored = ApiConfig.fromJson(config.toJson());
    expect(restored.usesExternalSdk, isTrue);
    expect(restored.externalSdk?.packageName, 'acme_mobile_sdk');
  });

  test('simple preset uses screens widgets services', () {
    final dirs = architectureFeatureDirectories(
      preset: ArchitecturePreset.simple,
      stateManagement: StateManagement.none,
      layers: const ArchitectureLayersConfig(),
    );
    expect(dirs, contains('screens'));
    expect(dirs, contains('services'));
  });

  test('grpc protocol uses grpc datasource file name', () {
    final files = architectureFeatureFilePaths(
      preset: ArchitecturePreset.featureFirstClean,
      prefix: 'auth_',
      stateManagement: StateManagement.none,
      layers: const ArchitectureLayersConfig(),
      api: ApiConfig(protocol: ApiProtocol.grpc),
    );
    expect(
      files.any((f) => f.contains('grpc_service.dart')),
      isTrue,
    );
  });

  test('external SDK uses sdk_data_source file name', () {
    final files = architectureFeatureFilePaths(
      preset: ArchitecturePreset.featureFirstClean,
      prefix: 'ride_',
      stateManagement: StateManagement.none,
      layers: const ArchitectureLayersConfig(),
      api: const ApiConfig(
        protocol: ApiProtocol.externalSdk,
        clientSource: ApiClientSource.externalSdk,
      ),
    );
    expect(
      files.any((f) => f.contains('sdk_data_source.dart')),
      isTrue,
    );
    expect(
      files.any((f) => f.contains('remote_data_source.dart')),
      isFalse,
    );
  });
}
