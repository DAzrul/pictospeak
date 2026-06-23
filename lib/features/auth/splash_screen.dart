import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 WAJIB IMPORT

import '../../core/theme/app_theme.dart';
import '../../core/services/local_db.dart';
import '../caregiver/caregiver_dashboard.dart';
import '../patient/quick_needs_screen.dart';
import 'role_selection_screen.dart';
// 🚨 J.A.R.V.I.S: Pastikan path untuk fail MaintenanceScreen ni betul ikut projek kau!
import 'maintenance_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalDB _localDB = LocalDB();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupNotificationListeners(); // 🚀 Pasang telinga untuk app yang Minimized
    _bootSequence();
  }

  // =========================================================
  // 🧠 OTAK ROUTING J.A.R.V.I.S (Tapis Security Auth)
  // =========================================================
  Future<bool> _handleNotificationRouting() async {
    if (!mounted) return false;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Caregiver memang dah login, tembak masuk Dashboard!
      print("✅ J.A.R.V.I.S: Caregiver Auth Sah! Pecut ke Dashboard!");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CaregiverDashboard()));
      return true;
    } else {
      // Babi, Caregiver tak login lagi! Tendang pergi Role Selection.
      print("🚨 J.A.R.V.I.S: Sesi tak wujud! Halakan ke Pintu Utama.");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
      return true;
    }
  }

  // =========================================================
  // 🚀 LITAR PINTASAN 1: APP TIDUR (BACKGROUND / MINIMIZED)
  // =========================================================
  void _setupNotificationListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚨 J.A.R.V.I.S: App dikejutkan dari Background!");
      // Asalkan dari notifikasi, kita pass ke otak routing
      _handleNotificationRouting();
    });
  }

  Future<void> _bootSequence() async {
    print("J.A.R.V.I.S: Memulakan Ghost Protocol...");

    // =========================================================
    // 🚀 LITAR PINTASAN 2: APP MAMPUS (TERMINATED / KILLED)
    // =========================================================
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        print("🚨 J.A.R.V.I.S: KECEMASAN DIKESAN (Dari Mampus)! Menjalankan Auto-Route...");
        bool isRouted = await _handleNotificationRouting();
        if (isRouted) return; // 🚀 BREAK! Litar potong barisan berjaya. Stop fungsi bawah!
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S Error Fast-Track: $e");
    }

    // =========================================================
    // 2. DATA INJECTION (Background setup)
    // =========================================================
    try {
      final existingData = await _localDB.getPictogramsByCategory('Subject');
      if (existingData.isEmpty) {
        String jsonString = await rootBundle.loadString('assets/global_icons.json');
        List<dynamic> jsonData = jsonDecode(jsonString);
        for (var item in jsonData) {
          Map<String, dynamic> dataMap = item as Map<String, dynamic>;
          await _localDB.insertOrUpdatePictogram(dataMap, dataMap['id']);
        }
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S: Ralat DB -> $e");
    }

    // =========================================================
    // 3. MASA MENUNGGU (Kesan Estetik Premium)
    // =========================================================
    await Future.delayed(const Duration(seconds: 1));

    // =========================================================
    // 4. GATEKEEPER SCAN (Routing Biasa / Normal Boot)
    // =========================================================
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isPatientLoggedIn = prefs.getBool('is_patient_logged_in') ?? false;
    User? currentUser = FirebaseAuth.instance.currentUser; // Cek memori Firebase Auth

    if (!mounted) return;

    if (isPatientLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QuickNeedsScreen()),
      );
    } else if (currentUser != null) {
      // 🚀 BONUS J.A.R.V.I.S: Caregiver Auto-Login Bypass!
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CaregiverDashboard())
      );
    } else {
      // ⚪ TIADA SESI AKTIF: Tunjuk butang LET'S START
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 160, width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              blurRadius: 40, offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset('assets/images/pictospeak.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                        'PictoSpeak',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Communication Made Simple',
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey[400], fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 80),

                    if (_isLoading)
                      const CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryBlue)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleSelectionScreen())
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: AppTheme.primaryBlue.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                              "LET'S START",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.5)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text('v1.6.7 Stable', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('UTeM PSM PROJECT', style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}