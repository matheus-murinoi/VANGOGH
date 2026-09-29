import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_asset.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_x.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../application/library_controller.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'Nada exportado ainda',
              message:
                  'Os cortes e vídeos aprimorados que você gerar aparecem aqui.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return SurfaceCard(
                  onTap: () => ref
                      .read(libraryProvider.notifier)
                      .remove(entry.asset),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: entry.feature.startsWith('Qualidade')
                              ? AppColors.cool
                              : AppColors.brand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          entry.asset.kind == MediaKind.video
                              ? Icons.movie_rounded
                              : Icons.image_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.feature} · ${entry.asset.resolutionLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.asset.sizeLabel}'
                              '${entry.asset.duration != null ? ' · ${entry.asset.duration!.clock}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
