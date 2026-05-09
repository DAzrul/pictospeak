import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_service.dart';
import '../../core/services/ai_icon_service.dart';
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

  String _selectedCategory = 'Subject';
  bool _isLoading = false;
  bool _isAiThinking = false;
  Timer? _debounce;

  IconData _dynamicIcon = Icons.image_search;
  Color _dynamicColor = Colors.grey;

  @override
  void dispose() {
    _labelEnController.dispose();
    _labelMsController.dispose();
    _tagController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- HELPER UNTUK TUKAR STRING JADI ICON (MIX MATERIAL + FONT AWESOME) ---
  IconData _mapAiStringToIcon(String aiResult) {
    switch (aiResult.toLowerCase().trim()) {
    // Font Awesome Icons (Kena paksa guna 'as IconData')
      case 'cat': return FontAwesomeIcons.cat as IconData;
      case 'dog': return FontAwesomeIcons.dog as IconData;
      case 'fish': return FontAwesomeIcons.fish as IconData;
      case 'bird': return FontAwesomeIcons.crow as IconData;
      case 'burger': return FontAwesomeIcons.burger as IconData;
      case 'apple': return FontAwesomeIcons.apple as IconData;
      case 'brain': return FontAwesomeIcons.brain as IconData;
      case 'tooth': return FontAwesomeIcons.tooth as IconData;
      case 'ghost': return FontAwesomeIcons.ghost as IconData;
      case 'gift': return FontAwesomeIcons.gift as IconData;
      case 'heart': return FontAwesomeIcons.solidHeart as IconData;
      case 'poop': return FontAwesomeIcons.poop as IconData;
      case 'wheelchair': return FontAwesomeIcons.wheelchair as IconData;

    // Material Icons (Biar je macam biasa)
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

  // --- HELPER PINTAR (FALLBACK KETIKA DATA ROSAK) ---
  IconData _getSpecificIcon(String text) {
    // Kita panggil checkOfflineDictionary (dah buang underscore)
    return _mapAiStringToIcon(_aiService.checkOfflineDictionary(text.toLowerCase()));
  }

  // --- ENJIN HYBRID YANG DAH DIBERSIHKAN (CLEAN) ---
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

    // Tunjuk efek AI tengah fikir
    setState(() {
      _isAiThinking = true;
      _dynamicIcon = Icons.more_horiz;
      _dynamicColor = AppTheme.primaryBlue;
    });

    // Lepas 0.8 saat user stop menaip, baru panggil AI Service
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      // AI Service akan buat semua kerja (Offline check -> Cache check -> Groq API)
      String aiResult = await _aiService.getRecommendedIcon(text);
      if (!mounted) return;

      setState(() {
        _isAiThinking = false;
        _dynamicIcon = _mapAiStringToIcon(aiResult);

        // Auto-tukar warna ikut logik sikit
        if (['Object', 'Subject', 'Verb'].contains(_selectedCategory)) {
          _dynamicColor = _getCategoryColor(_selectedCategory);
        } else {
          _dynamicColor = Colors.green; // Default
        }
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
        _dynamicIcon.codePoint.toString(), // Save DNA
      );

      _labelEnController.clear();
      _labelMsController.clear();
      _tagController.clear();
      setState(() {
        _dynamicIcon = Icons.image_search;
        _dynamicColor = Colors.grey;
        _selectedCategory = 'Subject';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pictogram Added to Firebase!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getCategoryColor(String category) {
    if (category == 'Subject') return Colors.blue;
    if (category == 'Verb') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Local Context Pictogram',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)
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
                              : Icon(_dynamicIcon, color: _dynamicColor, size: 40)
                      ),
                      const SizedBox(height: 12),
                      Text(
                          _isAiThinking ? 'AI is thinking...' :
                          _labelEnController.text.isEmpty ? 'Type below to generate icon...' : 'Auto-generated Icon',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)
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
                        hintText: 'English (e.g. Toilet)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.language, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    )
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: _labelMsController,
                    decoration: InputDecoration(
                        hintText: 'Bahasa Melayu (e.g. Tandas)',
                        isDense: true,
                        prefixIcon: const Icon(Icons.translate, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    )
                ),
                const SizedBox(height: 16),

                const Text('3. Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  // 🚨 J.A.R.V.I.S: Update senarai ni sama macam kat SVO Builder
                  items: ['Subject', 'Verb', 'Object', 'Adjective', 'Others'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                      _dynamicColor = _getCategoryColor(_selectedCategory);
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('4. Predictive Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                    controller: _tagController,
                    decoration: InputDecoration(hintText: 'Spicy, Sambal', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addPictogramToFirebase,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add Pictogram to Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('Existing Pictograms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 12),

          StreamBuilder<List<Pictogram>>(
            stream: _dbService.getAllPictograms(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Library kosong. Tambah piktogram kat atas tu.', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                );
              }

              final pictograms = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pictograms.length,
                itemBuilder: (context, index) {
                  final pic = pictograms[index];
                  return _buildListItem(pic);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Pictogram pic) {
    Color catColor = _getCategoryColor(pic.category);

    IconData specificIcon;
    int? savedCodePoint = int.tryParse(pic.imageUrl);

    if (savedCodePoint != null) {
      specificIcon = IconData(savedCodePoint, fontFamily: 'MaterialIcons');
    } else {
      specificIcon = _getSpecificIcon(pic.labelEn);
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
              child: Icon(specificIcon, color: catColor, size: 20)
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pic.labelEn} / ${pic.labelMs}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(pic.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]
              )
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Pictogram?'),
                    content: Text('Kau pasti nak buang "${pic.labelEn}" dari library?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                          onPressed: () {
                            _dbService.deletePictogram(pic.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${pic.labelEn} deleted!'), backgroundColor: Colors.red),
                            );
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
              );
            },
          ),
        ],
      ),
    );
  }
}