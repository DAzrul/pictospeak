import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({super.key, required this.patientData});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _currentData;

  String _selectedAnalyticMode = 'Daily';
  bool _isUploadingPic = false;
  bool _isGeneratingReport = false; // Loading state for report

  // 🚀 LITAR VOICE COMMAND (CAREGIVER)
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = "";

  // 🧠 OTAK KAMUS DINAMIK KITA
  Map<String, String> _dynamicKamus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentData = Map.from(widget.patientData);

    _speech = stt.SpeechToText(); // 🚀 Setup Mikrofon
    _autoCheckAndSaveWeeklyReport();

    // 🚀 PANGGIL DIA KAT SINI!
    _initDynamicDictionary();
  }

  // 🚀 Protocol: Auto-Generate & Save Weekly Report
  Future<void> _autoCheckAndSaveWeeklyReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Cari tarikh Isnin untuk minggu ini (Start of the week)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    try {
      // 1. SEMAK DATABASE: Ada tak report untuk minggu ni?
      final existingReports = await FirebaseFirestore.instance
          .collection('caregivers').doc(user.uid)
          .collection('patients').doc(_currentData['patient_id'])
          .collection('weekly_reports')
          .where('week_start', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate))
          .get();

      // Kalau report MINGGU INI dah ada, litar dimatikan. Tak payah spam database.
      if (existingReports.docs.isNotEmpty) {
        debugPrint("🚀 J.A.R.V.I.S: Report minggu ni dah wujud. Skip Auto-Save.");
        return;
      }

      // 2. Kalau takde, kita sedut data 7 hari lepas secara senyap
      debugPrint("🚀 J.A.R.V.I.S: Report minggu ni belum ada! Memulakan Auto-Save...");
      final lastWeek = now.subtract(const Duration(days: 7));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('caregivers').doc(user.uid)
          .collection('patients').doc(_currentData['patient_id'])
          .collection('communication_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek))
          .get();

      int totalSentences = querySnapshot.docs.length;

      // Kalau seminggu ni pesakit bisu/tak guna app langsung, litar batal. Tak payah save report kosong.
      if (totalSentences == 0) {
        debugPrint("🚀 J.A.R.V.I.S: Tiada data komunikasi. Auto-Save dibatalkan.");
        return;
      }

      int positiveCount = 0;
      int negativeCount = 0;

      for (var doc in querySnapshot.docs) {
        String mood = doc.data()['mood'] ?? 'Neutral';
        if (mood == 'Positive') positiveCount++;
        if (mood == 'Negative') negativeCount++;
      }

      String overallMood = (positiveCount == 0 && negativeCount == 0) ? "Neutral" : (positiveCount >= negativeCount ? "Positive" : "Distressed");

      // 3. Tulis (SAVE) secara automatik ke Firebase!
      await FirebaseFirestore.instance
          .collection('caregivers').doc(user.uid)
          .collection('patients').doc(_currentData['patient_id'])
          .collection('weekly_reports')
          .add({
        'week_start': Timestamp.fromDate(startOfWeekDate),
        'week_end': Timestamp.now(),
        'total_sentences': totalSentences,
        'positive_mood_count': positiveCount,
        'negative_mood_count': negativeCount,
        'overall_mood': overallMood,
        'summary': 'System Auto-Generated Weekly Report',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ J.A.R.V.I.S: Auto-Save Berjaya Disiapkan!");

    } catch (e) {
      debugPrint("🚨 J.A.R.V.I.S Auto-Save Error: $e");
    }
  }

  // 🚀 PROTOKOL: Sedut Label dari Firebase & Jadikan Kamus AI
  Future<void> _initDynamicDictionary() async {
    // 1. Masukkan kamus STATIK (Bawaan App) dulu
    Map<String, String> baseKamus = {
      // 🟢 BASIC / COMMANDS
      'ya': 'yes', 'yes': 'yes', 'nak': 'yes', 'mau': 'yes', 'ok': 'yes',
      'tak': 'no', 'tidak': 'no', 'no': 'no', 'dont': 'no', 'jangan': 'no',
      'siap': 'done', 'selesai': 'done', 'habis': 'done', 'done': 'done', 'finish': 'done',
      'tolong': 'help', 'bantuan': 'help', 'help': 'help', 'emergency': 'help', 'sos': 'help',

      // 🍔 FOOD & DRINKS
      'makan': 'hungry', 'lapar': 'hungry', 'eat': 'hungry', 'hungry': 'hungry', 'food': 'hungry',
      'minum': 'water', 'haus': 'water', 'air': 'water', 'drink': 'water', 'thirsty': 'water', 'water': 'water',
      'bubur': 'porridge', 'porridge': 'porridge',
      'kopi': 'coffee', 'coffee': 'coffee',
      'teh': 'tea', 'tea': 'tea',
      'susu': 'milk', 'milk': 'milk',

      // 💊 HEALTH & FEELINGS
      'sakit': 'pain', 'pain': 'pain', 'hurt': 'pain', 'pedih': 'pain', 'luka': 'pain',
      'pening': 'dizzy', 'dizzy': 'dizzy', 'pusing': 'dizzy',
      'ubat': 'medicine', 'medicine': 'medicine', 'pill': 'medicine', 'drugs': 'medicine',
      'nafas': 'breathe', 'semput': 'breathe', 'lelah': 'breathe', 'breathe': 'breathe',
      'gatal': 'itchy', 'miang': 'itchy', 'itchy': 'itchy', 'scratch': 'itchy',
      'penat': 'tired', 'letih': 'tired', 'tired': 'tired', 'exhausted': 'tired',
      'sedih': 'sad', 'sad': 'sad', 'cry': 'sad', 'depressed': 'sad',
      'marah': 'angry', 'angry': 'angry', 'mad': 'angry', 'bengang': 'angry',
      'gembira': 'happy', 'seronok': 'happy', 'happy': 'happy', 'glad': 'happy', 'joy': 'happy',

      // 🛏️ BODY & COMFORT
      'duduk': 'sit', 'sit': 'sit',
      'baring': 'lie', 'lie': 'lie', 'down': 'lie',
      'pusing': 'turn', 'kalih': 'turn', 'turn': 'turn', 'move': 'turn',
      'sejuk': 'cold', 'cold': 'cold', 'freezing': 'cold',
      'panas': 'hot', 'hot': 'hot', 'warm': 'hot',
      'rehat': 'rest', 'tidur': 'rest', 'rest': 'rest', 'sleep': 'rest',

      // 🚿 HYGIENE & ENVIRONMENT
      'tandas': 'toilet', 'kencing': 'toilet', 'berak': 'toilet', 'toilet': 'toilet', 'bathroom': 'toilet', 'pee': 'toilet', 'poop': 'toilet',
      'mandi': 'shower', 'shower': 'shower', 'bath': 'shower', 'wash': 'shower',
      'lampin': 'diaper', 'pampers': 'diaper', 'diaper': 'diaper',
      'baju': 'clothes', 'seluar': 'clothes', 'pakaian': 'clothes', 'clothes': 'clothes', 'shirt': 'clothes', 'pants': 'clothes',
      'berus': 'brush', 'gigi': 'brush', 'brush': 'brush', 'teeth': 'brush',
      'lampu': 'light', 'terang': 'light', 'gelap': 'light', 'light': 'light', 'lamp': 'light',
      'kipas': 'fan', 'aircon': 'fan', 'ekon': 'fan', 'fan': 'fan', 'ac': 'fan',
      'bising': 'noisy', 'bingit': 'noisy', 'noisy': 'noisy', 'loud': 'noisy',
      'senyap': 'quiet', 'diam': 'quiet', 'quiet': 'quiet', 'shh': 'quiet',
      'tingkap': 'window', 'jendela': 'window', 'window': 'window',

      // 🏥 LIFESTYLE / REHAB / OTHERS
      'hospital': 'hospital', 'klinik': 'hospital', 'doktor': 'hospital', 'doctor': 'hospital', 'clinic': 'hospital', 'wad': 'hospital',
      'keluarga': 'family', 'anak': 'family', 'isteri': 'family', 'suami': 'family', 'ibu': 'family', 'bapa': 'family', 'family': 'family',
      'fisio': 'physio', 'senaman': 'physio', 'exercise': 'physio', 'physio': 'physio', 'therapy': 'physio',
      'solat': 'pray', 'doa': 'pray', 'sembahyang': 'pray', 'pray': 'pray',
      'bosan': 'bored', 'jemu': 'bored', 'bored': 'bored',
      'telefon': 'phone', 'fon': 'phone', 'tepon': 'phone', 'call': 'phone', 'phone': 'phone',

      // 🔢 NUMBERS
      'kosong': 'num0', 'sifar': 'num0', 'zero': 'num0', '0': 'num0',
      'satu': 'num1', 'one': 'num1', '1': 'num1',
      'dua': 'num2', 'two': 'num2', '2': 'num2',
      'tiga': 'num3', 'three': 'num3', '3': 'num3',
      'empat': 'num4', 'four': 'num4', '4': 'num4',
      'lima': 'num5', 'five': 'num5', '5': 'num5',
      'enam': 'num6', 'six': 'num6', '6': 'num6',
      'tujuh': 'num7', 'seven': 'num7', '7': 'num7',
      'lapan': 'num8', 'eight': 'num8', '8': 'num8',
      'sembilan': 'num9', 'nine': 'num9', '9': 'num9',
    };

    _dynamicKamus.addAll(baseKamus);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 2. Tarik Kamus GLOBAL
      final globalSnap = await FirebaseFirestore.instance.collection('global_pictograms').get();
      for (var doc in globalSnap.docs) {
        final data = doc.data();
        String picId = data['pic_id'] ?? '';
        String labelEn = (data['label_en'] ?? '').toString().toLowerCase().trim();
        String labelMs = (data['label_ms'] ?? '').toString().toLowerCase().trim();

        if (labelEn.isNotEmpty) _dynamicKamus[labelEn] = picId;
        if (labelMs.isNotEmpty) _dynamicKamus[labelMs] = picId;
      }

      // 3. Tarik Kamus CUSTOM (Hak milik Caregiver ni)
      final customSnap = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).collection('custom_pictograms').get();
      for (var doc in customSnap.docs) {
        final data = doc.data();
        String picId = data['pic_id'] ?? '';
        String labelEn = (data['label_en'] ?? '').toString().toLowerCase().trim();
        String labelMs = (data['label_ms'] ?? '').toString().toLowerCase().trim();

        if (labelEn.isNotEmpty) _dynamicKamus[labelEn] = picId;
        if (labelMs.isNotEmpty) _dynamicKamus[labelMs] = picId;
      }

      debugPrint("✅ J.A.R.V.I.S: Otak AI Kamus Berjaya Disegerakkan! (Jumlah Kata Laluan: ${_dynamicKamus.length})");
    } catch (e) {
      debugPrint("🚨 J.A.R.V.I.S ERROR: Gagal sedut kamus dari Firebase -> $e");
    }
  }

  // 🚀 Protocol: Upload Profile Picture
  Future<void> _uploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() => _isUploadingPic = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        File imageFile = File(pickedFile.path);

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('patient_profiles/${user!.uid}/${_currentData['patient_id']}.jpg');

        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(user.uid)
            .collection('patients')
            .doc(_currentData['patient_id'])
            .update({'profile_url': downloadUrl});

        setState(() {
          _currentData['profile_url'] = downloadUrl;
          _isUploadingPic = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated successfully."), backgroundColor: Colors.green));
        }
      } catch (e) {
        setState(() => _isUploadingPic = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // 🚀 Protocol: Edit Patient Details
  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _currentData['name']);
    final ageCtrl = TextEditingController(text: _currentData['age'].toString());
    final conditionCtrl = TextEditingController(text: _currentData['condition']);
    final pinCtrl = TextEditingController(text: _currentData['pin_code']);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit Patient Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                  TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: 'Condition')),
                  TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN Code (4 Digits)'), maxLength: 4, keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('caregivers')
                      .doc(user!.uid)
                      .collection('patients')
                      .doc(_currentData['patient_id'])
                      .update({
                    'name': nameCtrl.text,
                    'age': ageCtrl.text,
                    'condition': conditionCtrl.text,
                    'pin_code': pinCtrl.text,
                  });

                  setState(() {
                    _currentData['name'] = nameCtrl.text;
                    _currentData['age'] = ageCtrl.text;
                    _currentData['condition'] = conditionCtrl.text;
                    _currentData['pin_code'] = pinCtrl.text;
                  });

                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Information updated successfully."), backgroundColor: Colors.blue));
                  }
                },
                child: const Text("SAVE"),
              )
            ],
          );
        }
    );
  }

  // 🚀 Protocol: Generate & Save Weekly Report (Data Persistence)
  Future<void> _generateAndSaveWeeklyReport() async {
    setState(() => _isGeneratingReport = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      // Fetch raw logs for the past 7 days
      final querySnapshot = await FirebaseFirestore.instance
          .collection('caregivers').doc(user!.uid)
          .collection('patients').doc(_currentData['patient_id'])
          .collection('communication_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek))
          .get();

      int totalSentences = querySnapshot.docs.length;
      int positiveCount = 0;
      int negativeCount = 0;

      for (var doc in querySnapshot.docs) {
        String mood = doc.data()['mood'] ?? 'Neutral';
        if (mood == 'Positive') positiveCount++;
        if (mood == 'Negative') negativeCount++;
      }

      String overallMood = (positiveCount == 0 && negativeCount == 0) ? "Neutral" : (positiveCount >= negativeCount ? "Positive" : "Distressed");

      // Save to weekly_reports sub-collection
      await FirebaseFirestore.instance
          .collection('caregivers').doc(user.uid)
          .collection('patients').doc(_currentData['patient_id'])
          .collection('weekly_reports')
          .add({
        'week_start': Timestamp.fromDate(lastWeek),
        'week_end': Timestamp.now(),
        'total_sentences': totalSentences,
        'positive_mood_count': positiveCount,
        'negative_mood_count': negativeCount,
        'overall_mood': overallMood,
        'summary': 'Weekly report manually generated by Caregiver',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Weekly report saved to database successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving report: $e"), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }

  // 🚀 LITAR DENGAR (VERSI UPGRADE SENSITIF & AGRESIF)
  void _listenRemoteCommand() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('🎤 STT Status: $val');
          // 🚀 LOCK ANTI-SPAM
          if ((val == 'notListening' || val == 'done') && _isListening) {
            if (mounted) {
              setState(() => _isListening = false);
              if (_spokenText.isNotEmpty) {
                _processKeyword(_spokenText.toLowerCase());
                _spokenText = "";
              }
            }
          }
        },
        onError: (val) {
          debugPrint('🚨 STT Error: ${val.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🟢 Cakap dengan jelas sekarang!"), backgroundColor: Colors.green, duration: Duration(seconds: 2)));

        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _spokenText = val.recognizedWords;
              });
            }
          },
          // 🚀 INI BAHAGIAN UPGRADE SENSITIVITI!
          listenFor: const Duration(seconds: 10), // Bagi masa panjang sikit untuk kau habiskan ayat
          pauseFor: const Duration(seconds: 3),   // Beri peluang nafas 3 saat sebelum dia cut
          partialResults: true,                   // Tangkap ayat serta-merta tanpa tunggu ayat habis
          listenMode: stt.ListenMode.dictation,   // Paksa STT masuk mod IMLAK (paling sensitif tangkap perkataan sebutir-sebutir)
          cancelOnError: true,
        );
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 🚀 LITAR AI TRANSLATOR KELAS DEWA (Kebal Nombor & Urutan Tepat)
  void _processKeyword(String text) async {
    List<Map<String, dynamic>> hasilCocok = [];

    // Kita bersihkan dulu ayat tu supaya semua jadi lower case
    String ayatLive = text.toLowerCase();

    List<String> kunciKamus = _dynamicKamus.keys.toList();
    // Sort dari paling panjang ke paling pendek
    kunciKamus.sort((a, b) => b.length.compareTo(a.length));

    for (String kunci in kunciKamus) {
      // 🚀 TRIK REGEX KEBAL: Kita cari perkataan tu secara TEPAT menggunakan sempadan perkataan (\b)
      // Ini akan selamatkan perkataan pendek macam "1" atau "ok" daripada tertelan
      RegExp regex = RegExp(r'\b' + RegExp.escape(kunci) + r'\b');

      Iterable<RegExpMatch> tangkapan = regex.allMatches(ayatLive);

      for (final match in tangkapan) {
        hasilCocok.add({
          'id': _dynamicKamus[kunci]!,
          'index': match.start, // Tangkap posisi indeks asli
        });
      }

      // Buang perkataan yang dah ditangkap dengan menggantikan ia dengan space kosong
      // supaya posisi index perkataan lain tak lari
      ayatLive = ayatLive.replaceAllMapped(regex, (match) => " " * match.group(0)!.length);
    }

    // 🚀 URUTKAN BERDASARKAN INDEKS (Ngikutin urutan mulut kau)
    hasilCocok.sort((a, b) => a['index'].compareTo(b['index']));

    // Ekstrak hasil sortir ke final list
    List<String> dikesan = [];
    for (var cocok in hasilCocok) {
      // Elak spam berturut-turut (1 1 1 jadi 1 je)
      if (dikesan.isEmpty || dikesan.last != cocok['id']) {
        dikesan.add(cocok['id']);
      }
    }

    if (dikesan.isNotEmpty) {
      String arahanPenuh = dikesan.join(',');

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user!.uid)
          .collection('patients')
          .doc(_currentData['patient_id'])
          .update({'remote_command': arahanPenuh});

      debugPrint("🚀 BERJAYA TEMBAK KE FIREBASE (SESUAI URUTAN): $arahanPenuh");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚀 Arahan dihantar: $arahanPenuh"), backgroundColor: Colors.blue));
      }
    } else {
      debugPrint("🚨 ENJIN TAK FAHAM AYAT: $text");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arahan tak faham."), backgroundColor: Colors.orange));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_currentData['name'] ?? 'Patient Details', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.person_outline)),
            Tab(text: 'Insights', icon: Icon(Icons.auto_graph_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInsightsTab(),
        ],
      ),
      // FLOATING ACTION BUTTON MIC DAH KENA DELETE!
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _currentData['profile_url'] != null ? NetworkImage(_currentData['profile_url']) : null,
                child: _currentData['profile_url'] == null
                    ? const Icon(Icons.person_rounded, size: 60, color: Colors.white)
                    : null,
              ),
              if (_isUploadingPic) const Positioned.fill(child: CircularProgressIndicator()),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadProfilePic,
                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildInfoCard("Condition", _currentData['condition'] ?? 'N/A', Icons.medical_services_outlined),
        _buildInfoCard("Age", "${_currentData['age']} Years Old", Icons.cake_outlined),
        _buildInfoCard("Relationship", _currentData['relationship'] ?? 'N/A', Icons.family_restroom),
        _buildInfoCard("Access PIN", _currentData['pin_code'] ?? 'N/A', Icons.lock_outline),
        const SizedBox(height: 20),

        // 🚀 LITAR BARU: BUTANG EDIT & MIC SEBARIS
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue),
                label: const Text("EDIT PATIENT DETAILS", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
            const SizedBox(width: 12),

            // 🚀 INI BUTANG MIC KAU!
            GestureDetector(
              onTap: _listenRemoteCommand,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ],
      ),
    );
  }

  BarChartGroupData _makeDynamicBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: y,
            color: AppTheme.primaryBlue,
            width: 16,
            borderRadius: BorderRadius.circular(4)
        )
      ],
    );
  }

  // 📊 Helper untuk Carta 2 (Mood Monitor - pastikan kau dah letak ni jugak)
  BarChartGroupData _makeMoodBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: y,
            color: color,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6))
        )
      ],
    );
  }

  Widget _buildInsightsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("User not authorized."));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(_currentData['patient_id'])
          .collection('communication_logs')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Data error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];

        int totalSentences = 0;
        int positiveMood = 0;
        int negativeMood = 0;
        int neutralMood = 0; // 🚀 LITAR BARU: Tambah kaunter Neutral
        Map<String, int> keywordCounts = {};

        DateTime now = DateTime.now();
        DateTime startOfToday = DateTime(now.year, now.month, now.day);
        DateTime startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          if (timestamp != null) {
            bool isWithinRange = false;

            // Analytic Mode Filtering
            if (_selectedAnalyticMode == 'Daily') {
              if (timestamp.isAfter(startOfToday)) isWithinRange = true;
            } else {
              if (timestamp.isAfter(startOfWeek) || timestamp.isAtSameMomentAs(startOfWeek)) isWithinRange = true;
            }

            if (isWithinRange) {
              totalSentences++;
              String mood = data['mood'] ?? 'Neutral';

              // 🚀 LITAR BARU: Asingkan mood ikut kategori
              if (mood == 'Positive') {
                positiveMood++;
              } else if (mood == 'Negative') {
                negativeMood++;
              } else {
                neutralMood++;
              }

              List<dynamic> items = data['items'] ?? [];
              for (var item in items) {
                String wordStr = item.toString().trim();

                if (wordStr.isEmpty || (wordStr.length == 20 && !wordStr.contains(' ') && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(wordStr))) continue;

                wordStr = "${wordStr[0].toUpperCase()}${wordStr.substring(1).toLowerCase()}";
                keywordCounts[wordStr] = (keywordCounts[wordStr] ?? 0) + 1;
              }
            }
          }
        }

        String overallMood = (positiveMood == 0 && negativeMood == 0) ? "Neutral" : (positiveMood >= negativeMood ? "Positive" : "Distressed");
        Color moodColor = overallMood == "Positive" ? Colors.green : (overallMood == "Distressed" ? Colors.red : Colors.grey);
        IconData moodIcon = overallMood == "Positive" ? Icons.sentiment_very_satisfied_rounded : (overallMood == "Distressed" ? Icons.sentiment_very_dissatisfied_rounded : Icons.sentiment_neutral_rounded);

        var sortedKeys = keywordCounts.keys.toList()..sort((a, b) => keywordCounts[b]!.compareTo(keywordCounts[a]!));
        List<String> top4Items = sortedKeys.take(4).toList();
        List<int> top4Values = top4Items.map((k) => keywordCounts[k]!).toList();
        double maxYGraph = top4Values.isNotEmpty ? top4Values.reduce((a, b) => a > b ? a : b).toDouble() : 10;

        // 🚀 Setup maksimum skala carta Mood Monitor
        double maxMoodY = [positiveMood, neutralMood, negativeMood].reduce((a, b) => a > b ? a : b).toDouble() + 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // DROPDOWN FILTER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAnalyticMode,
                    items: ['Daily', 'Weekly'].map((String mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
                    onChanged: (val) => setState(() => _selectedAnalyticMode = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildSummaryCard(totalSentences.toString(), "Sentences ($_selectedAnalyticMode)", Icons.chat_bubble_outline_rounded, Colors.blue),
                  const SizedBox(width: 16),
                  _buildSummaryCard(overallMood, "Mood Trend", moodIcon, moodColor),
                ],
              ),
              const SizedBox(height: 16),

              // 📊 CARTA 1: MOST FREQUENT NEEDS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insert_chart_outlined, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Most Frequent Needs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 200,
                      child: top4Items.isEmpty
                          ? const Center(child: Text("Insufficient data for charts.", style: TextStyle(color: Colors.grey)))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxYGraph + 2,
                          barGroups: List.generate(top4Items.length, (index) {
                            return _makeDynamicBarGroup(index, top4Values[index].toDouble());
                          }),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= top4Items.length) return const Text('');
                                  String titleRaw = top4Items[value.toInt()];
                                  String titleFormat = "${titleRaw[0].toUpperCase()}${titleRaw.substring(1).toLowerCase()}";
                                  return Text(titleFormat, style: const TextStyle(color: Colors.grey, fontSize: 10));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  if (value % (maxYGraph > 20 ? 5 : 2) == 0) {
                                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🚀 📊 CARTA 2: MOOD MONITOR (BARU!)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology_alt_rounded, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Text('Mood Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Frequency of emotional states based on communication.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 180,
                      child: (positiveMood == 0 && neutralMood == 0 && negativeMood == 0)
                          ? const Center(child: Text("No mood data available.", style: TextStyle(color: Colors.grey)))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          maxY: maxMoodY,
                          barGroups: [
                            _makeMoodBarGroup(0, positiveMood.toDouble(), Colors.green.shade400),
                            _makeMoodBarGroup(1, neutralMood.toDouble(), Colors.grey.shade400),
                            _makeMoodBarGroup(2, negativeMood.toDouble(), Colors.red.shade400),
                          ],
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Text('Positive', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold));
                                    case 1: return const Text('Neutral', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold));
                                    case 2: return const Text('Negative', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold));
                                    default: return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 == 0 && value != 0) { // Tunjuk nombor bulat je
                                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 📜 COMMUNICATION LOG (Sedia ada)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Communication Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (docs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text("No records detected.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length > 5 ? 5 : docs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final sentence = data['sentence'] ?? '';
                          final moodStr = data['mood'] ?? 'Neutral';

                          String timeText = "Just now";
                          Timestamp? ts = data['timestamp'] as Timestamp?;
                          if (ts != null) {
                            timeText = DateFormat('h:mm a, d MMM').format(ts.toDate());
                          }

                          Color tagColor = Colors.grey;
                          if (moodStr == 'Positive') tagColor = Colors.green;
                          if (moodStr == 'Negative') tagColor = Colors.red;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                  child: const Icon(Icons.record_voice_over, size: 14, color: AppTheme.primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('"$sentence"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                      const SizedBox(height: 4),
                                      Text(timeText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(moodStr, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String value, String title, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}