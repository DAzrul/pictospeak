import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/tts_service.dart'; // 🚨 J.A.R.V.I.S: Import mulut AI!
import 'svo_builder_screen.dart';

class MoodSelectionScreen extends StatelessWidget {
  // 🚨 J.A.R.V.I.S: Hidupkan enjin suara kat sini
  final TtsService _ttsService = TtsService();

  // Buang perkataan 'const' sebab kita ada panggil service kat atas
  MoodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            _ttsService.stop(); // Berhenti kalau tekan pangkah
            Navigator.pop(context);
          },
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
                _ttsService.stop(); // Potong suara kalau dia tekan skip
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
      // 🚨 J.A.R.V.I.S: Letak async supaya mulut ni boleh menunggu
      onTap: () async {
        // Berhentikan TTS lama kalau ada
        await _ttsService.stop();

        // Jeritkan emosi tu kuat-kuat!
        await _ttsService.speak(en, lang: "en-US");

        // SnackBar lawa untuk UI feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.white),
                const SizedBox(width: 10),
                Text('Speaking: $en'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(milliseconds: 1500),
          ),
        );

        // LOG DATA: Simpan mood untuk Dashboard (Nanti kita link masuk Firebase)
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
            // Kekalkan buang perkataan "I am" kat visual supaya nampak kemas
            Text(en.replaceAll('I am ', ''), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(ms.replaceAll('Saya ', ''), style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}