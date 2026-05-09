import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
// 🚨 J.A.R.V.I.S: Tukar import ke fail baru ni
import '../../features/auth/change_pin_screen.dart';
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
                  // 🚨 J.A.R.V.I.S: Tembak terus ke skrin Edit Profile
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                }),
                const Divider(height: 1),
                _buildListTile('Change Security PIN', 'Update your 4-digit access code', Icons.lock_reset_rounded, () {
                  // 🚨 J.A.R.V.I.S: Halakan ke skrin khas Tukar PIN
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

          // 5. DATA MANAGEMENT
          _buildSectionHeader(Icons.data_usage_rounded, 'Data Management', 'Control your application data and logs'),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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