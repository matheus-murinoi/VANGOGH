import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const supportEntitlementId = 'apoio';

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
  SubscriptionController.new,
);

class SubscriptionState {
  const SubscriptionState({
    this.storeAvailable = false,
    this.isLoading = true,
    this.isSupporter = false,
    this.packages = const [],
    this.pendingProductId,
    this.expirationDate,
    this.errorMessage,
    this.notice,
  });

  final bool storeAvailable;
  final bool isLoading;
  final bool isSupporter;
  final List<Package> packages;
  final String? pendingProductId;
  final String? expirationDate;
  final String? errorMessage;
  final String? notice;

  SubscriptionState copyWith({
    bool? storeAvailable,
    bool? isLoading,
    bool? isSupporter,
    List<Package>? packages,
    String? pendingProductId,
    String? expirationDate,
    String? errorMessage,
    String? notice,
    bool clearPendingProduct = false,
    bool clearExpirationDate = false,
    bool clearError = false,
    bool clearNotice = false,
  }) =>
      SubscriptionState(
        storeAvailable: storeAvailable ?? this.storeAvailable,
        isLoading: isLoading ?? this.isLoading,
        isSupporter: isSupporter ?? this.isSupporter,
        packages: packages ?? this.packages,
        pendingProductId: clearPendingProduct
            ? null
            : (pendingProductId ?? this.pendingProductId),
        expirationDate: clearExpirationDate
            ? null
            : (expirationDate ?? this.expirationDate),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        notice: clearNotice ? null : (notice ?? this.notice),
      );
}

class SubscriptionController extends Notifier<SubscriptionState> {
  bool _listenerRegistered = false;

  String? get _apiKey => switch (defaultTargetPlatform) {
        TargetPlatform.android => const String.fromEnvironment(
            'REVENUECAT_ANDROID_API_KEY',
          ),
        TargetPlatform.iOS => const String.fromEnvironment(
            'REVENUECAT_IOS_API_KEY',
          ),
        _ => null,
      };

  @override
  SubscriptionState build() {
    ref.onDispose(() {
      if (_listenerRegistered) {
        Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
        _listenerRegistered = false;
      }
    });
    unawaited(Future<void>.microtask(_initialize));
    return const SubscriptionState();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final apiKey = _apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        state = state.copyWith(
          storeAvailable: false,
          isLoading: false,
          errorMessage:
              'Configure a chave pública RevenueCat deste app para carregar os planos.',
        );
        return;
      }

      if (!await Purchases.isConfigured) {
        final configuration = PurchasesConfiguration(apiKey)
          ..entitlementVerificationMode =
              EntitlementVerificationMode.informational;
        await Purchases.configure(configuration);
      }
      if (!_listenerRegistered) {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
        _listenerRegistered = true;
      }

      final customerInfo = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdated(customerInfo);
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const <Package>[];
      final hasFreeTrial = packages.any(_hasFreeTrial);
      state = state.copyWith(
        storeAvailable: true,
        isLoading: false,
        packages: packages,
        notice: packages.isEmpty
            ? 'Configure uma oferta atual com planos mensais ou anuais no RevenueCat.'
            : hasFreeTrial
                ? null
                : 'Configure um teste grátis com preço zero para os planos de apoio.',
        clearNotice: packages.isNotEmpty && hasFreeTrial,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        storeAvailable: false,
        isLoading: false,
        errorMessage: error.message ?? 'Não foi possível conectar ao RevenueCat.',
      );
    } catch (error) {
      state = state.copyWith(
        storeAvailable: false,
        isLoading: false,
        errorMessage: 'Não foi possível carregar os planos: $error',
      );
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.active[supportEntitlementId];
    state = state.copyWith(
      isSupporter: entitlement?.isActive ?? false,
      expirationDate: entitlement?.expirationDate,
      clearExpirationDate: entitlement?.expirationDate == null,
    );
  }

  Future<void> buy(Package package) async {
    if (!state.storeAvailable) return;
    if (!_hasFreeTrial(package)) {
      state = state.copyWith(
        errorMessage: 'Este plano não será oferecido sem teste grátis.',
      );
      return;
    }

    state = state.copyWith(
      pendingProductId: package.identifier,
      clearError: true,
      clearNotice: true,
    );
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfoUpdated(result.customerInfo);
      state = state.copyWith(
        clearPendingProduct: true,
        notice: state.isSupporter
          ? 'Assinatura de apoio ativa.'
          : 'A compra foi recebida, mas o entitlement de apoio não está ativo no RevenueCat.',
        errorMessage: state.isSupporter
            ? null
          : 'Verifique se os produtos estão associados ao entitlement “apoio”.',
        clearError: state.isSupporter,
      );
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      state = state.copyWith(
        clearPendingProduct: true,
        notice: errorCode == PurchasesErrorCode.purchaseCancelledError
            ? 'Compra cancelada.'
            : null,
        clearNotice: errorCode != PurchasesErrorCode.purchaseCancelledError,
        errorMessage: errorCode == PurchasesErrorCode.purchaseCancelledError
            ? null
            : (error.message ?? 'A compra não foi concluída.'),
        clearError: errorCode == PurchasesErrorCode.purchaseCancelledError,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingProduct: true,
        errorMessage: 'Não foi possível iniciar a compra: $error',
      );
    }
  }

  Future<void> refreshProducts() => _initialize();

  Future<void> restorePurchases() async {
    if (!state.storeAvailable) {
      await _initialize();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      _onCustomerInfoUpdated(customerInfo);
      state = state.copyWith(
        isLoading: false,
        notice: state.isSupporter
          ? 'Assinatura de apoio restaurada.'
          : 'Nenhuma assinatura de apoio ativa foi encontrada nesta conta.',
        clearPendingProduct: true,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message ?? 'Não foi possível restaurar as compras.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível restaurar as compras: $error',
      );
    }
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

}