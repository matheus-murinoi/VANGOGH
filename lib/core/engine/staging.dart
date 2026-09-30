import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Gerencia o diretório de trabalho dos renders.
///
/// Toda saída vai primeiro para o diretório de cache do app (que o sistema
/// pode liberar sozinho quando o usuário fica sem espaço) e só depois é
/// copiada para o álbum. Isso evita encher o armazenamento público com
/// arquivos intermediários quando um export é cancelado no meio.
class RenderStaging {
  const RenderStaging();

  static const folderName = 'aprimorar_video';

  /// Resolve e cria o diretório de trabalho. Lança se o disco estiver cheio.
  Future<Directory> ensureDirectory() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/$folderName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Caminho de saída novo, com prefixo legível e sufixo único.
  ///
  /// O timestamp impede colisão entre dois exports do mesmo trecho em sequência
  /// rápida (o usuário pode apertar exportar duas vezes).
  Future<String> newOutputPath({
    required String prefix,
    required String extension,
  }) async {
    final dir = await ensureDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/${_slug(prefix)}_$stamp.$extension';
  }

  /// Apaga saídas antigas, mantendo as [keep] mais recentes.
  ///
  /// Sem isso o diretório de cache vira um depósito de renders que o cliente
  /// já exportou. Arquivos com menos de [minAge] são preservados para não
  /// derrubar um render que acabou de terminar.
  Future<int> prune({int keep = 8, Duration minAge = const Duration(hours: 1)}) async {
    final Directory dir;
    try {
      dir = await ensureDirectory();
    } on Exception {
      return 0;
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => _isRenderOutput(file.path))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final cutoff = DateTime.now().subtract(minAge);
    var removed = 0;
    for (final file in files.skip(keep)) {
      try {
        if (file.statSync().modified.isAfter(cutoff)) continue;
        file.deleteSync();
        removed++;
      } on FileSystemException {
        // Arquivo travado por outro processo: tenta de novo no próximo prune.
        continue;
      }
    }
    return removed;
  }

  /// Remove uma saída parcial após falha ou cancelamento.
  void discard(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Sem permissão ou já removido: nada a fazer.
    }
  }

  static bool _isRenderOutput(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.contains('_') && _renderExtensions.contains(_extensionOf(name));
  }

  static const _renderExtensions = {'mp4', 'jpg', 'png', 'wav', 'm4a'};

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static String _slug(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'export' : cleaned;
  }
}
