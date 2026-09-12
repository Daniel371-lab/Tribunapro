import 'package:flutter/foundation.dart';

/// Estado global de si el usuario actual es Pro (suscripción activa).
/// Placeholder en false por defecto: todavía no hay verificación real
/// contra Play Billing. Cuando se implemente esa verificación, este
/// notifier pasa a actualizarse desde ahí en vez de quedar fijo.
final ValueNotifier<bool> esProNotifier = ValueNotifier<bool>(false);