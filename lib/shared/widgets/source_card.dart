import 'package:flutter/material.dart';

import '../../core/media/media_asset.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/duration_x.dart';
import 'ui_kit.dart';

class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.asset,
    required this.onPick,
    required this.onClear,
    this.emptyHint = 'Vídeos longos são processados direto no aparelho',
  });

  final MediaAsset? asset;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String emptyHint;

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
                  Text(emptyHint, style: Theme.of(context).textTheme.bodySmall),
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
                    Text(
                      asset.sizeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
