import '../../../../core/media/media_asset.dart';
import '../entities/analysis.dart';
import '../entities/highlight_plan.dart';

abstract interface class HighlightRepository {
  Stream<AnalysisProgress> analyze(
    MediaAsset source,
    AnalysisSettings settings,
  );

  Stream<double> export(
    HighlightPlan plan,
    ExportSettings settings,
  );

  Future<MediaAsset> buildResult(HighlightPlan plan);

  void cancel();
}
