enum MomentSignal {
  audioPico('Pico de áudio', 1.0),
  risada('Risada', 0.95),
  fala('Fala em destaque', 0.88),
  rosto('Rosto em foco', 0.84),
  movimento('Movimento', 0.70),
  transicao('Virada de cena', 0.60),
  fimSilencio('Fim de silêncio', 0.50);

  const MomentSignal(this.label, this.weight);

  final String label;
  final double weight;
}

class Moment {
  const Moment({
    required this.id,
    required this.start,
    required this.end,
    required this.score,
    required this.signals,
  });

  final String id;
  final Duration start;
  final Duration end;
  final double score;
  final List<MomentSignal> signals;

  Duration get length => end - start;

  MomentSignal? get topSignal =>
      signals.isEmpty ? null : signals.reduce((a, b) => a.weight >= b.weight ? a : b);

  Moment copyWith({Duration? start, Duration? end, double? score}) => Moment(
    id: id,
    start: start ?? this.start,
    end: end ?? this.end,
    score: score ?? this.score,
    signals: signals,
  );

  bool overlaps(Moment other) =>
      start < other.end && other.start < end;
}
