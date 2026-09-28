import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/media_asset.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_x.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/analysis.dart';
import '../../domain/entities/target_duration.dart';

class TargetDurationSelector extends ConsumerWidget {
  const TargetDurationSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TargetDuration selected;
  final ValueChanged<TargetDuration> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Duração do vídeo final'),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: TargetDuration.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final option = TargetDuration.values[index];
              final active = option == selected;
              return GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 116,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        option.hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: active
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.asset,
    required this.onPick,
    required this.onClear,
  });

  final MediaAsset? asset;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    if (asset == null) {
      return SurfaceCard(
        onTap: onPick,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.video_file_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolher vídeo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vídeos longos são processados direto no aparelho',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      );
    }

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.movie_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      asset.duration?.approxHuman ?? '—',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(asset.sizeLabel, style: Theme.of(context).textTheme.bodySmall),
                    if (asset.isLarge)
                      const PillLabel(
                        text: 'Arquivo grande',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            tooltip: 'Trocar vídeo',
          ),
        ],
      ),
    );
  }
}

class AnalysisProgressCard extends StatelessWidget {
  const AnalysisProgressCard({
    super.key,
    required this.stage,
    required this.percent,
    required this.onCancel,
  });

  final AnalysisStage stage;
  final double percent;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(stage.label, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(value: percent, minHeight: 8),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }
}

class PlanSummaryCard extends StatelessWidget {
  const PlanSummaryCard({
    super.key,
    required this.totalLength,
    required this.targetLabel,
    required this.cutCount,
    required this.removedSeconds,
    required this.fillRatio,
  });

  final Duration totalLength;
  final String targetLabel;
  final int cutCount;
  final int removedSeconds;
  final double fillRatio;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('Duração', totalLength.clock),
      ('Alvo', targetLabel),
      ('Cortes', '$cutCount'),
      ('Removido', '${removedSeconds}s'),
    ];

    return SurfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B1430), Color(0xFF2A1526)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plano pronto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              PillLabel(
                text: '${(fillRatio * 100).round()}% do alvo',
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats[i].$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats[i].$2,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ExportSettingsRow extends StatelessWidget {
  const ExportSettingsRow({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ExportSettings settings;
  final ValueChanged<ExportSettings> onChanged;

  static const _options = <ExportSettings>[
    ExportSettings.vertical,
    ExportSettings.horizontal,
    ExportSettings.square,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Formato de saída'),
        Row(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_options[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _options[i].label == settings.label
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _options[i].label == settings.label
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        switch (i) {
                          0 => 'Vertical',
                          1 => 'Horizontal',
                          _ => 'Quadrado',
                        },
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _options[i].label == settings.label
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i != _options.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(settings.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
