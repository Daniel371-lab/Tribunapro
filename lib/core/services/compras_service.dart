import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'usuario_state.dart';

class ComprasIds {
  static const suscripcionMensual = 'modo_pro_mensual';
  static const desbloqueoPartido = 'desbloqueo_partido';
}

// Clave pública de licencia de Play Console (no es secreta, es de solo verificación).
const String _clavePublicaBase64 =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5QK/ZN2MYwnrVYhl2HSWC7f4nxxmrwADynEZ+KBWMcoeZVXvNlgxD4AYGaEXzp9QJgljS7dpKGRLbfyRO8kAm2gcP7rxyKWGwVVHJbeBrwutKJ4sC8YF7XLA/96KA41PyqoKFcmAAuvWLVDjpUF70WENlulIoWfI5mz5Q2MqGRG54kCGFf11GFyIKmTlgBa+bR9RwV1qI1xx/ShHI9dO+Yc/nqfWeJPA8WHkmuk2dFU45F11b+3hZm+kt0EYTkOe78hpSe2aXTsYr+tjRDx0yfV/CDRqRN2/nUBATTFilm5g3LCtbeXxrK9Ifmipt84dYa2OsSJRkldwgjFc+nShhQIDAQAB';

class ComprasService {
  ComprasService._();
  static final ComprasService instance = ComprasService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  String? _partidoIdEnCurso;

  Future<void> iniciar() async {
    final disponible = await _iap.isAvailable();
    if (!disponible) return;
    _sub = _iap.purchaseStream.listen(_procesarCompras);

    // Al arrancar la app verificamos el estado real de la suscripción
    // contra Google Play. Si el usuario canceló o no se renovó el pago,
    // esto lo detecta y actualiza Firestore en consecuencia.
    await _verificarEstadoSuscripcion();
  }

  void dispose() => _sub?.cancel();

  /// Consulta a Google Play qué compras siguen activas para este usuario
  /// y sincroniza el campo `suscripcionProActiva` en Firestore.
  ///
  /// - Si la suscripción está activa (pagada o en período de gracia) →
  ///   Firestore queda en true.
  /// - Si la suscripción expiró o está en "account hold" → Firestore
  ///   queda en false.
  /// - Si la consulta falla (sin red, sin Play Services, etc.) → no
  ///   tocamos nada, para no castigar al usuario por un fallo transitorio.
  Future<void> _verificarEstadoSuscripcion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final androidAddition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await androidAddition.queryPastPurchases();

      // Si la consulta devolvió un error, no tocamos Firestore.
      if (response.error != null) {
        debugPrint('Error al consultar compras pasadas: ${response.error}');
        return;
      }

      final tieneSuscripcionActiva = response.pastPurchases.any(
        (p) =>
            p.productID == ComprasIds.suscripcionMensual &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored),
      );

      if (tieneSuscripcionActiva) {
        await UsuarioState.instance.activarSuscripcion();
      } else {
        await UsuarioState.instance.desactivarSuscripcion();
      }
    } catch (e) {
      // No tocamos Firestore si la consulta falla. Preferimos que el
      // usuario siga con el acceso que tenía antes que cortárselo por
      // un problema de red.
      debugPrint('No se pudo verificar la suscripción: $e');
    }
  }

  Future<void> comprarSuscripcion() async {
    final response = await _iap.queryProductDetails({ComprasIds.suscripcionMensual});
    if (response.productDetails.isEmpty) return;
    final param = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> comprarDesbloqueo(String partidoId) async {
    final response = await _iap.queryProductDetails({ComprasIds.desbloqueoPartido});
    if (response.productDetails.isEmpty) return;
    _partidoIdEnCurso = partidoId;
    final param = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
  }

  Future<ProductDetails?> obtenerProductoSuscripcion() async {
    final response = await _iap.queryProductDetails({ComprasIds.suscripcionMensual});
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  Future<void> _procesarCompras(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      if (compra.status == PurchaseStatus.pending) continue;

      if (compra.status == PurchaseStatus.error) {
        if (compra.pendingCompletePurchase) await _iap.completePurchase(compra);
        continue;
      }

      if (compra.status == PurchaseStatus.purchased ||
          compra.status == PurchaseStatus.restored) {
        final valida = _verificarFirma(compra);

        if (valida) {
          if (compra.productID == ComprasIds.suscripcionMensual) {
            await UsuarioState.instance.activarSuscripcion();
          } else if (compra.productID == ComprasIds.desbloqueoPartido) {
            final partidoId = _partidoIdEnCurso;
            if (partidoId != null) {
              await UsuarioState.instance.desbloquearPorCompra(partidoId);
            }
            if (compra is GooglePlayPurchaseDetails) {
              final addicionAndroid =
                  _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              await addicionAndroid.consumePurchase(compra);
            }
          }
        }

        if (compra.pendingCompletePurchase) {
          await _iap.completePurchase(compra);
        }
      }
    }
  }

  bool _verificarFirma(PurchaseDetails compra) {
    if (compra is! GooglePlayPurchaseDetails) return false;

    try {
      final wrapper = compra.billingClientPurchase;
      final datosOriginales = wrapper.originalJson;
      final firmaBase64 = wrapper.signature;

      final clave = _parsearClavePublica(_clavePublicaBase64);
      final verificador = Signer('SHA-1/RSA') as RSASigner;
      verificador.init(false, PublicKeyParameter<RSAPublicKey>(clave));

      final mensaje = Uint8List.fromList(utf8.encode(datosOriginales));
      final firma = RSASignature(base64.decode(firmaBase64));

      return verificador.verifySignature(mensaje, firma);
    } catch (_) {
      return false;
    }
  }

  RSAPublicKey _parsearClavePublica(String base64Clave) {
    final bytes = base64.decode(base64Clave);
    final parser = ASN1Parser(bytes);
    final secuencia = parser.nextObject() as ASN1Sequence;

    final bitString = secuencia.elements[1] as ASN1BitString;
    final parserInterno = ASN1Parser(bitString.contentBytes());
    final secuenciaClave = parserInterno.nextObject() as ASN1Sequence;

    final modulo = secuenciaClave.elements[0] as ASN1Integer;
    final exponente = secuenciaClave.elements[1] as ASN1Integer;

    return RSAPublicKey(modulo.valueAsBigInteger, exponente.valueAsBigInteger);
  }
}