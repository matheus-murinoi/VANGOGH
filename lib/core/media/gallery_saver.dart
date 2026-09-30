import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../media/media_asset.dart';

/// Resultado de tentar gravar um export no álbum do aparelho.
enum SaveOutcome {
  saved('Salvo na galeria'),
  permissionDenied('Permissão negada. Libere o acesso nas configurações do aparelho.'),
  failed('Não foi possível salvar na galeria.');

  const SaveOutcome(this.message);

  final String message;

  bool get isSuccess => this == SaveOutcome.saved;
}

/// Grava o arquivo renderizado na galeria de Fotos/Imagens.
///
/// Até aqui o app funciona sem nenhuma permissão: o seletor de arquivos do
/// sistema entrega o arquivo e o render sai para o cache. A permissão só é
/// pedida aqui, no momento em que o cliente quer guardar o resultado — que é
/// quando ela faz sentido para ele.
class GallerySaver {
  const GallerySaver();

  static const albumName = 'Aprimorar Video';

  Future<SaveOutcome> save(MediaAsset asset) async {
    final file = File(asset.path);
    if (!file.existsSync()) return SaveOutcome.failed;

    if (!await _ensurePermission()) return SaveOutcome.permissionDenied;

    try {
      if (asset.isVideo) {
        await Gal.putVideo(asset.path, album: albumName);
      } else {
        await Gal.putImage(asset.path, album: albumName);
      }
      return SaveOutcome.saved;
    } on GalException {
      return SaveOutcome.failed;
    } on FileSystemException {
      return SaveOutcome.failed;
    }
  }

  /// Verdadeiro quando o app já pode gravar no álbum.
  Future<bool> hasAccess() async {
    try {
      return await Gal.hasAccess(toAlbum: true);
    } on Exception {
      return false;
    }
  }

  /// Pede a permissão de escrita na galeria, se ainda não tiver.
  ///
  /// `photos` no iOS é a permissão de *add* (Apple separou leitura de escrita em
  /// iOS 14+); no Android 13+ não há permissão de escrita porque o app usa
  /// MediaStore, então o pedido é um no-op.
  Future<bool> _ensurePermission() async {
    if (await hasAccess()) return true;
    try {
      final status = await Permission.photos.request();
      if (status.isGranted) return true;
      // `addOnly` é o caso do iOS quando o app só escreve, sem ler a galeria.
      if (status.isLimited) return true;
      return false;
    } on Exception {
      return false;
    }
  }
}
