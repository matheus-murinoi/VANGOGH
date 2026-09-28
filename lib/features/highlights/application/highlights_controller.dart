import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_asset.dart';
import '../../../core/media/media_picker.dart';
import '../data/mock_highlight_repository.dart';
import '../domain/entities/analysis.dart';
import '../domain/entities/target_duration.dart';
import '../domain/repositories/highlight_repository.dart';
import 'highlights_state.dart';

final mediaPickerProvider = Provider<MediaPicker>((ref) => const MediaPicker());

final highlightRepositoryProvider = Provider<HighlightRepository>(
  (ref) => MockHighlightRepository(),
);

final highlightsControllerProvider =
    NotifierProvider<HighlightsController, HighlightsState>(
      HighlightsController.new,
    );

class HighlightsController extends Notifier<HighlightsState> {
  StreamSubscription<dynamic>? _subscription;

  @override
  HighlightsState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const HighlightsState();
  }

  HighlightRepository get _repository => ref.read(highlightRepositoryProvider);

  void selectSource(MediaAsset asset) {
    state = state.copyWith(
      source: asset,
      status: HighlightsStatus.idle,
      stage: AnalysisStage.idle,
      progress: 0,
      candidates: const [],
      excluded: const {},
      clearError: true,
    );
  }

  void clearSource() {
    _repository.cancel();
    _subscription?.cancel();
    state = HighlightsState(target: state.target);
  }

  void setTarget(TargetDuration target) {
    state = state.copyWith(target: target);
  }

  void setExportSettings(ExportSettings settings) {
    state = state.copyWith(exportSettings: settings);
  }

  void toggleMoment(String id) {
    final next = {...state.excluded};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(excluded: next);
  }

  void keepOnlyTop(int count) {
    final ranked = [...state.candidates]..sort(
      (a, b) => b.score.compareTo(a.score),
    );
    final keep = ranked.take(count).map((m) => m.id).toSet();
    state = state.copyWith(excluded: state.candidates.map((m) => m.id).toSet()..removeAll(keep));
  }

  Future<void> analyze() async {
    final source = state.source;
    if (source == null || state.isBusy) return;

    _subscription?.cancel();
    state = state.copyWith(
      status: HighlightsStatus.analyzing,
      stage: AnalysisStage.abrindo,
      progress: 0,
      candidates: const [],
      excluded: const {},
      clearError: true,
    );

    _subscription = _repository
        .analyze(source, state.analysisSettings)
        .listen(
          (progress) {
            state = state.copyWith(
              stage: progress.stage,
              progress: progress.percent,
              candidates: progress.partialMoments,
              status: progress.isFinished
                  ? HighlightsStatus.ready
                  : HighlightsStatus.analyzing,
            );
          },
          onError: (Object error) {
            state = state.copyWith(
              status: HighlightsStatus.failure,
              errorMessage: 'Falha na análise: $error',
            );
          },
        );
  }

  Future<void> export() async {
    final source = state.source;
    if (source == null || state.isBusy) return;

    final plan = state.plan;
    if (plan.moments.isEmpty) {
      state = state.copyWith(
        status: HighlightsStatus.failure,
        errorMessage: 'Nenhum momento selecionado.',
      );
      return;
    }

    _subscription?.cancel();
    state = state.copyWith(
      status: HighlightsStatus.exporting,
      progress: 0,
      clearError: true,
    );

    _subscription = _repository.export(plan, state.exportSettings).listen(
      (value) => state = state.copyWith(progress: value),
      onError: (Object error) {
        state = state.copyWith(
          status: HighlightsStatus.failure,
          errorMessage: 'Falha na exportação: $error',
        );
      },
      onDone: () async {
        final result = await _repository.buildResult(plan);
        state = state.copyWith(
          status: HighlightsStatus.done,
          progress: 1,
          result: result,
        );
      },
    );
  }

  void cancel() {
    _repository.cancel();
    _subscription?.cancel();
    state = state.copyWith(status: HighlightsStatus.idle, progress: 0);
  }
}
