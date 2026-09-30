import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_asset.dart';
import '../../../core/media/media_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_x.dart';
import '../../../shared/widgets/source_card.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../library/application/library_controller.dart';
import '../application/highlights_controller.dart';
import '../application/highlights_state.dart';
import '../domain/entities/analysis.dart';
import 'widgets/highlight_widgets.dart';
import 'widgets/moment_list.dart';

class HighlightsPage extends ConsumerWidget {
  const HighlightsPage({super.key});

  Future<void> _pickVideo(BuildContext context, WidgetRef ref) async {
    final picker = ref.read(mediaPickerProvider);
    final asset = await picker.pickVideo();
    if (asset != null) {
      ref.read(highlightsControllerProvider.notifier).selectSource(asset);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(highlightsControllerProvider);
    final controller = ref.read(highlightsControllerProvider.notifier);
    final plan = state.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Melhores momentos'),
        actions: [
          if (state.hasSource && !state.isBusy)
            IconButton(
              tooltip: 'Reiniciar',
              onPressed: controller.clearSource,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SourceCard(
            asset: state.source,
            onPick: () => _pickVideo(context, ref),
            onClear: controller.clearSource,
          ),

          if (!state.hasSource) ...[
            const SizedBox(height: 40),
            const EmptyState(
              icon: Icons.auto_awesome_motion_rounded,
              title: 'Escolha um vídeo para começar',
              message:
                  'O app analisa o vídeo inteiro e monta um corte com os '
                  'melhores momentos no tamanho que você escolher.',
            ),
          ] else ...[
            TargetDurationSelector(
              selected: state.target,
              onChanged: controller.setTarget,
            ),

            const SizedBox(height: 20),
            if (!state.isBusy &&
                state.status != HighlightsStatus.done &&
                state.candidates.isEmpty)
              PrimaryGradientButton(
                label: 'Analisar e achar melhores momentos',
                icon: Icons.auto_awesome_rounded,
                onPressed: controller.analyze,
              ),

            if (state.isBusy && state.status == HighlightsStatus.analyzing) ...[
              const SizedBox(height: 8),
              AnalysisProgressCard(
                stage: state.stage,
                percent: state.progress,
                onCancel: controller.cancel,
              ),
            ],

            if (state.candidates.isNotEmpty) ...[
              PlanSummaryCard(
                totalLength: plan.totalLength,
                targetLabel: state.target.label,
                cutCount: plan.cutCount,
                removedSeconds: plan.secondsRemoved,
                fillRatio: plan.fillRatio,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${state.candidates.length} momentos encontrados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => controller.keepOnlyTop(3),
                    child: const Text('Manter os 3 melhores'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MomentList(
                moments: state.candidates,
                excludedIds: state.excluded,
                onToggle: controller.toggleMoment,
              ),

              ExportSettingsRow(
                settings: state.exportSettings,
                onChanged: controller.setExportSettings,
              ),

              const SizedBox(height: 20),
              if (state.status == HighlightsStatus.exporting) ...[
                AnalysisProgressCard(
                  stage: AnalysisStage.montandoPlano,
                  percent: state.progress,
                  onCancel: controller.cancel,
                ),
              ] else if (state.status == HighlightsStatus.done) ...[
                _ResultBanner(asset: state.result!),
                const SizedBox(height: 12),
                PrimaryGradientButton(
                  label: 'Gerar novo corte',
                  icon: Icons.refresh_rounded,
                  onPressed: controller.analyze,
                ),
              ] else
                PrimaryGradientButton(
                  label: 'Exportar ${plan.totalLength.clock}',
                  icon: Icons.movie_filter_rounded,
                  onPressed: controller.export,
                ),
            ],
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultBanner extends ConsumerWidget {
  const _ResultBanner({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E2A26), Color(0xFF10233A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vídeo pronto!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${asset.name} · ${asset.sizeLabel} · ${asset.resolutionLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Salvar na biblioteca',
            onPressed: () {
              ref.read(libraryProvider.notifier).add(asset, 'Melhores momentos');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Salvo na biblioteca')),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
    );
  }
}
