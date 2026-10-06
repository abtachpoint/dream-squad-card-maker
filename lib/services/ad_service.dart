import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_state.dart';
import '../config/app_config.dart';

enum RewardedAdResult { rewarded, dailyLimit, unavailable, notEarned }

class AdService extends ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _loading = false;

  bool get loading => _loading;
  bool get ready => _rewardedAd != null;

  String get _unitId => AppConfig.useTestAds ? AppConfig.rewardedAdUnitTest : AppConfig.rewardedAdUnitLive;

  Future<void> initialize() async {
    await loadRewarded();
  }

  Future<void> loadRewarded() async {
    if (_loading || _rewardedAd != null) return;
    _loading = true;
    notifyListeners();
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _loading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  Future<RewardedAdResult> showRewarded() async {
    if (appState.adsWatchedToday >= AppConfig.rewardedAdsPerDay) {
      return RewardedAdResult.dailyLimit;
    }
    if (_rewardedAd == null) await loadRewarded();
    final ad = _rewardedAd;
    if (ad == null) return RewardedAdResult.unavailable;

    _rewardedAd = null;
    notifyListeners();
    final completer = Completer<RewardedAdResult>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadRewarded();
        if (!completer.isCompleted) {
          completer.complete(earned ? RewardedAdResult.rewarded : RewardedAdResult.notEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        loadRewarded();
        if (!completer.isCompleted) completer.complete(RewardedAdResult.unavailable);
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) async {
        if (earned) return;
        earned = await appState.creditRewardedAd();
      },
    );

    return completer.future;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}

final adService = AdService();
