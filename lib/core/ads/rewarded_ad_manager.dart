import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

class RewardedAdManager {
  RewardedAdManager._();
  static final RewardedAdManager instance = RewardedAdManager._();

  RewardedAd? _anuncioPrecargado;

  void precargar() {
    RewardedAd.load(
      adUnitId: AdIds.recompensado,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _anuncioPrecargado = ad,
        onAdFailedToLoad: (error) => _anuncioPrecargado = null,
      ),
    );
  }

  void mostrar({
    required VoidCallback onRecompensaGanada,
    required VoidCallback onNoDisponible,
  }) {
    final anuncio = _anuncioPrecargado;
    if (anuncio == null) {
      onNoDisponible();
      precargar();
      return;
    }

    _anuncioPrecargado = null;
    anuncio.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        precargar();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        precargar();
        onNoDisponible();
      },
    );

    anuncio.show(
      onUserEarnedReward: (ad, reward) => onRecompensaGanada(),
    );
  }
}