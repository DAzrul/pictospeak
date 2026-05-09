import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_db.dart'; // Import peti besi kita tadi

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDB _localDB = LocalDB();

  Future<void> syncFromFirebase() async {
    try {
      // 1. Semak siapa yang tengah pegang fon ni
      User? user = _auth.currentUser;
      String currentUid = user?.uid ?? 'NONE';

      print("J.A.R.V.I.S: Mengaktifkan Lintah Awan! (Mode UID: $currentUid)...");

      // 2. Tarik data dari collection BARU 'library_v2'
      // Hanya tarik 'GLOBAL' dan hak milik sendiri (UID)
      QuerySnapshot snapshot = await _firestore
          .collection('library_v2') // 🚨 KITA PAKAI COLLECTION BARU!
          .where('ownerId', whereIn: ['GLOBAL', currentUid])
          .get();

      if (snapshot.docs.isEmpty) {
        print("J.A.R.V.I.S: Awan kosong, tiada benda nak disedut.");
        return;
      }

      // 3. Sumbat semua data tu ke dalam perut SQLite
      int count = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        await _localDB.insertOrUpdatePictogram(data, doc.id);
        count++;
      }

      print("J.A.R.V.I.S: Syncing selesai! Berjaya merompak $count data masuk ke fon.");
    } catch (e) {
      print("J.A.R.V.I.S: ERROR MASA SYNCING SIAL! -> $e");
    }
  }
}