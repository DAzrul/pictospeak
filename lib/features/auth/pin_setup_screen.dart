import 'package:flutter/material.dart';
import 'package:pictospeak/features/auth/patient_setup_screen.dart';
import '../../core/theme/app_theme.dart';
import 'services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String firstPin = '';
  String confirmPin = '';
  bool isConfirming = false;
  final AuthService _authService = AuthService();

  void _onKeypadPressed(String value) async {
    setState(() {
      if (value == 'back') {
        if (!isConfirming) {
          if (firstPin.isNotEmpty) firstPin = firstPin.substring(0, firstPin.length - 1);
        } else {
          if (confirmPin.isNotEmpty) confirmPin = confirmPin.substring(0, confirmPin.length - 1);
        }
      } else if (value == 'clear') {
        firstPin = '';
        confirmPin = '';
        isConfirming = false;
      } else {
        if (!isConfirming) {
          if (firstPin.length < 4) firstPin += value;
        } else {
          if (confirmPin.length < 4) confirmPin += value;
        }
      }
    });

    if (firstPin.length == 4 && !isConfirming) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        isConfirming = true;
      });
    } else if (confirmPin.length == 4 && isConfirming) {
      if (firstPin == confirmPin) {
        await _authService.savePin(confirmPin);

        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientSetupScreen())
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN tidak padan. Sila cuba lagi.'), backgroundColor: Colors.red),
        );
        setState(() {
          confirmPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth > 400 ? 80.0 : 70.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      // TAMBAH APPBAR UNTUK BUTANG SKIP
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Buang butang back default
        actions: [
          TextButton(
            onPressed: () {
              // Kalau malas buat PIN, lompat ke isi profil pesakit terus
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PatientSetupScreen()),
              );
            },
            child: const Text('Skip', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10), // Kurangkan sikit ruang atas sebab dah ada AppBar

            // Ikon Keselamatan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.shield_outlined, size: 40, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 24),

            Text(
              isConfirming ? 'Confirm Your PIN' : 'Set Security PIN',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              isConfirming ? 'Enter the 4-digit PIN again' : 'Create a 4-digit PIN for portal access',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey[400]),
            ),
            const SizedBox(height: 40),

            // Bulatan Indikator PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                String currentStr = isConfirming ? confirmPin : firstPin;
                bool isFilled = index < currentStr.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primaryBlue : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppTheme.primaryBlue : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Keypad Pad
            Column(
              children: [
                _buildRow(['1', '2', '3'], buttonSize),
                _buildRow(['4', '5', '6'], buttonSize),
                _buildRow(['7', '8', '9'], buttonSize),
                _buildRow(['clear', '0', 'back'], buttonSize),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> values, double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((val) => _buildKey(val, size)).toList(),
    );
  }

  Widget _buildKey(String val, double size) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: () => _onKeypadPressed(val),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (val == 'clear' || val == 'back') ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: (val == 'clear' || val == 'back') ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: (val == 'clear' || val == 'back') ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: val == 'back' ? const Icon(Icons.backspace_outlined, color: AppTheme.textDark) :
            val == 'clear' ? const Icon(Icons.close, color: Colors.grey) :
            Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
        ),
      ),
    );
  }
}