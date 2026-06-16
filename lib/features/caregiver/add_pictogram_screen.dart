import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class AddPictogramScreen extends StatefulWidget {
  const AddPictogramScreen({super.key});

  @override
  State<AddPictogramScreen> createState() => _AddPictogramScreenState();
}

class _AddPictogramScreenState extends State<AddPictogramScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final _enController = TextEditingController();
  final _msController = TextEditingController();

  final _newMainController = TextEditingController();
  final _newSubController = TextEditingController();

  String _selectedMainCategory = 'custom';
  String _selectedSubCategory = 'none';

  bool _isCreatingNewMain = false;
  bool _isCreatingNewSub = false;
  bool _isLoading = false;

  List<String> _mainCategories = [
    'custom', 'food_drinks', 'health', 'body', 'environment',
    'feelings', 'hygiene', 'rehab', 'number'
  ];

  Map<String, Set<String>> _subCategories = {};

  @override
  void initState() {
    super.initState();
    _scanForFolders();
  }

  Future<void> _scanForFolders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('custom_pictograms')
          .get();

      Set<String> fetchedMains = {};
      Map<String, Set<String>> tempSubCategories = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String cat = data['category'] ?? 'custom';
        String? parent = data['parent_folder'];

        if (parent != null && parent.isNotEmpty) {
          fetchedMains.add(parent);
          if (!tempSubCategories.containsKey(parent)) {
            tempSubCategories[parent] = {};
          }
          tempSubCategories[parent]!.add(cat);
        } else {
          fetchedMains.add(cat);
        }
      }

      if (mounted) {
        setState(() {
          _subCategories = tempSubCategories;
          for (var folder in fetchedMains) {
            if (!_mainCategories.contains(folder)) _mainCategories.add(folder);
          }
        });
      }
    } catch (e) {
      debugPrint("Error scanning folders: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  String _formatToId(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '_');
  }

  String _formatToDisplay(String raw) {
    return raw.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _uploadPictogram() async {
    if (_imageFile == null || _enController.text.isEmpty || _msController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields and add an image."), backgroundColor: Colors.orange));
      return;
    }

    if (_isCreatingNewMain && _newMainController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name for the new main folder."), backgroundColor: Colors.orange));
      return;
    }

    if (_selectedSubCategory == 'ADD_NEW' && _newSubController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name for the new sub-folder."), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      Reference storageRef = FirebaseStorage.instance.ref().child('custom_pictograms/${user!.uid}/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      String finalMain = _isCreatingNewMain ? _formatToId(_newMainController.text) : _selectedMainCategory;
      String? finalSub;

      if (_selectedSubCategory != 'none') {
        finalSub = (_selectedSubCategory == 'ADD_NEW') ? _formatToId(_newSubController.text) : _selectedSubCategory;
      }

      String actualCategory = finalSub ?? finalMain;
      String? parentFolder = finalSub != null ? finalMain : null;

      DocumentReference docRef = FirebaseFirestore.instance.collection('caregivers').doc(user.uid).collection('custom_pictograms').doc();

      await docRef.set({
        'pic_id': docRef.id,
        'owner_id': user.uid,
        'label_en': _enController.text.trim(),
        'label_ms': _msController.text.trim(),
        'image_url': downloadUrl,
        'category': actualCategory,
        'parent_folder': parentFolder,
        'tags': [
          _enController.text.trim().toLowerCase(),
          _msController.text.trim().toLowerCase(),
          actualCategory,
          if (parentFolder != null) parentFolder
        ],
        'is_custom': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pictogram saved successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentSubFolders = [];
    if (!_isCreatingNewMain && _subCategories.containsKey(_selectedMainCategory)) {
      currentSubFolders = _subCategories[_selectedMainCategory]!.toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Add Custom Pictogram', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                    ],
                  ),
                );
              },
              child: Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 50, color: AppTheme.primaryBlue), SizedBox(height: 12), Text("Tap to add photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]),
              ),
            ),
            const SizedBox(height: 24),

            TextField(controller: _enController, decoration: const InputDecoration(labelText: 'Word (English) - e.g: Carrot', filled: true, fillColor: Colors.white)),
            const SizedBox(height: 16),
            TextField(controller: _msController, decoration: const InputDecoration(labelText: 'Word (Malay) - e.g: Lobak Merah', filled: true, fillColor: Colors.white)),
            const SizedBox(height: 24),

            // Main Folder Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: const InputDecoration(labelText: '1. Main Folder', filled: true, fillColor: Colors.white),
              items: [
                ..._mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(_formatToDisplay(cat)))),
                const DropdownMenuItem(value: 'ADD_NEW', child: Text('➕ Create New Main Folder...', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMainCategory = value!;
                  _isCreatingNewMain = (value == 'ADD_NEW');
                  _selectedSubCategory = 'none';
                  _isCreatingNewSub = false;
                });
              },
            ),
            if (_isCreatingNewMain) ...[
              const SizedBox(height: 12),
              TextField(controller: _newMainController, decoration: InputDecoration(labelText: 'New Main Folder Name', filled: true, fillColor: Colors.blue.shade50, prefixIcon: const Icon(Icons.create_new_folder, color: AppTheme.primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],
            const SizedBox(height: 16),

            // Sub-Folder Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubCategory,
              decoration: const InputDecoration(labelText: '2. Sub-Folder (Optional)', filled: true, fillColor: Colors.white),
              items: [
                const DropdownMenuItem(value: 'none', child: Text('No Sub-folder (Direct in Main)')),
                ...currentSubFolders.map((cat) => DropdownMenuItem(value: cat, child: Text("↳ ${_formatToDisplay(cat)}"))),
                const DropdownMenuItem(value: 'ADD_NEW', child: Text('➕ Create New Sub-Folder...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubCategory = value!;
                  _isCreatingNewSub = (value == 'ADD_NEW');
                });
              },
            ),
            if (_isCreatingNewSub) ...[
              const SizedBox(height: 12),
              TextField(controller: _newSubController, decoration: InputDecoration(labelText: 'New Sub-Folder Name (e.g: Vegetables)', filled: true, fillColor: Colors.orange.shade50, prefixIcon: const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadPictogram,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE PICTOGRAM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}