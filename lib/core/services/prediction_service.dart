import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. LOG PENGGUNAAN (Membina "Pengalaman" Algoritma)
  Future<void> logUsage(String sub, String verb, String obj) async {
    try {
      await _db.collection('usage_history').add({
        'subject': sub,
        'verb': verb,
        'object': obj,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Sejarah penggunaan berjaya direkod untuk pembelajaran mesin.");
    } catch (e) {
      print("Gagal log sejarah: $e");
    }
  }

  // 2. MARKOV CHAIN ENGINE (Ramalan Perkataan Seterusnya)
  Future<List<String>> getSuggestions(String currentWord, String nextCategory) async {
    try {
      // Tarik sejarah dari Firebase
      QuerySnapshot history = await _db.collection('usage_history').get();

      Map<String, int> frequencies = {};

      for (var doc in history.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String? targetWord;

        // Logik N-gram: Tentukan 'target' berdasarkan kategori seterusnya
        if (nextCategory == 'Verb' && data['subject'] == currentWord) {
          targetWord = data['verb'];
        } else if (nextCategory == 'Object' && data['verb'] == currentWord) {
          targetWord = data['object'];
        }

        // Kira kekerapan (Frequency Count)
        if (targetWord != null) {
          frequencies[targetWord] = (frequencies[targetWord] ?? 0) + 1;
        }
      }

      // Susun mengikut kebarangkalian (paling kerap di atas)
      var sortedEntries = frequencies.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Ambil top 5 cadangan sahaja
      return sortedEntries.map((e) => e.key).take(5).toList();

    } catch (e) {
      print("Error generating suggestions: $e");
      return [];
    }
  }
}