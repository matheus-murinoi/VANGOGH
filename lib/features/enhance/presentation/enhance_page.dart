import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/media/media_asset.dart';
import '../../../core/media/media_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../library/application/library_controller.dart';
import '../application/enhance_controller.dart';
import '../domain/entities/enhance_job.dart';
import '../domain/entities/enhance_options.dart';
import 'widgets/enhance_widgets.dart';

class EnhancePage extends ConsumerWidget {
  const EnhancePage({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref, EnhanceKind kind) async {
    final picker = ref.read(mediaPickerProvider);
    final controller = ref.read(enhanceControllerProvider.notifier);

    if (kind == EnhanceKind.video) {
      final asset = await picker.pickVideo();
      if (asset != null) controller.setSources([asset]);
      return;
    }

    final asset = await picker.pickImages();
    if (asset != null) controller.setSources([asset]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enhanceControllerProvider);
    final controller = ref.read(enhanceControllerProvider.notifier);
    final options = state.options;

    return Scaffold(
      appBar: AppBar(title: const Text('Melhorar qualidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          EnhanceKindSelector(
            selected: options.kind,
            onChanged: controller.setKind,
          ),
          const SizedBox(height: 16),
          if (!state.hasSources)
            SurfaceCard(
              onTap: () => _pick(context, ref, options.kind),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      options.kind == EnhanceKind.video
                          ? Icons.video_file_rounded
                          : Icons.add_photo_alternate_rounded,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          options.kind == EnhanceKind.video
                              ? 'Escolher vídeo'
                              : 'Escolher imagens',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aumenta resolução, nitidez e limpa o áudio',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            )
          else
            _SourceChips(
              sources: state.sources,
              onAdd: () => _pick(context, ref, options.kind),
              onRemove: controller.removeSource,
            ),

          if (state.hasSources) ...[
            const SizedBox(height: 16),
            _EnhancePreview(
              source: state.sources.first,
              result: state.status == EnhanceStatus.done && state.results.isNotEmpty
                  ? state.results.first
                  : null,
            ),
          ],

          const SizedBox(height: 8),
          PresetSelector(
            selected: options.preset,
            onChanged: (preset) =>
                controller.updateOptions(options.copyWith(preset: preset)),
          ),

          const SectionTitle(title: 'Ajustes rápidos'),
          FilterSwitchTile(
            title: 'Upscale com IA',
            subtitle: options.estimatedScaleFactor > 1
                ? 'Reconstroi detalhes em ${options.estimatedScaleFactor}x'
                : 'Sem ganho de escala nesta resolução',
            icon: Icons.auto_fix_high_rounded,
            value: options.aiUpscale,
            onChanged: (v) =>
                controller.updateOptions(options.copyWith(aiUpscale: v)),
          ),
          FilterSwitchTile(
            title: 'Reduzir ruído',
            subtitle: 'Limpa grão de vídeo gravado com pouca luz',
            icon: Icons.blur_on_rounded,
            value: options.denoise,
            onChanged: (v) => controller.updateOptions(options.copyWith(denoise: v)),
          ),
          FilterSwitchTile(
            title: 'Aumentar nitidez',
            subtitle: 'Deixa bordas e detalhes mais definidos',
            icon: Icons.center_focus_strong_rounded,
            value: options.sharpen,
            onChanged: (v) =>
                controller.updateOptions(options.copyWith(sharpen: v)),
          ),
          if (options.kind == EnhanceKind.video) ...[
            FilterSwitchTile(
              title: 'Estabilizar',
              subtitle: 'Reduz tremida de câmera na mão',
              icon: Icons.videocam_rounded,
              value: options.stabilize,
              onChanged: (v) =>
                  controller.updateOptions(options.copyWith(stabilize: v)),
            ),
            FilterSwitchTile(
              title: 'Normalizar áudio',
              subtitle: 'Deixa o som no mesmo volume do original',
              icon: Icons.volume_up_rounded,
              value: options.normalizeAudio,
              onChanged: (v) =>
                  controller.updateOptions(options.copyWith(normalizeAudio: v)),
            ),
          ],

          const SectionTitle(title: 'Correções de cor'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                AdjustmentSlider(
                  label: 'Brilho',
                  value: options.brightness,
                  onChanged: (v) =>
                      controller.updateOptions(options.copyWith(brightness: v)),
                ),
                AdjustmentSlider(
                  label: 'Contraste',
                  value: options.contrast,
                  onChanged: (v) =>
                      controller.updateOptions(options.copyWith(contrast: v)),
                ),
                AdjustmentSlider(
                  label: 'Saturação',
                  value: options.saturation,
                  onChanged: (v) =>
                      controller.updateOptions(options.copyWith(saturation: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          if (options.activeFilters.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in options.activeFilters)
                  PillLabel(text: filter, color: AppColors.teal),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (state.isRunning)
            EnhanceProgressCard(
              progress: EnhanceProgress(
                stage: state.stage,
                percent: state.progress,
                etaSeconds: state.etaSeconds,
              ),
              onCancel: controller.cancel,
            )
          else if (state.status == EnhanceStatus.done)
            _DonePanel(
              results: state.results,
              onRerun: controller.run,
              onSave: () {
                final feature = options.kind == EnhanceKind.video
                    ? 'Qualidade (vídeo)'
                    : 'Qualidade (imagens)';
                for (final asset in state.results) {
                  ref.read(libraryProvider.notifier).add(asset, feature);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salvo na biblioteca')),
                );
              },
            )
          else
            PrimaryGradientButton(
              label: 'Melhorar qualidade agora',
              icon: Icons.hd_rounded,
              gradient: AppColors.cool,
              enabled: state.hasSources,
              onPressed: controller.run,
            ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnhancePreview extends StatefulWidget {
  const _EnhancePreview({required this.source, this.result});

  final MediaAsset source;
  final MediaAsset? result;

  @override
  State<_EnhancePreview> createState() => _EnhancePreviewState();
}

class _EnhancePreviewState extends State<_EnhancePreview> {
  VideoPlayerController? _videoController;
  bool _showResult = false;
  String? _loadedPath;

  MediaAsset get _activeAsset =>
      _showResult && widget.result != null ? widget.result! : widget.source;

  @override
  void initState() {
    super.initState();
    _loadVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _EnhancePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.path != widget.source.path ||
        oldWidget.result?.path != widget.result?.path) {
      _showResult = false;
      _loadVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoIfNeeded() async {
    final asset = _activeAsset;
    final path = asset.isVideo ? asset.path : null;
    if (_loadedPath == path) return;

    final previous = _videoController;
    _videoController = null;
    _loadedPath = path;
    await previous?.dispose();

    if (path == null) {
      if (mounted) setState(() {});
      return;
    }

    final next = VideoPlayerController.file(File(path));
    _videoController = next;
    try {
      await next.initialize();
      if (mounted && identical(_videoController, next)) setState(() {});
    } catch (_) {
      if (mounted && identical(_videoController, next)) setState(() {});
    }
  }

  void _selectResult(bool value) {
    if (_showResult == value) return;
    setState(() => _showResult = value);
    _loadVideoIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _activeAsset;
    final video = _videoController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Prévia', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (widget.result != null)
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Original')),
                  ButtonSegment(value: true, label: Text('Resultado')),
                ],
                selected: {_showResult},
                onSelectionChanged: (selection) =>
                    _selectResult(selection.first),
              )
            else
              const PillLabel(text: 'Original', color: AppColors.textMuted),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.surfaceHigh),
                if (asset.isVideo && video?.value.isInitialized == true)
                  VideoPlayer(video!)
                else if (!asset.isVideo)
                  Image.file(
                    File(asset.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _PreviewFallback(),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      if (asset.isVideo && video?.value.isInitialized == true)
                        IconButton.filledTonal(
                          tooltip: video!.value.isPlaying ? 'Pausar' : 'Reproduzir',
                          onPressed: () => video.value.isPlaying
                              ? video.pause()
                              : video.play(),
                          icon: Icon(
                            video.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${asset.name} · ${asset.resolutionLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textMuted,
        size: 36,
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({
    required this.sources,
    required this.onAdd,
    required this.onRemove,
  });

  final List<MediaAsset> sources;
  final VoidCallback onAdd;
  final ValueChanged<MediaAsset> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sources.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == sources.length) {
            return GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 92,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.textMuted),
              ),
            );
          }
          final asset = sources[index];
          return Container(
            width: 148,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      asset.kind == MediaKind.video
                          ? Icons.movie_rounded
                          : Icons.image_rounded,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onRemove(asset),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  asset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${asset.resolutionLabel} · ${asset.sizeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DonePanel extends StatelessWidget {
  const _DonePanel({
    required this.results,
    required this.onRerun,
    required this.onSave,
  });

  final List<MediaAsset> results;
  final VoidCallback onRerun;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E2A26), Color(0xFF10233A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Text(
                results.length == 1
                    ? 'Pronto!'
                    : '${results.length} arquivos prontos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final asset in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${asset.name} · ${asset.resolutionLabel} · ${asset.sizeLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRerun,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refazer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
