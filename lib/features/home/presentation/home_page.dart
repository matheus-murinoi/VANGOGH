import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../library/application/library_controller.dart';
import '../../../shared/widgets/ui_kit.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.onGoHighlights, required this.onGoEnhance});

  final VoidCallback onGoHighlights;
  final VoidCallback onGoEnhance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aprimorar Vídeo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Tudo processado no aparelho',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),
            Text(
              'Edite vídeos grandes\nsem perder tempo',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 10),
            Text(
              'O app acha os melhores momentos sozinho e melhora a '
              'qualidade de vídeo e imagens. Sem enviar para a nuvem.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 28),
            _FeatureCard(
              title: 'Cortar melhores momentos',
              description:
                  'Analisa áudio e cenas para montar o corte no tamanho que '
                  'você quiser: 30s, 45s, 1min, 1min30 ou 2min.',
              icon: Icons.auto_awesome_rounded,
              gradient: AppColors.brand,
              bullets: const [
                'Escolha a duração final',
                'Ajuste os trechos manualmente',
                'Exporta em 9:16, 16:9 ou 1:1',
              ],
              onTap: onGoHighlights,
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              title: 'Melhorar qualidade',
              description:
                  'Aumenta a resolução, deixa tudo mais nítido, tira ruído '
                  'e normaliza o som.',
              icon: Icons.hd_rounded,
              gradient: AppColors.cool,
              bullets: const [
                'Vídeo e imagens em lote',
                'Upscale até 4K',
                'Ajustes de cor rápidos',
              ],
              onTap: onGoEnhance,
            ),

            if (library.isNotEmpty) ...[
              SectionTitle(
                title: 'Recentes',
                trailing: Text(
                  '${library.length} itens',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final entry in library.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              Text(
                                '${entry.feature} · ${entry.asset.sizeLabel}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.bullets,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final List<String> bullets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(bullet, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
