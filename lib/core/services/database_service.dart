import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pictogram_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Tambah Piktogram Baru ke Awan
  Future<void> addPictogram(String en, String ms, String cat, String img, {bool isPublic = false}) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // 1. Simpan dalam library_v2 (Harta Sendiri)
      await _db.collection('library_v2').add({
        'label_en': en,
        'label_ms': ms,
        'category': cat,
        'image_url': img,
        'ownerId': currentUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Kalau user nak share, hantar ke community_submissions
      if (isPublic) {
        await _db.collection('community_submissions').add({
          'label_en': en,
          'label_ms': ms,
          'category': cat,
          'image_url': img,
          'submittedBy': currentUid,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      print("J.A.R.V.I.S: Data berjaya dihantar!");
    } catch (e) {
      print("Error add pictogram: $e");
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

  // 4. 🚨 J.A.R.V.I.S: Fungsi khas untuk Admin Approve Piktogram
  Future<void> approveSubmission(Map<String, dynamic> data, String submissionId) async {
    try {
      // 1. Salin data masuk ke library_v2 tapi tukar ownerId jadi GLOBAL
      await _db.collection('library_v2').add({
        'label_en': data['label_en'],
        'label_ms': data['label_ms'],
        'category': data['category'],
        'image_url': data['image_url'],
        'ownerId': 'GLOBAL', // 🚨 Kunci utama untuk semua user nampak!
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Padam dari senarai pending
      await _db.collection('community_submissions').doc(submissionId).delete();

      print("J.A.R.V.I.S: Piktogram kini bergelar GLOBAL! Semua user akan dapat masa sync.");
    } catch (e) {
      print("Error approve: $e");
    }
  }
}