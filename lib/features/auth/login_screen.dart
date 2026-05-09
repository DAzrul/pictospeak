import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sync_service.dart'; // 🚨 J.A.R.V.I.S: Import lintah rahsia
import 'services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'pin_gate.dart';
import '../caregiver/caregiver_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasSavedPin = false;

  @override
  void initState() {
    super.initState();
    _checkSavedPin();
  }

  void _checkSavedPin() async {
    String? pin = await _authService.getSavedPin();
    if (pin != null && pin.isNotEmpty) {
      setState(() => _hasSavedPin = true);
    }
  }

  // 🚨 J.A.R.V.I.S: Fungsi nav baru untuk bakar sejarah lama
  void _navigateToDashboard() {
    // 1. Kejutkan lintah awan serta-merta lepas login berjaya
    SyncService().syncFromFirebase();

    // 2. Padam semua history navigasi supaya tak boleh 'back' ke Login/Splash
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
          (route) => false,
    );
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('E-mel dan password wajib isi babi!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.loginCaregiver(email, password);
    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) _navigateToDashboard();
    } else {
      _showSnackBar('Login Gagal. Sila periksa e-mel/password kau.', Colors.red);
    }
  }

  void _handleBiometricLogin() async {
    bool authenticated = await _authService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      _navigateToDashboard();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating)
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark, size: 20),
          // 🚨 Ini patah balik ke Splash/Landing
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), // 🚨 Pakai withValues
                        blurRadius: 20,
                        offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('Welcome Back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email Address', Icons.email_outlined, false),
                    const SizedBox(height: 10),
                    _buildTextField(_passwordController, 'Password', Icons.lock_outline, true),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                        child: const Text('Forgot password?', style: TextStyle(color: AppTheme.primaryBlue)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAuthButton(Icons.dialpad, "Use PIN", () {
                    if (_hasSavedPin) {
                      // PIN Gate juga perlukan navigasi replacement nanti
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PinGateScreen()));
                    } else {
                      _showSnackBar('Tiada PIN direkodkan! Sila login guna e-mel dulu.', Colors.orange);
                    }
                  }),
                  _buildQuickAuthButton(Icons.fingerprint, "Biometric", () {
                    if (_hasSavedPin) {
                      _handleBiometricLogin();
                    } else {
                      _showSnackBar('Akaun tak aktif! Sila login guna e-mel dulu.', Colors.orange);
                    }
                  }),
                ],
              ),
              const SizedBox(height: 24),
              _buildSignUpLink(),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80, width: 80,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]
          ),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/pictospeak.png', fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40))
          ),
        ),
        const SizedBox(height: 16),
        const Text('PictoSpeak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text('Caregiver Portal', style: TextStyle(fontSize: 14, color: Colors.blueGrey[400])),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildQuickAuthButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: TextStyle(color: Colors.blueGrey[500])),
        TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
            child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
        ),
      ],
    );
  }
}