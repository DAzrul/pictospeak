import 'local_db.dart';

class PredictionService {
  final LocalDB _localDB = LocalDB();

  Future<List<String>> getSuggestions(List<String> lastWordTags, String activeCategory) async {
    // 1. Sedut data mengikut kategori yang tengah aktif (Verb/Object)
    final categoryData = await _localDB.getPictogramsByCategory(activeCategory);

    List<Map<String, dynamic>> matches = [];

    // 2. 🚨 LOGIK SCORING: Cari piktogram yang tag dia paling banyak "overlap"
    for (var item in categoryData) {
      List<String> itemTags = (item['tags'] as String).split(', ').map((e) => e.trim().toLowerCase()).toList();

      // Kira Score berdasarkan Tags (Overlap)
      int tagScore = itemTags.where((t) => lastWordTags.contains(t)).length;

      // 🚨 J.A.R.V.I.S: Ambil data frequency dari SQLite
      int frequency = item['frequency'] ?? 0;

      if (tagScore > 0 || frequency > 0) {
        matches.add({
          'label': "${item['label_en']} / ${item['label_ms']}",
          'score': (tagScore * 10) + frequency // 👈 TagScore lagi penting, tapi Frequency membantu!
        });
      }
    }

    // Susun ikut Score paling tinggi
    matches.sort((a, b) => b['score'].compareTo(a['score']));

    // 3. Susun: Yang score paling tinggi duduk depan
    matches.sort((a, b) => b['score'].compareTo(a['score']));

    // 4. Masukkan hasil ramalan ke dalam List akhir
    List<String> suggestions = matches.map((m) => m['label'] as String).toList();

    // 5. 🚨 FALLBACK: Kalau tak cukup 6 cadangan, sumbat data asal kategori tu
    // Supaya bar AI tak nampak kosong macam dompet hujung bulan.
    if (suggestions.length < 6) {
      for (var item in categoryData) {
        String fallbackLabel = "${item['label_en']} / ${item['label_ms']}";
        if (!suggestions.contains(fallbackLabel)) {
          suggestions.add(fallbackLabel);
        }
        if (suggestions.length >= 6) break;
      }
    }

    return suggestions.toSet().toList().take(6).toList();
  }
}