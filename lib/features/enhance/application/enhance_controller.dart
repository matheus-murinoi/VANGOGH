import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/engine_providers.dart';
import '../../../core/media/media_asset.dart';
import '../../../core/media/media_providers.dart';
import '../data/ffmpeg_enhance_repository.dart';
import '../domain/entities/enhance_job.dart';
import '../domain/entities/enhance_options.dart';
import '../domain/repositories/enhance_repository.dart';

enum EnhanceStatus { idle, running, done, failure }

class EnhanceState {
  const EnhanceState({
    this.sources = const [],
    this.options = const EnhanceOptions(),
    this.status = EnhanceStatus.idle,
    this.stage = EnhanceStage.idle,
    this.progress = 0,
    this.etaSeconds,
    this.results = const [],
    this.errorMessage,
  });

  final List<MediaAsset> sources;
  final EnhanceOptions options;
  final EnhanceStatus status;
  final EnhanceStage stage;
  final double progress;
  final int? etaSeconds;
  final List<MediaAsset> results;
  final String? errorMessage;

  bool get hasSources => sources.isNotEmpty;

  bool get isRunning => status == EnhanceStatus.running;

  EnhanceJob get job => EnhanceJob(
    sources: sources,
    options: options,
    results: results,
  );

  EnhanceState copyWith({
    List<MediaAsset>? sources,
    EnhanceOptions? options,
    EnhanceStatus? status,
    EnhanceStage? stage,
    double? progress,
    int? etaSeconds,
    bool clearEta = false,
    List<MediaAsset>? results,
    String? errorMessage,
    bool clearError = false,
  }) => EnhanceState(
    sources: sources ?? this.sources,
    options: options ?? this.options,
    status: status ?? this.status,
    stage: stage ?? this.stage,
    progress: progress ?? this.progress,
    etaSeconds: clearEta ? null : (etaSeconds ?? this.etaSeconds),
    results: results ?? this.results,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

final enhanceRepositoryProvider = Provider<EnhanceRepository>(
  (ref) => FfmpegEnhanceRepository(
    engine: ref.watch(renderEngineProvider),
    probe: ref.watch(mediaProbeProvider),
  ),
);

final enhanceControllerProvider =
    NotifierProvider<EnhanceController, EnhanceState>(
      EnhanceController.new,
    );

class EnhanceController extends Notifier<EnhanceState> {
  StreamSubscription<EnhanceProgress>? _subscription;

  @override
  EnhanceState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const EnhanceState();
  }

  EnhanceRepository get _repository => ref.read(enhanceRepositoryProvider);

  void setSources(List<MediaAsset> sources) {
    state = state.copyWith(
      sources: sources,
      options: state.options.copyWith(
        kind: sources.length == 1 && sources.first.kind == MediaKind.image
            ? EnhanceKind.images
            : state.options.kind,
      ),
      results: const [],
      clearError: true,
    );
  }

  void addSource(MediaAsset source) {
    setSources([...state.sources, source]);
  }

  void removeSource(MediaAsset source) {
    state = state.copyWith(
      sources: state.sources.where((s) => s.path != source.path).toList(),
    );
  }

  void updateOptions(EnhanceOptions options) {
    state = state.copyWith(options: options, clearError: true);
  }

  void setKind(EnhanceKind kind) {
    updateOptions(state.options.copyWith(kind: kind));
  }

  Future<void> run() async {
    if (state.sources.isEmpty || state.isRunning) return;

    _subscription?.cancel();
    state = state.copyWith(
      status: EnhanceStatus.running,
      stage: EnhanceStage.preparing,
      progress: 0,
      results: const [],
      clearError: true,
    );

    _subscription = _repository
        .enhance(state.sources, state.options)
        .listen(
          (progress) {
            state = state.copyWith(
              stage: progress.stage,
              progress: progress.percent,
              etaSeconds: progress.etaSeconds,
              clearEta: progress.etaSeconds == null,
            );
          },
          onError: (Object error) {
            state = state.copyWith(
              status: EnhanceStatus.failure,
              errorMessage: 'Falha ao melhorar: $error',
            );
          },
        );

    await _subscription?.asFuture<void>().catchError((_) {});
    if (state.status != EnhanceStatus.running) return;

    final results = <MediaAsset>[];
    for (final source in state.sources) {
      if (state.status != EnhanceStatus.running) return;
      results.add(await _repository.buildResult(source, state.options));
    }
    if (state.status != EnhanceStatus.running) return;

    state = state.copyWith(
      status: EnhanceStatus.done,
      stage: EnhanceStage.done,
      progress: 1,
      clearEta: true,
      results: results,
    );
  }

  void cancel() {
    _repository.cancel();
    _subscription?.cancel();
    state = state.copyWith(
      status: EnhanceStatus.idle,
      stage: EnhanceStage.idle,
      progress: 0,
      clearEta: true,
    );
  }
}
