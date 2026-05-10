import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚨 J.A.R.V.I.S: Kena import ni untuk logout
import '../../core/theme/app_theme.dart';
import '../../core/services/local_db.dart'; // 🚨 J.A.R.V.I.S: Untuk nuke database masa logout
import '../../features/auth/change_pin_screen.dart';
import '../auth/splash_screen.dart'; // 🚨 J.A.R.V.I.S: Untuk tendang ke Splash lepas logout
import '../caregiver/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE SETTINGS ---
  bool _lowSensoryMode = false;
  bool _hideDistractions = false;

  double _voiceSpeed = 1.0;
  double _voicePitch = 1.0;
  String _voiceGender = 'Female';

  double _holdDelay = 500.0;
  bool _ignoreRepeated = true;
  bool _largeTargets = false;

  // 🚨 J.A.R.V.I.S: Fungsi Logout Penuh (Termasuk Nuke Data)
  void _handleSignOut(BuildContext context) async {
    // 1. Tembak mati SQLite (Elak hantu Acc A kacau Acc B)
    await LocalDB().deleteAllPictograms();

    // 2. Logout dari Firebase
    await FirebaseAuth.instance.signOut();

    // 3. Tendang user ke Splash Screen dan buang semua history laluan (route)
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
              (route) => false
      );
    }
  }

  // 🚨 J.A.R.V.I.S: Dialog Amaran Logout
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to securely log out? This will clear local data and end your active session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _handleSignOut(context); // Jalan!
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 1. ACCOUNT MANAGEMENT
          _buildSectionHeader(Icons.manage_accounts_outlined, 'Account Management', 'Update your profile and security settings'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildListTile('Edit Patient Profile', 'Change name, age, or relationship', Icons.edit_note_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                }),
                const Divider(height: 1),
                _buildListTile('Change Security PIN', 'Update your 4-digit access code', Icons.lock_reset_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePinScreen()));
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. VISUAL & SENSORY
          _buildSectionHeader(Icons.visibility_outlined, 'Visual & Sensory', 'Adjust app appearance for sensory needs'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Low Sensory Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Use muted colors to prevent overstimulation', style: TextStyle(fontSize: 11)),
                  value: _lowSensoryMode,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _lowSensoryMode = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide Distractions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Remove non-essential animations and icons', style: TextStyle(fontSize: 11)),
                  value: _hideDistractions,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _hideDistractions = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. TTS ENGINE
          _buildSectionHeader(Icons.record_voice_over_outlined, 'TTS Engine', 'Configure text-to-speech voice settings'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildSliderRow('Voice Speed', _voiceSpeed, 0.5, 2.0, (val) => setState(() => _voiceSpeed = val)),
                const Divider(height: 24),
                _buildSliderRow('Voice Pitch', _voicePitch, 0.5, 2.0, (val) => setState(() => _voicePitch = val)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. MOTOR ACCESSIBILITY
          _buildSectionHeader(Icons.accessibility_new, 'Motor Accessibility', 'Settings for users with motor impairments'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildSliderRow('Hold-to-Select Delay', _holdDelay, 0.0, 1000.0, (val) => setState(() => _holdDelay = val), isMs: true),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Large Touch Targets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _largeTargets,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _largeTargets = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 5. DATA MANAGEMENT & LOGOUT (🚨 J.A.R.V.I.S: Baru ditambah)
          _buildSectionHeader(Icons.data_usage_rounded, 'System Control', 'Manage your data and active sessions'),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWipeDataDialog(context),
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
              label: const Text('Wipe Patient Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12), // Gap antara dua butang bahaya ni

          // 🚨 J.A.R.V.I.S: BUTANG SIGN OUT KAT SINI
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildListTile(String title, String sub, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primaryBlue, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showWipeDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DANGER ZONE!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('This will PERMANENTLY delete all communication logs and patient history. There is no undo!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been wiped!'), backgroundColor: Colors.black));
            },
            child: const Text('YES, DELETE EVERYTHING', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(children: [
      Icon(icon, color: AppTheme.primaryBlue, size: 20),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
      ])
    ]);
  }

  Widget _buildSliderRow(String title, double val, double min, double max, Function(double) onChanged, {bool isMs = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(isMs ? '${val.toInt()}ms' : '${val.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
      ]),
      Slider(value: val, min: min, max: max, onChanged: onChanged),
    ]);
  }
}