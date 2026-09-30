import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gallery_saver.dart';
import 'media_picker.dart';
import 'media_probe.dart';

final mediaPickerProvider = Provider<MediaPicker>((ref) => const MediaPicker());

final mediaProbeProvider = Provider<MediaProbe>((ref) => const MediaProbe());

final gallerySaverProvider = Provider<GallerySaver>((ref) => const GallerySaver());
