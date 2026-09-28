import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_asset.dart';

class ExportEntry {
  const ExportEntry({
    required this.asset,
    required this.feature,
    required this.createdAt,
  });

  final MediaAsset asset;
  final String feature;
  final DateTime createdAt;
}

final libraryProvider = NotifierProvider<LibraryController, List<ExportEntry>>(
  LibraryController.new,
);

class LibraryController extends Notifier<List<ExportEntry>> {
  @override
  List<ExportEntry> build() => const [];

  void add(MediaAsset asset, String feature) {
    state = [
      ExportEntry(asset: asset, feature: feature, createdAt: DateTime.now()),
      ...state,
    ];
  }

  void remove(MediaAsset asset) {
    state = state.where((e) => e.asset.path != asset.path).toList();
  }
}
