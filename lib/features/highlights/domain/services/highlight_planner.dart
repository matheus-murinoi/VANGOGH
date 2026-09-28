import '../entities/highlight_plan.dart';
import '../entities/moment.dart';
import '../entities/target_duration.dart';

abstract final class HighlightPlanner {
  static HighlightPlan build({
    required Duration sourceDuration,
    required TargetDuration target,
    required List<Moment> candidates,
    Set<String> excluded = const {},
  }) {
    final allowed = candidates.where((m) => !excluded.contains(m.id)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final budgetMs = target.duration.inMilliseconds;
    final picked = <Moment>[];
    var usedMs = 0;

    for (final moment in allowed) {
      final lengthMs = moment.length.inMilliseconds;
      if (usedMs + lengthMs > budgetMs) continue;
      if (picked.any(moment.overlaps)) continue;
      picked.add(moment);
      usedMs += lengthMs;
    }

    picked.sort((a, b) => a.start.compareTo(b.start));

    return HighlightPlan(
      sourceDuration: sourceDuration,
      target: target,
      moments: List.unmodifiable(picked),
    );
  }
}
