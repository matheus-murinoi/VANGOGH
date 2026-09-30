import 'clip_segment.dart';

class TrimPlan {
  const TrimPlan({
    required this.sourceDuration,
    required this.segments,
  });

  final Duration sourceDuration;
  final List<ClipSegment> segments;

  bool get isEmpty => segments.isEmpty;

  int get cutCount => segments.isEmpty ? 0 : segments.length - 1;

  Duration get totalLength => segments.fold(
    Duration.zero,
    (sum, segment) => sum + segment.length,
  );

  int get secondsRemoved => (sourceDuration - totalLength).inSeconds.clamp(0, 1 << 30);

  double get keptRatio {
    final total = sourceDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (totalLength.inMilliseconds / total).clamp(0, 1);
  }

  int get estimatedFrames =>
      segments.fold(0, (sum, segment) => sum + segment.length.inMilliseconds ~/ 40);
}
