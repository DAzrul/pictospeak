import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pictogram_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Tambah Piktogram Baru
  Future<void> addPictogram(String en, String ms, String cat, String img) async {
    try {
      await _db.collection('library').add({
        'label_en': en,
        'label_ms': ms,
        'category': cat,
        'image_url': img,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Pictogram $en berjaya disimpan!");
    } catch (e) {
      print("Error simpan data: $e");
    }
  }

  // 2. Ambil semua piktogram mengikut kategori
  Stream<List<Pictogram>> getPictograms(String category) {
    return _db
        .collection('library')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
  }

  // Tarik SEMUA piktogram untuk dipaparkan dlm Library
  Stream<List<Pictogram>> getAllPictograms() {
    return _db
        .collection('library')
        .orderBy('timestamp', descending: true) // Susun yg paling baru kat atas
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
  }

  // Fungsi bunuh data
  Future<void> deletePictogram(String id) async {
    try {
      await _db.collection('library').doc(id).delete();
      print("Data $id dah selamat jalan.");
    } catch (e) {
      print("Gagal delete: $e");
    }
  }
}

