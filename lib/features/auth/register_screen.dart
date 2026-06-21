import 'dart:async'; // 🚀 WAJIB UNTUK STREAM SUBSCRIPTION
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 WAJIB UNTUK SEDUT DATA FIREBASE
import '../../core/theme/app_theme.dart';
import '../caregiver/caregiver_dashboard.dart';
import 'services/auth_service.dart';
import 'pin_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🚀 LITAR PENGAWAL KESELAMATAN J.A.R.V.I.S
  bool _allowSignups = true; // Default ON
  StreamSubscription<DocumentSnapshot>? _configSubscription;

  @override
  void initState() {
    super.initState();
    // 🚀 Litar Intip "Allow New Sign-ups" secara live!
    _configSubscription = FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _allowSignups = doc.data()?['allow_signups'] ?? true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _configSubscription?.cancel(); // 🚀 WAJIB TUTUP LITAR SUPAYA TAK BOCOR MEMORI
    super.dispose();
  }

  // --- LOGIC HANDLERS ---

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.', Colors.redAccent);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerCaregiver(name, email, password);
      if (user != null) {
        _showSnackBar('Registration successful! Please set up your security PIN.', Colors.green);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PinSetupScreen()),
          );
        }
      }
    } catch (e) {
      _showSnackBar('Registration failed: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleRegister() async {
    setState(() => _isLoading = true);

    try {
      print("🚨 J.A.R.V.I.S: Disconnecting any active sessions to prevent overlap...");
      await _authService.signOut(forceGoogleDisconnect: true);

      print("J.A.R.V.I.S: Initiating clean Google Sign-In circuit...");
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _showSnackBar('Google Sign-Up successful!', Colors.green);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
                (route) => false,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Process cancelled or no account selected.', Colors.orange);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("🚨 J.A.R.V.I.S ERROR: $e");
      _showSnackBar('A critical error occurred. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
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
              _buildHeader(),
              const SizedBox(height: 32),

              // --- FORM KAD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Caregiver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text('Create an account to start monitoring patients.', style: TextStyle(color: Colors.blueGrey[400], fontSize: 13)),
                    const SizedBox(height: 24),

                    _buildTextField(_nameController, 'Full Name', Icons.person_outline, false),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email_outlined, false),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password', Icons.lock_outline_rounded, true),
                    const SizedBox(height: 16),
                    _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock_reset_rounded, true),

                    const SizedBox(height: 24),

                    // 🚀 BUTANG DAFTAR MANUAL (LITAR KILL SWITCH)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          // Tembak litar pengehadan!
                          if (!_allowSignups) {
                            _showSnackBar("Pendaftaran akaun baru ditutup oleh pihak pentadbir.", Colors.redAccent);
                            return;
                          }
                          _handleRegister();
                        },
                        style: ElevatedButton.styleFrom(
                          // Kalau switch off, tukar butang jadi kelabu mati
                          backgroundColor: _allowSignups ? AppTheme.primaryBlue : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                            _allowSignups ? 'CREATE ACCOUNT' : 'REGISTRATION CLOSED',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DIVIDER "OR"
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🚀 BUTANG GOOGLE (LITAR KILL SWITCH)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          // Tembak litar pengehadan Google!
                          if (!_allowSignups) {
                            _showSnackBar("Pendaftaran akaun baru ditutup oleh pihak pentadbir.", Colors.redAccent);
                            return;
                          }
                          _handleGoogleRegister();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade200),
                          backgroundColor: _allowSignups ? Colors.transparent : Colors.grey.shade100, // Matikan latar belakang sikit
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_logo.png',
                              height: 22,
                              color: _allowSignups ? null : Colors.grey, // 🚀 Matikan warna logo Google jadi hitam putih
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Text('Sign up with Google', style: TextStyle(color: _allowSignups ? const Color(0xFF475569) : Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSignInLink(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 90, width: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/images/pictospeak.png', fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Join PictoSpeak', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      // Kalau sistem tutup pendaftaran, kotak form auto mati
      enabled: _allowSignups,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _allowSignups ? AppTheme.primaryBlue : Colors.grey, size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: _allowSignups ? const Color(0xFFF8FAFC) : Colors.grey.shade100,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?", style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.w500)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
        ),
      ],
    );
  }
}