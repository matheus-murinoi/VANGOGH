import 'moment.dart';

enum AnalysisStage {
  idle('Pronto'),
  abrindo('Abrindo vídeo'),
  lendoAudio('Lendo áudio'),
  detectandoCenas('Detectando cenas'),
  classificandoMomentos('Classificando momentos'),
  montandoPlano('Montando plano'),
  concluido('Análise concluída');

  const AnalysisStage(this.label);

  final String label;
}

class AnalysisProgress {
  const AnalysisProgress({
    required this.stage,
    required this.percent,
    this.partialMoments = const [],
  });

  final AnalysisStage stage;
  final double percent;
  final List<Moment> partialMoments;

  bool get isFinished => stage == AnalysisStage.concluido;
}

class AnalysisSettings {
  const AnalysisSettings({
    this.minSegment = const Duration(seconds: 3),
    this.maxSegment = const Duration(seconds: 20),
    this.minSilenceGap = const Duration(milliseconds: 400),
    this.detectFaces = true,
    this.silenceThresholdDb = -32,
  });

  final Duration minSegment;
  final Duration maxSegment;
  final Duration minSilenceGap;
  final bool detectFaces;
  final double silenceThresholdDb;
}

class ExportSettings {
  const ExportSettings({
    this.width = 1080,
    this.height = 1920,
    this.fps = 30,
    this.crf = 20,
    this.hardwareAccelerated = true,
  });

  final int width;
  final int height;
  final int fps;
  final int crf;
  final bool hardwareAccelerated;

  String get label => '${width}x$height · ${fps}fps';

  ExportSettings copyWith({
    int? width,
    int? height,
    int? fps,
    int? crf,
    bool? hardwareAccelerated,
  }) => ExportSettings(
    width: width ?? this.width,
    height: height ?? this.height,
    fps: fps ?? this.fps,
    crf: crf ?? this.crf,
    hardwareAccelerated: hardwareAccelerated ?? this.hardwareAccelerated,
  );

  static const vertical = ExportSettings();
  static const horizontal = ExportSettings(width: 1920, height: 1080);
  static const square = ExportSettings(width: 1080, height: 1080);
}
