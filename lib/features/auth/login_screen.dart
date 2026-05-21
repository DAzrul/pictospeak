import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/sync_service.dart';
import 'services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
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

  void _navigateToDashboard() {
    SyncService().syncFromFirebase();
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
      _showSnackBar('E-mel & Password wajib isi babi!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.loginCaregiver(email, password);
    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) _navigateToDashboard();
    } else {
      _showSnackBar('Login Gagal. Salah info ni mat.', Colors.red);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        print("J.A.R.V.I.S: Login Google Berjaya. Terbang ke Dashboard!");
        if (mounted) _navigateToDashboard();
      } else {
        // Kalau user tekan back atau cancel masa pilih akaun
        setState(() => _isLoading = false);
        _showSnackBar('Login dibatalkan oleh pengguna.', Colors.orange);
      }
    } catch (e) {
      // 🚨 J.A.R.V.I.S: Tangkap error kalau litar terbakar
      setState(() => _isLoading = false);
      print("J.A.R.V.I.S: Ralat Kritikal Google Login -> $e");
      _showSnackBar('Ralat: Sila check internet atau SHA-1 Firebase kau.', Colors.red);
    }
  }

  void _handleBiometricLogin() async {
    bool authenticated = await _authService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      setState(() => _isLoading = true);
      bool loggedIn = await _authService.silentLogin();
      setState(() => _isLoading = false);
      if (loggedIn) _navigateToDashboard();
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(), // Logo baru yang dah repair
              const SizedBox(height: 48),

              // --- FORM KAD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20, offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Caregiver Portal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    const SizedBox(height: 24),

                    // Email Field
                    _buildTextField(_emailController, 'Email', Icons.email_outlined, false),
                    const SizedBox(height: 18),

                    // Password Field (Biometric minimized kat sini!)
                    _buildPasswordField(),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                        child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SIGN IN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Google Login
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 22,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            const Text('Continue with Google', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🚀 J.A.R.V.I.S: Tarik naik atas sikit biar nampak rapat
              const SizedBox(height: 16),

              _buildSignUpLink(),

              // 🚀 J.A.R.V.I.S: Ruang bernafas kat bawah sekali supaya tak langgar bucu fon
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- REPAIRED LOGO (NO MORE CACAT) ---
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 100, width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 25, offset: const Offset(0, 12)
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12), // Jarakkan logo dari border sikit
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/pictospeak.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('PictoSpeak', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  // Email Field Helper
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
      ),
    );
  }

  // 🚨 J.A.R.V.I.S: Password field yang dah disumbat Biometric icon
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryBlue, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Mata (Show/Hide)
            IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            // 🚨 Icon Fingerprint (Hanya muncul kalau ada saved session)
            if (_hasSavedPin)
              IconButton(
                icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryBlue, size: 24),
                onPressed: _handleBiometricLogin,
              ),
          ],
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New caregiver?", style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.w500)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
          child: const Text('Register Now', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
        ),
      ],
    );
  }
}