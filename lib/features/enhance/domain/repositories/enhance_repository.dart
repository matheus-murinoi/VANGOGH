import '../../../../core/media/media_asset.dart';
import '../entities/enhance_job.dart';
import '../entities/enhance_options.dart';

abstract interface class EnhanceRepository {
  Stream<EnhanceProgress> enhance(
    List<MediaAsset> sources,
    EnhanceOptions options,
  );

  Future<MediaAsset> buildResult(
    MediaAsset source,
    EnhanceOptions options,
  );

  void cancel();
}
