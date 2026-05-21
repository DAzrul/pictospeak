import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pictospeak/features/caregiver/patient_details_screen.dart';
import '../../core/theme/app_theme.dart';
import '../auth/patient_pin_screen.dart';
import '../auth/services/auth_service.dart';
import '../auth/role_selection_screen.dart'; // Import untuk litar logout/switch
import 'add_patient_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'package:audioplayers/audioplayers.dart'; // 🚀 Import ni kat atas sekali

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  // 🚨 J.A.R.V.I.S: Enjin Bunyi Siren
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSosActive = false; // Supaya pop-up tak keluar bertindih

  @override
  void initState() {
    super.initState();
    _startSosRadar(); // 🚀 Hidupkan radar masa Dashboard dibuka!
  }

  // 🚨 LITAR RADAR SOS
  void _startSosRadar() {
    FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .listen((snapshot) {

      // Kalau ada dokumen SOS baru yang berstatus 'ACTIVE'
      if (snapshot.docs.isNotEmpty && !_isSosActive) {
        final data = snapshot.docs.first.data();
        final docId = snapshot.docs.first.id;

        _triggerSosAlarm(data['patient_name'], docId);
      }
    });
  }

  // 🚨 LITAR PENGGERA & POP-UP
  void _triggerSosAlarm(String patientName, String docId) async {
    setState(() => _isSosActive = true);

    // Bunyikan Siren (Pastikan kau dah letak fail mp3 dlm folder assets)
    // Kalau takde file mp3 lagi, litar ni akan senyap je tapi pop-up tetap keluar
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Bunyi non-stop
      await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
    } catch (e) {
      print("Siren tak jumpa : $e");
    }

    if (!mounted) return;

    // Tembak Pop-up Merah Gergasi kat muka Penjaga
    showDialog(
        context: context,
        barrierDismissible: false, // Tak boleh tutup selagi tak tekan butang
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                SizedBox(width: 10),
                Text("KECEMASAN SOS!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text("Pesakit $patientName memerlukan bantuan segera!",
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // 1. Matikan bunyi
                  await _audioPlayer.stop();

                  // 2. Padam/Update status SOS dlm Firestore supaya tak jerit lagi
                  await FirebaseFirestore.instance.collection('sos_alerts').doc(docId).update({
                    'status': 'RESOLVED',
                  });

                  setState(() => _isSosActive = false);
                  if (mounted) Navigator.pop(context); // Tutup dialog
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                child: const Text("SAYA DATANG SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Matikan speaker bila tutup app
    super.dispose();
  }

  // 🚀 J.A.R.V.I.S: Litar untuk tukar tab bawah
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    // Susunan skrin untuk setiap tab
    final List<Widget> pages = [
      _buildPatientsListTab(), // Tab 0: Senarai Pesakit
      const LibraryScreen(),    // Tab 1: Library Piktogram
      const SettingsScreen(),   // Tab 2: Settings & Logout
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Tombol Switch Role (Bawa balik ke skrin depan tanpa logout kalau perlu)
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
            onPressed: () {}, // Nanti boleh letak notifikasi alert pesakit
          )
        ],
      ),

      body: pages[_selectedIndex],

      // 🚀 J.A.R.V.I.S: Butang Tambah Pesakit (Muncul hanya dlm tab Patients)
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
      stream: _authService.getPatientsStream(), // Sedut data dari Sub-collection
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
                // Avatar Visual
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded, color: AppTheme.primaryBlue, size: 30),
                ),
                const SizedBox(width: 16),

                // Info Pesakit
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

                // 🚀 J.A.R.V.I.S: LITAR FAST TRACK (SWITCH TO PATIENT)
                // Butang gergasi untuk terus masuk mod AAC pesakit ni
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

  // 🚀 J.A.R.V.I.S: Sub-litar Logik Fast Track
  void _handleFastTrack(Map<String, dynamic> patientData) async {
    // Kita tak nak dia susah-susah pilih nama lagi, terus hantar ke PIN Screen
    // Tapi kita bawa data pesakit ni sekali supaya PIN Screen tahu nak check PIN siapa

    // Import ni kalau belum ada kat atas:
    // import '../auth/patient_pin_screen.dart';

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