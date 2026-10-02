import 'dart:async';
import 'dart:io';

import '../../../core/engine/command_builder.dart';
import '../../../core/engine/ffmpeg_render_engine.dart';
import '../../../core/engine/media_range.dart';
import '../../../core/engine/render_engine.dart';
import '../../../core/engine/render_job.dart';
import '../../../core/engine/staging.dart';
import '../../../core/media/media_asset.dart';
import '../../../core/media/media_probe.dart';
import '../../../core/media/render_settings.dart';
import '../domain/entities/enhance_job.dart';
import '../domain/entities/enhance_options.dart';
import '../domain/repositories/enhance_repository.dart';

class FfmpegEnhanceRepository implements EnhanceRepository {
  FfmpegEnhanceRepository({
    required this.engine,
    required this.probe,
    RenderStaging? staging,
  }) : _staging = staging ?? const RenderStaging();

  final RenderEngine engine;
  final MediaProbe probe;
  final RenderStaging _staging;

  bool _cancelled = false;
  String? _lastOutputPath;

  @override
  Stream<EnhanceProgress> enhance(
    List<MediaAsset> sources,
    EnhanceOptions options,
  ) async* {
    _cancelled = false;

    // Para simplificar, processamos a primeira fonte ou simulamos lote
    // Em uma implementação real, faríamos um loop de RenderRequests
    final source = sources.first;
    final outputPath = await _staging.newOutputPath(
      prefix: 'aprimorado',
      extension: source.kind == MediaKind.image ? 'png' : 'mp4',
    );

    final hasAudio = source.kind == MediaKind.video;

    final request = RenderRequest(
      arguments: FfmpegCommand.concatenate(
        inputPath: source.path,
        outputPath: outputPath,
        ranges: [MediaRange(Duration.zero, source.duration ?? const Duration(seconds: 1))],
        settings: RenderSettings(
          format: RenderFormat(
            width: options.preset.width,
            height: options.preset.height,
          ),
          fps: options.targetFps,
          quality: RenderQuality.equilibrado,
          keepAudio: options.normalizeAudio,
        ),
        sourceHasAudio: hasAudio,
      ),
      outputPath: outputPath,
      expectedDurationMs: source.duration?.inMilliseconds ?? 0,
      label: 'Melhorando vídeo',
    );

    await for (final progress in engine.run(request)) {
      if (_cancelled) {
        yield EnhanceProgress(stage: EnhanceStage.idle, percent: 0);
        return;
      }

      yield EnhanceProgress(
        stage: _mapStage(progress.stage),
        percent: progress.fraction,
        etaSeconds: progress.eta?.inSeconds,
      );
    }

    _lastOutputPath = outputPath;
  }

  EnhanceStage _mapStage(RenderStage stage) {
    return switch (stage) {
      RenderStage.preparing => EnhanceStage.preparing,
      RenderStage.processing => EnhanceStage.processing,
      RenderStage.encoding => EnhanceStage.encoding,
      RenderStage.finalizing => EnhanceStage.saving,
      RenderStage.done => EnhanceStage.done,
    };
  }

  @override
  Future<MediaAsset> buildResult(
    MediaAsset source,
    EnhanceOptions options,
  ) async {
    final path = _lastOutputPath;
    if (path == null) throw StateError('Nenhum render concluído.');

    final file = File(path);
    if (!file.existsSync()) throw StateError('Arquivo de resultado não encontrado.');

    return await probe.enrich(
      MediaAsset(
        path: path,
        name: path.split('/').last,
        kind: source.kind,
        sizeBytes: file.lengthSync(),
        duration: source.duration,
        width: options.preset.width,
        height: options.preset.height,
        fps: options.targetFps.toDouble(),
      ),
    );
  }

  @override
  void cancel() {
    _cancelled = true;
    engine.cancel();
  }
}
