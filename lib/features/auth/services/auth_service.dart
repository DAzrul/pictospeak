import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Panggil ejen-ejen rahsia kita
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ---------------------------------------------------------
  // 1. REAKTOR FIREBASE (Untuk Daftar Penjaga Baru)
  // ---------------------------------------------------------
  Future<User?> registerCaregiver(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // J.A.R.V.I.S: Sumbat nama dan e-mel masuk Firestore jadual 'caregivers'
        await _firestore.collection('caregivers').doc(user.uid).set({
          'uid': user.uid,
          'name': name, // Nama dari kotak RegisterScreen
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
          'login_method': 'email',
        });
        print("J.A.R.V.I.S: Profil Caregiver berjaya didaftarkan ke pangkalan data!");
      }
      return user;
    } catch (e) {
      print("Error Register Sial: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 2. KUNCI FIREBASE (Dah di-upgrade untuk hafal e-mel)
  // ---------------------------------------------------------
  Future<User?> loginCaregiver(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🚀 Hafal sekali dengan kaedah login dia
      await _secureStorage.write(key: 'saved_email', value: email);
      await _secureStorage.write(key: 'saved_password', value: password);
      await _secureStorage.write(key: 'login_method', value: 'email'); // Tambah ini!

      return userCredential.user;
    } catch (e) {
      print("Error Login Bodoh: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // 3. PETI BESI PIN (Simpan secara Global)
  // ---------------------------------------------------------
  Future<void> savePin(String pin) async {
    await _secureStorage.write(key: 'device_quick_pin', value: pin);
    print("PIN $pin berjaya dikunci secara global!");
  }

  // ---------------------------------------------------------
  // 4. PEMERIKSA PIN
  // ---------------------------------------------------------
  Future<bool> verifyPin(String enteredPin) async {
    String? savedPin = await _secureStorage.read(key: 'device_quick_pin');
    if (savedPin == null) return false;
    return savedPin == enteredPin;
  }

  // ---------------------------------------------------------
  // 5. CIP PENGIMBAS JARI/MUKA (Biometrics)
  // ---------------------------------------------------------
  Future<bool> authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        print("Phone kau takde sensor jari/muka. Pakai PIN jelah.");
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Sila imbas jari atau muka untuk masuk ke sistem Penjaga.',
      );
    } catch (e) {
      print("Error Biometric Babi: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // 6. AMBIL PIN / STATUS BIOMETRIC (Dah di-upgrade untuk check sesi universal)
  // ---------------------------------------------------------
  Future<bool> hasSavedBiometricSession() async {
    // Kita check sama ada peranti ni pernah ada akaun yang sukses log masuk atau tidak
    String? email = await _secureStorage.read(key: 'saved_email');
    String? method = await _secureStorage.read(key: 'login_method');

    // Kalau e-mel ada dan kaedah login wujud, maksudnya butang bio wajib muncul!
    return (email != null && email.isNotEmpty && method != null);
  }

  // Cari fungsi getSavedPin lama kau dan kekalkan buat sementara jika skrin PIN pesakit guna:
  Future<String?> getSavedPin() async {
    return await _secureStorage.read(key: 'device_quick_pin');
  }

  // ---------------------------------------------------------
  // 🚀 7. [LITAR BARU] TAMBAH PESAKIT KE SUB-COLLECTION
  // ---------------------------------------------------------
  Future<void> addPatient({
    required String patientName,
    required String age,
    required String condition,
    required String relationship,
    required String pinCode, // PIN khas untuk pesakit ni nak masuk skrin AAC
  }) async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // J.A.R.V.I.S: Kita buat laluan Sub-collection -> caregivers/{uid}/patients/{auto_id}
        DocumentReference patientRef = _firestore
            .collection('caregivers')
            .doc(user.uid)
            .collection('patients')
            .doc(); // Biar kosong, Firebase tolong auto-generate ID babi ni

        await patientRef.set({
          'patient_id': patientRef.id,
          'caregiver_id': user.uid,
          'name': patientName,
          'age': age,
          'condition': condition,
          'relationship': relationship,
          'pin_code': pinCode,
          'created_at': FieldValue.serverTimestamp(),
          'last_active': null, // Boleh update nanti bila pesakit guna
        });

        print("J.A.R.V.I.S: Pesakit $patientName berjaya disumbat ke Sub-collection!");
      } catch (e) {
        print("J.A.R.V.I.S Error sumbat data pesakit: $e");
        rethrow;
      }
    } else {
      print("Woi, user belum login la!");
    }
  }

  // ---------------------------------------------------------
  // 🚨 8. FUNGSI BARU: SILENT LOGIN UNIVERSAL (E-mel & Google)
  // --------------------------------------------------------
  Future<bool> silentLogin() async {
    try {
      String? email = await _secureStorage.read(key: 'saved_email');
      String? method = await _secureStorage.read(key: 'login_method');

      if (email == null) return false;

      // 🌐 JIKA USER GUNA GOOGLE SEBELUM NI
      // 🚀 CABANG A: Jika pengguna sebelum ni login guna Google
      if (method == 'google') {
        print("J.A.R.V.I.S: Mencuba sambungan senyap Google...");

        // Cuba tarik user yang tengah 'tidur' dalam cache
        GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

        // 🚨 J.A.R.V.I.S: Kalau fail, kita paksa dia login balik (ini akan keluar prompt akaun)
        // Tapi untuk biometrik, selalunya signInSilently dah cukup kalau tak kena 'hard signout'
        if (googleUser == null) {
          print("J.A.R.V.I.S: Sesi Google mati total. Kena login manual semula.");
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        return true;
      }
      // ✉️ JIKA USER GUNA EMAIL BIASA
      else {
        String? password = await _secureStorage.read(key: 'saved_password');
        if (password != null) {
          await _auth.signInWithEmailAndPassword(email: email, password: password);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // 🚀 9. GOOGLE LOGIN + AUTO-REGISTER (DAH FIX KANTOI KOPI)
  // ---------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 🚀 J.A.R.V.I.S: SIMPAN INFO UNTUK BIOMETRIC SESI DEPAN
        await _secureStorage.write(key: 'saved_email', value: user.email);
        await _secureStorage.write(key: 'login_method', value: 'google');

        print("J.A.R.V.I.S: Memeriksa status pendaftaran profil di Firestore...");

        // 🔥 LITAR BARU: Check sama ada data user ni dah wujud tak dalam table caregivers
        final docSnap = await _firestore.collection('caregivers').doc(user.uid).get();

        if (!docSnap.exists) {
          print("J.A.R.V.I.S: Pengguna Google baru dikesan! Menyuntik data profil induk...");

          // Cipta dokumen induk supaya tulisan kat Firebase tak senget/italic lagi!
          await _firestore.collection('caregivers').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'Caregiver Google', // Tarik nama dari akaun Google
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
            'login_method': 'google',
          });
          print("J.A.R.V.I.S: Profil Google baru berjaya didaftarkan ke Firestore!");
        } else {
          print("J.A.R.V.I.S: Profil sedia ada dijumpai. Melangkau proses ciptaan data.");
        }
      }
      return user;
    } catch (e) {
      print("Error Google: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // 10. PROTOKOL PEMUSNAHAN (LOGOUT TOTAL) - VERSI PINTAR
  // ---------------------------------------------------------
  Future<void> signOut({bool forceGoogleDisconnect = false}) async {
    try {
      await _auth.signOut();

      // 🚀 Kalau forceGoogleDisconnect == true, kita cantas terus jambatan Google!
      // Ini wajib dipanggil kat RegisterScreen supaya dia tak auto-login akaun lama.
      if (forceGoogleDisconnect) {
        await _googleSignIn.signOut();
        print("J.A.R.V.I.S: Firebase & Google session dimusnahkan secara paksa!");
      } else {
        print("J.A.R.V.I.S: Firebase session ditamatkan. Jambatan Google dikekalkan untuk biometrik.");
      }
    } catch (e) {
      print("🚨 Ralat masa logout: $e");
    }
  }

  // ---------------------------------------------------------
  // 🚀 11. [LITAR BARU] SEDUT SENARAI PESAKIT UNTUK DASHBOARD
  // ---------------------------------------------------------
  Stream<QuerySnapshot> getPatientsStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .orderBy('created_at', descending: true)
          .snapshots();
    } else {
      // Return stream kosong kalau takde user (supaya app tak crash babi)
      return const Stream.empty();
    }
  }
}