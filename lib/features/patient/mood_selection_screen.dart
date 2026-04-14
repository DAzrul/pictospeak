import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'svo_builder_screen.dart';

class MoodSelectionScreen extends StatelessWidget {
  const MoodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'How are you feeling right now?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bagaimana perasaan anda sekarang?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // GRID MOOD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                children: [
                  _buildMoodButton(context, 'I am Happy', 'Saya Gembira', Icons.sentiment_very_satisfied, Colors.green),
                  _buildMoodButton(context, 'I am Sad', 'Saya Sedih', Icons.sentiment_very_dissatisfied, Colors.blue),
                  _buildMoodButton(context, 'I am Angry', 'Saya Marah', Icons.sentiment_dissatisfied_rounded, Colors.orange),
                  _buildMoodButton(context, 'I am in Pain', 'Saya Sakit', Icons.mood_bad_rounded, Colors.redAccent),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // SKIP BUTTON
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SvoBuilderScreen()),
                );
              },
              child: const Text(
                'Skip to sentence builder',
                style: TextStyle(color: Colors.blueGrey, fontSize: 14, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(BuildContext context, String en, String ms, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // 1. LOGIK TTS: Fon akan bercakap ikut emosi (KEKALKAN INI)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Bunyi: $en / $ms'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: color,
            duration: const Duration(milliseconds: 1000), // Pendekkan sikit duration
          ),
        );

        // 2. LOG DATA: Simpan mood untuk Dashboard (KEKALKAN INI)
        debugPrint("Mood selected and spoken: $en");

      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 8),
            // Aku adjust sikit text ni supaya dia sebut subjek "I am..."
            Text(en.replaceAll('I am ', ''), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(ms.replaceAll('Saya ', ''), style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}