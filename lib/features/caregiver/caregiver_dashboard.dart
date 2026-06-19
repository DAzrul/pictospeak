import 'dart:async'; // 🚀 J.A.R.V.I.S: Import ni wajib untuk StreamSubscription
import 'dart:io'; // 🚀 J.A.R.V.I.S: Untuk check Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // 🚀 J.A.R.V.I.S: Untuk check Web
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 J.A.R.V.I.S: Enjin Notification
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
  bool _isSosDialogOpen = false; // 🚀 LITAR BARU: Penjejak Popup Jarak Jauh
  StreamSubscription<QuerySnapshot>? _sosSubscription;

  @override
  void initState() {
    super.initState();
    _startSosRadar();
    _registerDeviceToken();
  }

  // =========================================================
  // 📡 J.A.R.V.I.S: SISTEM PENDAFTARAN RADAR (FCM TOKENS)
  // =========================================================
  Future<void> _registerDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();

        if (token != null) {
          String devicePlatform = kIsWeb ? 'Web Browser' : (Platform.isAndroid ? 'Android' : 'iOS');

          await FirebaseFirestore.instance
              .collection('caregivers')
              .doc(user.uid)
              .collection('device_tokens')
              .doc(token)
              .set({
            'token': token,
            'platform': devicePlatform,
            'last_updated': FieldValue.serverTimestamp(),
          });

          debugPrint("✅ J.A.R.V.I.S: Radar dipasang! Token $devicePlatform didaftarkan.");
        }
      } else {
        debugPrint("🚨 J.A.R.V.I.S: Penjaga kedekut, tak bagi kebenaran notification.");
      }
    } catch (e) {
      debugPrint("🚨 J.A.R.V.I.S Error: Gagal daftar token -> $e");
    }
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

      // 🚀 J.A.R.V.I.S REMOTE KILL SWITCH: Kalau orang lain dah setel, bunuh siren & tutup popup!
      if (snapshot.docs.isEmpty) {
        _audioPlayer.setReleaseMode(ReleaseMode.stop);
        _audioPlayer.stop();
        _isSosActive = false; // Buka balik mangga

        // Kalau skrin ni tengah buka popup, bunuh popup tu secara paksa!
        if (_isSosDialogOpen && mounted) {
          _isSosDialogOpen = false;
          Navigator.of(context, rootNavigator: true).pop();
          debugPrint("✅ J.A.R.V.I.S: Popup SOS ditutup dari jarak jauh!");
        }
        return;
      }

      // Kalau litar tengah sibuk handle pesakit A, abaikan dulu.
      if (_isSosActive) return;

      // Kunci litar & ambil dokumen TERATAS (First in line)
      _isSosActive = true;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final targetPatientId = data['patient_id'];
      String pName = data['patient_name'] ?? 'Pesakit';

      _triggerSosAlarm(pName, targetPatientId);
    });
  }

  // =========================================================
  // 🚨 LITAR PENGGERA & POP-UP (VERSI TARGETED STRIKE - ANTI BLACK SCREEN)
  // =========================================================
  void _triggerSosAlarm(String patientName, String targetPatientId) async {
    if (!mounted) return;

    // 🚀 J.A.R.V.I.S: Kalau popup dah terbentang, jangan bukak popup baru berlapis-lapis!
    if (_isSosDialogOpen) return;

    setState(() {});

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
    } catch (e) {
      print("🚨 J.A.R.V.I.S: Siren rosak -> $e");
    }

    _isSosDialogOpen = true;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) { // 🚀 GUNA dialogContext DI SINI!
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
                    // 🚀 LANGKAH 1: TUTUP DIALOG DULU! (Elak Black Screen / Double Pop)
                    Navigator.pop(dialogContext);

                    // 🚀 LANGKAH 2: MATIKAN SIREN
                    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
                    await _audioPlayer.stop();

                    // 🚀 LANGKAH 3: RESET LITAR RADAR
                    _isSosActive = false;
                    _isSosDialogOpen = false;
                    if (mounted) setState(() {});

                    // 🚀 LANGKAH 4: BARU UPDATE DATABASE!
                    // (Sebab kita dah tutup dialog awal-awal, bila stream trigger Remote Kill Switch,
                    // dia takkan jumpa dialog untuk di-pop lagi!)
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      var activeSosDocs = await FirebaseFirestore.instance
                          .collection('sos_alerts')
                          .where('caregiver_id', isEqualTo: user.uid)
                          .where('patient_id', isEqualTo: targetPatientId)
                          .where('status', isEqualTo: 'ACTIVE')
                          .get();

                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      for (var doc in activeSosDocs.docs) {
                        batch.update(doc.reference, {'status': 'RESOLVED'});
                      }
                      await batch.commit();
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
    ).then((_) {
      // 🚀 J.A.R.V.I.S: Pastikan mangga litar direlease kalau popup hilang
      _isSosDialogOpen = false;
      _isSosActive = false;
    });
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
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