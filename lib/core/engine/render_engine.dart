import 'render_job.dart';

/// Motor de mídia: executa um [RenderRequest] e emite progresso.
///
/// A interface existe para que as features dependam do *contrato*, e não do
/// FFmpegKit. Isso mantém `features/` testável com um motor falso e permite
/// trocar o backend (FFmpeg, MediaCodec, GPU) sem tocar nas features.
abstract interface class RenderEngine {
  /// Executa [request], emitindo progresso de 0 a 1.
  ///
  /// O stream encerra normalmente em sucesso. Em falha emite [RenderFailure];
  /// em cancelamento do usuário emite [RenderCancelled].
  Stream<RenderProgress> run(RenderRequest request);

  /// Cancela a execução em andamento. Seguro chamar quando não há nenhuma.
  Future<void> cancel();
}
