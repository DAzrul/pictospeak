import 'dart:async';
import 'dart:io'; // 🚨 J.A.R.V.I.S: Enjin untuk handle file gambar
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 🚨 Lintah picker
import '../../core/theme/app_theme.dart';
import '../../core/services/database_service.dart';
import '../../core/services/ai_icon_service.dart';
import '../../core/services/local_db.dart';
import '../../core/services/sync_service.dart';
import '../../core/models/pictogram_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _labelEnController = TextEditingController();
  final TextEditingController _labelMsController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final AiIconService _aiService = AiIconService();
  final LocalDB _localDB = LocalDB();
  final ImagePicker _picker = ImagePicker(); // 🚨 Init Picker

  File? _imageFile; // 🚨 Simpan gambar yang dipilih
  String _activeFilterCategory = 'All';
  String _activeSourceFilter = 'All';

  String _selectedCategory = 'Subject';
  bool _isLoading = false;
  bool _isAiThinking = false;
  bool _shareWithCommunity = false;
  Timer? _debounce;

  dynamic _dynamicIcon = Icons.image_search;
  Color _dynamicColor = Colors.grey;

  @override
  void dispose() {
    _labelEnController.dispose();
    _labelMsController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🚨 J.A.R.V.I.S: FUNGSI EDIT MODAL (BILIK BEDAH)
  void _showEditModal(BuildContext context, Pictogram pic) {
    final TextEditingController editEn = TextEditingController(text: pic.labelEn);
    final TextEditingController editMs = TextEditingController(text: pic.labelMs);
    String editCat = pic.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Piktogram', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: editEn, decoration: const InputDecoration(labelText: 'English Label')),
            const SizedBox(height: 12),
            TextField(controller: editMs, decoration: const InputDecoration(labelText: 'Label Melayu')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: editCat,
              items: ['Subject', 'Verb', 'Object', 'Adjective', 'Emergency', 'Hygiene', 'Question', 'Time', 'Others']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => editCat = v!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                onPressed: () async {
                  await _dbService.updatePictogram(pic.id, editEn.text.trim(), editMs.text.trim(), editCat);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🚨 PILIH GAMBAR DARI GALERI
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // Reset AI icon kalau user dah pilih gambar sendiri
        _dynamicIcon = Icons.image_search;
      });
    }
  }

  // 🚨 PROTOCOL CLEAN SLATE
  void _forceResetProtocol(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protocol Clean Slate?'),
        content: const Text('Reset data lokal Boss?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset!', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    setState(() => _isLoading = true);
    try {
      await _localDB.deleteAllPictograms();
      await SyncService().syncFromFirebase();
    } catch (e) {
      debugPrint("Reset Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _autoGenerateIcon(String text) {
    if (_imageFile != null) return; // 🚨 Jangan ganggu kalau dah ada imej
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (text.trim().isEmpty) {
      setState(() { _dynamicIcon = Icons.image_search; _dynamicColor = Colors.grey; });
      return;
    }

    setState(() { _isAiThinking = true; });

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      String aiResult = await _aiService.getRecommendedIcon(text);
      if (!mounted) return;
      setState(() {
        _isAiThinking = false;
        _dynamicIcon = _mapAiStringToIcon(aiResult);
        _dynamicColor = _getCategoryColor(_selectedCategory);
      });
    });
  }

  // 🚨 J.A.R.V.I.S: Tambah 'List<String> tags' kat dalam kurungan ni
  void _addPictogramToFirebase(List<String> tags) async {
    if (_labelEnController.text.isEmpty || _labelMsController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String finalImagePath = "";

      if (_imageFile != null) {
        // 🔥 Upload ke Storage dulu
        finalImagePath = await _dbService.uploadPictogramImage(_imageFile!);
      } else {
        // Guna icon CodePoint kalau takde imej
        finalImagePath = _dynamicIcon is IconData
            ? _dynamicIcon.codePoint.toString()
            : _labelEnController.text.toLowerCase().trim();
      }

      // 🚨 J.A.R.V.I.S: Hantar 'tags' tu masuk ke dalam enjin DatabaseService
      await _dbService.addPictogram(
        _labelEnController.text.trim(),
        _labelMsController.text.trim(),
        _selectedCategory,
        finalImagePath,
        tags, // 👈 INI YANG TERTINGGAL TADI BABI!
        isPublic: _shareWithCommunity,
      );

      // Bersihkan semua kotak lepas berjaya simpan
      _labelEnController.clear();
      _labelMsController.clear();
      _tagsController.clear(); // 🚨 Jangan lupa clear kotak tags

      setState(() { _imageFile = null; _dynamicIcon = Icons.image_search; });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      case 'Others': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddPictogramSection(),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Library Explorer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              IconButton(onPressed: () => _forceResetProtocol(context), icon: const Icon(Icons.sync, color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterBar(),
          const SizedBox(height: 16),
          _buildPictogramList(),
        ],
      ),
    );
  }

  // 🚨 J.A.R.V.I.S: Kena tambah controller ni kat atas skali dengan controller lain!
  final TextEditingController _tagsController = TextEditingController();

  Widget _buildAddPictogramSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Smart Icon / Image Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),

          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                    color: _dynamicColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _dynamicColor.withValues(alpha: 0.3), width: 2)
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : _isAiThinking
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _renderIcon(_dynamicIcon, color: _dynamicColor, size: 40),
                    const Text('Tap to Add Image', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          if (_imageFile != null) Center(child: TextButton(onPressed: () => setState(() => _imageFile = null), child: const Text('Remove Image', style: TextStyle(color: Colors.red, fontSize: 12)))),

          const SizedBox(height: 16),
          TextField(controller: _labelEnController, onChanged: _autoGenerateIcon, decoration: const InputDecoration(hintText: 'English Label', prefixIcon: Icon(Icons.language))),
          const SizedBox(height: 12),
          TextField(controller: _labelMsController, decoration: const InputDecoration(hintText: 'Label Melayu', prefixIcon: Icon(Icons.translate))),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ['Subject', 'Verb', 'Object', 'Adjective', 'Emergency', 'Hygiene', 'Question', 'Time', 'Others'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() { _selectedCategory = v!; _dynamicColor = _getCategoryColor(v); }),
            decoration: const InputDecoration(labelText: 'Category', isDense: true),
          ),
          const SizedBox(height: 16),

          // 🚨 J.A.R.V.I.S: INI KOTAK PREDICTIVE TAGGING
          const Text('Predictive Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                  hintText: 'e.g. Spicy, Sambal (Comma separated)',
                  prefixIcon: Icon(Icons.tag)
              )
          ),

          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Public Access?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            value: _shareWithCommunity,
            onChanged: (v) => setState(() => _shareWithCommunity = v),
          ),
          SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                // 🚨 Proses Tags sebelum hantar!
                List<String> finalTags = _tagsController.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toList();

                // Hantar! (Kau kena update _addPictogramToFirebase terima finalTags ni)
                _addPictogramToFirebase(finalTags);
              },
              child: const Text('Store in Cloud Library')
          )),
        ],
      ),
    );
  }

  Widget _buildPictogramList() {
    return StreamBuilder<List<Pictogram>>(
      stream: _dbService.getAllPictograms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        List<Pictogram> pictograms = snapshot.data ?? [];

        // LOGIK TAPISAN
        if (_activeFilterCategory != 'All') pictograms = pictograms.where((p) => p.category == _activeFilterCategory).toList();
        if (_activeSourceFilter == 'Private') pictograms = pictograms.where((p) => p.ownerId != 'GLOBAL').toList();
        else if (_activeSourceFilter == 'Online') pictograms = pictograms.where((p) => p.ownerId == 'GLOBAL').toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pictograms.length,
          itemBuilder: (context, index) => _buildListItem(pictograms[index]),
        );
      },
    );
  }

  Widget _buildListItem(Pictogram pic) {
    Color catColor = _getCategoryColor(pic.category);
    bool isOnline = pic.ownerId == 'GLOBAL';
    bool isUrl = pic.imageUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(
              child: isUrl
                  ? ClipOval(child: Image.network(pic.imageUrl, width: 45, height: 45, fit: BoxFit.cover))
                  : _renderIcon(int.tryParse(pic.imageUrl) != null ? IconData(int.parse(pic.imageUrl), fontFamily: 'MaterialIcons') : _mapAiStringToIcon(pic.labelEn), color: catColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${pic.labelEn} / ${pic.labelMs}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Text(pic.category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              if (isOnline) ...[const SizedBox(width: 8), const Icon(Icons.cloud_done, size: 12, color: Colors.blue)],
            ]),
          ])),
          if (!isOnline)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
              onPressed: () => _showEditModal(context, pic), // Panggil modal untuk edit
            ),
          // 🚨 J.A.R.V.I.S: Hanya tunjuk butang delete kalau HAK MILIK SENDIRI
          if (!isOnline)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _dbService.deletePictogram(pic.id),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Private', 'Online'].map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(s), selected: _activeSourceFilter == s, onSelected: (val) => setState(() => _activeSourceFilter = s)))).toList())),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Subject', 'Verb', 'Object', 'Adjective', 'Emergency', 'Hygiene', 'Question', 'Time', 'Others'].map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c, style: TextStyle(fontSize: 11, color: _activeFilterCategory == c ? Colors.white : Colors.black87)), selected: _activeFilterCategory == c, selectedColor: _getCategoryColor(c), onSelected: (val) => setState(() => _activeFilterCategory = c)))).toList())),
      ],
    );
  }

  Widget _renderIcon(dynamic iconData, {double size = 40, Color? color}) {
    if (iconData is IconData) return Icon(iconData, size: size, color: color);
    return FaIcon(iconData, size: size, color: color);
  }
}