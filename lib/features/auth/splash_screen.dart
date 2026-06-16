import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/local_db.dart';
import '../caregiver/caregiver_dashboard.dart';
import '../patient/quick_needs_screen.dart';
import 'role_selection_screen.dart'; // 🚨 J.A.R.V.I.S: Pastikan fail ni dah siap

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
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    print("J.A.R.V.I.S: Memulakan Ghost Protocol...");

    // 1. DATA INJECTION (Background setup)
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
      print("J.A.R.V.I.S: Ralat DB -> $e");
    }

    // 2. MASA MENUNGGU (1 Saat untuk kesan premium)
    await Future.delayed(const Duration(seconds: 1));

    // 2. GATEKEEPER SCAN
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isPatientLoggedIn = prefs.getBool('is_patient_logged_in') ?? false;

    if (!mounted) return;

    // 🚀 J.A.R.V.I.S: Kita hanya auto-route kalau pesakit TENGAH login (tengah guna mod AAC)
    // Kalau tak, kita biar dia nampak butang "Let's Start" supaya Caregiver pun boleh pilih role.
    if (isPatientLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QuickNeedsScreen()),
      );
    } else {
      // ⚪ NO ACTIVE SESSION: Tayang butang LET'S START
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
                    // --- LOGO PictoSpeak ---
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

                    // --- TAJUK & TAGLINE ---
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

                    // --- DYNAMIC AREA ---
                    if (_isLoading)
                      const CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryBlue)
                    else
                    // 🚀 SATU BUTANG KERAMAT UNTUK FIRST-TIME USER
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

            // FOOTER VERSION
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text('v2.6.7 Stable', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
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