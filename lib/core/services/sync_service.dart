import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_db.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDB _localDB = LocalDB();

  Future<void> syncFromFirebase() async {
    try {
      User? user = _auth.currentUser;
      // Kalau tak login, kita anggap dia 'GUEST'
      String currentUid = user?.uid ?? 'GUEST_USER';

      print("J.A.R.V.I.S: Protokol Auto-Purge diaktifkan untuk $currentUid...");

      // 🚨 1. NUCLEAR RESET AUTOMATIK!
      // Kita cuci dulu SQLite sebelum sedut data baru.
      await _localDB.deleteAllPictograms();

      // 2. Tarik data dari Firebase
      // Rule: Ambil 'GLOBAL' (untuk semua) + UID sendiri (untuk private)
      QuerySnapshot snapshot = await _firestore
          .collection('library_v2')
          .where('ownerId', whereIn: ['GLOBAL', currentUid])
          .get();

      if (snapshot.docs.isEmpty) {
        print("J.A.R.V.I.S: Awan kosong atau tiada akses.");
        return;
      }

      // 3. Sumbat data baru
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        await _localDB.insertOrUpdatePictogram(data, doc.id);
      }

      print("J.A.R.V.I.S: Sync selesai. Data kini bersih & spesifik untuk user.");
    } catch (e) {
      print("J.A.R.V.I.S: Sync Gagal! -> $e");
    }
  }
}