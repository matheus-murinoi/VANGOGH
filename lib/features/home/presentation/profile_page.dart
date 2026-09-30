import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../library/application/library_controller.dart';
import '../../subscription/application/subscription_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exports = ref.watch(libraryProvider);
    final subscription = ref.watch(subscriptionControllerProvider);
    final subscriptionController = ref.read(subscriptionControllerProvider.notifier);
    final videos = exports.where((entry) => entry.asset.isVideo).length;
    final images = exports.length - videos;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil e plano')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SurfaceCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF183B37), Color(0xFF172B3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Seu espaço criativo',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 3),
                        Text('Perfil local neste aparelho',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'Atividade'),
          SurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: _ActivityMetric(
                    label: 'Exportações',
                    value: '${exports.length}',
                  ),
                ),
                Container(width: 1, height: 42, color: AppColors.border),
                Expanded(
                  child: _ActivityMetric(label: 'Vídeos', value: '$videos'),
                ),
                Container(width: 1, height: 42, color: AppColors.border),
                Expanded(
                  child: _ActivityMetric(label: 'Imagens', value: '$images'),
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'Apoio ao projeto'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_outlined, color: AppColors.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subscription.isSupporter
                          ? 'Apoio ativo'
                          : 'Recursos gratuitos',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    PillLabel(
                        text: subscription.isSupporter ? 'OBRIGADO' : 'SEM CUSTO',
                        color: subscription.isSupporter
                          ? AppColors.success
                          : AppColors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                    subscription.isSupporter
                        ? _proStatus(subscription.expirationDate)
                        : 'Todos os recursos do app, incluindo exportação em 4K, continuam gratuitos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            gradient: AppColors.cool,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Assinatura simbólica',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                    PillLabel(
                        text: subscription.isSupporter
                          ? 'APOIO ATIVO'
                          : 'OPCIONAL',
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _ProFeature(text: 'Todos os recursos permanecem gratuitos'),
                const _ProFeature(text: 'Ajuda a manter e evoluir o aplicativo'),
              ],
            ),
          ),
          const SectionTitle(title: 'Apoio com teste grátis'),
          if (subscription.isLoading && subscription.packages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!subscription.storeAvailable)
            _StoreMessage(
              message: subscription.errorMessage ??
                  'Abra o app em um aparelho com App Store ou Google Play.',
              actionLabel: 'Tentar novamente',
              onPressed: subscriptionController.refreshProducts,
            )
          else if (subscription.packages.isEmpty)
            _StoreMessage(
              message: subscription.notice ??
                  'Nenhum plano de apoio foi encontrado na oferta RevenueCat.',
              actionLabel: 'Atualizar planos',
              onPressed: subscriptionController.refreshProducts,
            )
          else
            for (final package in subscription.packages)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(package.storeProduct.title,
                                style: Theme.of(context).textTheme.titleMedium),
                            if (package.storeProduct.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(package.storeProduct.description,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _freeTrialLabel(package),
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Depois do teste: ${package.storeProduct.priceString} ${_billingPeriod(package)}.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: subscription.isSupporter ||
                                !_hasFreeTrial(package) ||
                                subscription.pendingProductId != null
                            ? null
                            : () => subscriptionController.buy(package),
                          child: subscription.pendingProductId == package.identifier
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                              subscription.isSupporter
                                ? 'Ativo'
                                : _hasFreeTrial(package)
                                  ? 'Começar teste grátis'
                                  : 'Teste grátis ausente',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          if (subscription.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subscription.errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          if (subscription.notice != null && subscription.packages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subscription.notice!,
                style: Theme.of(context).textTheme.bodySmall),
          ],
          TextButton.icon(
            onPressed: subscription.storeAvailable
                ? subscriptionController.restorePurchases
                : null,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restaurar compras'),
          ),
          const SizedBox(height: 4),
          Text(
            'O apoio é opcional. O teste grátis depende da elegibilidade da loja; após o período, a renovação usa o preço mostrado acima. Cancele na loja quando quiser.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _proStatus(String? expirationDate) {
  if (expirationDate == null) return 'Sua assinatura de apoio está ativa.';
  final date = DateTime.tryParse(expirationDate);
  if (date == null) return 'Sua assinatura de apoio está ativa.';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'Sua assinatura de apoio está ativa até $day/$month/${date.year}.';
}

bool _hasFreeTrial(Package package) {
  final introductoryPrice = package.storeProduct.introductoryPrice;
  if (introductoryPrice != null && introductoryPrice.price == 0) return true;

  final options = [
    ?package.storeProduct.defaultOption,
    ...?package.storeProduct.subscriptionOptions,
  ];
  return options.any((option) {
    final freePhase = option.freePhase;
    return freePhase?.offerPaymentMode == OfferPaymentMode.freeTrial &&
        freePhase?.price.amountMicros == 0;
  });
}

String _freeTrialLabel(Package package) {
  final trial = package.storeProduct.introductoryPrice;
  if (trial == null || trial.price != 0) {
    return _hasFreeTrial(package)
        ? 'Teste grátis para assinantes elegíveis'
        : 'Teste grátis não configurado';
  }

  final count = trial.periodNumberOfUnits;
  final unit = switch (trial.periodUnit) {
    PeriodUnit.day => count == 1 ? 'dia' : 'dias',
    PeriodUnit.week => count == 1 ? 'semana' : 'semanas',
    PeriodUnit.month => count == 1 ? 'mês' : 'meses',
    PeriodUnit.year => count == 1 ? 'ano' : 'anos',
    PeriodUnit.unknown => 'período',
  };
  return '$count $unit grátis para assinantes elegíveis';
}

String _billingPeriod(Package package) => switch (package.packageType) {
      PackageType.weekly => 'por semana',
      PackageType.monthly => 'por mês',
      PackageType.twoMonth => 'a cada 2 meses',
      PackageType.threeMonth => 'a cada 3 meses',
      PackageType.sixMonth => 'a cada 6 meses',
      PackageType.annual => 'por ano',
      PackageType.lifetime => 'pagamento único',
      PackageType.unknown || PackageType.custom => 'por período da loja',
    };

class _StoreMessage extends StatelessWidget {
  const _StoreMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProFeature extends StatelessWidget {
  const _ProFeature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}