import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/usuario_state.dart';
import 'core/services/compras_service.dart';
import 'core/services/admin_state.dart';
import 'core/ads/rewarded_ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  unawaited(MobileAds.instance.initialize());

  UsuarioState.instance.iniciar();
  unawaited(ComprasService.instance.iniciar());
  RewardedAdManager.instance.precargar();

  FirebaseAuth.instance.authStateChanges().listen((_) {
    AdminState.verificar();
  });

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const TribunaProApp());
}