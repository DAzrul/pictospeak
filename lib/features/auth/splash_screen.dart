import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sync_service.dart'; // 🚨 J.A.R.V.I.S: Kejutkan lintah kat sini
import '../caregiver/caregiver_dashboard.dart';
import 'login_screen.dart';
import '../patient/quick_needs_screen.dart';

// 🚨 Tukar jadi StatefulWidget supaya kita boleh pasang "Enjin Boot-up" (initState)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // 🚨 GHOST PROTOCOL: Sebaik saja app buka, sedut data senyap-senyap!
    _silentPreFetch();
  }

  Future<void> _silentPreFetch() async {
    print("J.A.R.V.I.S: Ghost Protocol diaktifkan. Sedang curi data dari Awan ke dalam SQLite...");
    await SyncService().syncFromFirebase();
    print("J.A.R.V.I.S: Peluru dah penuh dalam chamber. Menunggu arahan bos!");
  }

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
                  if (FirebaseAuth.instance.currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
                    );
                  } else {
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
                    // Logo PictoSpeak
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                          // 🚨 J.A.R.V.I.S: Tak payah letak SyncService kat sini dah!
                          // Benda tu dah jalan kat background (initState).
                          // Tekan butang ni, app terus terbang masuk tanpa lag!
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

            // Footer (PDPA)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('Version 1.3.17', style: TextStyle(fontSize: 12, color: Colors.blueGrey[300])),
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