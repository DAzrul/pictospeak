import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_service.dart';
import '../../core/services/ai_icon_service.dart';
import '../../core/services/local_db.dart'; // 🚨 J.A.R.V.I.S: Import Stor Lokal
import '../../core/services/sync_service.dart'; // 🚨 J.A.R.V.I.S: Import Lintah Sync
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
  final TextEditingController _tagController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final AiIconService _aiService = AiIconService();
  final LocalDB _localDB = LocalDB(); // 🚨 J.A.R.V.I.S: Init Stor Lokal

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
    _tagController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🚨 J.A.R.V.I.S: PROTOCOL CLEAN SLATE (NUCLEAR RESET)
  void _forceResetProtocol(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protocol Clean Slate?'),
        content: const Text('Benda ni akan padam SEMUA data lokal dan sedut balik dari Firebase. Confirm ke Boss?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tak Jadi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Jalan!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      // 1. Padam SQLite
      await _localDB.deleteAllPictograms();

      // 2. Sedut data baru dari Firebase
      await SyncService().syncFromFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset Berjaya! Data suci telah dikembalikan.'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      debugPrint("Reset Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  Widget _renderIcon(dynamic iconData, {double size = 40, Color? color}) {
    if (iconData is IconData) {
      return Icon(iconData, size: size, color: color);
    } else {
      return FaIcon(iconData, size: size, color: color);
    }
  }

  void _autoGenerateIcon(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _dynamicIcon = Icons.image_search;
        _dynamicColor = Colors.grey;
        _isAiThinking = false;
      });
      return;
    }

    setState(() {
      _isAiThinking = true;
      _dynamicIcon = Icons.more_horiz;
      _dynamicColor = AppTheme.primaryBlue;
    });

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

  void _addPictogramToFirebase() async {
    if (_labelEnController.text.isEmpty || _labelMsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi label English DAN Melayu!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbService.addPictogram(
        _labelEnController.text.trim(),
        _labelMsController.text.trim(),
        _selectedCategory,
        _dynamicIcon is IconData
            ? _dynamicIcon.codePoint.toString()
            : _labelEnController.text.toLowerCase().trim(),
        isPublic: _shareWithCommunity,
      );

      _labelEnController.clear();
      _labelMsController.clear();

      setState(() {
        _dynamicIcon = Icons.image_search;
        _dynamicColor = Colors.grey;
        _selectedCategory = 'Subject';
        _shareWithCommunity = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berjaya ditambah! Sila refresh atau tunggu auto-sync.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getCategoryColor(String category) {
    if (category == 'Subject') return Colors.blue;
    if (category == 'Verb') return Colors.orange;
    if (category == 'Object') return Colors.green;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Pictogram Context',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Smart Icon Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: _dynamicColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _dynamicColor.withValues(alpha: 0.3))
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 80, width: 80,
                          decoration: BoxDecoration(
                              color: _dynamicColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16)
                          ),
                          child: _isAiThinking
                              ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                              : _renderIcon(_dynamicIcon, color: _dynamicColor)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('2. Labels (Bilingual)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                    controller: _labelEnController,
                    onChanged: (text) => _autoGenerateIcon(text),
                    decoration: InputDecoration(
                        hintText: 'English (e.g. Cat)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.language, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    )
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: _labelMsController,
                    decoration: InputDecoration(
                        hintText: 'Bahasa Melayu (e.g. Kucing)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.translate, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    )
                ),
                const SizedBox(height: 16),

                const Text('3. Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: ['Subject', 'Verb', 'Object', 'Adjective', 'Others'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                      _dynamicColor = _getCategoryColor(_selectedCategory);
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('4. Community Sharing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _shareWithCommunity ? Colors.green.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _shareWithCommunity ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2))
                  ),
                  child: SwitchListTile(
                    title: const Text('Share with Community?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Admin will review this for everyone to use.', style: TextStyle(fontSize: 11)),
                    secondary: Icon(_shareWithCommunity ? Icons.public : Icons.public_off, color: _shareWithCommunity ? Colors.green : Colors.grey),
                    value: _shareWithCommunity,
                    activeThumbColor: Colors.green,
                    onChanged: (val) => setState(() => _shareWithCommunity = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addPictogramToFirebase,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _shareWithCommunity ? Colors.green : AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_shareWithCommunity ? 'Submit to Community' : 'Add to Private Library',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 🚨 J.A.R.V.I.S: Bahagian ni dah dipasang butang RESET
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Pictograms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              TextButton.icon(
                onPressed: _isLoading ? null : () => _forceResetProtocol(context),
                icon: const Icon(Icons.history_sharp, size: 16, color: Colors.redAccent),
                label: const Text('Force Sync', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Pictogram>>(
            stream: _dbService.getAllPictograms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final pictograms = snapshot.data ?? [];
              if (pictograms.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Library anda kosong. Klik Force Sync kalau baru lepas reset."),
                ));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pictograms.length,
                itemBuilder: (context, index) => _buildListItem(pictograms[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Pictogram pic) {
    Color catColor = _getCategoryColor(pic.category);
    dynamic specificIcon;
    int? savedCodePoint = int.tryParse(pic.imageUrl);
    if (savedCodePoint != null) {
      specificIcon = IconData(savedCodePoint, fontFamily: 'MaterialIcons');
    } else {
      specificIcon = _mapAiStringToIcon(pic.labelEn);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: catColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: _renderIcon(specificIcon, color: catColor, size: 20)
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pic.labelEn} / ${pic.labelMs}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(pic.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]
              )
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: () => _dbService.deletePictogram(pic.id),
          ),
        ],
      ),
    );
  }
}