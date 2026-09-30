import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/media/render_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_x.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/entities/clip_segment.dart';
import '../../domain/entities/trim_plan.dart';

class TrimPreviewPlayer extends StatefulWidget {
  const TrimPreviewPlayer({
    super.key,
    required this.sourcePath,
    required this.segment,
    required this.playhead,
    required this.seekToken,
    required this.onPosition,
  });

  final String sourcePath;
  final ClipSegment? segment;
  final Duration playhead;
  final int seekToken;
  final ValueChanged<Duration> onPosition;

  @override
  State<TrimPreviewPlayer> createState() => _TrimPreviewPlayerState();
}

class _TrimPreviewPlayerState extends State<TrimPreviewPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.file(File(widget.sourcePath));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      final segment = widget.segment;
      if (segment != null) await controller.seekTo(segment.start);
      await controller.play();
    } catch (error) {
      _error = error;
    }
    controller.addListener(_tick);
    if (!mounted) return;
    setState(() {});
  }

  void _tick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final segment = widget.segment;
    if (segment != null && controller.value.position >= segment.end) {
      controller.seekTo(segment.start);
      if (!controller.value.isPlaying) controller.play();
      return;
    }
    widget.onPosition(controller.value.position);
  }

  void _seek(Duration position) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.seekTo(position);
    if (!controller.value.isPlaying) controller.play();
  }

  @override
  void didUpdateWidget(TrimPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seekToken != oldWidget.seekToken) {
      _seek(widget.playhead);
      return;
    }
    final segment = widget.segment;
    if (segment == null || segment == oldWidget.segment) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    if (position < segment.start || position >= segment.end) {
      _seek(segment.start);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) return _shell(aspectRatio: 16 / 9, child: _fallback());
    if (controller == null || !controller.value.isInitialized) {
      return _shell(
        aspectRatio: 16 / 9,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return _shell(
      aspectRatio: controller.value.aspectRatio,
      child: _preview(controller),
    );
  }

  Widget _shell({required double aspectRatio, required Widget child}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black),
            child: child,
          ),
        ),
      );

  Widget _fallback() => const Center(
    child: Icon(
      Icons.videocam_off_outlined,
      color: AppColors.textMuted,
      size: 32,
    ),
  );

  Widget _preview(VideoPlayerController controller) {
    final segment = widget.segment;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned(
          left: 8,
          right: 12,
          bottom: 8,
          child: Row(
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) => IconButton(
                  onPressed: () =>
                      value.isPlaying ? controller.pause() : controller.play(),
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              PillLabel(
                text: segment == null
                    ? '—'
                    : '${widget.playhead.clock} · ${segment.length.clock}',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SegmentStrip extends StatelessWidget {
  const SegmentStrip({
    super.key,
    required this.segments,
    required this.activeIndex,
    required this.onSelect,
    required this.onDelete,
  });

  final List<ClipSegment> segments;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: segments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final segment = segments[index];
          final active = index == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
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
                    'Trecho ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${segment.start.clock} → ${segment.end.clock}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    children: [
                      PillLabel(
                        text: segment.length.human,
                        color: active ? AppColors.primary : AppColors.teal,
                      ),
                      const Spacer(),
                      if (segments.length > 1)
                        InkWell(
                          onTap: () => onDelete(index),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TrimSummaryCard extends StatelessWidget {
  const TrimSummaryCard({super.key, required this.plan});

  final TrimPlan plan;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('Duração final', plan.totalLength.clock),
      ('Trechos', '${plan.segments.length}'),
      ('Cortes', '${plan.cutCount}'),
      ('Removido', '${plan.secondsRemoved}s'),
    ];

    return SurfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF141C33), Color(0xFF241536)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_cut_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text('Seu corte', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              PillLabel(
                text: '${(plan.keptRatio * 100).round()}% mantido',
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final stat in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.$1, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        stat.$2,
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
          ),
        ],
      ),
    );
  }
}

class RenderSettingsCard extends StatelessWidget {
  const RenderSettingsCard({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final RenderSettings settings;
  final ValueChanged<RenderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Qualidade da exportação'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quality in RenderQuality.values)
              _ChoiceChip(
                label: quality.label,
                hint: quality.hint,
                selected: quality == settings.quality,
                onTap: () => onChanged(settings.copyWith(quality: quality)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionTitle(title: 'Formato de saída'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final format in OutputFormat.values)
              _ChoiceChip(
                label: format.label,
                hint: format.hint,
                selected: format == settings.format,
                onTap: () => onChanged(settings.copyWith(format: format)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionTitle(title: 'Quadros por segundo'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoiceChip(
              label: 'Original',
              hint: 'Mantém do vídeo',
              selected: settings.fps == null,
              onTap: () => onChanged(settings.copyWith(clearFps: true)),
            ),
            for (final fps in RenderSettings.fpsOptions)
              _ChoiceChip(
                label: '$fps fps',
                hint: 'Fluido',
                selected: settings.fps == fps,
                onTap: () => onChanged(settings.copyWith(fps: fps)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: settings.keepAudio,
          onChanged: (value) => onChanged(settings.copyWith(keepAudio: value)),
          title: const Text('Manter o áudio'),
          subtitle: Text(
            'Desligue para salvar ainda mais espaço',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 6),
        Text(settings.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class TrimToolbar extends StatelessWidget {
  const TrimToolbar({
    super.key,
    required this.canSplit,
    required this.canUndo,
    required this.canRedo,
    required this.canKeepOnly,
    required this.canRestore,
    required this.onSplit,
    required this.onDelete,
    required this.onKeepOnly,
    required this.onRestore,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canSplit;
  final bool canUndo;
  final bool canRedo;
  final bool canKeepOnly;
  final bool canRestore;
  final VoidCallback onSplit;
  final VoidCallback onDelete;
  final VoidCallback onKeepOnly;
  final VoidCallback onRestore;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolButton(
          icon: Icons.content_cut_rounded,
          label: 'Cortar',
          enabled: canSplit,
          onTap: onSplit,
          primary: true,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          icon: Icons.delete_outline_rounded,
          label: 'Remover',
          enabled: canRestore,
          onTap: onDelete,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          icon: Icons.filter_alt_rounded,
          label: 'Só este',
          enabled: canKeepOnly,
          onTap: onKeepOnly,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          icon: Icons.undo_rounded,
          label: 'Desfazer',
          enabled: canUndo,
          onTap: onUndo,
        ),
        const SizedBox(width: 8),
        _ToolButton(
          icon: Icons.redo_rounded,
          label: 'Refazer',
          enabled: canRedo,
          onTap: onRedo,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: primary ? AppColors.primary : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primary ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: primary ? Colors.white : AppColors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: primary ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
