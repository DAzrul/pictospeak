import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'pin_setup_screen.dart'; // <--- Wajib ke skrin SETUP dulu bila baru daftar

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller & Service
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Fungsi magik daftar user dengan Error Handling yang padu
  void _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validation Asas (Client-side)
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Woi, semua kotak wajib isi!', Colors.orange);
      return;
    }

    // Regex Check Format Email
    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
    if (!emailValid) {
      _showSnackBar('Format e-mel salah sial. Check balik @ dan .com', Colors.redAccent);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password kena sekurang-kurangnya 6 aksara!', Colors.redAccent);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Password tak sama, kau taip pakai mata ke telinga?', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Tembak Firebase
      final user = await _authService.registerCaregiver(email, password);

      if (user != null) {
        _showSnackBar('Akaun Berjaya! Sila set up PIN keselamatan anda.', Colors.green);

        // 3. Kalau berjaya, WAJIB ke skrin SETUP PIN untuk kunci fon
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PinSetupScreen()),
          );
        }
      }
    } on Exception catch (e) {
      // 4. Tangkap error spesifik dari Firebase
      String errorMessage = 'Gagal daftar. Sila cuba lagi.';
      String eString = e.toString();

      if (eString.contains('email-already-in-use')) {
        errorMessage = 'E-mel ni dah ada orang gunalah, Boss.';
      } else if (eString.contains('invalid-email')) {
        errorMessage = 'E-mel ni rupa dia macam scammer, check balik.';
      } else if (eString.contains('weak-password')) {
        errorMessage = 'Password kau lemah sangat, letaklah yang susah sikit.';
      } else if (eString.contains('network-request-failed')) {
        errorMessage = 'Internet UTeM tengah buat hal ke? Check connection.';
      }

      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo PictoSpeak
              Container(
                height: 80, width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/images/pictospeak.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Join PictoSpeak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text('Create a caregiver account to start', style: TextStyle(fontSize: 14, color: Colors.blueGrey[400])),
              const SizedBox(height: 32),

              // Kotak Putih (Card Form)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Email Address'),
                    _buildTextField(_emailController, 'yourname@email.com', false),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    _buildTextField(_passwordController, 'Create password', true),
                    const SizedBox(height: 20),
                    _buildLabel('Confirm Password'),
                    _buildTextField(_confirmPasswordController, 'Repeat password', true),
                    const SizedBox(height: 32),

                    // Butang Register dengan Loading State
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already a member?", style: TextStyle(color: Colors.blueGrey[500])),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Helpers
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
      ),
    );
  }
}