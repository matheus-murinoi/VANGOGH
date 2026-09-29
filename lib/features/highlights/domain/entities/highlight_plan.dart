import 'moment.dart';
import 'target_duration.dart';

class HighlightPlan {
  const HighlightPlan({
    required this.sourceDuration,
    required this.target,
    required this.moments,
  });

  final Duration sourceDuration;
  final TargetDuration target;
  final List<Moment> moments;

  Duration get totalLength =>
      moments.fold(Duration.zero, (sum, m) => sum + m.length);

  int get cutCount => moments.isEmpty ? 0 : moments.length - 1;

  double get fillRatio {
    final targetSeconds = target.duration.inMilliseconds;
    if (targetSeconds == 0) return 0;
    return (totalLength.inMilliseconds / targetSeconds).clamp(0, 1);
  }

  double get compressionRatio {
    final source = sourceDuration.inMilliseconds;
    if (source == 0) return 0;
    return totalLength.inMilliseconds / source;
  }

  int get secondsRemoved =>
      ((sourceDuration - totalLength).inSeconds).clamp(0, 1 << 31);
}
