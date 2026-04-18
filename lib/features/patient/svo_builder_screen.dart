import 'package:flutter/material.dart';
import '../../core/services/database_service.dart';
import '../../core/services/prediction_service.dart';
import '../../core/services/tts_service.dart'; // Import mulut (TTS)
import '../../core/models/pictogram_model.dart';
import '../../core/theme/app_theme.dart';

class SvoBuilderScreen extends StatefulWidget {
  const SvoBuilderScreen({super.key});

  @override
  State<SvoBuilderScreen> createState() => _SvoBuilderScreenState();
}

class _SvoBuilderScreenState extends State<SvoBuilderScreen> {
  final DatabaseService _dbService = DatabaseService();
  final PredictionService _predictionService = PredictionService(); // Otak AI
  final TtsService _ttsService = TtsService(); // Suara AI

  String? selectedSubject;
  String? selectedVerb;
  String? selectedObject;
  List<String> dynamicSuggestions = [];

  @override
  void initState() {
    super.initState();
    _updateSuggestions();
  }

  void _updateSuggestions() async {
    String currentWord = "";
    if (selectedVerb != null) {
      currentWord = selectedVerb!;
    } else if (selectedSubject != null) {
      currentWord = selectedSubject!;
    }

    List<String> suggestions = await _predictionService.getSuggestions(
        currentWord,
        currentCategory
    );

    setState(() {
      dynamicSuggestions = suggestions;
    });
  }

  String get currentCategory {
    if (selectedSubject == null) return 'Subject';
    if (selectedVerb == null) return 'Verb';
    return 'Object';
  }

  IconData _getIconData(String category) {
    switch (category) {
      case 'Subject': return Icons.person_outline;
      case 'Verb': return Icons.play_arrow_outlined;
      case 'Object': return Icons.category_outlined;
      default: return Icons.help_outline;
    }
  }

  // 🚨 FUNGSI SOS BERCAKAP!
  void _triggerSOS(BuildContext context) async {
    const String sosEn = "Help me, please call my caregiver!";
    const String sosMs = "Tolong saya, sila panggil penjaga saya!";

    // Jerit guna TTS!
    await _ttsService.speak(sosEn, lang: "en-US");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 SOS: $sosMs'),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleWordSelection(String label) {
    setState(() {
      if (selectedSubject == null) {
        selectedSubject = label;
      } else if (selectedVerb == null) {
        selectedVerb = label;
      } else if (selectedObject == null) {
        selectedObject = label;
      }
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
            _ttsService.stop(); // Stop bunyi kalau keluar skrin
            Navigator.pop(context);
          },
        ),
        title: const Text('Build Sentence', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSosBar(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildSvoSlot('Subject', selectedSubject, true),
                const SizedBox(width: 8),
                _buildSvoSlot('Verb', selectedVerb, selectedSubject != null),
                const SizedBox(width: 8),
                _buildSvoSlot('Object', selectedObject, selectedVerb != null),
                const SizedBox(width: 8),
                _buildUndoButton(),
              ],
            ),
          ),

          _buildSuggestedWordsBar(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<List<Pictogram>>(
                stream: _dbService.getPictograms(currentCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final pictograms = snapshot.data ?? [];
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: pictograms.length,
                    itemBuilder: (context, index) {
                      final pic = pictograms[index];
                      return _buildLargeIconButton({
                        'label': '${pic.labelEn} / ${pic.labelMs}',
                        'icon': _getIconData(pic.category),
                      });
                    },
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

  Widget _buildSosBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange[800],
        child: InkWell(
          onTap: () => _triggerSOS(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('SOS / Call Caregiver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSvoSlot(String title, String? val, bool isActive) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: val != null ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: val != null ? 2 : 1,
          ),
        ),
        child: Center(
          child: val != null
              ? Text(val.split(' / ')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
              : Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          if (selectedObject != null) selectedObject = null;
          else if (selectedVerb != null) selectedVerb = null;
          else if (selectedSubject != null) selectedSubject = null;
        });
        _updateSuggestions();
      },
      icon: const Icon(Icons.undo_rounded, color: Colors.grey),
    );
  }

  Widget _buildSuggestedWordsBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUGGESTED WORDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dynamicSuggestions.isEmpty
                  ? [const Text("Tiada cadangan...", style: TextStyle(fontSize: 12, color: Colors.grey))]
                  : dynamicSuggestions.map((label) => _buildSuggestChip({'label': label, 'icon': _getIconData(currentCategory)})).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestChip(Map<String, dynamic> word) {
    return GestureDetector(
      onTap: () => _handleWordSelection(word['label']),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(word['icon'], size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(word['label'], style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeIconButton(Map<String, dynamic> word) {
    return InkWell(
      onTap: () => _handleWordSelection(word['label']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(word['icon'], size: 40, color: AppTheme.primaryBlue),
            const SizedBox(height: 12),
            Text(word['label'].split(' / ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(word['label'].split(' / ')[1], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: (selectedSubject != null)
                  ? () async {
                String sentenceEn = selectedSubject!.split(' / ')[0];
                String sentenceMs = selectedSubject!.split(' / ')[1]; // Tarik BM sekali

                if (selectedVerb != null) {
                  sentenceEn += " ${selectedVerb!.split(' / ')[0]}";
                  sentenceMs += " ${selectedVerb!.split(' / ')[1]}";
                }
                if (selectedObject != null) {
                  sentenceEn += " ${selectedObject!.split(' / ')[0]}";
                  sentenceMs += " ${selectedObject!.split(' / ')[1]}";
                }

                // 🗣️ BERCAKAP GUNA TTS (ENGLISH)
                await _ttsService.speak(sentenceEn, lang: "en-US");

                // 🧠 SIMPAN SEJARAH (MARKOV CHAIN)
                if (selectedSubject != null && selectedVerb != null && selectedObject != null) {
                  await _predictionService.logUsage(selectedSubject!, selectedVerb!, selectedObject!);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Speaking: $sentenceEn / $sentenceMs'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.volume_up, color: Colors.white),
              label: const Text('Speak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _ttsService.stop(); // Stop bunyi kalau pesakit tekan Clear
              setState(() {
                selectedSubject = null;
                selectedVerb = null;
                selectedObject = null;
                _updateSuggestions();
              });
            },
            child: const Text('Clear sentence', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}