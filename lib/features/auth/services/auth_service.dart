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

      if (email == null) {
        print("J.A.R.V.I.S: Tiada data email dijumpai dalam storan selamat.");
        return false;
      }

      // 🚀 CABANG A: Jika pengguna sebelum ni login guna Google
      if (method == 'google') {
        print("J.A.R.V.I.S: Mengaktifkan litar pintas Google Silent Login...");
        // Re-authenticate secara senyap menggunakan GoogleSignIn cache peranti
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await _auth.signInWithCredential(credential);
          print("J.A.R.V.I.S: Google Biometric Login Berjaya!");
          return true;
        }
      }

      // 🚀 CABANG B: Jika pengguna sebelum ni login guna E-mel biasa
      else {
        String? password = await _secureStorage.read(key: 'saved_password');
        if (password != null) {
          await _auth.signInWithEmailAndPassword(email: email, password: password);
          print("J.A.R.V.I.S: Email Biometric Login Berjaya!");
          return true;
        }
      }

      return false;
    } catch (e) {
      print("🚨 J.A.R.V.I.S: Silent Login Gagal total -> $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // 🚀 9. GOOGLE LOGIN + AUTO-REGISTER
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
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          print("J.A.R.V.I.S: User Baru Dikesan! Mendaftarkan profile ke Firestore...");

          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? "Caregiver Baru",
            'email': user.email,
            'role': 'caregiver',
            'created_at': FieldValue.serverTimestamp(),
            'login_method': 'google',
          });
        } else {
          print("J.A.R.V.I.S: User Lama. Melangkau fasa pendaftaran.");
        }
      }

      return user;
    } catch (e) {
      print("J.A.R.V.I.S: Litar Google Register terbakar! -> $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // 10. PROTOKOL PEMUSNAHAN (LOGOUT TOTAL) - VERSI SELAMAT
  // ---------------------------------------------------------
    Future<void> signOut() async {
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();

        // 🚀 J.A.R.V.I.S: JANGAN DELETE 'saved_email' & 'saved_password' kat sini mat!
        // Kalau kau delete kat sini, litar biometric kau automatik akan lumpuh total masa logout.
        // Kita cuma tamatkan session Firebase sahaja. Storan selamat dalam peranti kekal selamat.

        print("J.A.R.V.I.S: Sesi Firebase ditamatkan. Kredential biometrik dikekalkan dalam peti besi.");
      } catch (e) {
        print("J.A.R.V.I.S: Ralat masa logout -> $e");
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