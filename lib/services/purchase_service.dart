import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_state.dart';
import '../config/app_config.dart';

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, ProductDetails> _products = {};
  bool _available = false;
  bool _loading = false;
  String? _lastError;

  bool get available => _available;
  bool get loading => _loading;
  String? get lastError => _lastError;
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  Future<void> initialize() async {
    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _lastError = 'Purchase service error.';
        notifyListeners();
      },
    );
    _available = await _iap.isAvailable();
    if (_available) await refreshProducts();
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    if (!_available || _loading) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final response = await _iap.queryProductDetails(AppConfig.coinProducts.keys.toSet());
      _products
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
      if (response.error != null) _lastError = response.error!.message;
    } catch (_) {
      _lastError = 'Could not load coin packs.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      await refreshProducts();
    }
    final refreshed = _products[productId];
    if (refreshed == null) return false;
    final param = PurchaseParam(productDetails: refreshed);
    return _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        if (purchase.status == PurchaseStatus.purchased) {
          final coins = AppConfig.coinProducts[purchase.productID];
          if (coins != null) {
            final raw = '${purchase.purchaseID ?? ''}|${purchase.productID}|${purchase.transactionDate ?? ''}|${purchase.verificationData.localVerificationData}';
            final purchaseKey = sha256.convert(utf8.encode(raw)).toString();
            await appState.creditPurchase(
              productId: purchase.productID,
              purchaseKey: purchaseKey,
              coins: coins,
            );
          }
        }
        if (purchase.status == PurchaseStatus.error) {
          _lastError = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
        }
      } finally {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final purchaseService = PurchaseService();
