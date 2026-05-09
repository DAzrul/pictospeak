import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';
import '../patient/quick_needs_screen.dart'; // <--- Wajib import ni sial!

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
                  // TAK PAYAH CHECK SESSION KAT SINI.
                  // Terus hantar ke Login Screen. Logik PIN/Biometrik kita buat kat sana.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ),

            // --- ISI KANDUNGAN UTAMA (Pesakit) ---
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
                            color: AppTheme.primaryBlue.withOpacity(0.3),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'PictoSpeak',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Communication Made Simple',
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Empowering non-verbal individuals to\nexpress themselves through intuitive\npicture-based communication',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[400],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // BUTANG GERGASI PESAKIT (Tanpa Sekuriti)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // LOMPAT KE SKRIN QUICK NEEDS KITA TADI!
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => QuickNeedsScreen()),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(
                          "Let's Communicate",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: AppTheme.lightTheme.elevatedButtonTheme.style,
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

            // --- FOOTER PEMATUEM ---
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Version 1.0.3',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[300]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: Colors.blueGrey[300]),
                      const SizedBox(width: 4),
                      Text(
                        'PDPA Compliant  |  AAC Certified',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey[300]),
                      ),
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