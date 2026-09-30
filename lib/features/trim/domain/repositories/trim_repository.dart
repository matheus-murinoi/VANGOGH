import '../../../../core/media/media_asset.dart';
import '../../../../core/media/render_settings.dart';
import '../entities/trim_plan.dart';

/// Corte e concatenação de trechos de um vídeo.
///
/// A origem entra como parâmetro porque o plano de corte só carrega
/// durações — sem o caminho do arquivo nenhuma implementação real conseguiria
/// localizar a entrada.
abstract interface class TrimRepository {
  /// Executa o corte, emitindo progresso de 0 a 1.
  Stream<double> render(
    MediaAsset source,
    TrimPlan plan,
    RenderSettings settings,
  );

  /// Descreve o arquivo produzido por um `render` concluído com sucesso.
  Future<MediaAsset> buildResult(RenderSettings settings);

  void cancel();
}
