import 'dart:io';
import 'dart:typed_data'; // 🚀 J.A.R.V.I.S: Wajib untuk proses Bytes kat Web
import 'package:flutter/foundation.dart' show kIsWeb; // 🚀 J.A.R.V.I.S: Radar pengesan Web atau Mobile
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picIdController = TextEditingController();
  final _labelEnController = TextEditingController();
  final _labelMsController = TextEditingController();

  // Protocol: Dynamic Folder Management for CMS
  final _newMainController = TextEditingController();
  final _newSubController = TextEditingController();

  String _selectedMainCategory = 'health';
  String _selectedSubCategory = 'none';

  bool _isCreatingNewMain = false;
  bool _isCreatingNewSub = false;

  List<String> _mainCategories = ['health', 'body', 'food_drinks', 'feelings', 'environment', 'hygiene'];
  Map<String, Set<String>> _subCategories = {};

  Map<String, int> _globalPhraseFrequency = {};
  bool _isLoadingAnalytics = true;
  bool _isUploading = false;

  // 🚀 HYBRID MEDIA VARIABLES
  XFile? _selectedImage;
  Uint8List? _webImageBytes; // Menyimpan data binari gambar khas untuk Web
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchGlobalAnalytics();
    _scanGlobalFolders();
  }

  @override
  void dispose() {
    _picIdController.dispose();
    _labelEnController.dispose();
    _labelMsController.dispose();
    _newMainController.dispose();
    _newSubController.dispose();
    super.dispose();
  }

  // 🛡️ MODUL 5: AUDIT TRAIL CIRCUIT
  Future<void> _logAdminActivity(String activityDescription) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('admin_activity_logs').add({
        'admin_id': user?.email ?? 'SUPERADMIN_SYSTEM',
        'activity': activityDescription,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🚨 Audit Trail Failure: $e");
    }
  }

  // 🧠 J.A.R.V.I.S: CROSS-USER DATA AGGREGATION CIRCUIT
  Future<void> _fetchGlobalAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('global_analytics')
          .orderBy('total_usage', descending: true)
          .limit(50)
          .get();

      Map<String, int> frequencyMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        String picId = data['pic_id'] ?? doc.id;
        int usage = data['total_usage'] ?? 0;
        frequencyMap[picId] = usage;
      }

      setState(() {
        _globalPhraseFrequency = frequencyMap;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      debugPrint("🚨 Admin Error: Failed to fetch analytics -> $e");
      setState(() => _isLoadingAnalytics = false);
    }
  }

  // 🚀 Protocol: Scan Global Structure
  Future<void> _scanGlobalFolders() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('global_pictograms').get();

      Set<String> fetchedMains = {};
      Map<String, Set<String>> tempSubCategories = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String cat = data['category'] ?? 'uncategorized';
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
      debugPrint("🚨 Failed to scan global folders: $e");
    }
  }

  String _formatToId(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '_');
  }

  String _formatToDisplay(String raw) {
    return raw.replaceAll('_', ' ').toUpperCase();
  }

  // 📸 J.A.R.V.I.S: HYBRID IMAGE PICKER (WEB & MOBILE SAFE)
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      if (kIsWeb) {
        // Kalau Web: Kita hancurkan gambar jadi Bytes
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        // Kalau Mobile: Pakai cara biasa
        setState(() => _selectedImage = pickedFile);
      }
    }
  }

  // 💾 J.A.R.V.I.S: CENTRAL CMS COMPILER (HYBRID UPLOAD)
  Future<void> _uploadGlobalPictogram() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚨 Action Denied: Please select a pictogram image!')));
      return;
    }

    if (_isCreatingNewMain && _newMainController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please specify a name for the new main folder.")));
      return;
    }

    if (_selectedSubCategory == 'ADD_NEW' && _newSubController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please specify a name for the new sub-folder.")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String picId = _picIdController.text.trim().toLowerCase();
      String labelEn = _labelEnController.text.trim();

      String finalMain = _isCreatingNewMain ? _formatToId(_newMainController.text) : _selectedMainCategory;
      String? finalSub;
      if (_selectedSubCategory != 'none') {
        finalSub = (_selectedSubCategory == 'ADD_NEW') ? _formatToId(_newSubController.text) : _selectedSubCategory;
      }

      String actualCategory = finalSub ?? finalMain;
      String? parentFolder = finalSub != null ? finalMain : null;

      // 🚀 Step 1: Hybrid Upload (Web vs Mobile)
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('global_pictograms/$actualCategory/$picId.png');

      UploadTask uploadTask;
      if (kIsWeb) {
        // Kalau Web: Upload guna data bytes
        uploadTask = storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // Kalau Mobile: Upload guna path file
        uploadTask = storageRef.putFile(File(_selectedImage!.path));
      }

      TaskSnapshot snapshot = await uploadTask;
      String realDownloadUrl = await snapshot.ref.getDownloadURL();

      // Step 2: Inject metadata
      await FirebaseFirestore.instance.collection('global_pictograms').add({
        'pic_id': picId,
        'label_en': labelEn,
        'label_ms': _labelMsController.text.trim(),
        'category': actualCategory,
        'parent_folder': parentFolder,
        'image_url': realDownloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'uploaded_by': 'SUPERADMIN',
      });

      // 🛡️ MODUL 5: LOG TO AUDIT TRAIL
      await _logAdminActivity("Deployed new pictogram: $labelEn ($picId) to category: $actualCategory");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Success: New pictogram deployed to ecosystem!')),
        );
        _picIdController.clear();
        _labelEnController.clear();
        _labelMsController.clear();
        _newMainController.clear();
        _newSubController.clear();
        setState(() {
          _selectedImage = null;
          _webImageBytes = null;
          _scanGlobalFolders();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Deployment Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var sortedEntries = _globalPhraseFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<String> currentSubFolders = [];
    if (!_isCreatingNewMain && _subCategories.containsKey(_selectedMainCategory)) {
      currentSubFolders = _subCategories[_selectedMainCategory]!.toList();
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SUPERADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          backgroundColor: Colors.indigo.shade900,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart_rounded), text: "Analytics"),
              Tab(icon: Icon(Icons.cloud_upload_rounded), text: "CMS Deployment"),
              Tab(icon: Icon(Icons.support_agent_rounded), text: "Tickets"),
              Tab(icon: Icon(Icons.settings_input_component), text: "Config"),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            // 📊 TAB 1: ANALYTICS
            _isLoadingAnalytics
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _fetchGlobalAnalytics,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Community Usage Trends", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedEntries.length,
                        itemBuilder: (context, index) {
                          var entry = sortedEntries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text('Pictogram: ${entry.key.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Text('FREQ: ${entry.value}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ☁️ TAB 2: CMS DEPLOYMENT
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150, width: 150,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)),
                            child: _selectedImage != null
                                ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                // 🚀 J.A.R.V.I.S: HYBRID IMAGE RENDERER
                                child: kIsWeb
                                    ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                            )
                                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.indigo), Text("Select Media")]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(controller: _picIdController, decoration: const InputDecoration(labelText: 'Pictogram Unique ID (e.g. apple)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 15),
                      TextFormField(controller: _labelEnController, decoration: const InputDecoration(labelText: 'Label (English)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 15),
                      TextFormField(controller: _labelMsController, decoration: const InputDecoration(labelText: 'Label (Malay)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 24),

                      const Text("Directory Routing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),

                      // MAIN FOLDER ROUTING
                      DropdownButtonFormField<String>(
                        value: _selectedMainCategory,
                        decoration: const InputDecoration(labelText: '1. Target Main Folder', border: OutlineInputBorder()),
                        items: [
                          ..._mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(_formatToDisplay(cat)))),
                          const DropdownMenuItem(value: 'ADD_NEW', child: Text('➕ Create New Main Folder...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
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
                        const SizedBox(height: 10),
                        TextField(controller: _newMainController, decoration: const InputDecoration(labelText: 'New Main Folder Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.create_new_folder, color: Colors.indigo))),
                      ],
                      const SizedBox(height: 15),

                      // SUB FOLDER ROUTING
                      DropdownButtonFormField<String>(
                        value: _selectedSubCategory,
                        decoration: const InputDecoration(labelText: '2. Target Sub-Folder (Optional)', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: 'none', child: Text('No Sub-folder (Direct to Main)')),
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
                        const SizedBox(height: 10),
                        TextField(controller: _newSubController, decoration: const InputDecoration(labelText: 'New Sub-Folder Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.subdirectory_arrow_right, color: Colors.orange))),
                      ],

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadGlobalPictogram,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900),
                          icon: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.cloud_upload, color: Colors.white),
                          label: Text(_isUploading ? 'Deploying...' : 'PUBLISH TO ECOSYSTEM', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🎫 TAB 3: TICKETS
            _buildTicketsTab(),
          ],
        ),
      ),
    );
  }
  // 🎫 TAB 3: TICKETS MANAGEMENT
  Widget _buildTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        // 🚀 LITAR DEEP-DEBUGGING: Check error
        if (snapshot.hasError) {
          return Center(child: Text("🚨 LITAR ERROR: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Tiada tiket sokongan buat masa ini."));
        }

        final tickets = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final data = tickets[index].data() as Map<String, dynamic>;
            bool isResolved = data['status'] == 'RESOLVED';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isResolved ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: Icon(
                  isResolved ? Icons.check_circle : Icons.pending_actions,
                  color: isResolved ? Colors.green : Colors.orange,
                ),
                title: Text(data['user_email'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['message'] ?? 'Tiada mesej'),
                trailing: isResolved
                    ? const Icon(Icons.check, color: Colors.green)
                    : IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.indigo),
                  onPressed: () async {
                    await tickets[index].reference.update({'status': 'RESOLVED'});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tiket diselesaikan!")));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Maintenance Mode (Kill Switch)"),
                subtitle: const Text("Tutup akses pesakit jika sistem ada masalah"),
                value: data['maintenance_mode'] ?? false,
                onChanged: (val) => FirebaseFirestore.instance.collection('system_configs').doc('general').update({'maintenance_mode': val}),
              ),
              const Divider(),
              ListTile(
                title: const Text("Update Announcement"),
                subtitle: Text(data['app_announcement'] ?? "Tiada pengumuman"),
                trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {
                  // Buat dialog simple untuk edit text ni
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}