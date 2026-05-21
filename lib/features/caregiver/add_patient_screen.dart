import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/services/auth_service.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _pinController = TextEditingController();

  String _relationship = 'Parent';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // 🚀 J.A.R.V.I.S: Litar penghantaran data ke Sub-collection
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.addPatient(
          patientName: _nameController.text.trim(),
          age: _ageController.text.trim(),
          condition: _conditionController.text.trim(),
          relationship: _relationship,
          pinCode: _pinController.text.trim(), // PIN unik untuk pesakit ni
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesakit Berjaya Didaftarkan! 🦾'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Balik ke Dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal daftar pesakit: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Register New Patient', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionCard(),
                const SizedBox(height: 24),

                // --- FORM KAD ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Patient Full Name', Icons.face_rounded),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, 'Age', Icons.calendar_today_rounded, isNumber: true),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(_conditionController, 'Medical Condition (Optional)', Icons.medical_services_outlined, isMandatory: false),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),

                      // --- SECURITY PIN ---
                      const Text('Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Text('PIN ini digunakan oleh pesakit untuk login atau keluar dari mod AAC.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildTextField(_pinController, 'Set 4-Digit PIN', Icons.lock_clock_rounded, isNumber: true, isPin: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(child: Text('Pastikan maklumat pesakit tepat untuk laporan kesihatan masa depan.', style: TextStyle(color: Colors.blueGrey[800], fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, bool isMandatory = true, bool isPin = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: isPin ? 4 : null,
      obscureText: isPin,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        counterText: "",
      ),
      validator: (v) => (isMandatory && (v == null || v.trim().isEmpty)) ? 'Wajib isi babi!' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _relationship,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        prefixIcon: Icon(Icons.people_outline, color: Colors.grey.shade400, size: 20),
      ),
      items: ['Parent', 'Teacher', 'Therapist', 'Guardian']
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) => setState(() => _relationship = value!),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('REGISTER PATIENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }
}