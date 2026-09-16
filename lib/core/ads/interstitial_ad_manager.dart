import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import '../services/pro_state.dart';

/// Controla cuándo mostrar el intersticial al entrar al detalle de un
/// partido no-Pro: 1 de cada 2 visitas (1, 3, 5, 7...), contador que se
/// reinicia cada vez que se abre la app (vive solo en memoria).
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  int _contadorVisitas = 0;
  InterstitialAd? _anuncioPrecargado;

  bool _tocaMostrar() {
    _contadorVisitas++;
    return _contadorVisitas.isOdd;
  }

  void _precargar() {
    // Si el usuario ya es Pro, no tiene sentido precargar nada.
    if (esProNotifier.value) return;

    InterstitialAd.load(
      adUnitId: AdIds.intersticial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _anuncioPrecargado = ad;
        },
        onAdFailedToLoad: (error) {
          _anuncioPrecargado = null;
        },
      ),
    );
  }

  /// Decide si corresponde intersticial para este partido y, si aplica,
  /// lo muestra. [alTerminar] se llama siempre al final (haya habido
  /// anuncio o no), para recién ahí navegar al detalle.
  ///
  /// [esPro] indica si el PARTIDO es de contenido Pro (requiere pago).
  /// El estado Pro del USUARIO se lee directo de [esProNotifier], así
  /// que si ya pagó la suscripción nunca ve anuncios.
  void mostrarSiCorresponde({
    required bool esPro,
    required VoidCallback alTerminar,
  }) {
    // Salta el anuncio si: el partido es Pro, o el usuario ya es Pro.
    if (esPro || esProNotifier.value) {
      alTerminar();
      return;
    }

    final debeMostrar = _tocaMostrar();
    if (!debeMostrar || _anuncioPrecargado == null) {
      if (_anuncioPrecargado == null) _precargar();
      alTerminar();
      return;
    }

    final anuncio = _anuncioPrecargado!;
    _anuncioPrecargado = null;
    anuncio.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _precargar();
        alTerminar();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _precargar();
        alTerminar();
      },
    );
    anuncio.show();
  }

  /// Llamar una vez al iniciar la app para tener el primer intersticial
  /// listo desde el arranque.
  void precargarInicial() {
    _precargar();
  }
}