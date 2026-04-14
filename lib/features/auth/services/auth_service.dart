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
  // 2. KUNCI FIREBASE (Untuk Penjaga Login)
  // ---------------------------------------------------------
  Future<User?> loginCaregiver(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error Login Bodoh: $e");
      return null;
    }
  }

  // ---------------------------------------------------------
  // 3. PETI BESI PIN (Simpan PIN ikut User ID)
  // ---------------------------------------------------------
  Future<void> savePin(String pin) async {
    final user = _auth.currentUser; // Kenal pasti siapa tengah aktif

    if (user != null) {
      // Kita buat nama kunci unik untuk setiap orang
      String uniqueKey = 'pin_${user.uid}';
      await _secureStorage.write(key: uniqueKey, value: pin);
      print("PIN $pin berjaya dikunci dalam peti $uniqueKey!");
    } else {
      print("Woi, macam mana nak save PIN kalau tak login lagi?");
    }
  }

  // ---------------------------------------------------------
  // 4. PEMERIKSA PIN (Check masa nak masuk Caregiver Gate)
  // ---------------------------------------------------------
  Future<bool> verifyPin(String enteredPin) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    String uniqueKey = 'pin_${user.uid}';
    String? savedPin = await _secureStorage.read(key: uniqueKey);

    if (savedPin == null) {
      print("PIN belum di-setup lagi untuk user ni!");
      return false;
    }
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
  // 6. AMBIL PIN (Untuk check session kat main.dart / login_screen)
  // ---------------------------------------------------------
  Future<String?> getSavedPin() async {
    final user = _auth.currentUser;
    if (user == null) return null; // Kalau takde sapa login, return null terus

    String uniqueKey = 'pin_${user.uid}';
    return await _secureStorage.read(key: uniqueKey);
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
}
