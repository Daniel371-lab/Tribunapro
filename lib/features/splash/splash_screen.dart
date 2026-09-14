import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decidirDestino();
  }

  Future<void> _decidirDestino() async {
    final esperaMinima = Future.delayed(const Duration(seconds: 2));
    final estadoAuth = FirebaseAuth.instance.authStateChanges().first;

    await Future.wait([esperaMinima, estadoAuth]);

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.acento,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tribuna Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'JPLABS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DEBUG: ${FirebaseAuth.instance.currentUser}',
              style: const TextStyle(fontSize: 10, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}