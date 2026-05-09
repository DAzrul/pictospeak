import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🚨 J.A.R.V.I.S: Wajib untuk check kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

// --- Imports Navigation ---
import 'features/auth/splash_screen.dart';
import 'features/admin/admin_dashboard_screen.dart'; // 🚨 Pastikan path ni betul
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hidupkan Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚨 J.A.R.V.I.S: Lepaskan lintah hanya kalau kat Mobile.
  // Kat Web (Admin) kita tak pakai SQLite, kita baca direct dari Firebase.
  if (!kIsWeb) {
    SyncService().syncFromFirebase();
  }

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

      // 🚨 LOGIK DUA ALAM (HYBRID ROUTING)
      // Kalau kat Browser -> Terus ke Admin Dashboard
      // Kalau kat Android/iOS -> Pergi ke Splash Screen Pesakit
      home: kIsWeb
          ? const AdminDashboardScreen()
          : const SplashScreen(),
    );
  }
}