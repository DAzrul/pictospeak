import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/pin_gate.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hidupkan Firebase dulu
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚨 J.A.R.V.I.S: LEPASKAN LINTAH SEKARANG! KAU TERTINGGAL BARIS NI TADI SIAL!
  SyncService().syncFromFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PictoSpeak',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // Pintu utama untuk semua
    );
  }
}