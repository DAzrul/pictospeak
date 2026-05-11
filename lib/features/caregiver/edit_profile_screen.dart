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

  // 🚨 J.A.R.V.I.S: Semua Controller Diaktifkan!
  final _caregiverNameController = TextEditingController();
  final _phoneController = TextEditingController(); // Baru
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController(); // Baru & Kritikal
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController(); // Baru

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
    _phoneController.dispose();
    _patientNameController.dispose();
    _patientIdController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            // Sedut data lama kalau ada
            _caregiverNameController.text = data['caregiverName'] ?? '';
            _phoneController.text = data['emergencyContact'] ?? '';
            _patientNameController.text = data['patientName'] ?? '';
            _patientIdController.text = data['patientId'] ?? '';
            _ageController.text = data['patientAge']?.toString() ?? '';
            _conditionController.text = data['patientCondition'] ?? '';

            String fetchedRel = data['relationship'] ?? 'Parent';
            if (['Parent', 'Teacher', 'Therapist', 'Guardian'].contains(fetchedRel)) {
              _relationship = fetchedRel;
            } else {
              _relationship = 'Parent';
            }
          });
        }
      } catch (e) {
        print("Error sedut data babi: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // 🚨 J.A.R.V.I.S: Guna set dgn merge supaya data selamat!
          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).set({
            'caregiverName': _caregiverNameController.text.trim(),
            'emergencyContact': _phoneController.text.trim(),
            'patientName': _patientNameController.text.trim(),
            'patientId': _patientIdController.text.trim(), // Kunci ke Dashboard!
            'patientAge': _ageController.text.trim(),
            'patientCondition': _conditionController.text.trim(),
            'relationship': _relationship,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile Updated Successfully! 🚀'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 50, color: AppTheme.primaryBlue),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 16, color: AppTheme.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🚨 KOTAK CAREGIVER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Caregiver Details', Icons.shield_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_caregiverNameController, 'Your Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Emergency Contact (Phone)', Icons.phone_outlined, isNumber: true),
                      const SizedBox(height: 16),
                      const Text('Relationship to Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🚨 KOTAK PESAKIT
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Patient Details', Icons.child_care),
                      const SizedBox(height: 16),
                      _buildTextField(_patientNameController, 'Patient Name', Icons.face),
                      const SizedBox(height: 16),

                      // Patient ID (Kritikal)
                      _buildTextField(_patientIdController, 'Patient UID (From Firebase)', Icons.fingerprint),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 12),
                        child: Text("Sangat penting! Letak UID akaun pesakit kat sini.", style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontStyle: FontStyle.italic)),
                      ),

                      _buildTextField(_ageController, 'Age', Icons.calendar_today_outlined, isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField(_conditionController, 'Medical Condition (e.g. Autism)', Icons.medical_information_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Butang Save
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      elevation: 5,
                      shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
      validator: (v) => v!.trim().isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _relationship,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: ['Parent', 'Teacher', 'Therapist', 'Guardian']
          .map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: (value) => setState(() => _relationship = value!),
    );
  }
}