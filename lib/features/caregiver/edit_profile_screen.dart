import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caregiverNameController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  String _relationship = 'Parent';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _caregiverNameController.dispose();
    _patientNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // 🚨 J.A.R.V.I.S: Tarik data lama dari Firebase
  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _caregiverNameController.text = data['caregiverName'] ?? '';
            _patientNameController.text = data['patientName'] ?? '';
            _ageController.text = data['patientAge']?.toString() ?? '';

            // Pastikan nilai dropdown wujud dalam list
            String fetchedRel = data['relationship'] ?? 'Parent';
            if (['Parent', 'Teacher', 'Therapist', 'Guardian'].contains(fetchedRel)) {
              _relationship = fetchedRel;
            } else {
              _relationship = 'Parent';
            }
          });
        }
      } catch (e) {
        print("Error sedut data: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // 🚨 J.A.R.V.I.S: Tembak data baru ke Firebase
  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).update({
            'caregiverName': _caregiverNameController.text.trim(),
            'patientName': _patientNameController.text.trim(),
            'patientAge': _ageController.text.trim(),
            'relationship': _relationship,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil Berjaya Dikemaskini!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // Tendang balik ke Settings
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Patient Profile', style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Details 📝',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your caregiver and patient info up to date.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[400]),
                ),
                const SizedBox(height: 32),

                // 🚨 J.A.R.V.I.S: Kotak Putih Utama (Klon dari Setup)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200)
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200)
                          ),
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
                    onPressed: _isSaving ? null : _saveProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
      ),
      validator: (v) => v!.isEmpty ? 'Wajib isi!' : null,
    );
  }
}