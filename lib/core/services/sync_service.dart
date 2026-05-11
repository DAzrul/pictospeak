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

      print("J.A.R.V.I.S: Protokol Auto-Purge diaktifkan...");

      // 🚨 1. NUCLEAR RESET AUTOMATIK!
      await _localDB.deleteAllPictograms();

      QuerySnapshot snapshot;

      // 🚨 2. LOGIK TAKTIKAL J.A.R.V.I.S (Anti-Block)
      if (user == null) {
        // GUEST MODE: Minta GLOBAL je. Jangan minta benda pelik nanti kena block!
        print("J.A.R.V.I.S: Guest Mode. Tarik data GLOBAL sahaja.");
        snapshot = await _firestore
            .collection('library_v2')
            .where('ownerId', isEqualTo: 'GLOBAL')
            .get();
      } else {
        // LOGIN MODE: Minta GLOBAL dan Private ikon kau
        print("J.A.R.V.I.S: Auth Mode. Tarik data GLOBAL & Private.");
        snapshot = await _firestore
            .collection('library_v2')
            .where('ownerId', whereIn: ['GLOBAL', user.uid])
            .get();
      }

      if (snapshot.docs.isEmpty) {
        print("J.A.R.V.I.S: Awan kosong. Takde data ditarik.");
        return;
      }

      // 3. Sumbat data baru dalam SQLite
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        await _localDB.insertOrUpdatePictogram(data, doc.id);
      }

      print("J.A.R.V.I.S: Sync selesai! Memori kini sedia untuk digempur.");
    } catch (e) {
      print("J.A.R.V.I.S: Sync Gagal babi! -> $e"); // Tengok terminal kalau error ni keluar
    }
  }
}