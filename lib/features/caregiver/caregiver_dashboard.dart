import 'dart:async'; // 🚀 J.A.R.V.I.S: Import ni wajib untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pictospeak/features/caregiver/patient_details_screen.dart';
import '../../core/theme/app_theme.dart';
import '../auth/patient_pin_screen.dart';
import '../auth/services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import 'add_patient_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  // 🚨 J.A.R.V.I.S: Enjin Bunyi Siren & Radar
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSosActive = false;
  StreamSubscription<QuerySnapshot>? _sosSubscription; // 🚀 Telinga radar kita

  @override
  void initState() {
    super.initState();
    _startSosRadar(); // 🚀 Hidupkan radar masa Dashboard dibuka!
  }

  // =========================================================
  // 🚨 LITAR RADAR SOS (VERSI QUEUE BERGILIR - KALIS MULTI-PATIENT)
  // =========================================================
  void _startSosRadar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sosSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('caregiver_id', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .listen((snapshot) {

      // Kalau takde SOS langsung, diam je.
      if (snapshot.docs.isEmpty) return;

      // Kalau litar tengah sibuk handle pesakit A, abaikan dulu.
      // Jangan risau, Firestore akan trigger stream ni balik lepas kita setel pesakit A.
      if (_isSosActive) return;

      // 🚀 J.A.R.V.I.S: Kunci litar & ambil dokumen TERATAS (First in line)
      _isSosActive = true;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final targetPatientId = data['patient_id'];
      String pName = data['patient_name'] ?? 'Pesakit';

      // Hantar ID Pesakit, bukan ID dokumen SOS, supaya kita boleh bunuh SPAM pesakit ni je
      _triggerSosAlarm(pName, targetPatientId);
    });
  }

  // =========================================================
  // 🚨 LITAR PENGGERA & POP-UP (VERSI TARGETED STRIKE)
  // =========================================================
  void _triggerSosAlarm(String patientName, String targetPatientId) async {
    setState(() {});

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
    } catch (e) {
      print("🚨 J.A.R.V.I.S: Siren rosak -> $e");
    }

    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      "KECEMASAN SOS!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                ),
              ],
            ),
            content: Text("Pesakit ${patientName.toUpperCase()} memerlukan bantuan segera!",
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _audioPlayer.stop();

                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // 🚀 J.A.R.V.I.S TARGETED STRIKE:
                      // Cari SOS untuk PESAKIT INI SAHAJA. Biarkan pesakit lain punya SOS hidup.
                      var activeSosDocs = await FirebaseFirestore.instance
                          .collection('sos_alerts')
                          .where('caregiver_id', isEqualTo: user.uid)
                          .where('patient_id', isEqualTo: targetPatientId) // 🔥 INI PENYELAMAT NYA!
                          .where('status', isEqualTo: 'ACTIVE')
                          .get();

                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      for (var doc in activeSosDocs.docs) {
                        batch.update(doc.reference, {'status': 'RESOLVED'});
                      }
                      await batch.commit();
                    }

                    // 🚀 Buka balik mangga litar.
                    // Sebaik sahaja database update, stream akan berjalan balik.
                    // Kalau ada Patient B tengah tunggu, pop-up baru akan terus keluar!
                    _isSosActive = false;

                    if (context.mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  child: const Text("SAYA DATANG SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          );
        }
    );
  }

  @override
  void dispose() {
    _sosSubscription?.cancel(); // 🚀 Tutup telinga radar bila app mati
    _audioPlayer.dispose();
    super.dispose();
  }

  // 🚀 J.A.R.V.I.S: Litar untuk tukar tab bawah
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPatientsListTab(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlue),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    (route) => false
            );
          },
        ),
        title: const Text('PictoSpeak Dashboard',
            style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),

      body: pages[_selectedIndex],

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPatientScreen())
          );
        },
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  // --- TAB 0: LITAR SENARAI PESAKIT (LIVE STREAM) ---
  Widget _buildPatientsListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.getPatientsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Litar Meletup: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final patients = snapshot.data?.docs ?? [];

        if (patients.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final data = patients[index].data() as Map<String, dynamic>;
            return _buildPatientCard(data);
          },
        );
      },
    );
  }

  // --- KAD PESAKIT (VERSION MARK 129 - WITH FAST TRACK) ---
  Widget _buildPatientCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(patientData: data),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded, color: AppTheme.primaryBlue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.textDark)),
                      const SizedBox(height: 4),
                      Text("${data['relationship']} • ${data['age']} yrs old",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _handleFastTrack(data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.rocket_launch_rounded, size: 18),
                          Text("AAC", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFastTrack(Map<String, dynamic> patientData) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientPinScreen(patientData: patientData),
      ),
    );
  }

  // --- UI BILA TIADA DATA ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
            child: Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 24),
          const Text("Belum Ada Pesakit",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text("Sila daftarkan pesakit di bawah jagaan anda untuk mula memantau komunikasi mereka.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}