import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../patient/quick_needs_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
// 🚀 IMPORT PAKEJ BIOMETRIC KITA
import 'package:local_auth/local_auth.dart';

class PatientPinScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  const PatientPinScreen({super.key, required this.patientData});

  @override
  State<PatientPinScreen> createState() => _PatientPinScreenState();
}

class _PatientPinScreenState extends State<PatientPinScreen> {
  String _pin = "";
  bool _isLoading = false;
  bool _isLocked = false;
  final FlutterTts _tts = FlutterTts();

  // 🚀 LITAR BIOMETRIC
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage("ms-MY");
    // Automatik suruh pesakit guna cap jari bila masuk skrin ni
    _authenticateBiometric();
  }

  // 🚀 FUNGSI CAP JARI DEWA (VERSI KEBAL ERROR)
  Future<void> _authenticateBiometric() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        // Fon takde cap jari, so ignore je
        return;
      }

      // 🚀 KITA BOGELKAN DIA, TINGGAL YANG ASAS JE
      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Gunakan cap jari atau wajah anda untuk log masuk',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        HapticFeedback.heavyImpact(); // Gegar kuat tanda berjaya!
        await _tts.speak("Akses Diterima");
        _loginSuccess();
      }
    } on PlatformException catch (e) {
      debugPrint("🚨 J.A.R.V.I.S ERROR: Biometric Gagal -> $e");
    }
  }

  // 🚀 LITAR LOGIN BERJAYA (Asingkan supaya senang dipanggil)
  Future<void> _loginSuccess() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_patient_logged_in', true);
    await prefs.setString('patient_id', widget.patientData['patient_id']);
    await prefs.setString('patient_name', widget.patientData['name']);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const QuickNeedsScreen()), (route) => false);
  }

  void _onKeyPress(String value) async {
    if (_isLocked || _pin.length >= 4) return;

    HapticFeedback.lightImpact();
    await _tts.speak(value);

    setState(() {
      _pin += value;
      _isLocked = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLocked = false);
    });

    if (_pin.length == 4) _verifyPin();
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    if (_pin == widget.patientData['pin_code']) {
      _loginSuccess();
    } else {
      HapticFeedback.vibrate(); // Gegar error
      await _tts.speak("PIN Salah");
      setState(() { _pin = ""; _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN SALAH MAT! Cuba lagi."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          const Icon(Icons.lock_person_rounded, size: 80, color: AppTheme.primaryBlue),
          const SizedBox(height: 24),
          Text("HELLO, ${widget.patientData['name']?.toUpperCase()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Text("Sila masukkan kod PIN keselamatan anda", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: index < _pin.length ? AppTheme.primaryBlue : Colors.grey[200])
              ))
          ),
          const Spacer(),
          if (_isLoading) const CircularProgressIndicator()
          else Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
              child: Column(
                  children: [
                    _buildRow(["1", "2", "3"]),
                    _buildRow(["4", "5", "6"]),
                    _buildRow(["7", "8", "9"]),
                    // 🚀 TUKAR "null" JADI "BIO" KAT SINI
                    _buildRow(["BIO", "0", "BACK"])
                  ]
              )
          )
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {

          // 🚀 LUKIS BUTANG BIOMETRIK (CAP JARI)
          if (key == "BIO") {
            return Container(
                margin: const EdgeInsets.all(8), width: 80, height: 80,
                child: ElevatedButton(
                    onPressed: _authenticateBiometric,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryBlue, size: 36)
                )
            );
          }

          // LUKIS BUTANG BACK ATAU NOMBOR
          return Container(
              margin: const EdgeInsets.all(8), width: 80, height: 80,
              child: ElevatedButton(
                  onPressed: key == "BACK" ? _onBackspace : () => _onKeyPress(key),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: key == "BACK"
                      ? const Icon(Icons.backspace_rounded, color: Colors.red)
                      : Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87))
              )
          );
        }).toList()
    );
  }
}