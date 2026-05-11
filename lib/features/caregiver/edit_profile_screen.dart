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

  // --- CONTROLLERS ---
  final _caregiverNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController(); // Akan jadi Read-Only
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _addressController = TextEditingController(); // Baru
  final _secondaryContactController = TextEditingController(); // Baru

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
    _addressController.dispose();
    _secondaryContactController.dispose();
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
            _caregiverNameController.text = data['caregiverName'] ?? '';
            _phoneController.text = data['emergencyContact'] ?? '';
            _patientNameController.text = data['patientName'] ?? '';
            _patientIdController.text = data['patientId'] ?? ''; // Kod Auto-Gen
            _ageController.text = data['patientAge']?.toString() ?? '';
            _conditionController.text = data['patientCondition'] ?? '';
            _addressController.text = data['address'] ?? '';
            _secondaryContactController.text = data['secondaryContact'] ?? '';

            String fetchedRel = data['relationship'] ?? 'Parent';
            if (['Parent', 'Teacher', 'Therapist', 'Guardian'].contains(fetchedRel)) {
              _relationship = fetchedRel;
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
          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).set({
            'caregiverName': _caregiverNameController.text.trim(),
            'emergencyContact': _phoneController.text.trim(),
            'patientName': _patientNameController.text.trim(),
            // patientId tidak diubah untuk elak putus litar
            'patientAge': _ageController.text.trim(),
            'patientCondition': _conditionController.text.trim(),
            'address': _addressController.text.trim(),
            'secondaryContact': _secondaryContactController.text.trim(),
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
              children: [
                // Avatar
                _buildAvatar(),
                const SizedBox(height: 32),

                // --- SECTION: CAREGIVER ---
                _buildCard([
                  _buildSectionTitle('Caregiver Details', Icons.shield_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_caregiverNameController, 'Your Full Name', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Primary Phone Number', Icons.phone_outlined, isNumber: true),
                  const SizedBox(height: 16),
                  const Text('Relationship', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildDropdown(),
                ]),

                const SizedBox(height: 20),

                // --- SECTION: PATIENT ---
                _buildCard([
                  _buildSectionTitle('Patient Details', Icons.child_care),
                  const SizedBox(height: 16),
                  _buildTextField(_patientNameController, 'Patient Name', Icons.face),
                  const SizedBox(height: 16),

                  // Patient ID (Read Only)
                  _buildTextField(_patientIdController, 'Patient Code', Icons.fingerprint, isReadOnly: true),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Text("Kod unik ini tidak boleh diubah.", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),

                  const SizedBox(height: 16),
                  _buildTextField(_ageController, 'Age', Icons.calendar_today_outlined, isNumber: true, isMandatory: false),
                  const SizedBox(height: 16),
                  _buildTextField(_conditionController, 'Medical Condition', Icons.medical_information_outlined, isMandatory: false),
                ]),

                const SizedBox(height: 20),

                // --- SECTION: LOCATION & EXTRAS ---
                _buildCard([
                  _buildSectionTitle('Location & Extras', Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, 'Home Address', Icons.home_work_outlined, isMandatory: false),
                  const SizedBox(height: 16),
                  _buildTextField(_secondaryContactController, 'Secondary Contact Name', Icons.people_outline, isMandatory: false),
                ]),

                const SizedBox(height: 40),

                // Save Button
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildAvatar() {
    return Stack(
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
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, bool isMandatory = true, bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: isMandatory ? hint : "$hint (Optional)",
        prefixIcon: Icon(icon, size: 20, color: isReadOnly ? Colors.blueGrey : Colors.grey.shade500),
        filled: true,
        fillColor: isReadOnly ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
      ),
      validator: (v) => (isMandatory && (v == null || v.trim().isEmpty)) ? 'Wajib isi!' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _relationship,
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

  Widget _buildSaveButton() {
    return SizedBox(
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
    );
  }
}