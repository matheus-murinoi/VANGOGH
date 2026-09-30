class ClipSegment {
  const ClipSegment({
    required this.id,
    required this.start,
    required this.end,
  });

  final String id;
  final Duration start;
  final Duration end;

  Duration get length => end - start;

  bool get isEmpty => length <= Duration.zero;

  bool contains(Duration position) => position >= start && position < end;

  bool overlaps(ClipSegment other) => start < other.end && other.start < end;

  ClipSegment copyWith({String? id, Duration? start, Duration? end}) =>
      ClipSegment(
        id: id ?? this.id,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipSegment &&
          other.id == id &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(id, start, end);

  @override
  String toString() => 'ClipSegment($id, $start, $end)';
}
