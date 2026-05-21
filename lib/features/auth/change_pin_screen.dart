import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'services/auth_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String enteredPin = '';
  final AuthService _authService = AuthService();

  void _onKeypadPressed(String value) {
    setState(() {
      if (value == 'back') {
        if (enteredPin.isNotEmpty) {
          enteredPin = enteredPin.substring(0, enteredPin.length - 1);
        }
      } else if (value == 'clear') {
        enteredPin = '';
      } else {
        if (enteredPin.length < 4) {
          enteredPin += value;
        }
      }
    });
  }

  void _saveNewPin() async {
    if (enteredPin.length == 4) {
      await _authService.savePin(enteredPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PIN Baru berjaya dikemaskini!'),
              backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context); // Patah balik ke skrin Settings
      }
    }
  }

  Widget _buildKeypadButton(String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeypadPressed(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 75, height: 75,
          decoration: BoxDecoration(
            color: value == 'clear' || value == 'back' ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: value == 'clear' || value == 'back' ? Colors.transparent : Colors.grey.shade300),
            boxShadow: value == 'clear' || value == 'back' ? [] : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: value == 'back'
                ? const Icon(Icons.backspace_outlined, size: 28, color: AppTheme.textDark)
                : value == 'clear'
                ? const Icon(Icons.close, size: 28, color: Colors.grey)
                : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 50, color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          const Text('Update Security PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Enter your new 4-digit Quick Access PIN.', style: TextStyle(color: Colors.blueGrey[400])),
          const SizedBox(height: 32),

          // Penunjuk PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              bool isFilled = index < enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppTheme.primaryBlue : Colors.transparent,
                  border: Border.all(color: isFilled ? AppTheme.primaryBlue : Colors.grey.shade400, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),

          // Keypad
          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['1', '2', '3'].map((e) => _buildKeypadButton(e)).toList()),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['4', '5', '6'].map((e) => _buildKeypadButton(e)).toList()),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['7', '8', '9'].map((e) => _buildKeypadButton(e)).toList()),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['clear', '0', 'back'].map((e) => _buildKeypadButton(e)).toList()),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: enteredPin.length == 4 ? _saveNewPin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Update PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}