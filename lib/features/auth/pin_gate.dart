import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sync_service.dart'; // 🚨 J.A.R.V.I.S: Cloud sync protocol
import 'services/auth_service.dart';
import '../caregiver/caregiver_dashboard.dart';

class PinGateScreen extends StatefulWidget {
  const PinGateScreen({super.key});

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen> {
  String enteredPin = '';
  bool isError = false;
  final AuthService _authService = AuthService();

  // 🚨 J.A.R.V.I.S: Clean navigation protocol
  void _navigateToDashboard() {
    // Trigger cloud synchronization
    SyncService().syncFromFirebase();

    // Clear the navigation stack to prevent back-tracking
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
          (route) => false,
    );
  }

  void _onKeypadPressed(String value) async {
    setState(() {
      isError = false;
      if (value == 'back') {
        if (enteredPin.isNotEmpty) enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      } else if (value == 'clear') {
        enteredPin = '';
      } else {
        if (enteredPin.length < 4) enteredPin += value;
      }
    });

    // 🚨 J.A.R.V.I.S: Execute silent login upon 4-digit entry completion
    if (enteredPin.length == 4) {
      bool isValid = await _authService.verifyPin(enteredPin);

      if (isValid) {
        // 1. PIN verified. Initiating silent Firebase authentication.
        bool loggedIn = await _authService.silentLogin();

        if (loggedIn && mounted) {
          // 2. Firebase session established. Proceeding to Dashboard.
          _navigateToDashboard();
        } else {
          // Handle Firebase rejection despite correct PIN (e.g., credentials changed)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session expired. Please log in again using your email.'), backgroundColor: Colors.orange),
            );
            Navigator.pop(context); // Redirect to manual login
          }
        }
      } else {
        // Invalid PIN handling
        if (mounted) {
          setState(() {
            isError = true;
            enteredPin = ''; // Reset input field
          });
        }
      }
    }
  }

  // 🚨 J.A.R.V.I.S: Biometric Handler Protocol
  void _handleBiometric() async {
    // 1. Initiate biometric scan
    bool authenticated = await _authService.authenticateWithBiometrics();

    if (authenticated) {
      // 🚨 J.A.R.V.I.S: DO NOT PROCEED TO DASHBOARD IMMEDIATELY!
      // Firebase session must be re-authenticated first.
      bool loggedIn = await _authService.silentLogin();

      if (loggedIn && mounted) {
        // Firebase session active, routing to Dashboard.
        _navigateToDashboard();
      } else {
        // Handle failure (e.g., offline or credentials changed)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again using your email.'), backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  Widget _buildKeypadButton(String value, double size) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeypadPressed(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: value == 'clear' || value == 'back' ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value == 'clear' || value == 'back' ? Colors.transparent : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: value == 'clear' || value == 'back' ? [] : [
              BoxShadow(
                // 🚨 J.A.R.V.I.S: Opacity warning fix (withValues)
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: value == 'back'
                ? const Icon(Icons.backspace_outlined, size: 28, color: AppTheme.textDark)
                : value == 'clear'
                ? const Icon(Icons.close, size: 32, color: Colors.grey)
                : Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth > 400 ? 80.0 : 70.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        // 🚨 J.A.R.V.I.S: Opacity warning fix (withValues)
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.fingerprint, size: 40, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(height: 20),

                      const Text('Caregiver Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Text('Enter your 4-digit PIN to continue', style: TextStyle(fontSize: 14, color: Colors.blueGrey[400])),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          bool isFilled = index < enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? AppTheme.primaryBlue : Colors.transparent,
                              border: Border.all(color: isFilled ? AppTheme.primaryBlue : Colors.grey.shade400, width: 2),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 20,
                        child: isError ? const Text('Invalid PIN. Please try again.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : null,
                      ),

                      const Spacer(),

                      Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['1', '2', '3'].map((e) => _buildKeypadButton(e, buttonSize)).toList()),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['4', '5', '6'].map((e) => _buildKeypadButton(e, buttonSize)).toList()),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['7', '8', '9'].map((e) => _buildKeypadButton(e, buttonSize)).toList()),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: ['clear', '0', 'back'].map((e) => _buildKeypadButton(e, buttonSize)).toList()),
                        ],
                      ),

                      const Spacer(),

                      TextButton.icon(
                        onPressed: _handleBiometric,
                        icon: const Icon(Icons.fingerprint, color: AppTheme.primaryBlue),
                        label: const Text('Use Biometric Login', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Text('FaceID / Fingerprint', style: TextStyle(fontSize: 12, color: Colors.blueGrey[300])),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}