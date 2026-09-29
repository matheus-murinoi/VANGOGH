import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_x.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/moment.dart';

class MomentList extends StatelessWidget {
  const MomentList({
    super.key,
    required this.moments,
    required this.excludedIds,
    required this.onToggle,
  });

  final List<Moment> moments;
  final Set<String> excludedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final moment in moments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MomentTile(
              moment: moment,
              included: !excludedIds.contains(moment.id),
              onToggle: () => onToggle(moment.id),
            ),
          ),
      ],
    );
  }
}

class MomentTile extends StatelessWidget {
  const MomentTile({
    super.key,
    required this.moment,
    required this.included,
    required this.onToggle,
  });

  final Moment moment;
  final bool included;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final signal = moment.topSignal;
    final scoreColor = moment.score > 0.75
        ? AppColors.success
        : moment.score > 0.5
        ? AppColors.teal
        : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: included ? 1 : 0.42,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: included ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: included,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            moment.start.clock,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            '  →  ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            moment.end.clock,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            moment.length.clock,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (signal != null)
                            PillLabel(
                              text: signal.label,
                              color: scoreColor,
                              icon: _iconFor(signal),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: LinearProgressIndicator(
                                value: moment.score,
                                minHeight: 6,
                                color: scoreColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(moment.score * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(MomentSignal signal) => switch (signal) {
    MomentSignal.audioPico => Icons.graphic_eq_rounded,
    MomentSignal.risada => Icons.sentiment_very_satisfied_rounded,
    MomentSignal.fala => Icons.record_voice_over_rounded,
    MomentSignal.rosto => Icons.face_retouching_natural_rounded,
    MomentSignal.movimento => Icons.directions_run_rounded,
    MomentSignal.transicao => Icons.flash_on_rounded,
    MomentSignal.fimSilencio => Icons.motion_photos_off_rounded,
  };
}
