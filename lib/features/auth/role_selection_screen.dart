import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'select_patient_screen.dart'; // 🚀 Module for patient selection

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome to PictoSpeak", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text("Please select your role to proceed.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),

              // OPTION 1: PATIENT
              _buildRoleCard(
                context,
                title: "I AM A PATIENT",
                subtitle: "Access AAC communication tools",
                icon: Icons.accessibility_new_rounded,
                color: AppTheme.primaryBlue,
                onTap: () {
                  // 🚀 J.A.R.V.I.S: Verify caregiver authentication status
                  if (FirebaseAuth.instance.currentUser != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectPatientScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Caregiver authentication is required to access patient mode."), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // OPTION 2: CAREGIVER
              _buildRoleCard(
                context,
                title: "I AM A CAREGIVER",
                subtitle: "Manage patient profiles and data",
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.blueGrey.shade700,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withOpacity(0.3), width: 2)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 32, color: color)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)), Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400))])),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}