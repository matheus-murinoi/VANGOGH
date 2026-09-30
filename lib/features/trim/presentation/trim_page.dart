import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_asset.dart';
import '../../../core/media/media_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_x.dart';
import '../../../shared/widgets/source_card.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../library/application/library_controller.dart';
import '../application/trim_controller.dart';
import '../application/trim_state.dart';
import 'widgets/trim_timeline.dart';
import 'widgets/trim_widgets.dart';

class TrimPage extends ConsumerWidget {
  const TrimPage({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final asset = await ref.read(mediaPickerProvider).pickVideo();
    if (asset == null) return;
    await ref.read(trimControllerProvider.notifier).selectSource(asset);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trimControllerProvider);
    final controller = ref.read(trimControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cortar vídeo'),
        actions: [
          if (state.hasSource && !state.isRendering)
            IconButton(
              tooltip: 'Trocar vídeo',
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
            onPick: () => _pick(ref),
            onClear: controller.clearSource,
            emptyHint: 'Corte, junte e exporte sem perder qualidade',
          ),

          if (!state.hasSource) ...[
            const SizedBox(height: 40),
            const EmptyState(
              icon: Icons.content_cut_rounded,
              title: 'Escolha um vídeo para começar',
              message:
                  'Arraste as bordas da timeline para cortar, toque em Cortar '
                  'para dividir em vários trechos e junte tudo em um vídeo só.',
            ),
          ] else ...[
            const SizedBox(height: 16),
            TrimPreviewPlayer(
              sourcePath: state.source!.path,
              segment: state.activeSegment,
              playhead: state.playhead,
              seekToken: state.seekToken,
              onPosition: (position) => controller.setPlayhead(position),
            ),

            const SizedBox(height: 16),
            TrimToolbar(
              canSplit: state.canSplit,
              canUndo: state.canUndo,
              canRedo: state.canRedo,
              canKeepOnly: state.segments.length > 1,
              canRestore: state.hasSource,
              onSplit: controller.splitAtPlayhead,
              onDelete: controller.removeActive,
              onKeepOnly: controller.keepOnlyActive,
              onRestore: controller.restoreAll,
              onUndo: controller.undo,
              onRedo: controller.redo,
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${state.playhead.clock} / ${state.sourceDuration.clock}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TrimTimeline(
              sourceDuration: state.sourceDuration,
              segments: state.segments,
              activeIndex: state.activeIndex,
              playhead: state.playhead,
              onSeek: (position) => controller.setPlayhead(position, seek: true),
              onSelect: controller.setActive,
              onDragStart: controller.checkpoint,
              onEdgeChanged: controller.updateActiveEdges,
            ),
            Text(
              'Arraste as alças para ajustar. Toque para mover o cursor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),
            const SectionTitle(title: 'Trechos do corte'),
            SegmentStrip(
              segments: state.segments,
              activeIndex: state.activeIndex,
              onSelect: controller.setActive,
              onDelete: (index) {
                controller.setActive(index);
                controller.removeActive();
              },
            ),
            const SizedBox(height: 8),
            TrimSummaryCard(plan: state.plan),

            RenderSettingsCard(
              settings: state.settings,
              onChanged: controller.setSettings,
            ),

            const SizedBox(height: 20),
            if (state.isRendering)
              _RenderProgressCard(percent: state.progress, onCancel: controller.cancel)
            else if (state.status == TrimStatus.done && state.result != null)
              _ResultBanner(asset: state.result!)
            else
              PrimaryGradientButton(
                label: 'Exportar ${state.plan.totalLength.clock}',
                icon: Icons.download_rounded,
                enabled: !state.isEmpty,
                onPressed: controller.render,
              ),
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

class _RenderProgressCard extends StatelessWidget {
  const _RenderProgressCard({required this.percent, required this.onCancel});

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
              Text('Montando o vídeo', style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onCancel, child: const Text('Cancelar')),
          ),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success),
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
                      '${asset.duration?.human ?? '—'} · ${asset.sizeLabel} · ${asset.resolutionLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Guardar na biblioteca do app',
                onPressed: () {
                  ref.read(libraryProvider.notifier).add(asset, 'Cortar vídeo');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvo na biblioteca')),
                  );
                },
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Ação principal em largura total: é o momento em que o cliente
          // realmente leva o resultado, então não compete com o ícone ao lado.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _save(context, ref),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('Salvar no álbum'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ),
        ],
      ),
    );
  }

  /// Grava o render no álbum do aparelho.
  ///
  /// É o passo que faltava para o cliente levar o resultado: sem ele o arquivo
  /// ficava preso no cache do app, invisível para o cliente final.
  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref.read(gallerySaverProvider).save(asset);
    messenger.showSnackBar(SnackBar(content: Text(outcome.message)));
  }
}
