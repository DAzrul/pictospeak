import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🚀 J.A.R.V.I.S: Tong sampah awan
import 'package:image_picker/image_picker.dart'; // 🚀 J.A.R.V.I.S: Litar Kamera/Galeri
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

  // 🚀 J.A.R.V.I.S: Litar Memori Gambar
  String? _existingImageUrl;
  File? _selectedImage;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

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

  // 🚀 Protocol: Sedut data dari Firestore
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
            // 🚀 Sedut URL gambar lama kalau ada
            _existingImageUrl = data['profile_image_url'];
          });
        }
      } catch (e) {
        debugPrint("🚨 J.A.R.V.I.S Error fetching profile data: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // 🚀 Protocol: Pilih Gambar dari Galeri
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _selectedImage = null; // Reset mobile file
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImageBytes = null; // Reset web file
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Gagal buka galeri: $e'), backgroundColor: Colors.red));
    }
  }

  // 🚀 Protocol: Update caregiver profile data
  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          String? finalImageUrl = _existingImageUrl;

          // 🚀 J.A.R.V.I.S: Kalau user ada pilih gambar baru, hantar ke Storage dulu!
          if (_selectedImage != null || _webImageBytes != null) {
            Reference storageRef = FirebaseStorage.instance.ref().child('caregiver_profiles/${user.uid}.jpg');
            UploadTask uploadTask;

            if (kIsWeb) {
              uploadTask = storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
            } else {
              uploadTask = storageRef.putFile(_selectedImage!);
            }

            TaskSnapshot snapshot = await uploadTask;
            finalImageUrl = await snapshot.ref.getDownloadURL();
          }

          // 🚀 J.A.R.V.I.S: Simpan data (termasuk URL gambar) ke Firestore
          await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).update({
            'name': _nameController.text.trim(),
            'emergencyContact': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'secondaryContact': _secondaryContactController.text.trim(),
            'profile_image_url': finalImageUrl, // Simpan link muka dia
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Profile updated successfully.'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('🚨 Update failed: $e'), backgroundColor: Colors.red),
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
                _buildAvatar(), // 🚀 J.A.R.V.I.S panggil litar avatar baru
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

  // 🚀 LITAR AVATAR (SEKSI & BOLEH TEKAN)
  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    // Logik paparan (Kalau baru pilih, tunjuk yang baru. Kalau tak, tunjuk yang lama)
    if (_webImageBytes != null) {
      imageProvider = MemoryImage(_webImageBytes!);
    } else if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingImageUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryBlue, width: 3),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                ]
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 55, color: AppTheme.primaryBlue)
                  : null,
            ),
          ),
          // Bucu kamera kecil biar user tahu benda ni boleh tekan
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
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