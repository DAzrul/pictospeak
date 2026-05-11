import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 🚨 J.A.R.V.I.S: Import lintah & enjin utama
import 'package:pictospeak/core/services/local_db.dart';
import 'package:pictospeak/core/services/prediction_service.dart';
import 'package:pictospeak/core/services/tts_service.dart';
import 'package:pictospeak/core/services/ai_icon_service.dart';
import 'package:pictospeak/core/services/sync_service.dart';
import 'package:pictospeak/core/models/pictogram_model.dart';
import 'package:pictospeak/core/theme/app_theme.dart';

class SvoBuilderScreen extends StatefulWidget {
  const SvoBuilderScreen({super.key});

  @override
  State<SvoBuilderScreen> createState() => _SvoBuilderScreenState();
}

class _SvoBuilderScreenState extends State<SvoBuilderScreen> {
  final LocalDB _localDB = LocalDB();
  final PredictionService _predictionService = PredictionService();
  final TtsService _ttsService = TtsService();
  final AiIconService _aiService = AiIconService();

  List<Pictogram> selectedSentence = [];
  List<String> dynamicSuggestions = [];
  String _activeCategory = 'Subject';

  String _detectMood(List<Pictogram> sentence) {
    // 🚨 J.A.R.V.I.S: Scan kategori piktogram dlm ayat
    bool hasEmergency = sentence.any((p) => p.category == 'Emergency');
    bool hasPain = sentence.any((p) => p.labelEn.toLowerCase() == 'pain' || p.category == 'Hygiene');
    bool hasHappy = sentence.any((p) => p.labelEn.toLowerCase() == 'happy' || p.category == 'Play');

    if (hasEmergency || hasPain) {
      return "DISTRESSED"; // 🚨 Merah/Bahaya
    } else if (hasHappy) {
      return "GOOD";       // 😊 Hijau/Gembira
    } else {
      return "NEUTRAL";    // 😐 Biru/Biasa
    }
  }

  @override
  void initState() {
    super.initState();
    // 🚨 J.A.R.V.I.S: Tak payah panggil Firebase atau check SQLite dah.
    // Splash Screen dah siapkan semua data! Kita terus pecut je babi!
    _updateSuggestions();
  }

  // 🚨 PADAM TERUS fungsi _checkAndInitData() yang panjang tu. Tak guna dah!
  // 🚨 FUNGSI BARU: Cek memori sebelum buat keputusan
  Future<void> _checkAndInitData() async {
    // 1. Cek dulu, ada tak piktogram GLOBAL dlm SQLite?
    final existingData = await _localDB.getPictogramsByCategory('Subject');

    if (existingData.isEmpty) {
      print("J.A.R.V.I.S: Guest Mode dikesan. Sedang sedut piktogram GLOBAL...");

      if (mounted) setState(() => _activeCategory = 'Loading...'); // Kasih signal loading

      // 2. Paksa sedut dari Firebase (Rules Bilik 1 benarkan Guest baca GLOBAL)
      await SyncService().syncFromFirebase();

      print("J.A.R.V.I.S: Data GLOBAL dah mendarat dlm SQLite!");
    }

    if (mounted) {
      setState(() {
        _activeCategory = 'Subject'; // Set balik kategori lepas siap
      });
      _updateSuggestions();
    }
  }

  void _updateSuggestions() async {
    List<String> tagsToMatch = [];

    // Kalau dah ada ayat, ambil tags dari piktogram terakhir
    if (selectedSentence.isNotEmpty) {
      tagsToMatch = selectedSentence.last.tags;
    }

    // 🚨 J.A.R.V.I.S: Hantar List Tags, bukan String Label!
    List<String> suggestions = await _predictionService.getSuggestions(tagsToMatch, _activeCategory);

    if (mounted) {
      setState(() {
        dynamicSuggestions = suggestions;
      });
      // DEBUG: Tengok kat terminal keluar tak cadangan tu
      print("J.A.R.V.I.S: Cadangan baru dikesan -> $dynamicSuggestions");
    }
  }

  // --- 1. THE ULTIMATE KEYWORD-TO-ICON MAPPER ---
  dynamic _mapAiStringToIcon(String aiResult) {
    switch (aiResult.toLowerCase().trim()) {
    // Subjects
      case 'i': case 'me': case 'my': case 'myself': case 'person': return Icons.person;
      case 'you': case 'your': return Icons.person_outline;
      case 'we': case 'us': case 'our': return Icons.groups;
      case 'they': case 'them': return Icons.group_outlined;
      case 'mother': case 'mom': case 'woman': case 'female': return Icons.woman;
      case 'father': case 'dad': case 'man': case 'male': return Icons.man;
      case 'baby': case 'toddler': return Icons.child_care;
      case 'brother': case 'sister': case 'sibling': return Icons.child_friendly;
      case 'family': return Icons.family_restroom;
      case 'teacher': case 'school': case 'student': return Icons.school;
      case 'friend': return Icons.people_alt;
      case 'grandpa': case 'grandma': case 'elderly': return Icons.elderly;
      case 'uncle': case 'aunt': case 'cousin': return Icons.family_restroom;
      case 'husband': case 'wife': return Icons.family_restroom;
      case 'boyfriend': case 'girlfriend': return Icons.family_restroom;
      case 'son': case 'daughter': return Icons.family_restroom;
      case 'grandson': case 'granddaughter': return Icons.family_restroom;
      case 'grandfather': case 'grandmother': return Icons.family_restroom;

    // Verbs
      case 'want': case 'wish': case 'choose': return Icons.touch_app;
      case 'eat': case 'makan': case 'food': return Icons.restaurant;
      case 'drink': case 'minum': case 'coffee': case 'thirsty': return Icons.local_cafe;
      case 'sleep': case 'tired': case 'nap': return Icons.bed;
      case 'go': case 'walk': case 'move': return Icons.directions_walk;
      case 'run': case 'fast': return Icons.directions_run;
      case 'watch': case 'tv': case 'see': case 'look': return Icons.visibility;
      case 'listen': case 'hear': case 'music': return Icons.hearing;
      case 'shower': case 'bath': case 'wash': return Icons.shower;
      case 'play': case 'game': return Icons.sports_esports;
      case 'study': case 'read': case 'book': return Icons.menu_book;
      case 'work': case 'job': case 'office': return Icons.work;
      case 'help': case 'support': return Icons.help;
      case 'call': case 'talk': case 'chat': return Icons.chat;
      case 'open': return Icons.door_back_door;
      case 'close': return Icons.door_back_door;
      case 'stop': return Icons.stop_circle;
      case 'start': return Icons.play_circle_filled;
      case 'yeah': return Icons.check_circle;
      case 'yessir': return Icons.check_circle;
      case 'yep': return Icons.check_circle;
      case 'on': return Icons.power_settings_new;
      case 'off': return Icons.power_settings_new;

    // Objects
      case 'water': case 'liquid': return Icons.water_drop;
      case 'rice': return Icons.rice_bowl;
      case 'bread': return Icons.bakery_dining;
      case 'apple': return Icons.apple;
      case 'burger': return Icons.fastfood;
      case 'pizza': return Icons.local_pizza;
      case 'cake': return Icons.cake;
      case 'medicine': case 'pill': case 'drug': return Icons.medication;
      case 'toilet': case 'wc': case 'bathroom': return Icons.wc;
      case 'phone': case 'smartphone': case 'mobile': return Icons.smartphone;
      case 'money': case 'cash': case 'pay': return Icons.attach_money;
      case 'clothes': case 'shirt': return Icons.checkroom;
      case 'bag': case 'shopping': return Icons.shopping_bag;
      case 'home': case 'house': return Icons.home;
      case 'hospital': case 'clinic': return Icons.local_hospital;
      case 'toy': return Icons.toys;
      case 'car': case 'drive': return Icons.directions_car;
      case 'bus': return Icons.directions_bus;
      case 'bike': return Icons.directions_bike;
      case 'plane': return Icons.flight;
      case 'computer': case 'laptop': return Icons.computer;
      case 'key': return Icons.vpn_key;
      case 'door': return Icons.door_back_door;
      case 'chair': return Icons.chair;
      case 'table': return Icons.table_bar;

    // Adjectives (Feelings)
      case 'happy': case 'good': case 'smile': return Icons.sentiment_very_satisfied;
      case 'sad': case 'unhappy': case 'cry': return Icons.sentiment_very_dissatisfied;
      case 'angry': case 'mad': return Icons.mood_bad;
      case 'pain': case 'hurt': case 'injury': return Icons.personal_injury;
      case 'hungry': return Icons.restaurant_menu;
      case 'cold': case 'freeze': case 'ice': return Icons.ac_unit;
      case 'hot': case 'fire': case 'burn': return Icons.whatshot;
      case 'scared': case 'afraid': return Icons.psychology_alt;
      case 'bored': return Icons.sentiment_neutral;
      case 'loud': return Icons.volume_up;
      case 'quiet': return Icons.volume_off;

    // Emergency & Hygiene
      case 'danger': case 'warning': return Icons.warning_rounded;
      case 'police': return Icons.local_police;
      case 'ambulance': return Icons.emergency;
      case 'doctor': return Icons.medical_services;
      case 'nurse': return Icons.medical_information;
      case 'fever': case 'hot_body': return Icons.thermostat;
      case 'cough': case 'flu': case 'sick': return Icons.sick;
      case 'soap': return Icons.soap;
      case 'toothbrush': return Icons.clean_hands;
      case 'poop': return FontAwesomeIcons.poop;
      case 'pee': return Icons.water_drop_outlined;
      case 'blood': return Icons.bloodtype;

    // Time & Frequency
      case 'now': return Icons.access_time_filled;
      case 'later': return Icons.update;
      case 'always': return Icons.all_inclusive;
      case 'never': return Icons.block;
      case 'finish': return Icons.task_alt;
      case 'today': return Icons.today;
      case 'tomorrow': return Icons.event_note;
      case 'yesterday': return Icons.event_note;
      case 'next': return Icons.arrow_forward;
      case 'last': return Icons.arrow_back;
      case 'week': return Icons.calendar_view_week;
      case 'month': return Icons.calendar_month;
      case 'year': return Icons.calendar_today;
      case 'hour': return Icons.schedule;
      case 'minute': return Icons.schedule;
      case 'second': return Icons.schedule;
      case 'day': return Icons.calendar_today;
      case 'weekdays': return Icons.calendar_today;
      case 'weekends': return Icons.calendar_today;
      case 'morning': return Icons.wb_sunny;
      case 'afternoon': return Icons.wb_sunny;
      case 'evening': return Icons.wb_sunny;
      case 'night': return Icons.nights_stay;

    // Questions
      case 'what': return Icons.help_center;
      case 'where': return Icons.location_on;
      case 'who': return Icons.person_search;
      case 'why': return Icons.psychology_alt;
      case 'how': return Icons.question_mark;
      case 'when': return Icons.calendar_today;
      case 'is': return Icons.check_circle;
      case 'are': return Icons.check_circle;
      case 'was': return Icons.check_circle;
      case 'were': return Icons.check_circle;
      case 'have': return Icons.check_circle;
      case 'has': return Icons.check_circle;
      case 'had': return Icons.check_circle;
      case 'do': return Icons.check_circle;
      case 'does': return Icons.check_circle;
      case 'did': return Icons.check_circle;
      case 'can': return Icons.check_circle;
      case 'could': return Icons.check_circle;
      case 'will': return Icons.check_circle;
      case 'would': return Icons.check_circle;
      case 'should': return Icons.check_circle;
      case 'may': return Icons.check_circle;
      case 'might': return Icons.check_circle;
      case 'must': return Icons.check_circle;
      case 'need': return Icons.check_circle;
      case 'like': return Icons.check_circle;
      case 'love': return Icons.check_circle;
      case 'hate': return Icons.check_circle;
      case 'know': return Icons.check_circle;
      case 'think': return Icons.check_circle;
      case 'feel': return Icons.check_circle;

    // Others / DIRECTIONS & MISC
      case 'yes': case 'ok': case 'okay': case 'agree': return Icons.check_circle;
      case 'no': case 'disagree': case 'reject': return Icons.cancel;
      case 'up': case 'above': return Icons.arrow_upward;
      case 'down': case 'below': return Icons.arrow_downward;
      case 'left': return Icons.arrow_back;
      case 'right': return Icons.arrow_forward;
      case 'in': case 'inside': return Icons.login;
      case 'out': case 'outside': return Icons.logout;
      case 'more': return Icons.add_circle_outline;
      case 'less': return Icons.remove_circle_outline;

    // 9. ANIMALS (FONT AWESOME)
      case 'cat': return FontAwesomeIcons.cat;
      case 'dog': return FontAwesomeIcons.dog;
      case 'bird': return FontAwesomeIcons.dove;
      case 'fish': return FontAwesomeIcons.fish;
      case 'horse': return FontAwesomeIcons.horse;
      case 'cow': return FontAwesomeIcons.cow;
      case 'frog': return FontAwesomeIcons.frog;
      case 'spider': return FontAwesomeIcons.spider;

      default: return Icons.extension; // Puzzle fallback
    }
  }

  // --- 2. WARNA KATEGORI ---
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Subject': return Colors.blue;
      case 'Verb': return Colors.orange;
      case 'Object': return Colors.green;
      case 'Adjective': return Colors.purple;
      case 'Emergency': return Colors.red;
      case 'Hygiene': return Colors.teal;
      case 'Question': return Colors.indigo;
      case 'Time': return Colors.amber;
      default: return Colors.blueGrey;
    }
  }

  dynamic _getIconFromPic(Pictogram pic) {
    int? codePoint = int.tryParse(pic.imageUrl);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return _mapAiStringToIcon(pic.labelEn.toLowerCase());
  }

  // --- 2. RENDERER (Dah support gambar besar) ---
  Widget _renderSmartIcon(String imageUrl, double size, Color color, String label) {
    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, size: size, color: color),
        ),
      );
    }

    int? codePoint = int.tryParse(imageUrl);
    if (codePoint != null) {
      return Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: size, color: color);
    }

    dynamic iconData = _mapAiStringToIcon(imageUrl.isNotEmpty ? imageUrl : label);

    if (iconData == Icons.extension) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Center(
          child: Text(
            label.isNotEmpty ? label[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: size * 0.5),
          ),
        ),
      );
    }

    return iconData is IconData
        ? Icon(iconData, size: size, color: color)
        : FaIcon(iconData, size: size, color: color);
  }

  void _handleWordSelection(Pictogram pic) {
    setState(() {
      selectedSentence.add(pic);

      // 🚨 J.A.R.V.I.S: Protokol Aliran Minda (Multi-Category Auto-Jump)
      // Kita teka kategori seterusnya berdasarkan apa yang Azrul baru tekan.
      switch (pic.category) {
        case 'Question':
          _activeCategory = 'Subject'; // e.g. "Where" -> "I / You"
          break;
        case 'Subject':
          _activeCategory = 'Verb';    // e.g. "I" -> "Want / Eat"
          break;
        case 'Verb':
        // Lepas Verb selalunya Object (Makan Nasi)
        // tapi boleh jadi Adjective (Rasa Gembira)
          _activeCategory = 'Object';
          break;
        case 'Object':
          _activeCategory = 'Adjective'; // e.g. "Pizza" -> "Hot / Delicious"
          break;
        case 'Adjective':
          _activeCategory = 'Time';      // e.g. "Happy" -> "Now / Today"
          break;
        case 'Emergency':
        case 'Hygiene':
          _activeCategory = 'Verb';      // e.g. "Toilet" -> "Want / Go"
          break;
        case 'Time':
          _activeCategory = 'Others';    // e.g. "Now" -> "In House"
          break;
        default:
          _activeCategory = 'Object';    // Fallback kalau tak tahu nak pergi mana
      }
    });

    // 🚨 J.A.R.V.I.S: REKOD MEMORI (AI BELAJAR TABIAT)
    // Setiap kali klik, kita tambah frequency supaya AI tahu Azrul suka piktogram ni.
    _localDB.incrementFrequency(pic.id);

    // 🚨 UPDATE RAMALAN (BAR KUNING)
    _updateSuggestions();
  }

  // 🚨 J.A.R.V.I.S: Fungsi untuk tangkap perkataan bila user tekan cadangan AI
  void _addFromSuggestion(String labelEn) async {
    // Kita cari piktogram tu dalam database lokal (berdasarkan kategori aktif)
    final dataList = await _localDB.getPictogramsByCategory(_activeCategory);

    // Cari data yang sama nama dengan apa yang ditekan
    final match = dataList.firstWhere(
            (p) => (p['label_en'] ?? '').toString().toLowerCase() == labelEn.toLowerCase(),
        orElse: () => {}
    );

    if (match.isNotEmpty) {
      final pic = Pictogram(
        id: match['id'] ?? '',
        labelEn: match['label_en'] ?? '',
        labelMs: match['label_ms'] ?? '',
        category: match['category'] ?? 'Others',
        imageUrl: match['image_url'] ?? '',
        ownerId: match['ownerId'] ?? 'GLOBAL',
        // 🚨 J.A.R.V.I.S: Jangan lupa tags kat sini jugak!
        tags: match['tags'] != null
            ? match['tags'].toString().split(',').map((e) => e.trim()).toList()
            : [],
        createdAt: DateTime.now(),
      );
      _handleWordSelection(pic); // 👈 Tembak masuk dalam kotak Lego!
    } else {
      // Kalau tak jumpa dalam lokal (mungkin belum sync)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('J.A.R.V.I.S: Ikon $labelEn tiada dalam memori. Sila Sync di Library!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('SVO Builder', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSosBar(),

          // 1. Kotak Lego (Ayat yang sedang dibina)
          _buildLegoSvoDisplay(),

          // 🚨 J.A.R.V.I.S: PASANG HUD PREDICTIVE KAT SINI!
          // Benda ni akan muncul automatik bila ada cadangan
          _buildSuggestedWordsBar(),

          // 2. Tab Kategori (Subject, Verb, Object, dll)
          _buildCategoryTabs(),

          // 3. Grid Ikon (Pilihan Piktogram)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _localDB.getPictogramsByCategory(_activeCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final dataList = snapshot.data ?? [];

                  if (dataList.isEmpty) {
                    return Center(child: Text("Tiada data kategori $_activeCategory.\nSila Sync di Library.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)));
                  }

                  final pictograms = dataList.map((map) => Pictogram(
                    id: map['id'] ?? '',
                    labelEn: map['label_en'] ?? '',
                    labelMs: map['label_ms'] ?? '',
                    category: map['category'] ?? 'Others',
                    imageUrl: map['image_url'] ?? '',
                    ownerId: map['ownerId'] ?? 'GLOBAL',
                    // Ambil tags dari SQLite
                    tags: map['tags'] != null
                        ? map['tags'].toString().split(',').map((e) => e.trim()).toList()
                        : [],
                    createdAt: DateTime.now(),
                  )).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
                    ),
                    itemCount: pictograms.length,
                    itemBuilder: (context, index) => _buildLargeIconButton(pictograms[index]),
                  );
                },
              ),
            ),
          ),

          // 4. Butang Speak (Tukarkan ayat ke suara)
          _buildSpeakButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final List<String> categories = ['Subject', 'Verb', 'Object', 'Adjective', 'Emergency', 'Hygiene', 'Question', 'Time', 'Others'];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          String cat = categories[index];
          bool isActive = _activeCategory == cat;
          Color catColor = _getCategoryColor(cat);

          return GestureDetector(
            onTap: () {
              setState(() => _activeCategory = cat);
              _updateSuggestions();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? catColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isActive ? catColor : Colors.grey.shade300),
                boxShadow: isActive ? [BoxShadow(color: catColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Center(
                child: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? Colors.white : Colors.grey.shade600)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegoSvoDisplay() {
    int totalBoxes = selectedSentence.length >= 3 ? selectedSentence.length + 1 : 3;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 90,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(totalBoxes, (index) {
                    bool isFirst = index == 0;
                    bool isLast = index == totalBoxes - 1;
                    bool isFilled = index < selectedSentence.length;

                    String? val = isFilled ? selectedSentence[index].labelEn : null;
                    String title = index == 0 ? 'Subject' : index == 1 ? 'Verb' : index == 2 ? 'Object' : '...';

                    Color boxColor = isFilled
                        ? _getCategoryColor(selectedSentence[index].category).withValues(alpha: 0.2)
                        : Colors.white;
                    Color textColor = isFilled
                        ? _getCategoryColor(selectedSentence[index].category)
                        : Colors.grey.shade400;

                    return Transform.translate(
                      offset: Offset(isFirst ? 0 : index * -15.0, 0),
                      child: ClipPath(
                        clipper: PuzzleClipper(isFirst: isFirst, isLast: isLast),
                        child: Container(
                          width: 110, height: 85,
                          color: boxColor,
                          // Cari bahagian Row dalam _buildLegoSvoDisplay, ganti bahagian Text(val ?? title)
                          // Ganti Text tu dengan Column atau Stack supaya ada icon + text:

                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: isFilled
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 🚨 Tayang gambar/icon dalam lego!
                                  _renderSmartIcon(selectedSentence[index].imageUrl, 32, textColor, selectedSentence[index].labelEn),
                                  const SizedBox(height: 4),
                                  Text(val!, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 10), textAlign: TextAlign.center),
                                ],
                              )
                                  : Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          _buildUndoButton(),
        ],
      ),
    );
  }

  Widget _buildSosBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: ElevatedButton(
      onPressed: () async {
        await _ttsService.speak("Help me, please call my caregiver!", lang: "en-US");
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700], foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4, minimumSize: const Size(double.infinity, 50),
      ),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.warning_amber_rounded), SizedBox(width: 8),
        Text('SOS / CALL CAREGIVER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    ),
  );

  Widget _buildUndoButton() => Container(
    margin: const EdgeInsets.only(left: 8),
    child: IconButton(
      onPressed: () {
        if (selectedSentence.isNotEmpty) {
          setState(() {
            selectedSentence.removeLast();
            if (selectedSentence.isEmpty) _activeCategory = 'Subject';
            else if (selectedSentence.length == 1) _activeCategory = 'Verb';
            else _activeCategory = 'Object';
          });
          _updateSuggestions();
        }
      },
      icon: const Icon(Icons.undo_rounded, color: Colors.redAccent),
    ),
  );

  // 🚨 J.A.R.V.I.S: UI Predictive Tagging (Dah di-upgrade)
  Widget _buildSuggestedWordsBar() {
    if (dynamicSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dynamicSuggestions.length,
        itemBuilder: (context, index) {
          String labelEn = dynamicSuggestions[index].split(' / ')[0];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
              label: Text(labelEn, style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _addFromSuggestion(labelEn), // 👈 Fungsi baru
            ),
          );
        },
      ),
    );
  }

  // --- 4. GRID BUTTONS (VERSI XL) ---
  Widget _buildLargeIconButton(Pictogram pic) {
    Color catColor = _getCategoryColor(pic.category);
    return InkWell(
      onTap: () => _handleWordSelection(pic),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: catColor.withValues(alpha: 0.1), width: 3), // Border tebal sikit
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _renderSmartIcon(pic.imageUrl, 50, catColor, pic.labelEn), // 🚨 ICON BESAR! (Asal 36)
            const SizedBox(height: 12),
            Text(pic.labelEn,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
            Text(pic.labelMs,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakButton() => Container(
    padding: const EdgeInsets.all(20), color: Colors.white,
    child: Column(children: [
      SizedBox(
        width: double.infinity, height: 60,
        child: ElevatedButton.icon(
          onPressed: selectedSentence.isEmpty ? null : () async {
            String sentenceEn = selectedSentence.map((p) => p.labelEn).join(" ");
            String currentMood = _detectMood(selectedSentence);
            String? currentUid = FirebaseAuth.instance.currentUser?.uid;

            // 1. Suara bunyi (TTS)
            await _ttsService.speak(sentenceEn, lang: "en-US");

            // 2. 🚨 J.A.R.V.I.S: Hantar log ke Firebase untuk Dashboard Penjaga
            try {
              await FirebaseFirestore.instance.collection('usage_logs').add({
                'userId': currentUid ?? 'GUEST',
                'phrase': sentenceEn,
                'mood': currentMood,
                'timestamp': FieldValue.serverTimestamp(),
                'last_object': selectedSentence.last.labelEn, // Untuk graf "Most Frequent"
                'category_flow': selectedSentence.map((p) => p.category).toList(),
              });

              // 3. Simpan Local (Update frequency piktogram)
              for (var pic in selectedSentence) {
                await _localDB.incrementFrequency(pic.id);
              }

              print("J.A.R.V.I.S: Log dihantar. Mood: $currentMood");
            } catch (e) {
              print("Error hantar log babi: $e");
            }
          },
          icon: const Icon(Icons.volume_up, color: Colors.white),
          label: const Text('Speak Sentence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
          onPressed: () => setState(() { selectedSentence.clear(); _activeCategory = 'Subject'; _updateSuggestions(); }),
          child: const Text('Reset Builder', style: TextStyle(color: Colors.grey))
      ),
    ]),
  );
}

// 🧩 PUZZLE CLIPPER (Slightly Scaled)
class PuzzleClipper extends CustomClipper<Path> {
  final bool isFirst; final bool isLast;
  PuzzleClipper({this.isFirst = false, this.isLast = false});
  @override
  Path getClip(Size size) {
    final path = Path();
    final double tabWidth = 20.0; // 🚨 NAIK!
    final double tabHeight = 35.0; // 🚨 NAIK!
    final double radius = 15.0; // 🚨 NAIK!
    path.moveTo(radius, 0);
    path.lineTo(size.width - (isLast ? 0 : tabWidth) - radius, 0);
    path.arcToPoint(Offset(size.width - (isLast ? 0 : tabWidth), radius), radius: Radius.circular(radius));
    if (!isLast) {
      path.lineTo(size.width - tabWidth, (size.height / 2) - (tabHeight / 2));
      path.arcToPoint(Offset(size.width - tabWidth, (size.height / 2) + (tabHeight / 2)), radius: Radius.circular(tabHeight / 2), clockwise: true);
      path.lineTo(size.width - tabWidth, size.height - radius);
    } else { path.lineTo(size.width, size.height - radius); }
    path.arcToPoint(Offset(size.width - (isLast ? 0 : tabWidth) - radius, size.height), radius: Radius.circular(radius));
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius));
    if (!isFirst) {
      path.lineTo(0, (size.height / 2) + (tabHeight / 2));
      path.arcToPoint(Offset(0, (size.height / 2) - (tabHeight / 2)), radius: Radius.circular(tabHeight / 2), clockwise: false);
      path.lineTo(0, radius);
    } else { path.lineTo(0, radius); }
    path.close(); return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}