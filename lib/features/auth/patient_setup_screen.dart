import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../caregiver/caregiver_dashboard.dart';
import 'services/auth_service.dart';

class PatientSetupScreen extends StatefulWidget {
  const PatientSetupScreen({super.key});

  @override
  State<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends State<PatientSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caregiverNameController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  String _relationship = 'Parent';
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Ganti fungsi ni
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Tembak masuk Firestore!
      await _authService.savePatientProfile(
        caregiverName: _caregiverNameController.text.trim(),
        patientName: _patientNameController.text.trim(),
        age: _ageController.text.trim(),
        relationship: _relationship,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil Berjaya Disimpan!'), backgroundColor: Colors.green),
        );

        // Terus terbang ke Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Final Step! 🚀',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up the patient and caregiver profile.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[400]),
                ),
                const SizedBox(height: 32),

                // Kotak Putih Utama
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
                      _buildSectionTitle('Caregiver Information'),
                      _buildTextField(_caregiverNameController, 'Your Full Name', Icons.person_pin_outlined),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Patient Information'),
                      _buildTextField(_patientNameController, 'Patient Full Name', Icons.child_care),
                      const SizedBox(height: 16),
                      _buildTextField(_ageController, 'Patient Age', Icons.calendar_today_outlined, isNumber: true),
                      const SizedBox(height: 16),

                      const Text('Relationship to Patient', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _relationship,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Parent', 'Teacher', 'Therapist', 'Guardian']
                            .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                            .toList(),
                        onChanged: (value) => setState(() => _relationship = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      'Complete Setup & Enter Dashboard',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      validator: (v) => v!.isEmpty ? 'Wajib isi!' : null,
    );
  }
}