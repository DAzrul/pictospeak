import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../patient/quick_needs_screen.dart';

class PatientPinScreen extends StatefulWidget {
  final Map<String, dynamic> patientData; // 🚀 J.A.R.V.I.S: Terima data pesakit dari skrin sebelah
  const PatientPinScreen({super.key, required this.patientData});

  @override
  State<PatientPinScreen> createState() => _PatientPinScreenState();
}

class _PatientPinScreenState extends State<PatientPinScreen> {
  String _pin = "";
  bool _isLoading = false;

  void _onKeyPress(String value) {
    if (_pin.length < 4) { // 🚀 PS: Tadi kau set 6, tapi dlm AddPatient tadi aku buat 4. Ikut mana kau suka babi!
      setState(() => _pin += value);
      if (_pin.length == 4) _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    // 🚀 J.A.R.V.I.S: Verifikasi litar lokal je, tak payah panggil Firestore balik sbb data dah ada!
    if (_pin == widget.patientData['pin_code']) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_patient_logged_in', true);
      await prefs.setString('patient_id', widget.patientData['patient_id']);
      await prefs.setString('patient_name', widget.patientData['name']);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const QuickNeedsScreen()), (route) => false);
    } else {
      setState(() { _pin = ""; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN SALAH MAT! Cuba lagi."), backgroundColor: Colors.red));
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
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: index < _pin.length ? AppTheme.primaryBlue : Colors.grey[200])))),
          const Spacer(),
          if (_isLoading) const CircularProgressIndicator()
          else Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(40))), child: Column(children: [_buildRow(["1", "2", "3"]), _buildRow(["4", "5", "6"]), _buildRow(["7", "8", "9"]), _buildRow([null, "0", "BACK"])]))
        ],
      ),
    );
  }

  Widget _buildRow(List<String?> keys) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: keys.map((key) {
      if (key == null) return const SizedBox(width: 80, height: 80);
      return Container(margin: const EdgeInsets.all(8), width: 80, height: 80, child: ElevatedButton(onPressed: key == "BACK" ? _onBackspace : () => _onKeyPress(key), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: key == "BACK" ? const Icon(Icons.backspace_rounded, color: Colors.red) : Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87))));
    }).toList());
  }
}