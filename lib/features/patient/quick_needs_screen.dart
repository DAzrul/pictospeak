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

  double _storedSpeed = 1.0;
  double _storedPitch = 1.0;

  String? _currentFolder;
  final List<String> _folderHistory = [];
  final List<Map<String, dynamic>> _selectedItems = [];

  List<Map<String, dynamic>> _mergedData = [];
  late List<Map<String, dynamic>> _staticData;
  bool _isLoadingFirebase = true;

  bool _isLowSensory = false;
  bool _hideIcons = false;
  bool _useLargeTargets = false;
  double _selectDelay = 500.0;

  Map<String, int> _globalFrequencyMap = {};

  // =========================================================
  // 🧠 J.A.R.V.I.S: Otak AI Statik (Versi Penuh / Full Mapping)
  // =========================================================
  final Map<String, List<String>> _predictionMap = {
    // 1. ASAS & KECEMASAN
    'yes': ['happy', 'done'],
    'no': ['sad', 'angry', 'pain'],
    'pain': ['medicine', 'rest', 'dizzy', 'hospital', 'help'],
    'toilet': ['water', 'diaper', 'shower', 'done'],
    'help': ['breathe', 'pain', 'hospital', 'family', 'dizzy'], // SOS dah tukar jadi Help

    // 2. KESIHATAN & FIZIKAL
    'medicine': ['water', 'rest', 'done'],
    'dizzy': ['lie', 'rest', 'medicine', 'water'],
    'breathe': ['rest', 'help', 'hospital', 'fan'],
    'itchy': ['shower', 'medicine', 'clothes'],
    'tired': ['rest', 'lie', 'water', 'quiet'],

    // 3. POSISI & KESELESAAN
    'sit': ['water', 'bored', 'phone', 'family'],
    'lie': ['rest', 'tired', 'cold', 'hot', 'quiet'],
    'turn': ['pain', 'rest', 'lie'],
    'cold': ['clothes', 'window', 'tea', 'turn'],
    'hot': ['fan', 'water', 'shower', 'window', 'clothes'],

    // 4. MAKAN & MINUM
    'water': ['done', 'happy', 'toilet'],
    'hungry': ['porridge', 'milk', 'water', 'done'],
    'porridge': ['water', 'done', 'happy'],
    'coffee': ['water', 'done'],
    'tea': ['water', 'done'],
    'milk': ['water', 'done', 'rest'],

    // 5. EMOSI & SOSIAL
    'happy': ['family', 'phone', 'done'],
    'sad': ['family', 'rest', 'pray', 'quiet'],
    'angry': ['quiet', 'rest', 'breathe', 'noisy'],
    'family': ['happy', 'phone', 'pray'],
    'quiet': ['rest', 'lie', 'breathe'],
    'rest': ['quiet', 'lie', 'fan', 'light'],

    // 6. KEBERSIHAN DIRI
    'diaper': ['shower', 'clothes', 'done'],
    'shower': ['clothes', 'cold', 'done'],
    'clothes': ['cold', 'hot', 'done'],
    'brush': ['water', 'done'],

    // 7. KAWALAN BILIK
    'light': ['rest', 'lie', 'bored'],
    'fan': ['hot', 'cold', 'rest', 'window'],
    'noisy': ['quiet', 'angry', 'sad', 'window'],
    'window': ['hot', 'cold', 'fan', 'light'],

    // 8. LIFESTYLE & REHAB
    'physio': ['tired', 'pain', 'water', 'rest'],
    'pray': ['quiet', 'clothes', 'water'],
    'bored': ['phone', 'family', 'sit'],
    'phone': ['family', 'happy', 'bored'],

    // 9. NOMBOR
    'num0': ['done'], 'num1': ['done'], 'num2': ['done'],
    'num3': ['done'], 'num4': ['done'], 'num5': ['done'],
    'num6': ['done'], 'num7': ['done'], 'num8': ['done'], 'num9': ['done'],

    // TAMBAHAN
    'done': ['happy', 'rest'],
    'hospital': ['help', 'family', 'pain'],
  };

  // 🚀 J.A.R.V.I.S: KOTAK MEMORI OTAK AI PERIBADI
  Map<String, Map<String, int>> _personalizedPredictions = {};

  // =========================================================
  // 🎯 LITAR PENAPIS AI (Otak Peribadi > Otak Statik)
  // =========================================================
  List<Map<String, dynamic>> get _currentRecommendations {
    if (_selectedItems.isEmpty) return [];

    String lastItemId = _selectedItems.last['id'];
    List<String> predictedIds = [];

    // 🚀 LANGKAH 1: Tanya Otak Peribadi dulu
    if (_personalizedPredictions.containsKey(lastItemId)) {
      var nextWordsMap = _personalizedPredictions[lastItemId]!;
      var sortedWords = nextWordsMap.keys.toList()
        ..sort((a, b) => nextWordsMap[b]!.compareTo(nextWordsMap[a]!));

      predictedIds = sortedWords.take(4).toList();
    }

    // 🚀 LANGKAH 2: Kalau otak peribadi kosong, pakai Otak Statik
    if (predictedIds.isEmpty) {
      predictedIds = _predictionMap[lastItemId] ?? [];
    }

    return _mergedData.where((item) => predictedIds.contains(item['id'])).toList();
  }

  @override
  void initState() {
    super.initState();
    _initStaticDatabase();
    _syncWithFirebase();
    _applyStoredSettings();
    _buildPersonalizedBrain();
  }

  Future<void> _applyStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _storedSpeed = prefs.getDouble('tts_speed') ?? 1.0;
        _storedPitch = prefs.getDouble('tts_pitch') ?? 1.0;
        _isLowSensory = prefs.getBool('low_sensory') ?? false;
        _hideIcons = prefs.getBool('hide_distractions') ?? false;
        _useLargeTargets = prefs.getBool('large_targets') ?? false;
        _selectDelay = prefs.getDouble('hold_delay') ?? 500.0;
      });
    }
    await _ttsService.setSpeed(_storedSpeed);
    await _ttsService.setPitch(_storedPitch);
  }

  // =========================================================
  // 🧠 J.A.R.V.I.S MACHINE LEARNING: Bina Otak Peribadi + Kira Freq Grid
  // =========================================================
  Future<void> _buildPersonalizedBrain() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');

    if (user == null || patientId == null) return;

    try {
      print("🚀 J.A.R.V.I.S: Menyelam masuk ke memori pesakit untuk susun semula kedudukan Grid...");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(patientId)
          .collection('communication_logs')
          .orderBy('timestamp', descending: true)
          .limit(100) // Ambil 100 log terakhir untuk analisis trend semasa
          .get();

      Map<String, Map<String, int>> tempBrain = {};
      Map<String, int> tempFrequency = {}; // Tempat simpan kiraan kekerapan baru

      for (var doc in querySnapshot.docs) {
        List<dynamic> items = doc.data()['items'] ?? [];

        for (int i = 0; i < items.length; i++) {
          String currentWord = items[i].toString();

          // 📊 Kira kekerapan global untuk susunan grid utama
          tempFrequency[currentWord] = (tempFrequency[currentWord] ?? 0) + 1;

          // Logik Next-Word Prediction asal kau
          if (i < items.length - 1) {
            String nextWord = items[i + 1].toString();
            if (!tempBrain.containsKey(currentWord)) {
              tempBrain[currentWord] = {};
            }
            tempBrain[currentWord]![nextWord] = (tempBrain[currentWord]![nextWord] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _personalizedPredictions = tempBrain;
          _globalFrequencyMap = tempFrequency; // Simpan data kekerapan ke dalam state
        });
      }
      print("✅ J.A.R.V.I.S: Susunan frekuensi grid berjaya dikira! -> $_globalFrequencyMap");
    } catch (e) {
      print("🚨 J.A.R.V.I.S ERROR: Gagal bina susunan frekuensi -> $e");
    }
  }

  // =========================================================
  // 💾 J.A.R.V.I.S DATA LOGGER (VERSI AUTO-UPDATE LAST ACTIVE & GLOBAL ANALYTICS)
  // =========================================================
  Future<void> _logCommunicationToFirebase(String fullSentence, List<String> itemIds) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');

    if (user == null) {
      print("🚨 J.A.R.V.I.S: GAGAL! Caregiver belum login Firebase.");
      return;
    }
    if (patientId == null || patientId.isEmpty) {
      print("🚨 J.A.R.V.I.S: GAGAL! ID Pesakit KOSONG dalam memori fon!");
      print("💡 J.A.R.V.I.S: Menggunakan 'Override' sementara untuk ujian...");
      patientId = "nkRDAkCjRWVaC7biOZu7";
    }

    String mood = "Neutral";
    if (itemIds.any((id) => ['happy', 'yes', 'pray'].contains(id))) mood = "Positive";
    if (itemIds.any((id) => ['sad', 'angry', 'pain', 'dizzy', 'noisy'].contains(id))) mood = "Negative";

    try {
      // 1. Simpan log ayat (Untuk rekod peribadi pesakit/caregiver)
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(patientId)
          .collection('communication_logs')
          .add({
        'sentence': fullSentence,
        'items': itemIds,
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update Last Active
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(patientId)
          .update({
        'last_active': FieldValue.serverTimestamp(),
      });

      // =========================================================
      // 🔥 3. LITAR SUPERADMIN: HANTAR DATA KE GLOBAL ANALYTICS
      // =========================================================
      // Loop setiap pictogram yang ditekan dan tambah +1 kat table pusat
      for (String id in itemIds) {
        await FirebaseFirestore.instance
            .collection('global_analytics')
            .doc(id)
            .set({
          'pic_id': id,
          'total_usage': FieldValue.increment(1), // Auto tambah 1!
          'last_triggered': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // merge: true supaya tak padam data lama
      }

      print("✅ J.A.R.V.I.S: Data berjaya ditembak ke pangkalan peribadi & SuperAdmin!");

    } catch (e) {
      print("🚨 J.A.R.V.I.S ERROR: Tempatan terbakar masa nak save -> $e");
    }
  }

  Future<void> _speakAllItems() async {
    if (_selectedItems.isEmpty) return;

    String fullSentenceEn = _selectedItems.map((item) => item['en']).join(' ');
    List<String> itemIds = _selectedItems.map((item) => item['id'] as String).toList();

    await _ttsService.stop();
    await _applyStoredSettings();
    await _ttsService.speak(fullSentenceEn, lang: "en-US");

    await _logCommunicationToFirebase(fullSentenceEn, itemIds);
  }

  void _initStaticDatabase() {
    _staticData = [
      // 1. MAIN MENU (LUARAN)
      {'id': 'yes', 'folder': null, 'en': 'YES', 'ms': 'Ya', 'image': 'assets/Pictogram/yes.png', 'color': Colors.green.shade600, 'isFolder': false},
      {'id': 'no', 'folder': null, 'en': 'NO', 'ms': 'Tidak', 'image': 'assets/Pictogram/no.png', 'color': Colors.red.shade600, 'isFolder': false},
      {'id': 'pain', 'folder': null, 'en': 'Pain', 'ms': 'Sakit', 'image': 'assets/Pictogram/pain.png', 'color': const Color(0xFFF43F5E), 'isFolder': false},
      {'id': 'toilet', 'folder': null, 'en': 'Toilet', 'ms': 'Tandas', 'image': 'assets/Pictogram/toilet.png', 'color': Colors.orange, 'isFolder': false},

      // 🚀 J.A.R.V.I.S: SOS DAH TUKAR JADI HELP BIASA
      {'id': 'help', 'folder': null, 'en': 'Help', 'ms': 'Tolong', 'image': 'assets/Pictogram/SOS.png', 'color': Colors.amber.shade700, 'isFolder': false},

      // FOLDER UTAMA DI MAIN MENU
      {'id': 'health', 'folder': null, 'en': 'Health', 'ms': 'Kesihatan', 'image': 'assets/Pictogram/Health/medicine.png', 'color': Colors.purple.shade400, 'isFolder': true},
      {'id': 'body', 'folder': null, 'en': 'Body & Comfort', 'ms': 'Selesa', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'color': Colors.teal.shade400, 'isFolder': true},
      {'id': 'food_drinks', 'folder': null, 'en': 'Food & Drinks', 'ms': 'Makan Minum', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'color': Colors.blue.shade400, 'isFolder': true},
      {'id': 'feelings', 'folder': null, 'en': 'Feelings', 'ms': 'Emosi', 'image': 'assets/Pictogram/Feelings/happy.png', 'color': Colors.pink.shade300, 'isFolder': true},
      {'id': 'hygiene', 'folder': null, 'en': 'Hygiene', 'ms': 'Kebersihan', 'image': 'assets/Pictogram/Hygiene/shower.png', 'color': Colors.cyan.shade400, 'isFolder': true},
      {'id': 'environment', 'folder': null, 'en': 'Environment', 'ms': 'Sekeliling', 'image': 'assets/Pictogram/Environment/light.png', 'color': Colors.indigo.shade400, 'isFolder': true},
      {'id': 'rehab', 'folder': null, 'en': 'Lifestyle', 'ms': 'Gaya Hidup', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'color': Colors.lime.shade600, 'isFolder': true},
      {'id': 'number', 'folder': null, 'en': 'Numbers', 'ms': 'Nombor', 'image': 'assets/Pictogram/Number/one.png', 'color': Colors.brown.shade400, 'isFolder': true},

      // 2. KESIHATAN & FIZIKAL
      {'id': 'medicine', 'folder': 'health', 'en': 'Medicine', 'ms': 'Ubat', 'image': 'assets/Pictogram/Health/medicine.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'dizzy', 'folder': 'health', 'en': 'Dizzy', 'ms': 'Pening', 'image': 'assets/Pictogram/Health/feel dizzy.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'breathe', 'folder': 'health', 'en': 'Breathe', 'ms': 'Susah Nafas', 'image': 'assets/Pictogram/Health/breathe.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'itchy', 'folder': 'health', 'en': 'Itchy', 'ms': 'Gatal', 'image': 'assets/Pictogram/Health/itch.png', 'color': Colors.purple.shade400, 'isFolder': false},
      {'id': 'tired', 'folder': 'health', 'en': 'Tired', 'ms': 'Penat', 'image': 'assets/Pictogram/Health/tired.png', 'color': Colors.purple.shade400, 'isFolder': false},

      // 3. POSISI & KESELESAAN
      {'id': 'sit', 'folder': 'body', 'en': 'Sit Up', 'ms': 'Duduk', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'lie', 'folder': 'body', 'en': 'Lie Down', 'ms': 'Baring', 'image': 'assets/Pictogram/Body and Comfort/lie down.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'turn', 'folder': 'body', 'en': 'Turn Me', 'ms': 'Pusing Badan', 'image': 'assets/Pictogram/Body and Comfort/turn.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'cold', 'folder': 'body', 'en': 'Cold', 'ms': 'Sejuk', 'image': 'assets/Pictogram/Body and Comfort/cold.png', 'color': Colors.teal.shade400, 'isFolder': false},
      {'id': 'hot', 'folder': 'body', 'en': 'Hot', 'ms': 'Panas', 'image': 'assets/Pictogram/Body and Comfort/be hot.png', 'color': Colors.teal.shade400, 'isFolder': false},

      // 4. MAKAN & MINUM
      {'id': 'water', 'folder': 'food_drinks', 'en': 'Water', 'ms': 'Air Kosong', 'image': 'assets/Pictogram/food_drinks/water.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'hungry', 'folder': 'food_drinks', 'en': 'Hungry', 'ms': 'Lapar', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'porridge', 'folder': 'food_drinks', 'en': 'Porridge', 'ms': 'Bubur', 'image': 'assets/Pictogram/food_drinks/bowl.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'coffee', 'folder': 'food_drinks', 'en': 'Coffee', 'ms': 'Kopi', 'image': 'assets/Pictogram/food_drinks/coffee.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'tea', 'folder': 'food_drinks', 'en': 'Tea', 'ms': 'Teh', 'image': 'assets/Pictogram/food_drinks/tea.png', 'color': Colors.blue.shade400, 'isFolder': false},
      {'id': 'milk', 'folder': 'food_drinks', 'en': 'Milk', 'ms': 'Susu', 'image': 'assets/Pictogram/food_drinks/milk.png', 'color': Colors.blue.shade400, 'isFolder': false},

      // 5. EMOSI & SOSIAL
      {'id': 'happy', 'folder': 'feelings', 'en': 'Happy', 'ms': 'Gembira', 'image': 'assets/Pictogram/Feelings/happy.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'sad', 'folder': 'feelings', 'en': 'Sad', 'ms': 'Sedih', 'image': 'assets/Pictogram/Feelings/sad.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'angry', 'folder': 'feelings', 'en': 'Angry', 'ms': 'Marah', 'image': 'assets/Pictogram/Feelings/angry.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'family', 'folder': 'feelings', 'en': 'Family', 'ms': 'Keluarga', 'image': 'assets/Pictogram/Feelings/family.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'quiet', 'folder': 'feelings', 'en': 'Quiet', 'ms': 'Senyap', 'image': 'assets/Pictogram/Feelings/quiet.png', 'color': Colors.pink.shade300, 'isFolder': false},
      {'id': 'rest', 'folder': 'feelings', 'en': 'Rest', 'ms': 'Nak Rehat', 'image': 'assets/Pictogram/Feelings/rest.png', 'color': Colors.pink.shade300, 'isFolder': false},

      // 6. KEBERSIHAN DIRI
      {'id': 'diaper', 'folder': 'hygiene', 'en': 'Diaper', 'ms': 'Tukar Lampin', 'image': 'assets/Pictogram/Hygiene/diaper.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'shower', 'folder': 'hygiene', 'en': 'Shower', 'ms': 'Mandi / Lap', 'image': 'assets/Pictogram/Hygiene/shower.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'clothes', 'folder': 'hygiene', 'en': 'Change Clothes', 'ms': 'Tukar Baju', 'image': 'assets/Pictogram/Hygiene/clothes.png', 'color': Colors.cyan.shade400, 'isFolder': false},
      {'id': 'brush', 'folder': 'hygiene', 'en': 'Brush Teeth', 'ms': 'Berus Gigi', 'image': 'assets/Pictogram/Hygiene/brush teeth.png', 'color': Colors.cyan.shade400, 'isFolder': false},

      // 7. KAWALAN BILIK
      {'id': 'light', 'folder': 'environment', 'en': 'Light', 'ms': 'Lampu', 'image': 'assets/Pictogram/Environment/light.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'fan', 'folder': 'environment', 'en': 'Fan/AC', 'ms': 'Kipas', 'image': 'assets/Pictogram/Environment/fan.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'noisy', 'folder': 'environment', 'en': 'Noisy', 'ms': 'Bising', 'image': 'assets/Pictogram/Environment/noisy.png', 'color': Colors.indigo.shade400, 'isFolder': false},
      {'id': 'window', 'folder': 'environment', 'en': 'Window', 'ms': 'Tingkap', 'image': 'assets/Pictogram/Environment/open the window.png', 'color': Colors.indigo.shade400, 'isFolder': false},

      // 8. LIFESTYLE & REHAB
      {'id': 'physio', 'folder': 'rehab', 'en': 'Physio', 'ms': 'Senaman', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'pray', 'folder': 'rehab', 'en': 'Pray', 'ms': 'Solat', 'image': 'assets/Pictogram/Lifestyle and Rehab/pray.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'bored', 'folder': 'rehab', 'en': 'Bored/TV', 'ms': 'Bosan / TV', 'image': 'assets/Pictogram/Lifestyle and Rehab/bored.png', 'color': Colors.lime.shade600, 'isFolder': false},
      {'id': 'phone', 'folder': 'rehab', 'en': 'Phone', 'ms': 'Telefon', 'image': 'assets/Pictogram/Lifestyle and Rehab/phone.png', 'color': Colors.lime.shade600, 'isFolder': false},

      // 9. NOMBOR
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

      // TAMBAHAN
      {'id': 'done', 'folder': null, 'en': 'Done', 'ms': 'Selesai', 'image': 'assets/Pictogram/yes.png', 'color': Colors.grey, 'isFolder': false},
      {'id': 'hospital', 'folder': null, 'en': 'Hospital', 'ms': 'Hospital', 'image': 'assets/Pictogram/SOS.png', 'color': Colors.red, 'isFolder': false},
    ];
    _mergedData = List.from(_staticData);
  }

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
        if (parent != null && parent.isNotEmpty) subFoldersFound.add("$cat|$parent");
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

  // =========================================================
  // 🎯 LITAR SUSUNAN DYNAMIC GRID (VERSI KUASA ANAK-BAPAK)
  // =========================================================

  // Fungsi khas untuk kira frekuensi (Bapak sedut markah anak)
  int _calculateItemFrequency(Map<String, dynamic> item) {
    bool isFolder = item['isFolder'] ?? false;
    String id = item['id'] ?? '';

    if (!isFolder) {
      // Kalau ni gambar biasa (Tired, Yes, No) -> Ambil direct dari rekod
      return _globalFrequencyMap[id] ?? 0;
    } else {
      // Kalau ni FOLDER (Health, Body) -> Campurkan semua markah anak-anak dia
      int totalFolderFreq = 0;
      var children = _mergedData.where((child) => child['folder'] == id);
      for (var child in children) {
        totalFolderFreq += (_globalFrequencyMap[child['id']] ?? 0);
      }
      return totalFolderFreq; // Pulangkan markah hasil gabungan
    }
  }

  List<Map<String, dynamic>> get _currentDisplayItems {
    // 1. Ambil list item yang sepadan dengan folder semasa
    List<Map<String, dynamic>> itemsInFolder = _mergedData.where((item) => item['folder'] == _currentFolder).toList();

    // 2. Susun item guna enjin pengiraan baru
    itemsInFolder.sort((a, b) {
      int freqA = _calculateItemFrequency(a);
      int freqB = _calculateItemFrequency(b);

      // Susun secara menurun (Yang markah tinggi, tamak duduk atas!)
      return freqB.compareTo(freqA);
    });

    return itemsInFolder;
  }

  void _removeItem(int index) => setState(() => _selectedItems.removeAt(index));
  void _removeLastItem() { if (_selectedItems.isNotEmpty) setState(() => _selectedItems.removeLast()); }
  void _clearAllItems() => setState(() => _selectedItems.clear());

  // =========================================================
  // 🚨 J.A.R.V.I.S: PROTOKOL KECEMASAN (TEMBAK KE AWAN)
  // =========================================================
  Future<void> _triggerSOS() async {
    final user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? patientId = prefs.getString('patient_id');
    String patientName = prefs.getString('patient_name') ?? "Pesakit Tanpa Nama";

    if (user != null && patientId != null) {
      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'caregiver_id': user.uid,
        'patient_id': patientId,
        'patient_name': patientName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'ACTIVE',
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

    List<Map<String, dynamic>> aiSuggestions = _currentRecommendations;

    return Scaffold(
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

            if (aiSuggestions.isNotEmpty)
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border(bottom: BorderSide(color: Colors.amber.shade200, width: 2))
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(Icons.auto_awesome, color: Colors.amber),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: aiSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = aiSuggestions[index];
                          return InkWell(
                            onTap: () async {
                              setState(() => _selectedItems.add(suggestion));

                              await _ttsService.stop();
                              await _applyStoredSettings();
                              await _ttsService.speak(suggestion['en'], lang: "en-US");
                              await _logCommunicationToFirebase(suggestion['en'], [suggestion['id']]);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(height: 30, width: 30, child: _renderImage(suggestion)),
                                  const SizedBox(width: 8),
                                  Text(suggestion['en'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _isLoadingFirebase
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

      // 🚀 J.A.R.V.I.S: BUTANG KECEMASAN TERAPUNG (SENTIASA ADA)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.red.shade50,
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text("PANGGIL BANTUAN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text("Adakah anda perlukan bantuan kecemasan sekarang?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("BATAL", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _triggerSOS(); // Tembak litar SOS!
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("YA, TOLONG SAYA!", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.red.shade600,
        elevation: 6,
        icon: const Icon(Icons.sos_rounded, color: Colors.white, size: 30),
        label: const Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
          // 🚀 J.A.R.V.I.S: Litar SOS dari grid dah DIBUANG sepenuhnya!
        } else {
          setState(() => _selectedItems.add(item));
          await _ttsService.stop();

          await _applyStoredSettings();
          await _ttsService.speak(item['en'], lang: "en-US");

          await _logCommunicationToFirebase(item['en'], [item['id']]);
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
                  Text(item['en'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: _useLargeTargets ? 16 : 13, color: AppTheme.textDark), maxLines: 1),
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