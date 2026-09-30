import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ffmpeg_render_engine.dart';
import 'render_engine.dart';
import 'staging.dart';

final renderStagingProvider = Provider<RenderStaging>(
  (ref) => const RenderStaging(),
);

/// Motor único de mídia para o app inteiro.
///
/// Todas as features que produzem arquivo (cortar, montar highlights, melhorar
/// qualidade) dependem deste provider, e não de um motor próprio. É o que
/// garante um único lugar para cancelar, reportar progresso e recuperar
/// render interrompido.
final renderEngineProvider = Provider<RenderEngine>(
  (ref) => FfmpegRenderEngine(staging: ref.watch(renderStagingProvider)),
);
