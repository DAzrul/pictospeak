import 'package:firebase_auth/firebase_auth.dart'; // <-- Dah dibaiki! Takde double package dah
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Panggil ejen-ejen rahsia kita
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------
  // 1. REAKTOR FIREBASE (Untuk Daftar Penjaga Baru)
  // ---------------------------------------------------------
  Future<User?> registerCaregiver(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error Register Sial: $e");
      return null;
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

      // 🚨 J.A.R.V.I.S: Hafal e-mel & password untuk Silent Login guna PIN nanti
      await _secureStorage.write(key: 'saved_email', value: email);
      await _secureStorage.write(key: 'saved_password', value: password);

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
    // Kita simpan PIN untuk fon ni terus, tak payah check UID dah
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
      // Check fon kau support cap jari/Face ID ke tak
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        print("Phone kau takde sensor jari/muka. Pakai PIN jelah.");
        return false;
      }

      // Tembak popup suruh letak jari (Sintaks paling basic, kalis error)
      return await _localAuth.authenticate(
        localizedReason: 'Sila imbas jari atau muka untuk masuk ke sistem Penjaga.',
      );
    } catch (e) {
      print("Error Biometric Babi: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // 6. AMBIL PIN (Untuk check kat Login Screen)
  // ---------------------------------------------------------
  Future<String?> getSavedPin() async {
    // Tak payah check currentUser == null lagi. Terus ambik dari peti.
    return await _secureStorage.read(key: 'device_quick_pin');
  }

  // ---------------------------------------------------------
  // 7. SIMPAN PROFIL PESAKIT KE FIRESTORE
  // ---------------------------------------------------------
  Future<void> savePatientProfile({
    required String caregiverName,
    required String patientName,
    required String age,
    required String relationship,
  }) async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Kita simpan dlm folder 'caregivers', nama fail ikut UID user
        await _firestore.collection('caregivers').doc(user.uid).set({
          'caregiverName': caregiverName,
          'patientName': patientName,
          'patientAge': age,
          'relationship': relationship,
          'createdAt': FieldValue.serverTimestamp(), // Tanda waktu bila dia daftar
        });
        print("Data berjaya disumbat masuk Firestore!");
      } catch (e) {
        print("Error sumbat data babi: $e");
      }
    } else {
      print("Woi, user belum login la!");
    }
  }

  // ---------------------------------------------------------
  // 🚨 8. FUNGSI BARU: SILENT LOGIN (Guna masa PIN betul)J.A.R.V.I.S: Fungsi untuk pecah masuk Firebase secara senyap
  // --------------------------------------------------------
  Future<bool> silentLogin() async {
    try {
      // 1. Sedut balik e-mel & password dari peti besi rahsia
      String? email = await _secureStorage.read(key: 'saved_email');
      String? password = await _secureStorage.read(key: 'saved_password');

      if (email != null && password != null) {
        // 2. Tembak Firebase secara latar belakang
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        print("J.A.R.V.I.S: Silent Login Berjaya! Firebase dah kenal kau.");
        return true;
      }
      print("J.A.R.V.I.S: Data login tak jumpa. Kena login manual sekali.");
      return false;
    } catch (e) {
      print("Silent Login Gagal: $e");
      return false;
    }
  }
}
