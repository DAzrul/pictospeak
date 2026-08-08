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
import 'features/auth/admin_login_screen.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
// =========================================================
// 🚨 J.A.R.V.I.S GHOST PROTOCOL MARK II: BACKGROUND HANDLER
// Litar ni MESTI duduk luar dari sebarang class (Top-level)
// =========================================================
// =========================================================
// 🚨 J.A.R.V.I.S GHOST PROTOCOL: BACKGROUND HANDLER
// =========================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Hidupkan nadi Firebase masa memori utama mati
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("🚨 J.A.R.V.I.S: NOTIFIKASI KECEMASAN MASUK MASA APP MAMPUS! ID: ${message.messageId}");

  // Tapis kalau notification tu memang jenis SOS
  if (message.data['type'] == 'SOS_ALERT') {
    // 🚀 Litar ni akan tembus Silent Mode dan melolong macam orang gila!
    FlutterRingtonePlayer().play(
      fromAsset: "assets/sounds/siren.mp3", // Pastikan path ni betul wujud!
      looping: true, // Biar dia menjerit sampai Caregiver buka app
      volume: 1.0,
      asAlarm: true, // Wajib letak true untuk override OS battery restriction
    );
  }
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

      // Litar Diktator J.A.R.V.I.S kau kekalkan macam biasa...
      builder: (context, child) {
        if (kIsWeb) return child!;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              if (data['maintenance_mode'] ?? false) return const MaintenanceScreen();
            }
            return child!;
          },
        );
      },

      // 🚨 LOGIK ROUTING BARU (ADA BOUNCER)
      home: kIsWeb
          ? const AdminAuthGate() // 👈 Kalau kat Web, pergi ke pintu gate dulu
          : const SplashScreen(), // 👈 Kalau App, jalan macam biasa
    );
  }
}

// =========================================================
// 🚀 LITAR BOUNCER: ADMIN AUTH GATE (LETAK BAWAH SEKALI DALAM MAIN.DART)
// =========================================================
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Kalau tengah loading check token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1E1B4B))));
        }

        // Kalau Firebase tak jumpa token user (Belum Login)
        if (!snapshot.hasData) {
          return const AdminLoginScreen(); // ⛔ Tendang ke Skrin Login
        }

        // Kalau token wujud (Dah Login)
        return const AdminDashboardScreen(); // ✅ Benarkan masuk Dashboard
      },
    );
  }
}