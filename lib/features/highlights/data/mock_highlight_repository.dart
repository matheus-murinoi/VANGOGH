import 'dart:async';
import 'dart:math';

import '../../../core/media/media_asset.dart';
import '../domain/entities/analysis.dart';
import '../domain/entities/highlight_plan.dart';
import '../domain/entities/moment.dart';
import '../domain/repositories/highlight_repository.dart';

class MockHighlightRepository implements HighlightRepository {
  MockHighlightRepository({this.sourceDuration = const Duration(minutes: 3)});

  final Duration sourceDuration;
  final Random _random = Random(7);

  bool _cancelled = false;

  Future<void> _wait(Duration delay) => Future<void>.delayed(delay);

  bool get _stopped => _cancelled;

  @override
  Stream<AnalysisProgress> analyze(
    MediaAsset source,
    AnalysisSettings settings,
  ) async* {
    _cancelled = false;
    final duration = source.duration ?? sourceDuration;
    final steps = <(AnalysisStage, double, double)>[
      (AnalysisStage.abrindo, 0.08, 0.04),
      (AnalysisStage.lendoAudio, 0.26, 0.22),
      (AnalysisStage.detectandoCenas, 0.48, 0.40),
      (AnalysisStage.classificandoMomentos, 0.70, 0.64),
      (AnalysisStage.montandoPlano, 0.88, 0.84),
    ];

    final collected = <Moment>[];
    for (final (stage, percent, threshold) in steps) {
      await _wait(const Duration(milliseconds: 420));
      if (_stopped) return;
      collected
        ..clear()
        ..addAll(_generate(duration, threshold));
      yield AnalysisProgress(
        stage: stage,
        percent: percent,
        partialMoments: List.unmodifiable(collected),
      );
    }

    yield AnalysisProgress(
      stage: AnalysisStage.concluido,
      percent: 1,
      partialMoments: List.unmodifiable(collected),
    );
  }

  List<Moment> _generate(Duration duration, double density) {
    final windowMs = duration.inMilliseconds;
    final wanted = 14 + (density * 18).round();
    final pool = <MomentSignal>[
      MomentSignal.audioPico,
      MomentSignal.risada,
      MomentSignal.fala,
      MomentSignal.rosto,
      MomentSignal.movimento,
      MomentSignal.transicao,
      MomentSignal.fimSilencio,
    ];

    final raw = List.generate(wanted, (i) {
      final startMs =
          (windowMs * (i / wanted) + _random.nextInt(4000))
              .round()
              .clamp(0, windowMs - 1);
      final lengthMs = 2600 + _random.nextInt(12000);
      final signals = <MomentSignal>{
        pool[_random.nextInt(pool.length)],
        pool[_random.nextInt(pool.length)],
        pool[_random.nextInt(pool.length)],
      }.toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      return Moment(
        id: 'm$i',
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: startMs + lengthMs),
        score: 0.35 + _random.nextDouble() * 0.6,
        signals: signals,
      );
    });

    raw.sort((a, b) => b.score.compareTo(a.score));
    final deduped = <Moment>[];
    for (final moment in raw) {
      if (deduped.every((m) => !m.overlaps(moment))) deduped.add(moment);
    }
    deduped.sort((a, b) => a.start.compareTo(b.start));
    return deduped;
  }

  @override
  Stream<double> export(HighlightPlan plan, ExportSettings settings) async* {
    _cancelled = false;
    for (var i = 0; i <= 20; i++) {
      await _wait(const Duration(milliseconds: 180));
      if (_stopped) return;
      yield i / 20;
    }
  }

  @override
  Future<MediaAsset> buildResult(HighlightPlan plan) async {
    await _wait(const Duration(milliseconds: 300));
    return MediaAsset(
      path: '/saida/melhores_momentos.mp4',
      name: 'melhores_momentos.mp4',
      kind: MediaKind.video,
      sizeBytes: plan.totalLength.inSeconds * 2_400_000,
      duration: plan.totalLength,
      width: 1080,
      height: 1920,
      fps: 30,
    );
  }

  @override
  void cancel() => _cancelled = true;
}
