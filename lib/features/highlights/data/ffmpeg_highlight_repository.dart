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
import '../domain/entities/analysis.dart';
import '../domain/entities/highlight_plan.dart';
import '../domain/entities/moment.dart';
import '../domain/repositories/highlight_repository.dart';

class FfmpegHighlightRepository implements HighlightRepository {
  FfmpegHighlightRepository({
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
  Stream<AnalysisProgress> analyze(
    MediaAsset source,
    AnalysisSettings settings,
  ) async* {
    _cancelled = false;
    final duration = source.duration ?? const Duration(minutes: 3);

    final stages = <(AnalysisStage, double)>[
      (AnalysisStage.abrindo, 0.1),
      (AnalysisStage.lendoAudio, 0.3),
      (AnalysisStage.detectandoCenas, 0.6),
      (AnalysisStage.classificandoMomentos, 0.8),
      (AnalysisStage.montandoPlano, 0.9),
    ];

    for (final (stage, percent) in stages) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cancelled) return;

      // Mock de detecção de momentos baseada em duração
      yield AnalysisProgress(
        stage: stage,
        percent: percent,
        partialMoments: _generateMockMoments(duration),
      );
    }

    yield AnalysisProgress(
      stage: AnalysisStage.concluido,
      percent: 1.0,
      partialMoments: _generateMockMoments(duration),
    );
  }

  List<Moment> _generateMockMoments(Duration duration) {
    // Gera alguns momentos fixos para simular a análise
    return [
      Moment(
        id: 'm1',
        start: Duration.zero,
        end: Duration(seconds: 5),
        score: 0.9,
        signals: [MomentSignal.audioPico],
      ),
      Moment(
        id: 'm2',
        start: duration ~/ 2,
        end: (duration ~/ 2) + Duration(seconds: 5),
        score: 0.8,
        signals: [MomentSignal.rosto],
      ),
    ];
  }

  @override
  Stream<double> export(HighlightPlan plan, ExportSettings settings) async* {
    _cancelled = false;
    final sourcePath = plan.moments.isNotEmpty
        ? 'input_video_path' // Aqui deveria vir do source original
        : '';

    if (sourcePath.isEmpty) {
      yield 0.0;
      return;
    }

    final outputPath = await _staging.newOutputPath(
      prefix: 'highlights',
      extension: 'mp4',
    );

    final request = RenderRequest(
      arguments: FfmpegCommand.concatenate(
        inputPath: sourcePath,
        outputPath: outputPath,
        ranges: plan.moments.map((m) => MediaRange(m.start, m.end)).toList(),
        settings: RenderSettings(
          customWidth: settings.width,
          customHeight: settings.height,
          fps: settings.fps,
          quality: RenderQuality.equilibrado,
          keepAudio: true,
        ),
      ),
      outputPath: outputPath,
      expectedDurationMs: plan.totalLength.inMilliseconds,
      label: 'Exportando Melhores Momentos',
    );

    await for (final progress in engine.run(request)) {
      if (_cancelled) break;
      yield progress.fraction;
    }

    _lastOutputPath = outputPath;
  }

  @override
  Future<MediaAsset> buildResult(HighlightPlan plan) async {
    final path = _lastOutputPath;
    if (path == null) throw StateError('Nenhum export concluído.');

    final file = File(path);
    if (!file.existsSync()) throw StateError('Arquivo não encontrado.');

    return await probe.enrich(
      MediaAsset(
        path: path,
        name: path.split('/').last,
        kind: MediaKind.video,
        sizeBytes: file.lengthSync(),
        duration: plan.totalLength,
        width: 1080,
        height: 1920,
        fps: 30,
      ),
    );
  }

  @override
  void cancel() {
    _cancelled = true;
    engine.cancel();
  }
}
