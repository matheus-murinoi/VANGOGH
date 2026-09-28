import 'dart:async';

import '../../../core/media/media_asset.dart';
import '../domain/entities/enhance_job.dart';
import '../domain/entities/enhance_options.dart';
import '../domain/repositories/enhance_repository.dart';

class MockEnhanceRepository implements EnhanceRepository {
  bool _cancelled = false;

  Future<void> _wait(Duration delay) => Future<void>.delayed(delay);

  @override
  Stream<EnhanceProgress> enhance(
    List<MediaAsset> sources,
    EnhanceOptions options,
  ) async* {
    _cancelled = false;
    const stages = <(EnhanceStage, double, int)>[
      (EnhanceStage.preparing, 0.08, 0),
      (EnhanceStage.decoding, 0.22, 0),
      (EnhanceStage.processing, 0.46, 30),
      (EnhanceStage.processing, 0.70, 12),
      (EnhanceStage.encoding, 0.90, 4),
      (EnhanceStage.saving, 0.98, 1),
    ];

    for (final (stage, percent, eta) in stages) {
      await _wait(const Duration(milliseconds: 500));
      if (_cancelled) return;
      yield EnhanceProgress(stage: stage, percent: percent, etaSeconds: eta);
    }

    yield EnhanceProgress(stage: EnhanceStage.done, percent: 1);
  }

  @override
  Future<MediaAsset> buildResult(
    MediaAsset source,
    EnhanceOptions options,
  ) async {
    await _wait(const Duration(milliseconds: 200));
    final width = options.preset.width ?? (source.width ?? 1920);
    final height = options.preset.height ?? (source.height ?? 1080);
    final extension = source.kind == MediaKind.image ? 'png' : 'mp4';
    return MediaAsset(
      path: '/saida/aprimorado.$extension',
      name: 'aprimorado.$extension',
      kind: source.kind,
      sizeBytes: (source.sizeBytes * 1.4).round(),
      duration: source.duration,
      width: width,
      height: height,
      fps: source.kind == MediaKind.video ? options.targetFps.toDouble() : null,
    );
  }

  @override
  void cancel() => _cancelled = true;
}
