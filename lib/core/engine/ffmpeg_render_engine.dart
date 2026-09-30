import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_full/log.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/session_state.dart';
import 'package:ffmpeg_kit_flutter_new_full/statistics.dart';

import 'command_builder.dart';
import 'render_engine.dart';
import 'render_job.dart';
import 'staging.dart';

/// Motor de mídia backed by FFmpegKit.
class FfmpegRenderEngine implements RenderEngine {
  FfmpegRenderEngine({HwCodec? codec, RenderStaging? staging})
    : _codec = codec ?? defaultCodec,
      _staging = staging ?? const RenderStaging();

  final HwCodec _codec;
  final RenderStaging _staging;

  int? _sessionId;
  bool _busy = false;
  bool _cancelled = false;
  final List<String> _logs = [];

  /// Codec de hardware adequado à plataforma.
  ///
  /// `MediaCodec` no Android e `VideoToolbox` no iOS são o mesmo H.264
  /// acelerado por hardware; o fallback por software cobre emuladores e
  /// aparelhos sem encoder de vídeo.
  static HwCodec get defaultCodec {
    if (Platform.isIOS || Platform.isMacOS) return HwCodec.videoToolbox;
    if (Platform.isAndroid) return HwCodec.mediaCodec;
    return HwCodec.software;
  }

  HwCodec get codec => _codec;

  @override
  Stream<RenderProgress> run(RenderRequest request) {
    final controller = StreamController<RenderProgress>();
    _cancelled = false;
    _logs.clear();

    // Um render por vez: o FFmpegKit compartilha o mesmo contexto nativo, e
    // sessões concorrentes disputam o encoder de hardware do aparelho.
    if (_busy) {
      controller.addError(
        const RenderFailure('Já existe uma exportação em andamento.'),
        StackTrace.current,
      );
      return controller.stream;
    }

    _busy = true;
    unawaited(_execute(request, controller));
    return controller.stream;
  }

  Future<void> _execute(
    RenderRequest request,
    StreamController<RenderProgress> controller,
  ) async {
    controller.add(const RenderProgress.idle());

    try {
      final completer = Completer<FFmpegSession>();

      final session = await FFmpegKit.executeWithArgumentsAsync(
        request.arguments,
        (FFmpegSession session) {
          if (!completer.isCompleted) completer.complete(session);
        },
        (Log log) => _onLog(log),
        (Statistics stats) {
          if (!controller.isClosed) {
            controller.add(_toProgress(stats, request.expectedDurationMs));
          }
        },
      );
      _sessionId = session.getSessionId();

      // `executeWithArgumentsAsync` devolve antes de terminar. Se o usuário
      // cancelou entre o pedido e a criação da sessão, aborta agora.
      if (_cancelled) {
        await FFmpegKit.cancel(_sessionId);
        _staging.discard(request.outputPath);
        if (!controller.isClosed) {
          controller.addError(const RenderCancelled(), StackTrace.current);
          await controller.close();
        }
        return;
      }

      final finished = completer.future;
      final state = await session.getState();
      if (state == SessionState.created || state == SessionState.running) {
        await finished;
      }
      if (controller.isClosed) return;

      if (_cancelled) {
        _staging.discard(request.outputPath);
        controller.addError(const RenderCancelled(), StackTrace.current);
        await controller.close();
        return;
      }

      final returnCode = await session.getReturnCode();
      final log = await session.getAllLogsAsString();
      final output = File(request.outputPath);
      final produced = output.existsSync() && output.lengthSync() > 0;

      if (returnCode == null || returnCode.getValue() != ReturnCode.success) {
        if (request.cleanupOnFailure) _staging.discard(request.outputPath);
        controller.addError(
          RenderFailure(_describeFailure(returnCode, log), log: _tail(log)),
          StackTrace.current
        );
        await controller.close();
        return;
      }

      if (!produced) {
        // Sucesso com arquivo ausente quase sempre significa que a entrada não
        // tinha faixa de vídeo: o FFmpeg não gera saída, mas sai com código 0.
        if (request.cleanupOnFailure) _staging.discard(request.outputPath);
        controller.addError(
          const RenderFailure(
            'A exportação terminou sem gerar arquivo. '
            'O arquivo escolhido talvez não tenha faixa de vídeo.',
          ),
          StackTrace.current
        );
        await controller.close();
        return;
      }

      controller.add(
        RenderProgress(
          fraction: 1,
          stage: RenderStage.done,
          processedMs: request.expectedDurationMs,
          totalMs: request.expectedDurationMs,
          sizeBytes: output.lengthSync(),
        ),
      );
      await controller.close();
    } on RenderCancelled {
      _staging.discard(request.outputPath);
      if (!controller.isClosed) {
        controller.addError(const RenderCancelled(), StackTrace.current);
        await controller.close();
      }
    } on RenderFailure catch (failure, stack) {
      if (request.cleanupOnFailure) _staging.discard(request.outputPath);
      if (!controller.isClosed) {
        controller.addError(failure, stack);
        await controller.close();
      }
    } on Exception catch (error, stack) {
      if (request.cleanupOnFailure) _staging.discard(request.outputPath);
      if (!controller.isClosed) {
        controller.addError(
          RenderFailure('Falha inesperada na exportação: $error', log: _tail(null)),
          stack
        );
        await controller.close();
      }
    } finally {
      _busy = false;
      _sessionId = null;
      unawaited(_staging.prune());
    }
  }

  void _onLog(Log log) {
    final message = log.getMessage();
    if (message.isEmpty) return;
    if (_logs.length >= 200) _logs.removeAt(0);
    _logs.add(message);
  }

  RenderProgress _toProgress(Statistics stats, int expectedMs) {
    final processed = stats.getTime();
    // Sem duração esperada (imagem estática, por exemplo) o FFmpeg reporta 0 e
    // o progresso fica em 0; a UI mostra "processando" até o fim.
    final fraction = expectedMs > 0
        ? (processed / expectedMs).clamp(0.0, 1.0)
        : 0.0;
    return RenderProgress(
      fraction: fraction,
      stage: fraction >= 0.995 ? RenderStage.finalizing : RenderStage.encoding,
      processedMs: processed,
      totalMs: expectedMs,
      speed: stats.getSpeed(),
      sizeBytes: stats.getSize(),
    );
  }

  /// Traduz falha do FFmpeg em texto que o cliente entende.
  ///
  /// O build roda com `-loglevel error`, então o log traz a causa real — é
  /// ele que permite diferenciar disco cheio de arquivo inválido.
  String _describeFailure(ReturnCode? code, String? log) {
    if (code != null && code.getValue() == ReturnCode.cancel) {
      return 'A exportação foi cancelada.';
    }
    final text = (log ?? '').toLowerCase();
    if (text.contains('no space left') || text.contains('enospc')) {
      return 'Sem espaço no aparelho. Libere memória e tente de novo.';
    }
    if (text.contains('invalid data found') || text.contains('moov atom not found')) {
      return 'O arquivo de origem parece corrompido ou não é um vídeo válido.';
    }
    if (text.contains('permission denied') || text.contains('eperm')) {
      return 'Sem permissão para ler o arquivo escolhido.';
    }
    if (text.contains('no such file')) {
      return 'O arquivo de origem não foi encontrado. Escolha o vídeo novamente.';
    }
    if (text.contains('unknown encoder') || text.contains('encoder not found')) {
      return 'Este aparelho não suporta o codec de vídeo escolhido.';
    }
    final value = code?.getValue();
    return 'Falha ao exportar${value == null ? '' : ' (código $value)'}.';
  }

  String? _tail(String? log) {
    final lines = (log ?? _logs.join('\n')).trim().split('\n');
    final useful = lines.where((line) => line.trim().isNotEmpty).toList();
    if (useful.isEmpty) return null;
    return useful.length <= 12
        ? useful.join('\n')
        : useful.sublist(useful.length - 12).join('\n');
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    final id = _sessionId;
    _sessionId = null;
    if (id == null) return;
    try {
      await FFmpegKit.cancel(id);
    } on Exception {
      // A sessão pode ter terminado entre a leitura do id e o cancel.
    }
  }

  /// Estado de todas as sessões, para diagnóstico em bug reports.
  Future<List<String>> sessionStates() async {
    final sessions = await FFmpegKit.listSessions();
    final out = <String>[];
    for (final FFmpegSession session in sessions) {
      out.add('${session.getSessionId()}: ${await session.getState()}');
    }
    return out;
  }
}
