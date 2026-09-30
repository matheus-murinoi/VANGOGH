/// Trecho de mídia com início e fim absolutos, em segundos de mídia.
///
/// É o tipo de troca entre o domínio de cada feature e o motor de render.
/// Cada feature converte suas entidades (`ClipSegment`, `Moment`, ...) para
/// `MediaRange`, de modo que `core/engine` nunca dependa de `features/`.
class MediaRange {
  const MediaRange(this.start, this.end);

  final Duration start;
  final Duration end;

  Duration get length => end - start;

  bool get isEmpty => length <= Duration.zero;

  /// Rótulo temporal seguro para nome de arquivo, ex.: `000004.500-000012.000`.
  String get fileLabel => '${stamp(start)}-${stamp(end)}';

  static String stamp(Duration value) {
    final ms = value.inMilliseconds.clamp(0, 1 << 40);
    return (ms / 1000).toStringAsFixed(3).padLeft(8, '0');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'MediaRange($start → $end)';
}
