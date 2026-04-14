import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SvoBuilderScreen extends StatefulWidget {
  const SvoBuilderScreen({super.key});

  @override
  State<SvoBuilderScreen> createState() => _SvoBuilderScreenState();
}

class _SvoBuilderScreenState extends State<SvoBuilderScreen> {
  String? selectedSubject;
  String? selectedVerb;
  String? selectedObject;

  // Logik Tekaan Dinamik (Mockup N-gram/Markov Chain) [cite: 14]
  List<Map<String, dynamic>> get suggestedWords {
    if (selectedSubject == null) {
      return [{'label': 'I / Saya', 'icon': Icons.person_outline}];
    } else if (selectedVerb == null) {
      return [
        {'label': 'want / mahu', 'icon': Icons.favorite_border},
        {'label': 'need / perlu', 'icon': Icons.pan_tool_outlined},
        {'label': 'feel / rasa', 'icon': Icons.sentiment_satisfied},
      ];
    } else if (selectedObject == null) {
      return [
        {'label': 'food / makanan', 'icon': Icons.restaurant},
        {'label': 'water / air', 'icon': Icons.water_drop_outlined},
        {'label': 'rest / rehat', 'icon': Icons.bed_outlined},
      ];
    }
    return [];
  }

  // Fungsi untuk trigger suara SOS [cite: 15]
  void _triggerSOS(BuildContext context) {
    const String sosEn = "Help me, please call my caregiver!";
    const String sosMs = "Tolong saya, sila panggil penjaga saya!";

    debugPrint("SOS TRIGGERED: $sosEn");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚨 SOS: Tolong saya, sila panggil penjaga saya!'),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Build Sentence', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. BAR SOS (BUTTON STYLE) - Ikut design image_7d464e.png
          Padding(
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
                      Text(
                        'SOS / Call Caregiver',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Slot Pembina Ayat (SVO) [cite: 21, 25]
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
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (selectedObject != null) {
                        selectedObject = null;
                      } else if (selectedVerb != null) {
                        selectedVerb = null;
                      } else if (selectedSubject != null) {
                        selectedSubject = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.undo_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 3. Bar Cadangan Piktogram Pintar [cite: 14, 25]
          Container(
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
                    children: suggestedWords.map((word) => _buildSuggestChip(word)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 4. Grid Piktogram Gergasi [cite: 13, 17]
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: suggestedWords.length,
                itemBuilder: (context, index) {
                  final word = suggestedWords[index];
                  return _buildLargeIconButton(word);
                },
              ),
            ),
          ),

          // 5. Butang Speak (Voice Output) [cite: 15, 26]
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: (selectedSubject != null)
                        ? () {
                      String sentenceEn = selectedSubject!.split(' / ')[0];
                      String sentenceMs = selectedSubject!.split(' / ')[1];
                      if (selectedVerb != null) {
                        sentenceEn += " ${selectedVerb!.split(' / ')[0]}";
                        sentenceMs += " ${selectedVerb!.split(' / ')[1]}";
                      }
                      if (selectedObject != null) {
                        sentenceEn += " ${selectedObject!.split(' / ')[0]}";
                        sentenceMs += " ${selectedObject!.split(' / ')[1]}";
                      }
                      debugPrint("TTS SPEAKING: $sentenceEn");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('TTS Bunyi: $sentenceEn / $sentenceMs'),
                          backgroundColor: AppTheme.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    setState(() {
                      selectedSubject = null;
                      selectedVerb = null;
                      selectedObject = null;
                    });
                  },
                  child: const Text('Clear sentence', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
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
            Text(word['label'].split(' / ')[1], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}