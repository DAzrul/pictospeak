import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Tambah Piktogram Baru ke Awan
  Future<void> addPictogram(String en, String ms, String cat, String img) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // 🚨 TEMBAK MASUK KE library_v2
      await _db.collection('library_v2').add({
        'label_en': en,
        'label_ms': ms,
        'category': cat,
        'image_url': img,
        'ownerId': currentUid, // 🚨 Cop Mohor Rahsia Caregiver!
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("J.A.R.V.I.S: Pictogram $en berjaya terbang ke library_v2!");
    } catch (e) {
      print("J.A.R.V.I.S: Error tembak data: $e");
    }
  }

  // 2. Tarik piktogram untuk skrin Library Caregiver
  Stream<List<Pictogram>> getAllPictograms() {
    String currentUid = _auth.currentUser!.uid;

    return _db
        .collection('library_v2') // 🚨 BACA DARI library_v2
        .where('ownerId', whereIn: ['GLOBAL', currentUid]) // Hanya baca hak sendiri & GLOBAL
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
  }

  // 3. Fungsi bunuh data
  Future<void> deletePictogram(String id) async {
    try {
      await _db.collection('library_v2').doc(id).delete(); // 🚨 PADAM DARI library_v2
      print("J.A.R.V.I.S: Data $id berjaya dibunuh.");
    } catch (e) {
      print("J.A.R.V.I.S: Gagal delete: $e");
    }
  }

  // (Fungsi getPictograms lama kita biar je, nanti kita tak pakai dah kat SVO Builder)
  Stream<List<Pictogram>> getPictograms(String category) {
    String currentUid = _auth.currentUser?.uid ?? 'NONE';
    return _db
        .collection('library_v2')
        .where('category', isEqualTo: category)
        .where('ownerId', whereIn: ['GLOBAL', currentUid])
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
  }
}