import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🚨 Wajib ada!
import 'package:path/path.dart' as p; // 🚨 Untuk ambil extension file
import '../models/pictogram_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // 🚨 Enjin Storage

  // --- 1. UPLOAD GAMBAR KE CLOUD STORAGE ---
  Future<String> uploadPictogramImage(File imageFile) async {
    try {
      // Buat nama unik guna timestamp + extension asal (e.g. .jpg)
      String fileName = 'pic_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';

      // Referensi folder 'pictograms' dalam Firebase Storage
      Reference ref = _storage.ref().child('pictograms').child(fileName);

      // Mula proses tembak gambar ke awan
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Ambil link (URL) gambar yang dah siap upload
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print("J.A.R.V.I.S: Gambar berjaya mendarat di Storage! URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("J.A.R.V.I.S: Enjin Storage sangkut! Error: $e");
      return ""; // Pulangkan kosong kalau fail
    }
  }

  // --- 2. TAMBAH PIKTOGRAM (PRIVATE & COMMUNITY) ---
  Future<void> addPictogram(String en, String ms, String cat, String img, List<String> tags, {bool isPublic = false}) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      await _db.collection('library_v2').add({
        'label_en': en,
        'label_ms': ms,
        'category': cat,
        'image_url': img,
        'tags': tags, // 🚨 SIMPAN TAGS (Private)
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
          'tags': tags, // 🚨 INI YANG BOCOR TADI! Kena hantar tags kat admin jugak!
          'submittedBy': currentUid,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      print("J.A.R.V.I.S: Data piktogram berjaya didaftarkan!");
    } catch (e) {
      print("Error add pictogram: $e");
    }
  }

  // --- 3. AMBIL SEMUA DATA (LIBRARY EXPLORER) ---
  Stream<List<Pictogram>> getAllPictograms() {
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      // Kalau GUEST (tak login), tayang GLOBAL je
      return _db.collection('library_v2')
          .where('ownerId', isEqualTo: 'GLOBAL')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
    } else {
      // Kalau dah login, tayang GLOBAL + Hak Milik Sendiri
      return _db.collection('library_v2')
          .where('ownerId', whereIn: ['GLOBAL', currentUid])
          .snapshots()
          .map((snap) => snap.docs.map((doc) => Pictogram.fromFirestore(doc)).toList());
    }
  }

  // --- 4. FUNGSI PADAM (TERMINATE DATA) ---
  Future<void> deletePictogram(String id) async {
    try {
      await _db.collection('library_v2').doc(id).delete();
      print("J.A.R.V.I.S: Data $id telah dihapuskan dari sistem.");
    } catch (e) {
      print("J.A.R.V.I.S: Gagal delete: $e");
    }
  }

  // --- 5. ADMIN APPROVAL SYSTEM ---
  Future<void> approveSubmission(Map<String, dynamic> data, String submissionId) async {
    try {
      // 1. Salin data ke library_v2 dengan ownerId GLOBAL
      await _db.collection('library_v2').add({
        'label_en': data['label_en'],
        'label_ms': data['label_ms'],
        'category': data['category'],
        'image_url': data['image_url'],
        'tags': data.containsKey('tags') ? data['tags'] : [], // 🚨 SALIN TAGS SEKALI MASA APPROVE!
        'ownerId': 'GLOBAL', // Supaya semua user boleh nampak
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Buang dari senarai pending
      await _db.collection('community_submissions').doc(submissionId).delete();

      print("J.A.R.V.I.S: Submission di-approve! Kini berstatus GLOBAL.");
    } catch (e) {
      print("Error approve: $e");
    }
  }

  Future<void> updatePictogram(String id, String newEn, String newMs, String newCat) async {
    try {
      await _db.collection('library_v2').doc(id).update({
        'label_en': newEn,
        'label_ms': newMs,
        'category': newCat,
        'timestamp': FieldValue.serverTimestamp(), // Update masa dia edit
      });
      print("J.A.R.V.I.S: Data $id dah siap di-upgrade!");
    } catch (e) {
      print("Error update: $e");
    }
  }
}