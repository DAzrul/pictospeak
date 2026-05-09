import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 🚨 J.A.R.V.I.S: Guna package import supaya tak sesat jalan
import 'package:pictospeak/core/services/local_db.dart';
import 'package:pictospeak/core/services/prediction_service.dart';
import 'package:pictospeak/core/services/tts_service.dart';
import 'package:pictospeak/core/services/ai_icon_service.dart';
import 'package:pictospeak/core/services/sync_service.dart';
import 'package:pictospeak/core/models/pictogram_model.dart';
import 'package:pictospeak/core/theme/app_theme.dart';

class SvoBuilderScreen extends StatefulWidget {
  // 🚨 J.A.R.V.I.S: Dah repair constructor kat bawah ni. Takde lagi 'super.override' merapu tu.
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

  @override
  void initState() {
    super.initState();
    SyncService().syncFromFirebase().then((_) {
      if (mounted) setState(() {});
    });
    _updateSuggestions();
  }

  // --- LOGIK RENDER ICON (FIXED DECIMAL VERSION) ---
  dynamic _mapAiStringToIcon(String aiResult) {
    switch (aiResult.toLowerCase().trim()) {
      case 'cat': return FontAwesomeIcons.cat;
      case 'dog': return FontAwesomeIcons.dog;
      case 'fish': return FontAwesomeIcons.fish;
      case 'bird': return FontAwesomeIcons.crow;
      case 'burger': return FontAwesomeIcons.burger;
      case 'apple': return FontAwesomeIcons.apple;
      case 'brain': return FontAwesomeIcons.brain;
      case 'tooth': return FontAwesomeIcons.tooth;
      case 'ghost': return FontAwesomeIcons.ghost;
      case 'gift': return FontAwesomeIcons.gift;
      case 'heart': return FontAwesomeIcons.solidHeart;
      case 'poop': return FontAwesomeIcons.poop;
      case 'wheelchair': return FontAwesomeIcons.wheelchair;
      case 'woman': return Icons.woman;
      case 'man': return Icons.man;
      case 'baby': return Icons.child_care;
      case 'family': return Icons.family_restroom;
      case 'person': return Icons.person;
      case 'car': return Icons.directions_car;
      case 'bus': return Icons.directions_bus;
      case 'bike': return Icons.directions_bike;
      case 'plane': return Icons.flight;
      case 'boat': return Icons.directions_boat;
      case 'water': return Icons.water_drop;
      case 'food': return Icons.restaurant;
      case 'coffee': return Icons.local_cafe;
      case 'cake': return Icons.cake;
      case 'pet': return Icons.pets;
      case 'sun': return Icons.wb_sunny;
      case 'moon': return Icons.nightlight_round;
      case 'fire': return Icons.local_fire_department;
      case 'tree': return Icons.park;
      case 'star': return Icons.star;
      case 'home': return Icons.home;
      case 'hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'shop': return Icons.store;
      case 'toilet': return Icons.wc;
      case 'happy': return Icons.sentiment_very_satisfied;
      case 'sad': return Icons.sentiment_very_dissatisfied;
      case 'angry': return Icons.mood_bad;
      case 'pain': return Icons.personal_injury;
      case 'hand': return Icons.back_hand;
      case 'face': return Icons.face;
      case 'body': return Icons.accessibility_new;
      case 'eye': return Icons.visibility;
      case 'ear': return Icons.hearing;
      case 'tv': return Icons.tv;
      case 'phone': return Icons.smartphone;
      case 'book': return Icons.menu_book;
      case 'music': return Icons.music_note;
      case 'camera': return Icons.photo_camera;
      case 'money': return Icons.attach_money;
      case 'clothes': return Icons.checkroom;
      case 'bag': return Icons.shopping_bag;
      case 'clock': return Icons.access_time;
      case 'key': return Icons.vpn_key;
      case 'toy': return Icons.toys;
      case 'bed': return Icons.bed;
      case 'walk': return Icons.directions_walk;
      case 'run': return Icons.directions_run;
      case 'search': return Icons.search;
      case 'chat': return Icons.chat;
      case 'work': return Icons.work;
      case 'play': return Icons.sports_esports;
      case 'sport': return Icons.sports_soccer;
      default: return Icons.extension;
    }
  }

  dynamic _getIconFromPic(Pictogram pic) {
    int? codePoint = int.tryParse(pic.imageUrl);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return _mapAiStringToIcon(_aiService.checkOfflineDictionary(pic.labelEn.toLowerCase()));
  }

  Widget _renderSmartIcon(dynamic iconData, double size, Color color) {
    try {
      if (iconData is IconData) {
        return Icon(iconData, size: size, color: color);
      } else {
        return FaIcon(iconData, size: size, color: color);
      }
    } catch (e) {
      return Icon(Icons.broken_image, size: size, color: color);
    }
  }

  void _updateSuggestions() async {
    String currentWord = "";
    if (selectedSentence.isNotEmpty) {
      currentWord = "${selectedSentence.last.labelEn} / ${selectedSentence.last.labelMs}";
    }
    List<String> suggestions = await _predictionService.getSuggestions(currentWord, _activeCategory);
    if (mounted) setState(() => dynamicSuggestions = suggestions);
  }

  void _triggerSOS(BuildContext context) async {
    const String sosEn = "Help me, please call my caregiver!";
    const String sosMs = "Tolong saya, sila panggil penjaga saya!";
    await _ttsService.speak(sosEn, lang: "en-US");

    // 🚨 J.A.R.V.I.S: Repair 'async gap'. Check mounted dulu sebelum guna context.
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚨 SOS: $sosMs'), backgroundColor: Colors.red[900], behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4)),
    );
  }

  void _handleWordSelection(Pictogram pic) {
    setState(() {
      selectedSentence.add(pic);
      if (_activeCategory == 'Subject') _activeCategory = 'Verb';
      else if (_activeCategory == 'Verb') _activeCategory = 'Object';
    });
    _updateSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _ttsService.stop();
            Navigator.pop(context);
          },
        ),
        title: const Text('Build Sentence', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSosBar(),
          _buildLegoSvoDisplay(),
          _buildSuggestedWordsBar(),
          _buildCategoryTabs(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _localDB.getPictogramsByCategory(_activeCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final dataList = snapshot.data ?? [];

                  if (dataList.isEmpty) {
                    return Center(
                        child: Text(
                            "Tiada data untuk kategori $_activeCategory.\nSila pastikan data telah di-sync.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400)
                        )
                    );
                  }

                  final pictograms = dataList.map((map) => Pictogram(
                    id: map['id'] ?? '',
                    labelEn: map['label_en'] ?? '',
                    labelMs: map['label_ms'] ?? '',
                    category: map['category'] ?? 'Others',
                    imageUrl: map['image_url'] ?? '',
                    ownerId: map['ownerId'] ?? 'GLOBAL',
                    createdAt: DateTime.now(),
                  )).toList();

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
                    ),
                    itemCount: pictograms.length,
                    itemBuilder: (context, index) => _buildLargeIconButton(pictograms[index]),
                  );
                },
              ),
            ),
          ),
          _buildSpeakButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Subject', 'Verb', 'Object', 'Adjective', 'Others'].map((cat) {
            bool isActive = _activeCategory == cat;
            return GestureDetector(
              onTap: () {
                setState(() => _activeCategory = cat);
                _updateSuggestions();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppTheme.primaryBlue : Colors.grey.shade300),
                  boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Center(
                  child: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isActive ? Colors.white : Colors.grey.shade600)),
                ),
              ),
            );
          }).toList(),
        ),
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
                    bool isActive = index == selectedSentence.length;
                    String title = index == 0 ? 'Subject' : index == 1 ? 'Verb' : index == 2 ? 'Object' : '...';
                    String? val = isFilled ? selectedSentence[index].labelEn.split(' / ')[0] : null;

                    Color boxColor = isActive ? AppTheme.primaryBlue : (isFilled ? Colors.blue.shade100 : Colors.grey.shade300);
                    Color textColor = isActive ? Colors.white : (isFilled ? AppTheme.primaryBlue : Colors.grey.shade600);

                    return Transform.translate(
                      offset: Offset(isFirst ? 0 : index * -15.0, 0),
                      child: ClipPath(
                        clipper: PuzzleClipper(isFirst: isFirst, isLast: isLast),
                        child: Container(
                          width: 100, height: 85, color: boxColor,
                          child: Center(
                            child: val != null
                                ? Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)
                                : Text(title, style: TextStyle(fontSize: 11, color: textColor)),
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

  Widget _buildSosBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        elevation: 4, borderRadius: BorderRadius.circular(12), color: Colors.orange[800],
        child: InkWell(
          onTap: () => _triggerSOS(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('SOS / Call Caregiver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoButton() => IconButton(
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
    icon: const Icon(Icons.undo_rounded, color: Colors.grey),
  );

  Widget _buildSuggestedWordsBar() => Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Colors.blue.withValues(alpha: 0.05),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dynamicSuggestions.isEmpty
            ? [const Text("Tiada cadangan...", style: TextStyle(fontSize: 12, color: Colors.grey))]
            : dynamicSuggestions.map((label) => _buildSuggestChip(label)).toList(),
      ),
    ),
  );

  Widget _buildSuggestChip(String label) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
    child: Text(label.split(' / ')[0], style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
  );

  Widget _buildLargeIconButton(Pictogram pic) => InkWell(
    onTap: () => _handleWordSelection(pic),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _renderSmartIcon(_getIconFromPic(pic), 40, AppTheme.primaryBlue),
        const SizedBox(height: 12),
        Text(pic.labelEn.split(' / ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(pic.labelMs.split(' / ')[0], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ]),
    ),
  );

  Widget _buildSpeakButton() => Container(
    padding: const EdgeInsets.all(20), color: Colors.white,
    child: Column(children: [
      SizedBox(
        width: double.infinity, height: 60,
        child: ElevatedButton.icon(
          onPressed: selectedSentence.isEmpty ? null : () async {
            String sentenceEn = selectedSentence.map((pic) => pic.labelEn.split(' / ')[0]).join(" ");
            await _ttsService.speak(sentenceEn, lang: "en-US");
          },
          icon: const Icon(Icons.volume_up, color: Colors.white),
          label: const Text('Speak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
      TextButton(onPressed: () => setState(() { selectedSentence.clear(); _activeCategory = 'Subject'; _updateSuggestions(); }), child: const Text('Clear sentence', style: TextStyle(color: Colors.grey, fontSize: 12))),
    ]),
  );
}

class PuzzleClipper extends CustomClipper<Path> {
  final bool isFirst; final bool isLast;
  PuzzleClipper({this.isFirst = false, this.isLast = false});
  @override
  Path getClip(Size size) {
    final path = Path();
    final double tabWidth = 15.0; final double tabHeight = 25.0; final double radius = 8.0;
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