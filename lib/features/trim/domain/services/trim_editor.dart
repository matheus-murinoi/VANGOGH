import '../entities/clip_segment.dart';

abstract final class TrimEditor {
  static const minSegment = Duration(milliseconds: 200);

  static List<ClipSegment> initial({
    required Duration sourceDuration,
    required String id,
  }) => [
    ClipSegment(id: id, start: Duration.zero, end: sourceDuration),
  ];

  static Duration snap(Duration position, {int? fps}) {
    if (fps == null || fps <= 0) return position;
    final frames = (position.inMilliseconds * fps / 1000).round();
    return Duration(milliseconds: (frames * 1000 / fps).round());
  }

  static Duration clamp(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int? indexOfSegmentAt(
    List<ClipSegment> segments,
    Duration position, {
    Duration tolerance = Duration.zero,
  }) {
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].contains(position)) return i;
    }
    if (tolerance <= Duration.zero) return null;
    int? best;
    var bestGap = tolerance;
    for (var i = 0; i < segments.length; i++) {
      final distance = (segments[i].start - position).abs();
      if (distance <= bestGap) {
        bestGap = distance;
        best = i;
      }
    }
    return best;
  }

  static ({List<ClipSegment> segments, int activeIndex}) split({
    required List<ClipSegment> segments,
    required Duration position,
    required Duration sourceDuration,
    required String Function() idFor,
    int? fps,
    Duration minLength = minSegment,
  }) {
    final index = indexOfSegmentAt(segments, position);
    if (index == null) return (segments: segments, activeIndex: -1);

    final segment = segments[index];
    final cut = snap(clamp(position, Duration.zero, sourceDuration), fps: fps);
    if (!segment.contains(cut)) return (segments: segments, activeIndex: -1);

    final head = segment.copyWith(end: cut);
    final tail = segment.copyWith(id: idFor(), start: cut);
    if (head.length < minLength || tail.length < minLength) {
      return (segments: segments, activeIndex: -1);
    }

    final next = [...segments]..[index] = head;
    next.insert(index + 1, tail);
    return (
      segments: normalize(segments: next, sourceDuration: sourceDuration),
      activeIndex: index + 1,
    );
  }

  static List<ClipSegment> removeAt({
    required List<ClipSegment> segments,
    required int index,
    required Duration sourceDuration,
  }) {
    if (index < 0 || index >= segments.length) return segments;
    return normalize(
      segments: [...segments]..removeAt(index),
      sourceDuration: sourceDuration,
    );
  }

  static List<ClipSegment> updateEdges({
    required List<ClipSegment> segments,
    required int index,
    required Duration sourceDuration,
    Duration? start,
    Duration? end,
    int? fps,
    Duration minLength = minSegment,
  }) {
    if (index < 0 || index >= segments.length) return segments;
    final segment = segments[index];
    final limit = sourceDuration;
    final nextStart = clamp(snap(start ?? segment.start, fps: fps), Duration.zero, limit);
    final nextEnd = clamp(snap(end ?? segment.end, fps: fps), Duration.zero, limit);
    final low = nextStart <= nextEnd ? nextStart : nextEnd;
    final high = nextStart <= nextEnd ? nextEnd : nextStart;
    if (high - low < minLength) return segments;

    final next = [...segments]..[index] = segment.copyWith(start: low, end: high);
    return normalize(segments: next, sourceDuration: limit);
  }

  static List<ClipSegment> keepOnly({
    required List<ClipSegment> segments,
    required int index,
  }) {
    if (index < 0 || index >= segments.length) return segments;
    return List.unmodifiable([segments[index]]);
  }

  static List<ClipSegment> normalize({
    required List<ClipSegment> segments,
    required Duration sourceDuration,
  }) {
    final cleaned = segments
        .map(
          (segment) => segment.copyWith(
            start: clamp(segment.start, Duration.zero, sourceDuration),
            end: clamp(segment.end, Duration.zero, sourceDuration),
          ),
        )
        .where((segment) => !segment.isEmpty)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <ClipSegment>[];
    for (final segment in cleaned) {
      final previous = merged.isEmpty ? null : merged.last;
      if (previous != null && previous.overlaps(segment)) {
        merged.removeLast();
        merged.add(
          previous.copyWith(
            end: previous.end > segment.end ? previous.end : segment.end,
          ),
        );
        continue;
      }
      merged.add(segment);
    }
    return List.unmodifiable(merged);
  }
}
