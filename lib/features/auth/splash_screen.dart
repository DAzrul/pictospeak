import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sync_service.dart'; // 🚨 J.A.R.V.I.S: Kejutkan lintah kat sini
import '../caregiver/caregiver_dashboard.dart';
import 'login_screen.dart';
import '../patient/quick_needs_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // --- KUNCI PENJAGA (Gear Icon) ---
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 28),
                onPressed: () {
                  // 🚨 J.A.R.V.I.S: Check pintu dulu!
                  // Kalau FirebaseAuth ada data currentUser, maksudnya belum logout.
                  if (FirebaseAuth.instance.currentUser != null) {
                    // Terus masuk Dashboard, tak payah login
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
                    );
                  } else {
                    // Kalau takde, baru hantar ke skrin Login
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo PictoSpeak (Kekalkan UI lawa kau)
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3), // 🚨 Pakai withValues
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/pictospeak.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'PictoSpeak',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Communication Made Simple',
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                    ),
                    const SizedBox(height: 48),

                    // BUTANG GERGASI PESAKIT
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 🚨 1. KEJUTKAN LINTAH AWAN
                          // Walaupun user 'tak login' secara manual, Firebase Auth
                          // selalunya simpan session Caregiver yang lepas.
                          SyncService().syncFromFirebase();

                          // 🚨 2. GUNA pushReplacement
                          // Ini ubat supaya bila budak tu dah masuk QuickNeeds,
                          // dia tak boleh 'back' balik ke skrin Splash ni.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => QuickNeedsScreen()),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(
                          "Let's Communicate",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Mari Berkomunikasi',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey[300]),
                    ),
                  ],
                ),
              ),
            ),

            // Footer (Kekalkan PDPA kau tu, nampak legit sikit PSM)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('Version 1.3.12', style: TextStyle(fontSize: 12, color: Colors.blueGrey[300])),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: Colors.blueGrey[300]),
                      const SizedBox(width: 4),
                      Text('PDPA Compliant  |  AAC Certified', style: TextStyle(fontSize: 12, color: Colors.blueGrey[300])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}