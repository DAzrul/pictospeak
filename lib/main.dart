import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🚨 J.A.R.V.I.S: Wajib untuk check kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 J.A.R.V.I.S: Import Wajib FCM
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 Wajib untuk litar Diktator baca database!

import 'core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

// --- Imports Navigation ---
import 'features/auth/splash_screen.dart';
import 'features/admin/admin_dashboard_screen.dart'; // 🚨 Pastikan path ni betul
import 'core/services/sync_service.dart';

// 🚀 J.A.R.V.I.S: Wajib import skrin maintenance kau! (Periksa path ni kalau salah)
import 'features/auth/maintenance_screen.dart';

// =========================================================
// 🚨 J.A.R.V.I.S GHOST PROTOCOL MARK II: BACKGROUND HANDLER
// Litar ni MESTI duduk luar dari sebarang class (Top-level)
// =========================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase dah initialize dalam background (sebab memori utama app dah mati)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("🚨 J.A.R.V.I.S: KECEMASAN DIKESAN MASA APP MATI! ID: ${message.messageId}");

  // Nota untuk VIVA:
  // Untuk bunyikan siren secara fizikal kat sini, kita perlukan Firebase Cloud Functions (backend)
  // dan plugin khas (macam flutter_ringtone_player) untuk bypass sekatan OS bateri.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hidupkan Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚨 J.A.R.V.I.S: Lepaskan lintah hanya kalau kat Mobile.
  // Kat Web (Admin) kita tak pakai SQLite, kita baca direct dari Firebase.
  if (!kIsWeb) {
    await FcmService.initialize();
    SyncService().syncFromFirebase();

    // 🚀 J.A.R.V.I.S: Daftarkan pengawal keselamatan masa app tidur/mati
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

      // =========================================================
      // 🚀 LITAR DIKTATOR J.A.R.V.I.S (GLOBAL MAINTENANCE OVERRIDE)
      // =========================================================
      builder: (context, child) {
        // 🚨 VVIP BYPASS: Kalau bukak kat Web (Admin), jangan block!
        // Nanti Admin sendiri terkunci dari Dashboard nak off suis macam mana babi 😂
        if (kIsWeb) return child!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots(),
          builder: (context, snapshot) {
            // Intip secara live dari bumbung app
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              bool isMaintenance = data['maintenance_mode'] ?? false;

              // Kalau admin petik suis ON, tendang app mobile masuk MaintenanceScreen!
              if (isMaintenance) {
                return const MaintenanceScreen();
              }
            }
            // Kalau OFF, app jalan macam biasa
            return child!;
          },
        );
      },

      // 🚨 LOGIK DUA ALAM (HYBRID ROUTING)
      // Kalau kat Browser -> Terus ke Admin Dashboard
      // Kalau kat Android/iOS -> Pergi ke Splash Screen Pesakit/Penjaga
      home: kIsWeb
          ? const AdminDashboardScreen()
          : const SplashScreen(),
    );
  }
}