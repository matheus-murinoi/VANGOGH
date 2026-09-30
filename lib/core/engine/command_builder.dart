import '../media/render_settings.dart';
import 'media_range.dart';

/// Codec de vídeo de saída.
///
/// A build Full **não-GPL** do FFmpegKit não traz `libx264`/`libx265`. Para
/// publicar na Play Store sem obrigações de GPL, o encode é feito pelos encoders
/// de hardware do sistema — que também são ordens de magnitude mais rápidos:
///
/// - Android: `MediaCodec` (presente em qualquer aparelho com encoder H.264)
/// - iOS/macOS: `VideoToolbox`
/// - Sem nenhum deles: `mpeg4` por software, sempre disponível
///
/// Consequência prática: encoders de hardware não aceitam CRF, e sim taxa de
/// bits. Por isso [RenderQuality] é convertido em taxa de bits alvo por
/// [FfmpegCommand.targetBitrateKbps].
enum HwCodec {
  mediaCodec('h264_mediacodec', 'MediaCodec'),
  videoToolbox('h264_videotoolbox', 'VideoToolbox'),
  software('mpeg4', 'software');

  const HwCodec(this.encoder, this.label);

  final String encoder;
  final String label;

  bool get isHardware => this != HwCodec.software;
}

/// Monta argumentos de linha de comando do FFmpeg.
///
/// Deliberadamente **Dart puro**: nenhuma plataforma, nenhum plugin, nenhum
/// `dart:io`. Cada feature vira uma `List<String>` testável unitariamente e o
/// motor só executa. Se essa lógica vaza para o motor, perde-se a única parte
/// do pipeline que dá para testar sem aparelho conectado.
abstract final class FfmpegCommand {
  /// Argumentos globais comuns a toda execução.
  static List<String> base() => const ['-hide_banner', '-loglevel', 'error', '-y'];

  /// Corta [ranges] de um único input e concatena o resultado, aplicando
  /// formato, fps e áudio.
  ///
  /// Com **um** trecho, o corte é um *seek* de entrada (`-ss`/`-t` antes do
  /// `-i`), bem mais rápido porque não decodifica o que vem antes, e os filtros
  /// de vídeo/áudio vão em `-vf`/`-af`. Com **vários** trechos, tudo acontece em
  /// um único passe de `-filter_complex` (`trim`/`atrim` + `concat`), sem
  /// arquivos intermediários.
  ///
  /// `-ss` e `-t` ficam **antes** do `-i`, ou seja, incidem sobre o arquivo e
  /// não sobre a rede. Isso evita reconstruir índices e preserva a sincronia A/V.
  static List<String> concatenate({
    required String inputPath,
    required String outputPath,
    required List<MediaRange> ranges,
    required RenderSettings settings,
    HwCodec codec = HwCodec.mediaCodec,
    bool normalizeAudio = false,
    bool sourceHasAudio = true,
  }) {
    final valid = ranges.where((range) => !range.isEmpty).toList();
    if (valid.isEmpty) {
      throw ArgumentError('concatenate exige ao menos um trecho com duração > 0');
    }

    final audioOut = settings.keepAudio && sourceHasAudio;
    final videoChain = <String>[
      if (settings.format.width != null && settings.format.height != null)
        ..._fitToBox(settings.format.width!, settings.format.height!),
      if (settings.fps != null) 'fps=${settings.fps}',
    ];
    final audioChain = <String>[
      if (normalizeAudio) 'loudnorm=I=-16:TP=-1.5:LRA=11',
    ];

    final single = valid.length == 1;

    return [
      ...base(),
      if (single) ..._inputSeek(valid.single),
      '-i',
      inputPath,
      if (single) ..._simpleFilters(videoChain, audioChain, withAudio: audioOut)
      else ..._complexFilters(valid, videoChain, audioChain, withAudio: audioOut),
      ..._encodeVideo(
        codec: codec,
        width: settings.format.width,
        height: settings.format.height,
        fps: settings.fps,
        quality: settings.quality,
      ),
      if (audioOut) ..._encodeAudio(),
      // `faststart` move o índice para o começo: o vídeo abre antes de baixar
      // inteiro e o player não mostra um retângulo preto inicial.
      '-movflags',
      '+faststart',
      outputPath,
    ];
  }

  /// Formata duração como decimal fixo para argumentos do FFmpeg.
  ///
  /// Precisão de milissegundos: `trim` e `atrim` aceitam, e evita notação
  /// científica, que o FFmpeg não entende.
  static String seconds(Duration value) =>
      (value.inMilliseconds.clamp(0, 1 << 40) / 1000).toStringAsFixed(3);

  /// Um trecho só: filtros simples em `-vf`/`-af`, sem grafo nomeado.
  static List<String> _simpleFilters(
    List<String> videoChain,
    List<String> audioChain, {
    required bool withAudio,
  }) => [
    if (videoChain.isNotEmpty) ...['-vf', videoChain.join(',')],
    if (withAudio && audioChain.isNotEmpty) ...['-af', audioChain.join(',')],
    '-map',
    '0:v:0',
    // `?` final deixa o FFmpeg seguir sem erro quando a fonte é muda.
    if (withAudio) ...['-map', '0:a:0?'],
  ];

  /// Vários trechos: um grafo com `trim`/`atrim` por segmento e um `concat`.
  static List<String> _complexFilters(
    List<MediaRange> ranges,
    List<String> videoChain,
    List<String> audioChain, {
    required bool withAudio,
  }) {
    final graph = <String>[];
    for (var i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final videoTail = videoChain.isEmpty ? '' : ',${videoChain.join(',')}';
      graph.add(
        '[0:v]trim=start=${seconds(range.start)}:end=${seconds(range.end)},'
        'setpts=PTS-STARTPTS$videoTail[v$i]',
      );
      if (withAudio) {
        final audioTail = audioChain.isEmpty ? '' : ',${audioChain.join(',')}';
        graph.add(
          '[0:a]atrim=start=${seconds(range.start)}:end=${seconds(range.end)},'
          'asetpts=PTS-STARTPTS$audioTail[a$i]',
        );
      }
    }

    final labels = <String>[];
    for (var i = 0; i < ranges.length; i++) {
      labels.add('[v$i]');
      if (withAudio) labels.add('[a$i]');
    }
    graph.add(
      '${labels.join()}'
      'concat=n=${ranges.length}:v=1:a=${withAudio ? 1 : 0}'
      '[vout]${withAudio ? '[aout]' : ''}',
    );

    return [
      '-filter_complex',
      graph.join(';'),
      '-map',
      '[vout]',
      if (withAudio) ...['-map', '[aout]'],
    ];
  }

  static List<String> _inputSeek(MediaRange range) => [
    '-ss',
    seconds(range.start),
    '-t',
    seconds(range.length),
  ];

  /// Escala preservando proporção e centraliza o excedente (letterbox/pillarbox).
  ///
  /// `x=`/`y=` precisam ser nomeados: misturados com `w=`/`h=` na forma
  /// posicional, o FFmpeg mapeia a expressão para a opção errada e aborta com
  /// "Error when evaluating the expression".
  static List<String> _fitToBox(int width, int height) => [
    'scale=w=$width:h=$height:force_original_aspect_ratio=decrease',
    'pad=w=$width:h=$height:x=(ow-iw)/2:y=(oh-ih)/2:color=black',
    'setsar=1',
  ];

  static List<String> _encodeVideo({
    required HwCodec codec,
    required int? width,
    required int? height,
    required int? fps,
    required RenderQuality quality,
  }) {
    final out = <String>['-c:v', codec.encoder];
    final bitrate = targetBitrateKbps(
      quality: quality,
      width: width,
      height: height,
      fps: fps,
    );
    if (bitrate != null) {
      out.addAll(['-b:v', '${bitrate}k']);
      // VBV: teto de 2x a média evita estouro de buffer em cenas complexas.
      out.addAll(['-maxrate', '${bitrate * 2}k']);
      out.addAll(['-bufsize', '${bitrate * 2}k']);
    }
    if (codec.isHardware) {
      // GOP explícito e perfil alto: sem isso alguns players Android
      // recusam o arquivo ou travam ao buscar o próximo ponto de seek.
      out.addAll(['-profile:v', 'high', '-g', '${(fps ?? 30) * 2}']);
    }
    out.addAll(['-pix_fmt', 'yuv420p']);
    return out;
  }

  static List<String> _encodeAudio() => const [
    '-c:a',
    'aac',
    '-b:a',
    '192k',
    '-ar',
    '48000',
    '-ac',
    '2',
  ];

  /// Converte a escolha de qualidade em taxa de bits alvo, em **kbps**.
  ///
  /// Encoders de hardware não entendem CRF, então o modelo é
  /// `w × h × fps × fator`, com fator por preset — a mesma aproximação usada
  /// por *targeting* de bitrate H.264. Com 1080p30 como referência, o preset
  /// equilibrado gira em torno de 6 Mb/s.
  ///
  /// O cálculo é feito em bits por segundo: o piso de 400 kbps evita arquivo
  /// degenerado em fontes muito pequenas, e o teto de 120 Mbps evita passar do
  /// que o encoder de hardware do aparelho aceita.
  static int? targetBitrateKbps({
    required RenderQuality quality,
    required int? width,
    required int? height,
    required int? fps,
    int fallbackWidth = 1920,
    int fallbackHeight = 1080,
    int fallbackFps = 30,
  }) {
    final w = width ?? fallbackWidth;
    final h = height ?? fallbackHeight;
    final f = fps ?? fallbackFps;
    if (w <= 0 || h <= 0 || f <= 0) return null;
    final factor = switch (quality) {
      RenderQuality.leve => 0.055,
      RenderQuality.equilibrado => 0.10,
      RenderQuality.maxima => 0.18,
    };
    final bps = w * h * f * factor;
    return (bps.clamp(400000, 120000000) / 1000).round();
  }
}
