import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'media_asset.dart';

class MediaPicker {
  const MediaPicker();

  Future<MediaAsset?> pickVideo() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Escolher vídeo',
      type: FileType.video,
    );
    if (files.isEmpty) return null;
    return _assetFrom(files.first);
  }

  Future<MediaAsset?> pickImages() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Escolher imagens',
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    );
    if (files.isEmpty) return null;
    return _assetFrom(files.first);
  }

  MediaAsset _assetFrom(PlatformFile file) {
    final path = file.path ?? '';
    final extension = (file.extension ?? '').toLowerCase();
    final kind = const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)
        ? MediaKind.image
        : MediaKind.video;
    final size = path.isEmpty ? 0 : File(path).existsSync()
        ? File(path).lengthSync()
        : 0;

    return MediaAsset(
      path: path,
      name: file.name,
      kind: kind,
      sizeBytes: size,
    );
  }

  Future<Directory> workingDirectory() async {
    final root = await getTemporaryDirectory();
    final dir = Directory('${root.path}/aprimorar_video');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}
