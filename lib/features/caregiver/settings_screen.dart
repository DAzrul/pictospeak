import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚀 J.A.R.V.I.S: Wajib untuk litar Password
import '../../core/theme/app_theme.dart';
import '../../core/services/local_db.dart';
import '../../features/auth/change_pin_screen.dart';
import '../auth/role_selection_screen.dart';
import '../auth/splash_screen.dart';
import '../caregiver/edit_profile_screen.dart';
import '../auth/services/auth_service.dart';
import 'SupportTicketScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 🚀 J.A.R.V.I.S: Isytihar AuthService ejen rahsia kita kat sini mat!
  final AuthService _authService = AuthService();

  // --- STATE SETTINGS ---
  bool _lowSensoryMode = false;
  bool _hideDistractions = false;

  // Nilai asal (default) sebelum dibaca dari memori
  double _voiceSpeed = 1.0;
  double _voicePitch = 1.0;
  String _voiceGender = 'Female';

  double _holdDelay = 500.0;
  bool _ignoreRepeated = true;
  bool _largeTargets = false;

  bool _biometricEnabled = false;
  bool _isLoading = false; // 🚀 Ni punca error "Undefined name"

  @override
  void initState() {
    super.initState();
    _loadSettingsData(); // Sedut semua jenis data dari disk peranti sekaligus
  }

  // 🚀 J.A.R.V.I.S: Litar mengawal pengaktifan opt-in biometrik secara manual
  void _toggleBiometric(bool value) async {
    if (value) {
      // Suruh user scan jari dulu sebelum bagi tukar status switch jadi ON!
      bool authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        setState(() => _biometricEnabled = true);
        _showSnackBar('Biometrik berjaya diaktifkan!', Colors.green);
      } else {
        _showSnackBar('Pengesahan biometrik gagal.', Colors.red);
      }
    } else {
      // Kalau dia nak OFF, terus tutup tanpa kekangan scan
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      setState(() => _biometricEnabled = false);
      _showSnackBar('Biometrik dinyahaktifkan.', Colors.orange);
    }
  }

  // 🚀 3. LITAR MEMBACA DATA DARI STORAN PERANTI
  void _loadSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceSpeed = prefs.getDouble('tts_speed') ?? 1.0;
      _voicePitch = prefs.getDouble('tts_pitch') ?? 1.0;
      _lowSensoryMode = prefs.getBool('low_sensory') ?? false;
      _hideDistractions = prefs.getBool('hide_distractions') ?? false;
      _holdDelay = prefs.getDouble('hold_delay') ?? 500.0;
      _largeTargets = prefs.getBool('large_targets') ?? false;

      // 🚀 J.A.R.V.I.S: Kita sumbat bacaan status biometrik terus kat sini biar kemas!
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
    print("J.A.R.V.I.S: Konfigurasi sistem & status biometrik dipulihkan! Biometric: $_biometricEnabled");
  }

  // 🚀 4. LITAR KEMASKINI KELAJUAN & SIMPAN TERUS KE STORAN
  void _updateVoiceSpeed(double newSpeed) async {
    setState(() => _voiceSpeed = newSpeed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speed', newSpeed);
    print("J.A.R.V.I.S: Kelajuan $_voiceSpeed disimpan secara kekal.");
  }

  // 🚀 5. LITAR KEMASKINI PITCH & SIMPAN TERUS KE STORAN
  void _updateVoicePitch(double newPitch) async {
    setState(() => _voicePitch = newPitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', newPitch);
    print("J.A.R.V.I.S: Nada (Pitch) $_voicePitch disimpan secara kekal.");
  }

  // 🚀 J.A.R.V.I.S: Fungsi memaparkan maklum balas terapung (SnackBar) yang hilang tadi
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // 🔐 J.A.R.V.I.S: LITAR SET/TUKAR PASSWORD (Firebase Engine)
  // =========================================================
  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Set / Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Masukkan kata laluan baru anda (Minima 6 aksara).', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setStateDialog(() => isObscured = !isObscured),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    String newPass = passwordController.text.trim();
                    if (newPass.length < 6) {
                      _showSnackBar('Password terlalu pendek! Minima 6 aksara.', Colors.red);
                      return;
                    }

                    Navigator.pop(context); // Tutup dialog dulu

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await user.updatePassword(newPass);
                        _showSnackBar('BOOM! Password berjaya dikemaskini!', Colors.green);
                      }
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'requires-recent-login') {
                        _showSnackBar('🚨 Sesi tamat tempoh! Sila LOGOUT dan LOGIN semula sebelum menukar password.', Colors.red.shade700);
                      } else {
                        _showSnackBar('Gagal: ${e.message}', Colors.red);
                      }
                    } catch (e) {
                      _showSnackBar('Litar terbakar: $e', Colors.red);
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
      ),
    );
  }

  // 🚨 J.A.R.V.I.S: Fungsi Logout Penuh (Versi Kebal Tetapan TTS)
  void _handleSignOut(BuildContext context) async {
    try {
      print("🚨 J.A.R.V.I.S: Mengaktifkan Protokol Pemusnahan Sesi...");

      await LocalDB().deleteAllPictograms();
      await AuthService().signOut();

      final prefs = await SharedPreferences.getInstance();

      // 🚀 LITAR PENAPISAN KEKAL (Safe Wipe)
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('is_patient_logged_in');
      await prefs.remove('patient_id');
      await prefs.remove('patient_name');

      print("J.A.R.V.I.S: Sesi berjaya diclearkan. Tetapan TTS Engine & Biometrik dikekalkan.");

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S ERROR masa logout: $e");
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              (route) => false,
        );
      }
    }
  }

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
              Navigator.pop(context);
              _handleSignOut(context);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveAndWipePatientData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');

    if (user == null || patientId == null) return;

    try {
      setState(() => _isLoading = true);
      final firestore = FirebaseFirestore.instance;
      final patientRef = firestore.collection('caregivers').doc(user.uid).collection('patients').doc(patientId);

      // Senarai sub-collection yang nak di-archive
      List<String> collectionsToArchive = ['communication_logs', 'weekly_reports'];

      for (String collName in collectionsToArchive) {
        bool hasMore = true;
        while (hasMore) {
          // Tarik 400 rekod je setiap kali (biar tak langgar limit 500 batch)
          var query = patientRef.collection(collName).limit(400);
          var snapshot = await query.get();

          if (snapshot.docs.isEmpty) {
            hasMore = false;
            continue;
          }

          WriteBatch batch = firestore.batch();
          for (var doc in snapshot.docs) {
            // 1. Copy ke archive
            DocumentReference archiveRef = firestore.collection('archived_logs').doc();
            batch.set(archiveRef, {
              ...doc.data(),
              'original_path': doc.reference.path,
              'archived_at': FieldValue.serverTimestamp(),
            });

            // 2. Padam asal
            batch.delete(doc.reference);
          }

          await batch.commit(); // Hantar 400 operasi sekaligus
          debugPrint("J.A.R.V.I.S: Berjaya archive & wipe 400 rekod dari $collName...");
        }
      }

      _showSnackBar("✅ Ribuan data berjaya di-archive!", Colors.green);
      setState(() => _isLoading = false);
    } catch (e) {
      _showSnackBar("Ralat: $e", Colors.red);
      setState(() => _isLoading = false);
    }
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
                const Divider(height: 1),
                _buildListTile('Set / Change Password', 'Update your login password', Icons.password_rounded, () {
                  _showChangePasswordDialog(context);
                }),
                // 👇 LITAR REQUEST SUPPORT BARU KITA 👇
                const Divider(height: 1),
                _buildListTile(
                    'Support & Request',
                    'Request new pictograms or get help',
                    Icons.support_agent_rounded,
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportTicketScreen()));
                    }
                ),
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
                // 🚀 J.A.R.V.I.S: Switch Opt-in Biometric Universal
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Biometric Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Masuk ke portal menggunakan cap jari/muka', style: TextStyle(fontSize: 11)),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  activeColor: AppTheme.primaryBlue,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Low Sensory Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Use muted colors to prevent overstimulation', style: TextStyle(fontSize: 11)),
                  value: _lowSensoryMode,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) async {
                    setState(() => _lowSensoryMode = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('low_sensory', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide Distractions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Remove non-essential animations and icons', style: TextStyle(fontSize: 11)),
                  value: _hideDistractions,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) async {
                    setState(() => _hideDistractions = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hide_distractions', val);
                  },
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
                _buildSliderRow('Voice Speed', _voiceSpeed, 0.1, 1.5, _updateVoiceSpeed),
                const Divider(height: 24),
                _buildSliderRow('Voice Pitch', _voicePitch, 0.1, 1.5, _updateVoicePitch),
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
                _buildSliderRow('Hold-to-Select Delay', _holdDelay, 0.0, 1000.0, (val) async {
                  setState(() => _holdDelay = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('hold_delay', val);
                }, isMs: true),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Large Touch Targets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _largeTargets,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) async {
                    setState(() => _largeTargets = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('large_targets', val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 5. DATA MANAGEMENT & LOGOUT
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
          const SizedBox(height: 12),

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
              _archiveAndWipePatientData(); // 🚀 Panggil fungsi pemusnah kat sini!
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(
              children: [
                Text(
                  isMs ? '${val.toInt()}ms' : '${val.toStringAsFixed(1)}x',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.grey),
                  onPressed: () => onChanged(isMs ? 500.0 : 1.0),
                  tooltip: 'Reset to Neutral',
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          divisions: isMs ? 20 : 14,
          activeColor: AppTheme.primaryBlue,
          inactiveColor: Colors.blue.shade50,
          onChanged: onChanged,
        ),
      ],
    );
  }
}