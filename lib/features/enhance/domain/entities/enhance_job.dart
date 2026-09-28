import '../../../../core/media/media_asset.dart';
import 'enhance_options.dart';

enum EnhanceStage {
  idle('Pronto'),
  preparing('Preparando arquivo'),
  decoding('Decodificando'),
  processing('Melhorando qualidade'),
  encoding('Codificando'),
  saving('Salvando'),
  done('Concluído');

  const EnhanceStage(this.label);

  final String label;
}

class EnhanceProgress {
  const EnhanceProgress({
    required this.stage,
    required this.percent,
    this.etaSeconds,
  });

  final EnhanceStage stage;
  final double percent;
  final int? etaSeconds;
}

class EnhanceJob {
  const EnhanceJob({
    required this.sources,
    required this.options,
    this.results = const [],
  });

  final List<MediaAsset> sources;
  final EnhanceOptions options;
  final List<MediaAsset> results;

  int get total => sources.length;

  bool get isBatch => sources.length > 1;

  int get finished => results.length;
}
