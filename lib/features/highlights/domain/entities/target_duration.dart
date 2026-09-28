enum TargetDuration {
  seg30(Duration(seconds: 30)),
  seg45(Duration(seconds: 45)),
  min1(Duration(minutes: 1)),
  min1e30(Duration(seconds: 90)),
  min2(Duration(minutes: 2));

  const TargetDuration(this.duration);

  final Duration duration;

  String get label => switch (this) {
    TargetDuration.seg30 => '30s',
    TargetDuration.seg45 => '45s',
    TargetDuration.min1 => '1min',
    TargetDuration.min1e30 => '1min30',
    TargetDuration.min2 => '2min',
  };

  String get longLabel => switch (this) {
    TargetDuration.seg30 => '30 segundos',
    TargetDuration.seg45 => '45 segundos',
    TargetDuration.min1 => '1 minuto',
    TargetDuration.min1e30 => '1 minuto e meio',
    TargetDuration.min2 => '2 minutos',
  };

  String get hint => switch (this) {
    TargetDuration.seg30 => 'Reels, TikTok, Shorts',
    TargetDuration.seg45 => 'Cortes rápidos',
    TargetDuration.min1 => 'Compilação curta',
    TargetDuration.min1e30 => 'Melhor equilíbrio',
    TargetDuration.min2 => 'Resumo com contexto',
  };

  static const TargetDuration defaultChoice = TargetDuration.min1e30;
}
