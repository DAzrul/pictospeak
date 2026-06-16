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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _secondaryContactController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCaregiverData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _secondaryContactController.dispose();
    super.dispose();
  }

  // 🚀 Protocol: Fetch caregiver data from Firestore
  Future<void> _fetchCaregiverData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['emergencyContact'] ?? '';
            _addressController.text = data['address'] ?? '';
            _secondaryContactController.text = data['secondaryContact'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error fetching profile data: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // 🚀 Protocol: Update caregiver profile data
  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).update({
            'name': _nameController.text.trim(),
            'emergencyContact': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'secondaryContact': _secondaryContactController.text.trim(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully.'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
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
        title: const Text('Caregiver Profile', style: TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatar(),
                const SizedBox(height: 32),

                // --- CARD: PERSONAL INFORMATION ---
                _buildCard([
                  _buildSectionTitle('Personal Info', Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, 'Full Name', Icons.badge_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Primary Phone Number', Icons.phone_android_outlined, isNumber: true),
                ]),

                const SizedBox(height: 20),

                // --- CARD: CONTACT & LOCATION ---
                _buildCard([
                  _buildSectionTitle('Emergency & Location', Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, 'Home Address', Icons.home_work_outlined, isMandatory: false),
                  const SizedBox(height: 16),
                  _buildTextField(_secondaryContactController, 'Secondary Contact (Name/Phone)', Icons.contact_emergency_outlined, isMandatory: false),
                ]),

                const SizedBox(height: 40),

                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 50, color: AppTheme.primaryBlue),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false, bool isMandatory = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: isMandatory ? hint : "$hint (Optional)",
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => (isMandatory && (v == null || v.trim().isEmpty)) ? 'This field is required.' : null,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SAVE PROFILE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}