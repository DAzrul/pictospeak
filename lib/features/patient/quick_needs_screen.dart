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

  final Map<String, List<String>> _predictionMap = {
    'yes': ['happy', 'done'],
    'no': ['sad', 'angry', 'pain'],
    'pain': ['medicine', 'rest', 'dizzy', 'hospital', 'help'],
    'toilet': ['water', 'diaper', 'shower', 'done'],
    'help': ['breathe', 'pain', 'hospital', 'family', 'dizzy'],
    'medicine': ['water', 'rest', 'done'],
    'dizzy': ['lie', 'rest', 'medicine', 'water'],
    'breathe': ['rest', 'help', 'hospital', 'fan'],
    'itchy': ['shower', 'medicine', 'clothes'],
    'tired': ['rest', 'lie', 'water', 'quiet'],
    'sit': ['water', 'bored', 'phone', 'family'],
    'lie': ['rest', 'tired', 'cold', 'hot', 'quiet'],
    'turn': ['pain', 'rest', 'lie'],
    'cold': ['clothes', 'window', 'tea', 'turn'],
    'hot': ['fan', 'water', 'shower', 'window', 'clothes'],
    'water': ['done', 'happy', 'toilet'],
    'hungry': ['porridge', 'milk', 'water', 'done'],
    'porridge': ['water', 'done', 'happy'],
    'coffee': ['water', 'done'],
    'tea': ['water', 'done'],
    'milk': ['water', 'done', 'rest'],
    'happy': ['family', 'phone', 'done'],
    'sad': ['family', 'rest', 'pray', 'quiet'],
    'angry': ['quiet', 'rest', 'breathe', 'noisy'],
    'family': ['happy', 'phone', 'pray'],
    'quiet': ['rest', 'lie', 'breathe'],
    'rest': ['quiet', 'lie', 'fan', 'light'],
    'diaper': ['shower', 'clothes', 'done'],
    'shower': ['clothes', 'cold', 'done'],
    'clothes': ['cold', 'hot', 'done'],
    'brush': ['water', 'done'],
    'light': ['rest', 'lie', 'bored'],
    'fan': ['hot', 'cold', 'rest', 'window'],
    'noisy': ['quiet', 'angry', 'sad', 'window'],
    'window': ['hot', 'cold', 'fan', 'light'],
    'physio': ['tired', 'pain', 'water', 'rest'],
    'pray': ['quiet', 'clothes', 'water'],
    'bored': ['phone', 'family', 'sit'],
    'phone': ['family', 'happy', 'bored'],
    'num0': ['done'], 'num1': ['done'], 'num2': ['done'],
    'num3': ['done'], 'num4': ['done'], 'num5': ['done'],
    'num6': ['done'], 'num7': ['done'], 'num8': ['done'], 'num9': ['done'],
    'done': ['happy', 'rest'],
    'hospital': ['help', 'family', 'pain'],
  };

  Map<String, Map<String, int>> _personalizedPredictions = {};

  List<Map<String, dynamic>> get _currentRecommendations {
    if (_selectedItems.isEmpty) return [];

    String lastItemId = _selectedItems.last['id'];
    List<String> predictedIds = [];

    if (_personalizedPredictions.containsKey(lastItemId)) {
      var nextWordsMap = _personalizedPredictions[lastItemId]!;
      var sortedWords = nextWordsMap.keys.toList()
        ..sort((a, b) => nextWordsMap[b]!.compareTo(nextWordsMap[a]!));
      predictedIds = sortedWords.take(4).toList();
    }

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

  Future<void> _buildPersonalizedBrain() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');

    if (user == null || patientId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(patientId)
          .collection('communication_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      Map<String, Map<String, int>> tempBrain = {};
      Map<String, int> tempFrequency = {};

      for (var doc in querySnapshot.docs) {
        List<dynamic> items = doc.data()['items'] ?? [];

        for (int i = 0; i < items.length; i++) {
          String currentWord = items[i].toString();
          tempFrequency[currentWord] = (tempFrequency[currentWord] ?? 0) + 1;

          if (i < items.length - 1) {
            String nextWord = items[i + 1].toString();
            if (!tempBrain.containsKey(currentWord)) tempBrain[currentWord] = {};
            tempBrain[currentWord]![nextWord] = (tempBrain[currentWord]![nextWord] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _personalizedPredictions = tempBrain;
          _globalFrequencyMap = tempFrequency;
        });
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S ERROR: Gagal bina susunan frekuensi -> $e");
    }
  }

  Future<void> _logCommunicationToFirebase(String fullSentence, List<String> itemIds) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');

    if (user == null) return;
    if (patientId == null || patientId.isEmpty) patientId = "nkRDAkCjRWVaC7biOZu7"; // Override fallback

    String mood = "Neutral";
    if (itemIds.any((id) => ['happy', 'yes', 'pray'].contains(id))) mood = "Positive";
    if (itemIds.any((id) => ['sad', 'angry', 'pain', 'dizzy', 'noisy'].contains(id))) mood = "Negative";

    try {
      // 1. Simpan Sejarah Ayat Penuh (Sedia ada)
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

      // 2. COP PESAKIT AKTIF - last_active (Sedia ada)
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(patientId)
          .update({'last_active': FieldValue.serverTimestamp()});

      // 🚀 LOOP UNTUK SETIAP PIKTOGRAM YANG DITEKAN
      for (String id in itemIds) {

        // 3. UPDATE PAPAN MARKAH - global_analytics (Sedia ada)
        await FirebaseFirestore.instance
            .collection('global_analytics')
            .doc(id)
            .set({
          'pic_id': id,
          'total_usage': FieldValue.increment(1),
          'last_triggered': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4. 🚀 LITAR BARU: TULIS BUKU SEJARAH - usage_logs 🚀
        // Ini yang Admin Dashboard kau nak sedut untuk kira Trend Bulanan!
        await FirebaseFirestore.instance.collection('usage_logs').add({
          'pic_id': id,
          'patient_uid': patientId,
          'caregiver_uid': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

      }

      debugPrint("✅ J.A.R.V.I.S: Telemetry untuk [$fullSentence] berjaya ditembak ke semua pangkalan data!");

    } catch (e) {
      debugPrint("🚨 J.A.R.V.I.S ERROR: Tempatan terbakar masa nak save -> $e");
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
    // 🚀 LITAR BARU: Tambah 'source': 'static' untuk semua data asal
    List<Map<String, dynamic>> rawStatic = [
      {'id': 'yes', 'folder': null, 'en': 'YES', 'ms': 'Ya', 'image': 'assets/Pictogram/yes.png', 'isFolder': false},
      {'id': 'no', 'folder': null, 'en': 'NO', 'ms': 'Tidak', 'image': 'assets/Pictogram/no.png', 'isFolder': false},
      {'id': 'pain', 'folder': null, 'en': 'Pain', 'ms': 'Sakit', 'image': 'assets/Pictogram/pain.png', 'isFolder': false},
      {'id': 'toilet', 'folder': null, 'en': 'Toilet', 'ms': 'Tandas', 'image': 'assets/Pictogram/toilet.png', 'isFolder': false},
      {'id': 'help', 'folder': null, 'en': 'Help', 'ms': 'Tolong', 'image': 'assets/Pictogram/SOS.png', 'isFolder': false},

      {'id': 'health', 'folder': null, 'en': 'Health', 'ms': 'Kesihatan', 'image': 'assets/Pictogram/Health/medicine.png', 'isFolder': true},
      {'id': 'body', 'folder': null, 'en': 'Body & Comfort', 'ms': 'Selesa', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'isFolder': true},
      {'id': 'food_drinks', 'folder': null, 'en': 'Food & Drinks', 'ms': 'Makan Minum', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'isFolder': true},
      {'id': 'feelings', 'folder': null, 'en': 'Feelings', 'ms': 'Emosi', 'image': 'assets/Pictogram/Feelings/happy.png', 'isFolder': true},
      {'id': 'hygiene', 'folder': null, 'en': 'Hygiene', 'ms': 'Kebersihan', 'image': 'assets/Pictogram/Hygiene/shower.png', 'isFolder': true},
      {'id': 'environment', 'folder': null, 'en': 'Environment', 'ms': 'Sekeliling', 'image': 'assets/Pictogram/Environment/light.png', 'isFolder': true},
      {'id': 'rehab', 'folder': null, 'en': 'Lifestyle', 'ms': 'Gaya Hidup', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'isFolder': true},
      {'id': 'number', 'folder': null, 'en': 'Numbers', 'ms': 'Nombor', 'image': 'assets/Pictogram/Number/one.png', 'isFolder': true},

      {'id': 'medicine', 'folder': 'health', 'en': 'Medicine', 'ms': 'Ubat', 'image': 'assets/Pictogram/Health/medicine.png', 'isFolder': false},
      {'id': 'dizzy', 'folder': 'health', 'en': 'Dizzy', 'ms': 'Pening', 'image': 'assets/Pictogram/Health/feel dizzy.png', 'isFolder': false},
      {'id': 'breathe', 'folder': 'health', 'en': 'Breathe', 'ms': 'Susah Nafas', 'image': 'assets/Pictogram/Health/breathe.png', 'isFolder': false},
      {'id': 'itchy', 'folder': 'health', 'en': 'Itchy', 'ms': 'Gatal', 'image': 'assets/Pictogram/Health/itch.png', 'isFolder': false},
      {'id': 'tired', 'folder': 'health', 'en': 'Tired', 'ms': 'Penat', 'image': 'assets/Pictogram/Health/tired.png', 'isFolder': false},
      {'id': 'sit', 'folder': 'body', 'en': 'Sit Up', 'ms': 'Duduk', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'isFolder': false},
      {'id': 'lie', 'folder': 'body', 'en': 'Lie Down', 'ms': 'Baring', 'image': 'assets/Pictogram/Body and Comfort/lie down.png', 'isFolder': false},
      {'id': 'turn', 'folder': 'body', 'en': 'Turn Me', 'ms': 'Pusing Badan', 'image': 'assets/Pictogram/Body and Comfort/turn.png', 'isFolder': false},
      {'id': 'cold', 'folder': 'body', 'en': 'Cold', 'ms': 'Sejuk', 'image': 'assets/Pictogram/Body and Comfort/cold.png', 'isFolder': false},
      {'id': 'hot', 'folder': 'body', 'en': 'Hot', 'ms': 'Panas', 'image': 'assets/Pictogram/Body and Comfort/be hot.png', 'isFolder': false},
      {'id': 'water', 'folder': 'food_drinks', 'en': 'Water', 'ms': 'Air Kosong', 'image': 'assets/Pictogram/food_drinks/water.png', 'isFolder': false},
      {'id': 'hungry', 'folder': 'food_drinks', 'en': 'Hungry', 'ms': 'Lapar', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'isFolder': false},
      {'id': 'porridge', 'folder': 'food_drinks', 'en': 'Porridge', 'ms': 'Bubur', 'image': 'assets/Pictogram/food_drinks/bowl.png', 'isFolder': false},
      {'id': 'coffee', 'folder': 'food_drinks', 'en': 'Coffee', 'ms': 'Kopi', 'image': 'assets/Pictogram/food_drinks/coffee.png', 'isFolder': false},
      {'id': 'tea', 'folder': 'food_drinks', 'en': 'Tea', 'ms': 'Teh', 'image': 'assets/Pictogram/food_drinks/tea.png', 'isFolder': false},
      {'id': 'milk', 'folder': 'food_drinks', 'en': 'Milk', 'ms': 'Susu', 'image': 'assets/Pictogram/food_drinks/milk.png', 'isFolder': false},
      {'id': 'happy', 'folder': 'feelings', 'en': 'Happy', 'ms': 'Gembira', 'image': 'assets/Pictogram/Feelings/happy.png', 'isFolder': false},
      {'id': 'sad', 'folder': 'feelings', 'en': 'Sad', 'ms': 'Sedih', 'image': 'assets/Pictogram/Feelings/sad.png', 'isFolder': false},
      {'id': 'angry', 'folder': 'feelings', 'en': 'Angry', 'ms': 'Marah', 'image': 'assets/Pictogram/Feelings/angry.png', 'isFolder': false},
      {'id': 'family', 'folder': 'feelings', 'en': 'Family', 'ms': 'Keluarga', 'image': 'assets/Pictogram/Feelings/family.png', 'isFolder': false},
      {'id': 'quiet', 'folder': 'feelings', 'en': 'Quiet', 'ms': 'Senyap', 'image': 'assets/Pictogram/Feelings/quiet.png', 'isFolder': false},
      {'id': 'rest', 'folder': 'feelings', 'en': 'Rest', 'ms': 'Nak Rehat', 'image': 'assets/Pictogram/Feelings/rest.png', 'isFolder': false},
      {'id': 'diaper', 'folder': 'hygiene', 'en': 'Diaper', 'ms': 'Tukar Lampin', 'image': 'assets/Pictogram/Hygiene/diaper.png', 'isFolder': false},
      {'id': 'shower', 'folder': 'hygiene', 'en': 'Shower', 'ms': 'Mandi / Lap', 'image': 'assets/Pictogram/Hygiene/shower.png', 'isFolder': false},
      {'id': 'clothes', 'folder': 'hygiene', 'en': 'Change Clothes', 'ms': 'Tukar Baju', 'image': 'assets/Pictogram/Hygiene/clothes.png', 'isFolder': false},
      {'id': 'brush', 'folder': 'hygiene', 'en': 'Brush Teeth', 'ms': 'Berus Gigi', 'image': 'assets/Pictogram/Hygiene/brush teeth.png', 'isFolder': false},
      {'id': 'light', 'folder': 'environment', 'en': 'Light', 'ms': 'Lampu', 'image': 'assets/Pictogram/Environment/light.png', 'isFolder': false},
      {'id': 'fan', 'folder': 'environment', 'en': 'Fan/AC', 'ms': 'Kipas', 'image': 'assets/Pictogram/Environment/fan.png', 'isFolder': false},
      {'id': 'noisy', 'folder': 'environment', 'en': 'Noisy', 'ms': 'Bising', 'image': 'assets/Pictogram/Environment/noisy.png', 'isFolder': false},
      {'id': 'window', 'folder': 'environment', 'en': 'Window', 'ms': 'Tingkap', 'image': 'assets/Pictogram/Environment/open the window.png', 'isFolder': false},
      {'id': 'physio', 'folder': 'rehab', 'en': 'Physio', 'ms': 'Senaman', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'isFolder': false},
      {'id': 'pray', 'folder': 'rehab', 'en': 'Pray', 'ms': 'Solat', 'image': 'assets/Pictogram/Lifestyle and Rehab/pray.png', 'isFolder': false},
      {'id': 'bored', 'folder': 'rehab', 'en': 'Bored/TV', 'ms': 'Bosan / TV', 'image': 'assets/Pictogram/Lifestyle and Rehab/bored.png', 'isFolder': false},
      {'id': 'phone', 'folder': 'rehab', 'en': 'Phone', 'ms': 'Telefon', 'image': 'assets/Pictogram/Lifestyle and Rehab/phone.png', 'isFolder': false},
      {'id': 'num0', 'folder': 'number', 'en': 'Zero', 'ms': 'Kosong', 'image': 'assets/Pictogram/Number/0.png', 'isFolder': false},
      {'id': 'num1', 'folder': 'number', 'en': 'One', 'ms': 'Satu', 'image': 'assets/Pictogram/Number/one.png', 'isFolder': false},
      {'id': 'num2', 'folder': 'number', 'en': 'Two', 'ms': 'Dua', 'image': 'assets/Pictogram/Number/2.png', 'isFolder': false},
      {'id': 'num3', 'folder': 'number', 'en': 'Three', 'ms': 'Tiga', 'image': 'assets/Pictogram/Number/3.png', 'isFolder': false},
      {'id': 'num4', 'folder': 'number', 'en': 'Four', 'ms': 'Empat', 'image': 'assets/Pictogram/Number/4.png', 'isFolder': false},
      {'id': 'num5', 'folder': 'number', 'en': 'Five', 'ms': 'Lima', 'image': 'assets/Pictogram/Number/5.png', 'isFolder': false},
      {'id': 'num6', 'folder': 'number', 'en': 'Six', 'ms': 'Enam', 'image': 'assets/Pictogram/Number/6.png', 'isFolder': false},
      {'id': 'num7', 'folder': 'number', 'en': 'Seven', 'ms': 'Tujuh', 'image': 'assets/Pictogram/Number/7.png', 'isFolder': false},
      {'id': 'num8', 'folder': 'number', 'en': 'Eight', 'ms': 'Lapan', 'image': 'assets/Pictogram/Number/8.png', 'isFolder': false},
      {'id': 'num9', 'folder': 'number', 'en': 'Nine', 'ms': 'Sembilan', 'image': 'assets/Pictogram/Number/9.png', 'isFolder': false},
      {'id': 'done', 'folder': null, 'en': 'Done', 'ms': 'Selesai', 'image': 'assets/Pictogram/yes.png', 'isFolder': false},
      {'id': 'hospital', 'folder': null, 'en': 'Hospital', 'ms': 'Tolong', 'image': 'assets/Pictogram/hospital.png', 'isFolder': false},
    ];

    _staticData = rawStatic.map((item) {
      item['source'] = 'static'; // 🚀 Tag statik
      return item;
    }).toList();
    _mergedData = List.from(_staticData);
  }

  Future<void> _syncWithFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isLoadingFirebase = false); return; }

    List<Map<String, dynamic>> globalItems = [];
    Map<String, String> dynamicFolderSources = {}; // 🚀 Jejaki asal usul folder

    try {
      final globalSnap = await FirebaseFirestore.instance.collection('global_pictograms').get();
      for (var doc in globalSnap.docs) {
        final data = doc.data();
        String cat = data['category'] ?? 'uncategorized';
        String? parent = data['parent_folder'];

        globalItems.add({
          'id': data['pic_id'],
          'folder': cat,
          'category': cat,
          'parent_folder': parent,
          'en': data['label_en'],
          'ms': data['label_ms'],
          'image': data['image_url'],
          'isFolder': false,
          'isNetwork': true,
          'source': 'global', // 🚀 Tag Global
        });

        if (parent != null && parent.isNotEmpty) {
          dynamicFolderSources["$cat|$parent"] = 'global';
        }
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S: Gagal sedut Global Dictionary -> $e");
    }

    FirebaseFirestore.instance
        .collection('caregivers').doc(user.uid).collection('custom_pictograms')
        .snapshots().listen((snapshot) {

      List<Map<String, dynamic>> customItems = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String cat = data['category'] ?? 'custom';
        String? parent = data['parent_folder'];

        customItems.add({
          'id': data['pic_id'],
          'folder': cat,
          'category': cat,
          'parent_folder': parent,
          'en': data['label_en'],
          'ms': data['label_ms'],
          'image': data['image_url'],
          'isFolder': false,
          'isNetwork': true,
          'source': 'custom', // 🚀 Tag Custom
        });

        if (parent != null && parent.isNotEmpty) {
          // Kalau folder tu diwujudkan oleh user, kita tag as custom
          // Walaupun nama dia sama dengan global, custom akan take-over visual dia
          dynamicFolderSources["$cat|$parent"] = 'custom';
        }
      }

      List<Map<String, dynamic>> dynamicFolders = [];
      for (var folderInfo in dynamicFolderSources.keys) {
        var parts = folderInfo.split('|');
        String sourceTag = dynamicFolderSources[folderInfo]!;

        dynamicFolders.add({
          'id': parts[0],
          'folder': parts[1],
          'en': parts[0].replaceAll('_', ' ').toUpperCase(),
          'ms': parts[0].replaceAll('_', ' ').toUpperCase(),
          'image': 'assets/Pictogram/Environment/light.png',
          'isFolder': true,
          'isNetwork': false,
          'source': sourceTag, // 🚀 Tag Folder
        });
      }

      if (mounted) {
        setState(() {
          _mergedData = [..._staticData, ...dynamicFolders, ...globalItems, ...customItems];
          _isLoadingFirebase = false;
        });
      }
    });
  }

  int _calculateItemFrequency(Map<String, dynamic> item) {
    bool isFolder = item['isFolder'] ?? false;
    String id = item['id'] ?? '';

    if (!isFolder) {
      return _globalFrequencyMap[id] ?? 0;
    } else {
      int totalFolderFreq = 0;
      var children = _mergedData.where((child) => child['folder'] == id);
      for (var child in children) {
        totalFolderFreq += (_globalFrequencyMap[child['id']] ?? 0);
      }
      return totalFolderFreq;
    }
  }

  List<Map<String, dynamic>> get _currentDisplayItems {
    List<Map<String, dynamic>> itemsInFolder = _mergedData.where((item) => item['folder'] == _currentFolder).toList();
    itemsInFolder.sort((a, b) {
      int freqA = _calculateItemFrequency(a);
      int freqB = _calculateItemFrequency(b);
      return freqB.compareTo(freqA);
    });
    return itemsInFolder;
  }

  void _removeItem(int index) => setState(() => _selectedItems.removeAt(index));
  void _removeLastItem() { if (_selectedItems.isNotEmpty) setState(() => _selectedItems.removeLast()); }
  void _clearAllItems() => setState(() => _selectedItems.clear());

  Future<void> _triggerSOS() async {
    final user = FirebaseAuth.instance.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? patientId = prefs.getString('patient_id');
    String patientName = prefs.getString('patient_name') ?? "Pesakit Tanpa Nama";

    if (user == null || patientId == null) return;

    try {
      await _ttsService.stop();
      await _ttsService.speak("Kecemasan! Saya perlukan bantuan!", lang: "ms-MY");

      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'caregiver_id': user.uid,
        'patient_id': patientId,
        'patient_name': patientName,
        'status': 'ACTIVE',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Bantuan Sedang Dipanggil!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S Error: SOS gagal -> $e");
    }
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
                    _triggerSOS();
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

  // =========================================================
  // 🎨 LITAR UI: SMART CARD DENGAN COLOR-CODING
  // =========================================================
  Widget _buildSmartCard(Map<String, dynamic> item) {
    bool isFolder = item['isFolder'] ?? false;
    String source = item['source'] ?? 'static'; // Tag yang kita buat tadi

    Color folderColor;
    Color itemBorderColor;
    IconData? sourceIcon;
    Color? sourceIconColor;

    // 🚀 LITAR PENENTUAN WARNA & BADGE
    if (source == 'global') {
      folderColor = Colors.indigo;
      itemBorderColor = Colors.indigo.shade300;
      sourceIcon = Icons.verified_rounded; // Badge Admin/Global
      sourceIconColor = Colors.indigo;
    } else if (source == 'custom') {
      folderColor = Colors.orange.shade700;
      itemBorderColor = Colors.orange.shade300;
      sourceIcon = Icons.person; // Badge User/Caregiver
      sourceIconColor = Colors.orange.shade700;
    } else {
      // 'static' atau Bawaan App
      folderColor = AppTheme.primaryBlue;
      itemBorderColor = Colors.grey.shade300;
    }

    Color borderColor = isFolder ? folderColor : itemBorderColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (isFolder) {
          setState(() {
            _folderHistory.add(item['id']);
            _currentFolder = item['id'];
          });
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

          // Folder Tab (Kiri Atas)
          if (isFolder)
            Positioned(
              top: 0, left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: folderColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                child: const Icon(Icons.folder_rounded, color: Colors.white, size: 14),
              ),
            ),

          // 🚀 Badge Tanda Pangkat (Kanan Atas) - Hanya untuk Global/Custom
          if (sourceIcon != null)
            Positioned(
              top: isFolder ? 18 : 6, right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: sourceIconColor!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(sourceIcon, size: 14, color: sourceIconColor),
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