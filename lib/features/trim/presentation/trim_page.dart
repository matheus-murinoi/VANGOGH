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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('VanGogh Editor', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (state.hasSource)
            IconButton(
              tooltip: 'Trocar vídeo',
              onPressed: controller.clearSource,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          if (!state.isRendering)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PrimaryGradientButton(
                label: 'Exportar',
                onPressed: controller.render,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              child: state.hasSource
                  ? Center(
                      child: TrimPreviewPlayer(
                        sourcePath: state.source!.path,
                        segment: state.activeSegment,
                        playhead: state.playhead,
                        seekToken: state.seekToken,
                        onPosition: (position) => controller.setPlayhead(position),
                      ),
                    )
                  : _EmptyPreview(onPick: () => _pick(ref)),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${state.playhead.clock} / ${state.sourceDuration.clock}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  _CapCutToolBar(
                    canSplit: state.canSplit,
                    canUndo: state.canUndo,
                    canRedo: state.canRedo,
                    onSplit: controller.splitAtPlayhead,
                    onDelete: controller.removeActive,
                    onUndo: controller.undo,
                    onRedo: controller.redo,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: state.isRendering
          ? _RenderProgressBar(percent: state.progress, onCancel: controller.cancel)
          : null,
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library_rounded, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text('Nenhum vídeo selecionado', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.add),
          label: const Text('Importar Vídeo'),
        ),
      ],
    );
  }
}

class _CapCutToolBar extends StatelessWidget {
  const _CapCutToolBar({
    required this.canSplit,
    required this.canUndo,
    required this.canRedo,
    required this.onSplit,
    required this.onDelete,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canSplit;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onSplit;
  final VoidCallback onDelete;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolItem(icon: Icons.undo_rounded, label: 'Desfazer', enabled: canUndo, onTap: onUndo),
          _ToolItem(icon: Icons.redo_rounded, label: 'Refazer', enabled: canRedo, onTap: onRedo),
          _ToolItem(icon: Icons.content_cut_rounded, label: 'Dividir', enabled: canSplit, onTap: onSplit),
          _ToolItem(icon: Icons.delete_outline_rounded, label: 'Excluir', enabled: true, onTap: onDelete),
          _ToolItem(icon: Icons.auto_fix_high_rounded, label: 'Ajustar', enabled: true, onTap: () {}),
          _ToolItem(icon: Icons.music_note_rounded, label: 'Áudio', enabled: true, onTap: () {}),
          _ToolItem(icon: Icons.text_fields_rounded, label: 'Texto', enabled: true, onTap: () {}),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            Icon(icon, color: enabled ? Colors.white : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: enabled ? Colors.white : AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _RenderProgressBar extends StatelessWidget {
  const _RenderProgressBar({required this.percent, required this.onCancel});
  final double percent;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Exportando...', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(percent * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: percent, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 12),
          TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
