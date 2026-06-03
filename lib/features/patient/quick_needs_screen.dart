import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/tts_service.dart';
import '../auth/splash_screen.dart';

class QuickNeedsScreen extends StatefulWidget {
  const QuickNeedsScreen({super.key});

  @override
  State<QuickNeedsScreen> createState() => _QuickNeedsScreenState();
}

class _QuickNeedsScreenState extends State<QuickNeedsScreen> {
  final TtsService _ttsService = TtsService();

  // 🚀 J.A.R.V.I.S: Pembolehubah setempat untuk memegang konfigurasi enjin TTS
  double _storedSpeed = 1.0;
  double _storedPitch = 1.0;

  // 🚀 J.A.R.V.I.S: State Management
  String? _currentFolder;
  final List<String> _folderHistory = [];
  final List<Map<String, dynamic>> _selectedItems = [];

  List<Map<String, dynamic>> _mergedData = [];
  late List<Map<String, dynamic>> _staticData;
  bool _isLoadingFirebase = true;

  // 🚀 J.A.R.V.I.S: Pembolehubah aksesibiliti & visual
  bool _isLowSensory = false;
  bool _hideIcons = false;
  bool _useLargeTargets = false;
  double _selectDelay = 500.0;

  @override
  void initState() {
    super.initState();
    _initStaticDatabase();
    _syncWithFirebase();
    _applyStoredSettings(); // Tarik data masa mula-mula masuk
  }

  // 🚀 J.A.R.V.I.S: LITAR UTAMA - Sedut SEMUA data konfigurasi dari storan setempat sekaligus
  Future<void> _applyStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // 1. Parameter TTS
        _storedSpeed = prefs.getDouble('tts_speed') ?? 1.0;
        _storedPitch = prefs.getDouble('tts_pitch') ?? 1.0;

        // 2. Parameter Visual & Sensory
        _isLowSensory = prefs.getBool('low_sensory') ?? false;
        _hideIcons = prefs.getBool('hide_distractions') ?? false;

        // 3. Parameter Motor Accessibility
        _useLargeTargets = prefs.getBool('large_targets') ?? false;
        _selectDelay = prefs.getDouble('hold_delay') ?? 500.0;
      });
    }

    // Suntik terus ke dalam enjin fizikal suara
    await _ttsService.setSpeed(_storedSpeed);
    await _ttsService.setPitch(_storedPitch);
  }

  // 🚀 J.A.R.V.I.S: Sebutan penuh untuk senarai bar ayat atas
  Future<void> _speakAllItems() async {
    if (_selectedItems.isEmpty) return;
    String fullSentence = _selectedItems.map((item) => item['en']).join(' ');

    await _ttsService.stop();

    // 🚀 LANGKAH 1: Paksa sistem baca fail SharedPreferences terbaharu (Visual + Audio)
    await _applyStoredSettings();

    // 🚀 LANGKAH 2: Bersuara mengikut arahan yang telah dikemaskini
    await _ttsService.speak(fullSentence, lang: "en-US");
  }

  void _initStaticDatabase() {
    _staticData = [
      // =========================================================
      // 1. MAIN MENU (LUARAN)
      // =========================================================
      {'id': 'yes', 'folder': null, 'en': 'YES', 'ms': 'Ya', 'image': 'assets/Pictogram/yes.png', 'color': Colors.green.shade600, 'isFolder': false},
      {'id': 'no', 'folder': null, 'en': 'NO', 'ms': 'Tidak', 'image': 'assets/Pictogram/no.png', 'color': Colors.red.shade600, 'isFolder': false},
      {'id': 'pain', 'folder': null, 'en': 'Pain', 'ms': 'Sakit', 'image': 'assets/Pictogram/pain.png', 'color': const Color(0xFFF43F5E), 'isFolder': false},
      {'id': 'toilet', 'folder': null, 'en': 'Toilet', 'ms': 'Tandas', 'image': 'assets/Pictogram/toilet.png', 'color': Colors.orange, 'isFolder': false},
      {'id': 'sos', 'folder': null, 'en': 'SOS / Help', 'ms': 'Tolong', 'image': 'assets/Pictogram/SOS.png', 'color': Colors.amber.shade700, 'isFolder': false},

      // FOLDER UTAMA DI MAIN MENU
      {'id': 'health', 'folder': null, 'en': 'Health', 'ms': 'Kesihatan', 'image': 'assets/Pictogram/Health/medicine.png', 'color': Colors.purple.shade400, 'isFolder': true},
      {'id': 'body', 'folder': null, 'en': 'Body & Comfort', 'ms': 'Selesa', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'color': Colors.teal.shade400, 'isFolder': true},
      {'id': 'food_drinks', 'folder': null, 'en': 'Food & Drinks', 'ms': 'Makan Minum', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'color': Colors.blue.shade400, 'isFolder': true},
      {'id': 'feelings', 'folder': null, 'en': 'Feelings', 'ms': 'Emosi', 'image': 'assets/Pictogram/Feelings/happy.png', 'color': Colors.pink.shade300, 'isFolder': true},
      {'id': 'hygiene', 'folder': null, 'en': 'Hygiene', 'ms': 'Kebersihan', 'image': 'assets/Pictogram/Hygiene/shower.png', 'color': Colors.cyan.shade400, 'isFolder': true},
      {'id': 'environment', 'folder': null, 'en': 'Environment', 'ms': 'Sekeliling', 'image': 'assets/Pictogram/Environment/light.png', 'color': Colors.indigo.shade400, 'isFolder': true},
      {'id': 'rehab', 'folder': null, 'en': 'Lifestyle', 'ms': 'Gaya Hidup', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'color': Colors.lime.shade600, 'isFolder': true},
      {'id': 'number', 'folder': null, 'en': 'Numbers', 'ms': 'Nombor', 'image': 'assets/Pictogram/Number/one.png', 'color': Colors.brown.shade400, 'isFolder': true},

      // =========================================================
      // 2. KESIHATAN & FIZIKAL (folder: 'health')
      // =========================================================
      {'id': 'medicine', 'folder': 'health', 'en': 'Medicine', 'ms': 'Ubat', 'image': 'assets/Pictogram/Health/medicine.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'dizzy', 'folder': 'health', 'en': 'Dizzy', 'ms': 'Pening', 'image': 'assets/Pictogram/Health/feel dizzy.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'breathe', 'folder': 'health', 'en': 'Breathe', 'ms': 'Susah Nafas', 'image': 'assets/Pictogram/Health/breathe.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'itchy', 'folder': 'health', 'en': 'Itchy', 'ms': 'Gatal', 'image': 'assets/Pictogram/Health/itch.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'tired', 'folder': 'health', 'en': 'Tired', 'ms': 'Penat', 'image': 'assets/Pictogram/Health/tired.png', 'color': Colors.purple.shade400, 'isFolder': false},

      // =========================================================
      // 3. POSISI & KESELESAAN (folder: 'body')
      // =========================================================
      {'id': 'sit', 'folder': 'body', 'en': 'Sit Up', 'ms': 'Duduk', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'lie', 'folder': 'body', 'en': 'Lie Down', 'ms': 'Baring', 'image': 'assets/Pictogram/Body and Comfort/lie down.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'turn', 'folder': 'body', 'en': 'Turn Me', 'ms': 'Pusing Badan', 'image': 'assets/Pictogram/Body and Comfort/turn.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'cold', 'folder': 'body', 'en': 'Cold', 'ms': 'Sejuk', 'image': 'assets/Pictogram/Body and Comfort/cold.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'hot', 'folder': 'body', 'en': 'Hot', 'ms': 'Panas', 'image': 'assets/Pictogram/Body and Comfort/be hot.png', 'color': Colors.teal.shade400, 'isFolder': false},

      // =========================================================
      // 4. MAKAN & MINUM (folder: 'food_drinks')
      // =========================================================
      {'id': 'water', 'folder': 'food_drinks', 'en': 'Water', 'ms': 'Air Kosong', 'image': 'assets/Pictogram/food_drinks/water.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'hungry', 'folder': 'food_drinks', 'en': 'Hungry', 'ms': 'Lapar', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'porridge', 'folder': 'food_drinks', 'en': 'Porridge', 'ms': 'Bubur', 'image': 'assets/Pictogram/food_drinks/bowl.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'coffee', 'folder': 'food_drinks', 'en': 'Coffee', 'ms': 'Kopi', 'image': 'assets/Pictogram/food_drinks/coffee.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'tea', 'folder': 'food_drinks', 'en': 'Tea', 'ms': 'Teh', 'image': 'assets/Pictogram/food_drinks/tea.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'milk', 'folder': 'food_drinks', 'en': 'Milk', 'ms': 'Susu', 'image': 'assets/Pictogram/food_drinks/milk.png', 'color': Colors.blue.shade400, 'isFolder': false},

      // =========================================================
      // 5. EMOSI & SOSIAL (folder: 'feelings')
      // =========================================================
      {'id': 'happy', 'folder': 'feelings', 'en': 'Happy', 'ms': 'Gembira', 'image': 'assets/Pictogram/Feelings/happy.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'sad', 'folder': 'feelings', 'en': 'Sad', 'ms': 'Sedih', 'image': 'assets/Pictogram/Feelings/sad.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'angry', 'folder': 'feelings', 'en': 'Angry', 'ms': 'Marah', 'image': 'assets/Pictogram/Feelings/angry.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'family', 'folder': 'feelings', 'en': 'Family', 'ms': 'Keluarga', 'image': 'assets/Pictogram/Feelings/family.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'quiet', 'folder': 'feelings', 'en': 'Quiet', 'ms': 'Senyap', 'image': 'assets/Pictogram/Feelings/quiet.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'rest', 'folder': 'feelings', 'en': 'Rest', 'ms': 'Nak Rehat', 'image': 'assets/Pictogram/Feelings/rest.png', 'color': Colors.pink.shade300, 'isFolder': false},

      // =========================================================
      // 6. KEBERSIHAN DIRI (folder: 'hygiene')
      // =========================================================
      {'id': 'diaper', 'folder': 'hygiene', 'en': 'Diaper', 'ms': 'Tukar Lampin', 'image': 'assets/Pictogram/Hygiene/diaper.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'shower', 'folder': 'hygiene', 'en': 'Shower', 'ms': 'Mandi / Lap', 'image': 'assets/Pictogram/Hygiene/shower.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'clothes', 'folder': 'hygiene', 'en': 'Change Clothes', 'ms': 'Tukar Baju', 'image': 'assets/Pictogram/Hygiene/clothes.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'brush', 'folder': 'hygiene', 'en': 'Brush Teeth', 'ms': 'Berus Gigi', 'image': 'assets/Pictogram/Hygiene/brush teeth.png', 'color': Colors.cyan.shade400, 'isFolder': false},

      // =========================================================
      // 7. KAWALAN BILIK (folder: 'environment')
      // =========================================================
      {'id': 'light', 'folder': 'environment', 'en': 'Light', 'ms': 'Lampu', 'image': 'assets/Pictogram/Environment/light.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'fan', 'folder': 'environment', 'en': 'Fan/AC', 'ms': 'Kipas', 'image': 'assets/Pictogram/Environment/fan.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'noisy', 'folder': 'environment', 'en': 'Noisy', 'ms': 'Bising', 'image': 'assets/Pictogram/Environment/noisy.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'window', 'folder': 'environment', 'en': 'Window', 'ms': 'Tingkap', 'image': 'assets/Pictogram/Environment/open the window.png', 'color': Colors.indigo.shade400, 'isFolder': false},

      // =========================================================
      // 8. LIFESTYLE & REHAB (folder: 'rehab')
      // =========================================================
      {'id': 'physio', 'folder': 'rehab', 'en': 'Physio', 'ms': 'Senaman', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'pray', 'folder': 'rehab', 'en': 'Pray', 'ms': 'Solat', 'image': 'assets/Pictogram/Lifestyle and Rehab/pray.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'bored', 'folder': 'rehab', 'en': 'Bored/TV', 'ms': 'Bosan / TV', 'image': 'assets/Pictogram/Lifestyle and Rehab/bored.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'phone', 'folder': 'rehab', 'en': 'Phone', 'ms': 'Telefon', 'image': 'assets/Pictogram/Lifestyle and Rehab/phone.png', 'color': Colors.lime.shade600, 'isFolder': false},

      // =========================================================
      // 9. NOMBOR (folder: 'number')
      // =========================================================
      {'id': 'num0', 'folder': 'number', 'en': 'Zero', 'ms': 'Kosong', 'image': 'assets/Pictogram/Number/0.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num1', 'folder': 'number', 'en': 'One', 'ms': 'Satu', 'image': 'assets/Pictogram/Number/one.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num2', 'folder': 'number', 'en': 'Two', 'ms': 'Dua', 'image': 'assets/Pictogram/Number/2.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num3', 'folder': 'number', 'en': 'Three', 'ms': 'Tiga', 'image': 'assets/Pictogram/Number/3.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num4', 'folder': 'number', 'en': 'Four', 'ms': 'Empat', 'image': 'assets/Pictogram/Number/4.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num5', 'folder': 'number', 'en': 'Five', 'ms': 'Lima', 'image': 'assets/Pictogram/Number/5.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num6', 'folder': 'number', 'en': 'Six', 'ms': 'Enam', 'image': 'assets/Pictogram/Number/6.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num7', 'folder': 'number', 'en': 'Seven', 'ms': 'Tujuh', 'image': 'assets/Pictogram/Number/7.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num8', 'folder': 'number', 'en': 'Eight', 'ms': 'Lapan', 'image': 'assets/Pictogram/Number/8.png', 'color': Colors.brown.shade400, 'isFolder': false},
      {'id': 'num9', 'folder': 'number', 'en': 'Nine', 'ms': 'Sembilan', 'image': 'assets/Pictogram/Number/9.png', 'color': Colors.brown.shade400, 'isFolder': false},
    ];
    _mergedData = List.from(_staticData);
  }

  // 🚀 J.A.R.V.I.S: Sinkronisasi Awan
  Future<void> _syncWithFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isLoadingFirebase = false); return; }

    FirebaseFirestore.instance
        .collection('caregivers').doc(user.uid).collection('custom_pictograms')
        .snapshots().listen((snapshot) {

      List<Map<String, dynamic>> firebaseItems = [];
      Set<String> subFoldersFound = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String cat = data['category'] ?? 'custom';
        String? parent = data['parent_folder'];

        String folderTarget = (parent != null && parent.isNotEmpty) ? cat : cat;

        firebaseItems.add({
          'id': data['pic_id'],
          'folder': folderTarget,
          'category': cat,
          'parent_folder': parent,
          'en': data['label_en'],
          'ms': data['label_ms'],
          'image': data['image_url'],
          'isFolder': false,
          'isNetwork': true,
        });

        if (parent != null && parent.isNotEmpty) {
          subFoldersFound.add("$cat|$parent");
        }
      }

      List<Map<String, dynamic>> dynamicFolders = [];
      for (var folderInfo in subFoldersFound) {
        var parts = folderInfo.split('|');
        dynamicFolders.add({
          'id': parts[0],
          'folder': parts[1],
          'en': parts[0].replaceAll('_', ' ').toUpperCase(),
          'ms': parts[0].replaceAll('_', ' ').toUpperCase(),
          'image': 'assets/Pictogram/Environment/light.png',
          'isFolder': true,
          'isNetwork': false,
        });
      }

      if (mounted) {
        setState(() {
          _mergedData = [..._staticData, ...dynamicFolders, ...firebaseItems];
          _isLoadingFirebase = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _currentDisplayItems {
    return _mergedData.where((item) => item['folder'] == _currentFolder).toList();
  }

  void _removeItem(int index) => setState(() => _selectedItems.removeAt(index));
  void _removeLastItem() { if (_selectedItems.isNotEmpty) setState(() => _selectedItems.removeLast()); }
  void _clearAllItems() => setState(() => _selectedItems.clear());

  Future<void> _triggerSOS() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');
    if (patientId != null) {
      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'patient_id': patientId, 'patient_name': prefs.getString('patient_name') ?? "Unknown",
        'timestamp': FieldValue.serverTimestamp(), 'status': 'ACTIVE',
      });
    }
    await _ttsService.stop();
    await _ttsService.speak("Kecemasan! Saya perlukan bantuan!", lang: "ms-MY");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    int gridColumns = screenWidth >= 900 ? 5 : (isTablet ? 4 : 3);

    return Scaffold(
      // 🚀 Dinamik mengikut Low Sensory Theme
      backgroundColor: _isLowSensory ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: Icon(_currentFolder != null ? Icons.arrow_back_ios_new : Icons.power_settings_new,
              color: _currentFolder != null ? AppTheme.textDark : Colors.redAccent),
          onPressed: () async {
            _ttsService.stop();
            if (_folderHistory.isNotEmpty) {
              setState(() {
                _folderHistory.removeLast();
                _currentFolder = _folderHistory.isEmpty ? null : _folderHistory.last;
              });
            } else {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_patient_logged_in', false);
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
            }
          },
        ),
        title: Text(_currentFolder != null ? _currentFolder!.replaceAll('_', ' ').toUpperCase() : 'QUICK NEEDS', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedItems.isNotEmpty)
              Container(
                height: isTablet ? 140 : 160, width: double.infinity, color: Colors.white,
                child: Column(
                  children: [
                    Expanded(child: _buildImageScroller(isTablet)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: _buildActionButtons()),
                  ],
                ),
              ),

            Expanded(
              child: _isLoadingFirebase
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // 🚀 Dinamik mengikut Large Touch Targets
                  crossAxisCount: _useLargeTargets ? (gridColumns - 1).clamp(2, 5) : gridColumns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: _useLargeTargets ? 1.0 : 0.8,
                ),
                itemCount: _currentDisplayItems.length,
                itemBuilder: (context, index) => _buildSmartCard(_currentDisplayItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCard(Map<String, dynamic> item) {
    bool isFolder = item['isFolder'] ?? false;
    Color borderColor = isFolder ? AppTheme.primaryBlue : Colors.grey.shade300;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (isFolder) {
          setState(() {
            _folderHistory.add(item['id']);
            _currentFolder = item['id'];
          });
        } else if (item['id'] == 'sos') {
          _triggerSOS();
        } else {
          setState(() => _selectedItems.add(item));
          await _ttsService.stop();

          // 🚀 FIX: Panggil fungsi penyedut yang lengkap (Audio + Visual)
          await _applyStoredSettings();
          await _ttsService.speak(item['en'], lang: "en-US");
        }
      },
      child: Stack(
        children: [
          Positioned(
            top: isFolder ? 14 : 0, bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: isFolder ? 2.5 : 1.2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.all(12), child: _renderImage(item))),

                  // 🚀 Dinamik Font Size mengikut saiz target kotak
                  Text(item['en'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: _useLargeTargets ? 16 : 13, color: AppTheme.textDark), maxLines: 1),

                  // 🚀 Dinamik Sorok Terjemahan jika Hide Distractions aktif
                  if (!_hideIcons)
                    Text(item['ms'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (isFolder)
            Positioned(
              top: 0, left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                child: const Icon(Icons.folder_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderImage(Map<String, dynamic> item) {
    bool isNetwork = item['isNetwork'] ?? false;
    String path = item['image'] ?? '';
    if (path.isEmpty) return const Icon(Icons.broken_image, color: Colors.grey);
    return isNetwork
        ? Image.network(path, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image))
        : Image.asset(path, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
  }

  Widget _buildImageScroller(bool isTablet) {
    return ListView.builder(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedItems.length,
      itemBuilder: (context, index) {
        final item = _selectedItems[index];
        return InkWell(
          onTap: () => _removeItem(index),
          child: Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            width: isTablet ? 100 : 80,
            child: Column(children: [Expanded(child: _renderImage(item)), Text(item['en'].toLowerCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1)]),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(icon: const Icon(Icons.backspace_rounded, color: Colors.grey), onPressed: _removeLastItem),
      IconButton(icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_forever, color: Colors.white, size: 20)), onPressed: _clearAllItems),
      IconButton(icon: const Icon(Icons.play_circle_fill, color: Colors.green, size: 50), onPressed: _speakAllItems),
    ]);
  }
}