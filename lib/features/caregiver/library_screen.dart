import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/theme/app_theme.dart';
import 'add_pictogram_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🚀 Protocol: Navigation history management
  String? _currentFolder;
  final List<String> _folderHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 🚀 LITAR NINJA: Reset folder history bila tukar tab!
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentFolder = null;
          _folderHistory.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  // =========================================================================
  // 🗑️ LITAR PEMUSNAH: PADAM CUSTOM PICTOGRAM
  // =========================================================================
  Future<void> _deleteCustomPictogram(String docId, String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🚀 Litar amaran sebelum tembak!
    bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Padam Pictogram?"),
          content: const Text("Adakah anda pasti nak buang gambar ni dari koleksi peribadi anda?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        )
    ) ?? false;

    if (!confirm) return;

    try {
      // 1. Padam dari Firestore Database
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('custom_pictograms')
          .doc(docId)
          .delete();

      // 2. Padam gambar dari Storage (Kalau link tu memang dari Storage kita)
      if (imageUrl.contains('firebasestorage')) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Gambar storage tak wujud/dah kena padam: $e");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Pictogram berjaya dipadam!"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚨 Gagal memadam: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _currentFolder != null ? _formatCategoryName(_currentFolder!) : "LIBRARY SYSTEM",
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'My Custom', icon: Icon(Icons.folder_shared_rounded)),
            Tab(text: 'Global Dictionary', icon: Icon(Icons.public_rounded)),
          ],
        ),
      ),

      // 🚀 Butang "Add Custom" hanya muncul kat Tab 0 (My Custom)
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPictogramScreen()));
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("Add Custom", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
          : null,

      body: TabBarView(
        controller: _tabController,
        // Kita halang swipe pakai jari supaya user tak tertekan dan rosakkan memori folder
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildCustomLibraryTab(),
          _buildGlobalLibraryTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // 📁 TAB 1: LITAR MY CUSTOM (DATABASE CAREGIVER)
  // =========================================================================
  Widget _buildCustomLibraryTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Authentication Error"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('custom_pictograms')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text("Custom Library is empty.\nClick 'Add Custom' to begin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          );
        }

        return _buildGridStructure(docs, isGlobal: false);
      },
    );
  }

  // =========================================================================
  // 🌍 TAB 2: LITAR GLOBAL DICTIONARY (DATABASE ADMIN)
  // =========================================================================
  Widget _buildGlobalLibraryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('global_pictograms')
          .orderBy('timestamp', descending: true) // Gunakan timestamp yang admin set
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text("Global Library is currently empty.\nWaiting for Admin deployment.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          );
        }

        return _buildGridStructure(docs, isGlobal: true);
      },
    );
  }

  // =========================================================================
  // 🧠 ENJIN PEMBINAAN FOLDER & GRID (Dikongsi oleh dua-dua tab)
  // =========================================================================
  Widget _buildGridStructure(List<QueryDocumentSnapshot> docs, {required bool isGlobal}) {
    Set<String> displayFolders = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      String? parent = data['parent_folder'];
      String category = data['category'] ?? 'uncategorized';

      if (_currentFolder == null) {
        // 🚀 BILA BERADA DI MENU UTAMA (ROOT)
        if (parent != null && parent.isNotEmpty) {
          // Kalau gambar tu ada bapak (Macam pisang anak kepada food_drinks)
          // Kita wujudkan folder bapak tu kat depan!
          displayFolders.add(parent);
        } else {
          // Kalau gambar tu takde bapak (Direct category)
          displayFolders.add(category);
        }
      } else {
        // 🚀 BILA BERADA DI DALAM FOLDER
        if (parent == _currentFolder) {
          displayFolders.add(category); // Tunjuk sub-folder
        }
      }
    }

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
          return _buildFolderCard(folderList[index], docs, isGlobal);
        } else {
          // 🚀 Hantar doc (Snapshot) terus, supaya kita boleh dapat doc.id untuk delete
          return _buildCustomIconCard(filteredFiles[index - folderList.length], isGlobal);
        }
      },
    );
  }

  Widget _buildFolderCard(String folderName, List<QueryDocumentSnapshot> allDocs, bool isGlobal) {
    int itemCount = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['category'] == folderName || data['parent_folder'] == folderName;
    }).length;

    Color folderColor = isGlobal ? Colors.indigo : AppTheme.primaryBlue;

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
          boxShadow: [BoxShadow(color: folderColor.withValues(alpha: 0.1), blurRadius: 10)],
          border: Border.all(color: folderColor.withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy_rounded, color: folderColor, size: 50),
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

  // 🚀 LITAR KAD DENGAN TONG SAMPAH
  Widget _buildCustomIconCard(QueryDocumentSnapshot doc, bool isGlobal) {
    final data = doc.data() as Map<String, dynamic>;
    String textEn = data['label_en'] ?? data['en'] ?? 'Unknown';
    String imageUrl = data['image_url'] ?? '';
    String docId = doc.id; // 🚀 Tarik ID Dokumen

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            border: Border.all(color: isGlobal ? Colors.indigo.shade100 : Colors.grey.shade200),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGlobal) const Icon(Icons.verified_rounded, color: Colors.blue, size: 12),
                    if (isGlobal) const SizedBox(width: 4),
                    Flexible(
                      child: Text(textEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // 🚀 LITAR TONG SAMPAH: HANYA MUNCUL DI TAB "MY CUSTOM" (BUKAN GLOBAL)
        if (!isGlobal)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => _deleteCustomPictogram(docId, imageUrl),
              ),
            ),
          )
      ],
    );
  }
}