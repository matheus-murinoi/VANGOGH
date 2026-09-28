import 'package:aprimorar_video/core/media/media_asset.dart';
import 'package:aprimorar_video/core/utils/duration_x.dart';
import 'package:aprimorar_video/features/enhance/domain/entities/enhance_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DurationX', () {
    test('clock', () {
      expect(const Duration(seconds: 75).clock, '1:15');
      expect(const Duration(minutes: 3).clock, '3:00');
    });

    test('approxHuman', () {
      expect(const Duration(seconds: 46).approxHuman, '~45s');
      expect(const Duration(minutes: 2).approxHuman, '~2 min');
    });

    test('human', () {
      expect(const Duration(seconds: 30).human, '30s');
      expect(const Duration(minutes: 1).human, '1 min');
    });
  });

  group('formatBytes', () {
    test('escala', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(2 * 1024 * 1024 * 1024), '2.00 GB');
    });
  });

  group('MediaAsset', () {
    test('classifica a resolução', () {
      const hd = MediaAsset(
        path: '/a.mp4',
        name: 'a.mp4',
        kind: MediaKind.video,
        sizeBytes: 1,
        width: 1920,
        height: 1080,
      );
      const sd = MediaAsset(
        path: '/b.mp4',
        name: 'b.mp4',
        kind: MediaKind.video,
        sizeBytes: 1,
        width: 640,
        height: 480,
      );

      expect(hd.resolutionLabel, 'Full HD · 1920x1080');
      expect(sd.resolutionLabel, 'SD · 640x480');
    });

    test('marca arquivo grande', () {
      const big = MediaAsset(
        path: '/a.mp4',
        name: 'a.mp4',
        kind: MediaKind.video,
        sizeBytes: 900 * 1024 * 1024,
      );
      expect(big.isLarge, isTrue);
    });
  });

  group('EnhanceOptions', () {
    test('lista os filtros ativos', () {
      const options = EnhanceOptions(
        preset: EnhancePreset.ultraHd,
        denoise: true,
        brightness: 0.1,
      );

      expect(options.activeFilters, contains('Escala 3840x2160'));
      expect(options.activeFilters, contains('Upscale IA (3.6x)'));
      expect(options.activeFilters, contains('Redução de ruído'));
      expect(options.activeFilters, contains('Brilho +10%'));
    });

    test('preset original não redimensiona', () {
      const options = EnhanceOptions(preset: EnhancePreset.keepOriginal);
      expect(options.estimatedScaleFactor, 1);
      expect(options.activeFilters, isNot(contains('Escala 3840x2160')));
    });

    test('copyWith', () {
      const base = EnhanceOptions();
      final updated = base.copyWith(saturation: -0.2, kind: EnhanceKind.images);

      expect(updated.saturation, -0.2);
      expect(updated.kind, EnhanceKind.images);
      expect(updated.sharpen, base.sharpen);
    });
  });
}
