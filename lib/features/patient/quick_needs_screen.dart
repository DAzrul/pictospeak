import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/tts_service.dart'; // 🚨 J.A.R.V.I.S: Import mulut AI kat sini!
import 'mood_selection_screen.dart';
import 'svo_builder_screen.dart';

class QuickNeedsScreen extends StatelessWidget {
  // 🚨 J.A.R.V.I.S: Panggil enjin suara AI
  final TtsService _ttsService = TtsService();

  QuickNeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.black87, size: 28),
          onPressed: () {
            _ttsService.stop(); // Berhenti cakap kalau user keluar skrin
            Navigator.pop(context);
          },
        ),
        title: const Column(
          children: [
            Text('Quick Needs', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Keperluan Segera', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.black87, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MoodSelectionScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bahagian tengah untuk butang keperluan asas
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.9,
                      children: [
                        _buildNeedButton(context, 'I need the toilet', 'Saya perlu tandas', Icons.wc_rounded, Colors.orange),
                        _buildNeedButton(context, 'I am in pain', 'Saya sakit', Icons.sentiment_very_dissatisfied_rounded, const Color(0xFFF43F5E)),
                        _buildNeedButton(context, 'I am thirsty', 'Saya dahaga', Icons.water_drop_rounded, const Color(0xFF0EA5E9)),
                        _buildNeedButton(context, 'Call the doctor', 'Panggil doktor', Icons.medical_services_outlined, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // BUTANG "BUILD CUSTOM SENTENCE" (Pintu masuk ke SVO Builder)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // NAVIGASI KE SVO BUILDER: Jantung PictoSpeak kau
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SvoBuilderScreen()),
                    );
                  },
                  icon: const Icon(Icons.grid_on_rounded, color: AppTheme.primaryBlue, size: 24),
                  label: const Text(
                    'Build Custom Sentence',
                    style: TextStyle(color: AppTheme.primaryBlue, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk butang piktogram keperluan segera
  Widget _buildNeedButton(BuildContext context, String titleEn, String titleMs, IconData icon, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          // 🚨 J.A.R.V.I.S: Letak async kat sini supaya dia boleh tunggu TTS bercakap
          onTap: () async {
            // Berhentikan TTS kalau dia tengah bising merapu benda lain
            await _ttsService.stop();

            // Jerit guna TTS! (Boleh tukar 'titleMs' kalau nak dia sebut Melayu)
            await _ttsService.speak(titleEn, lang: "en-US");

            // SnackBar feedback kat skrin
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('Speaking: $titleEn'),
                  ],
                ),
                backgroundColor: bgColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(milliseconds: 1500),
              ),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 14),
                Text(
                  titleEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  titleMs,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}