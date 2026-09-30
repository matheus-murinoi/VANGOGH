import '../../../../core/media/media_asset.dart';
import '../../../../core/media/render_settings.dart';
import '../domain/entities/clip_segment.dart';
import '../domain/entities/trim_plan.dart';

enum TrimStatus { idle, ready, rendering, done, failure }

class TrimState {
  const TrimState({
    this.source,
    this.sourceDuration = const Duration(minutes: 1),
    this.segments = const [],
    this.activeIndex = 0,
    this.playhead = Duration.zero,
    this.seekToken = 0,
    this.settings = RenderSettings.defaults,
    this.status = TrimStatus.idle,
    this.progress = 0,
    this.undoCount = 0,
    this.redoCount = 0,
    this.result,
    this.errorMessage,
  });

  final MediaAsset? source;
  final Duration sourceDuration;
  final List<ClipSegment> segments;
  final int activeIndex;
  final Duration playhead;
  final int seekToken;
  final RenderSettings settings;
  final TrimStatus status;
  final double progress;
  final int undoCount;
  final int redoCount;
  final MediaAsset? result;
  final String? errorMessage;

  bool get hasSource => source != null;

  bool get isRendering => status == TrimStatus.rendering;

  bool get isEmpty => segments.isEmpty;

  bool get canUndo => undoCount > 0;

  bool get canRedo => redoCount > 0;

  bool get canSplit =>
      segments.isNotEmpty &&
      segments.any((segment) => segment.contains(playhead));

  ClipSegment? get activeSegment {
    if (segments.isEmpty) return null;
    if (activeIndex < 0 || activeIndex >= segments.length) return null;
    return segments[activeIndex];
  }

  Duration get playheadInSource =>
      TrimState.clamp(playhead, Duration.zero, sourceDuration);

  TrimPlan get plan =>
      TrimPlan(sourceDuration: sourceDuration, segments: segments);

  static Duration clamp(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  TrimState copyWith({
    MediaAsset? source,
    Duration? sourceDuration,
    List<ClipSegment>? segments,
    int? activeIndex,
    Duration? playhead,
    int? seekToken,
    RenderSettings? settings,
    TrimStatus? status,
    double? progress,
    int? undoCount,
    int? redoCount,
    MediaAsset? result,
    String? errorMessage,
    bool clearSource = false,
    bool clearResult = false,
    bool clearError = false,
  }) => TrimState(
    source: clearSource ? null : (source ?? this.source),
    sourceDuration: sourceDuration ?? this.sourceDuration,
    segments: segments ?? this.segments,
    activeIndex: activeIndex ?? this.activeIndex,
    playhead: playhead ?? this.playhead,
    seekToken: seekToken ?? this.seekToken,
    settings: settings ?? this.settings,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    undoCount: undoCount ?? this.undoCount,
    redoCount: redoCount ?? this.redoCount,
    result: clearResult ? null : (result ?? this.result),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
