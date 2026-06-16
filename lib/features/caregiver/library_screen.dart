import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'add_pictogram_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // 🚀 Protocol: Navigation history management
  String? _currentFolder;
  final List<String> _folderHistory = [];

  String _formatCategoryName(String raw) {
    return raw.replaceAll('_', ' ').toUpperCase();
  }

  void _goBack() {
    setState(() {
      if (_folderHistory.isNotEmpty) {
        _folderHistory.removeLast();
        _currentFolder = _folderHistory.isEmpty ? null : _folderHistory.last;
      } else {
        _currentFolder = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentFolder != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
          onPressed: _goBack,
        )
            : null,
        title: Text(
            _currentFolder != null ? _formatCategoryName(_currentFolder!) : "MY LIBRARY",
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPictogramScreen()));
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("Add Custom", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('caregivers')
            .doc(user?.uid)
            .collection('custom_pictograms')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                  "Library is empty.\nClick 'Add Custom' to begin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)
              ),
            );
          }

          // ==========================================
          // 🚀 Protocol: Content grouping logic
          // ==========================================

          // 1. Identify folders to display at current level
          Set<String> displayFolders = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String? parent = data['parent_folder'];
            String category = data['category'] ?? 'uncategorized';

            if (_currentFolder == null) {
              if (parent == null) {
                displayFolders.add(category);
              }
            } else {
              if (parent == _currentFolder) {
                displayFolders.add(category);
              }
            }
          }

          // 2. Identify files to display at current level
          var filteredFiles = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['category'] == _currentFolder;
          }).toList();

          List<String> folderList = displayFolders.toList();
          int totalItems = folderList.length + filteredFiles.length;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85
            ),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index < folderList.length) {
                return _buildFolderCard(folderList[index], docs);
              } else {
                final fileData = filteredFiles[index - folderList.length].data() as Map<String, dynamic>;
                return _buildCustomIconCard(fileData);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(String folderName, List<QueryDocumentSnapshot> allDocs) {
    int itemCount = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['category'] == folderName || data['parent_folder'] == folderName;
    }).length;

    return InkWell(
      onTap: () {
        setState(() {
          _folderHistory.add(folderName);
          _currentFolder = folderName;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.1), blurRadius: 10)],
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_copy_rounded, color: AppTheme.primaryBlue, size: 50),
            const SizedBox(height: 10),
            Text(_formatCategoryName(folderName),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text("$itemCount Items", style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIconCard(Map<String, dynamic> data) {
    String textEn = data['label_en'] ?? data['en'] ?? 'Unknown';
    String imageUrl = data['image_url'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(textEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        ],
      ),
    );
  }
}