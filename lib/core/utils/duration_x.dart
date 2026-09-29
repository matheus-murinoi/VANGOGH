extension DurationX on Duration {
  String get clock {
    final totalSeconds = inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get human {
    if (inSeconds < 60) return '${inSeconds}s';
    if (inSeconds % 60 == 0) return '${inSeconds ~/ 60} min';
    return clock;
  }

  String get approxHuman {
    if (inMinutes < 1) return '~${(inSeconds / 5).round() * 5}s';
    final rest = inSeconds % 60;
    return rest == 0 ? '~$inMinutes min' : '~$inMinutes' 'min${rest}s';
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
