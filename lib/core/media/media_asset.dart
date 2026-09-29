import '../utils/duration_x.dart';

enum MediaKind {
  video('Vídeo', 'mp4'),
  image('Imagem', 'jpg');

  const MediaKind(this.label, this.extension);

  final String label;
  final String extension;
}

class MediaAsset {
  const MediaAsset({
    required this.path,
    required this.name,
    required this.kind,
    required this.sizeBytes,
    this.duration,
    this.width,
    this.height,
    this.fps,
    this.bitrate,
  });

  final String path;
  final String name;
  final MediaKind kind;
  final int sizeBytes;
  final Duration? duration;
  final int? width;
  final int? height;
  final double? fps;
  final int? bitrate;

  bool get isVideo => kind == MediaKind.video;

  String get sizeLabel => formatBytes(sizeBytes);

  String get resolutionLabel {
    if (width == null || height == null) return '—';
    final h = height!;
    final label = switch (h) {
      >= 2160 => '4K',
      >= 1440 => '2K',
      >= 1080 => 'Full HD',
      >= 720 => 'HD',
      _ => 'SD',
    };
    return '$label · ${width!}x$h';
  }

  bool get isLarge => sizeBytes > 500 * 1024 * 1024;
}
