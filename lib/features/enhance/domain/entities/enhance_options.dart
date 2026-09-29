enum EnhanceKind {
  video('Vídeo', 'Upscale e nitidez frame a frame'),
  images('Imagens', 'Upscale e nitidez em lote');

  const EnhanceKind(this.label, this.hint);

  final String label;
  final String hint;
}

enum EnhancePreset {
  hd720(1280, 720, 'HD', 'Mais leve, exporta rápido'),
  fullHd(1920, 1080, 'Full HD', 'Padrão do YouTube'),
  qhd(2560, 1440, '2K', 'Mais detalhes'),
  ultraHd(3840, 2160, '4K', 'Máxima qualidade'),
  keepOriginal(null, null, 'Original', 'Não redimensiona, só melhora');

  const EnhancePreset(this.width, this.height, this.label, this.hint);

  final int? width;
  final int? height;
  final String label;
  final String hint;

  bool get resizes => width != null;

  String get resolutionLabel =>
      width == null ? '—' : '${width}x$height';
}

class EnhanceOptions {
  const EnhanceOptions({
    this.kind = EnhanceKind.video,
    this.preset = EnhancePreset.fullHd,
    this.aiUpscale = true,
    this.denoise = false,
    this.sharpen = true,
    this.stabilize = false,
    this.normalizeAudio = true,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.targetFps = 30,
  });

  final EnhanceKind kind;
  final EnhancePreset preset;
  final bool aiUpscale;
  final bool denoise;
  final bool sharpen;
  final bool stabilize;
  final bool normalizeAudio;
  final double brightness;
  final double contrast;
  final double saturation;
  final int targetFps;

  double get estimatedScaleFactor {
    if (!preset.resizes) return 1;
    final target = preset.width!;
    final source = 1080;
    if (target <= source) return 1;
    return double.parse((target / source).toStringAsFixed(1));
  }

  List<String> get activeFilters => [
    if (preset.resizes) 'Escala ${preset.resolutionLabel}',
    if (aiUpscale) 'Upscale IA (${estimatedScaleFactor}x)',
    if (denoise) 'Redução de ruído',
    if (sharpen) 'Nitidez',
    if (kind == EnhanceKind.video && stabilize) 'Estabilização',
    if (kind == EnhanceKind.video && normalizeAudio) 'Normalizar áudio',
    if (brightness != 0) 'Brilho ${_signed(brightness)}',
    if (contrast != 0) 'Contraste ${_signed(contrast)}',
    if (saturation != 0) 'Saturação ${_signed(saturation)}',
  ];

  String _signed(double value) =>
      '${value > 0 ? '+' : ''}${(value * 100).round()}%';

  EnhanceOptions copyWith({
    EnhanceKind? kind,
    EnhancePreset? preset,
    bool? aiUpscale,
    bool? denoise,
    bool? sharpen,
    bool? stabilize,
    bool? normalizeAudio,
    double? brightness,
    double? contrast,
    double? saturation,
    int? targetFps,
  }) => EnhanceOptions(
    kind: kind ?? this.kind,
    preset: preset ?? this.preset,
    aiUpscale: aiUpscale ?? this.aiUpscale,
    denoise: denoise ?? this.denoise,
    sharpen: sharpen ?? this.sharpen,
    stabilize: stabilize ?? this.stabilize,
    normalizeAudio: normalizeAudio ?? this.normalizeAudio,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    targetFps: targetFps ?? this.targetFps,
  );
}
