enum RenderQuality {
  leve('Leve', 'Arquivo pequeno, exporta mais rápido', 28),
  equilibrado('Equilibrado', 'Recomendado', 23),
  maxima('Máxima', 'Melhor imagem, arquivo maior', 18);

  const RenderQuality(this.label, this.hint, this.crf);

  final String label;
  final String hint;
  final int crf;
}

enum OutputFormat {
  original('Original', 'Proporção do vídeo', null, null),
  vertical('Vertical 9:16', 'Reels, Shorts, TikTok', 1080, 1920),
  square('Quadrado 1:1', 'Feed', 1080, 1080),
  horizontal('Horizontal 16:9', 'YouTube', 1920, 1080);

  const OutputFormat(this.label, this.hint, this.width, this.height);

  final String label;
  final String hint;
  final int? width;
  final int? height;

  bool get keepsOriginalSize => width == null || height == null;

  String get ratio => switch (this) {
    OutputFormat.original => 'auto',
    OutputFormat.vertical => '9:16',
    OutputFormat.square => '1:1',
    OutputFormat.horizontal => '16:9',
  };
}

class RenderSettings {
  const RenderSettings({
    this.format = OutputFormat.original,
    this.customWidth,
    this.customHeight,
    this.fps,
    this.quality = RenderQuality.equilibrado,
    this.keepAudio = true,
  }) : assert(
         (customWidth == null) == (customHeight == null),
         'customWidth e customHeight devem ser informados juntos',
       );

  /// Preset de proporção. Ignorado quando [customWidth]/[customHeight] estão
  /// definidos — as features que trabalham com dimensões exatas (enhance,
  /// highlights) usam o par customizado em vez de um preset fixo.
  final OutputFormat format;

  /// Dimensões de saída em pixels, quando a feature precisa de um tamanho que
  /// não é nenhum dos presets de [OutputFormat]. Nulos mantêm o comportamento
  /// do preset.
  final int? customWidth;
  final int? customHeight;
  final int? fps;
  final RenderQuality quality;
  final bool keepAudio;

  static const defaults = RenderSettings();
  static const fpsOptions = [24, 30, 60];

  /// Largura efetiva de saída: a customizada, se houver, senão a do preset.
  int? get width => customWidth ?? format.width;

  /// Altura efetiva de saída: a customizada, se houver, senão a do preset.
  int? get height => customHeight ?? format.height;

  bool get keepsOriginalSize => width == null || height == null;

  int get crf => quality.crf;

  bool get matchesSource =>
      keepsOriginalSize && fps == null;

  String get label => [
    customWidth != null ? '${customWidth}x$customHeight' : format.ratio,
    fps == null ? 'fps original' : '${fps}fps',
    quality.label,
  ].join(' · ');

  RenderSettings copyWith({
    OutputFormat? format,
    int? customWidth,
    int? customHeight,
    int? fps,
    RenderQuality? quality,
    bool? keepAudio,
    bool clearCustomSize = false,
    bool clearFps = false,
  }) => RenderSettings(
    format: format ?? this.format,
    customWidth: clearCustomSize ? null : (customWidth ?? this.customWidth),
    customHeight: clearCustomSize ? null : (customHeight ?? this.customHeight),
    fps: clearFps ? null : (fps ?? this.fps),
    quality: quality ?? this.quality,
    keepAudio: keepAudio ?? this.keepAudio,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderSettings &&
          other.format == format &&
          other.customWidth == customWidth &&
          other.customHeight == customHeight &&
          other.fps == fps &&
          other.quality == quality &&
          other.keepAudio == keepAudio;

  @override
  int get hashCode =>
      Object.hash(format, customWidth, customHeight, fps, quality, keepAudio);
}
