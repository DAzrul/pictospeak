import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Global form key and controllers for CMS input
  final _formKey = GlobalKey<FormState>();
  final _picIdController = TextEditingController();
  final _labelEnController = TextEditingController();
  final _labelMsController = TextEditingController();
  String _selectedCategory = 'health';

  Map<String, int> _globalPhraseFrequency = {};
  bool _isLoadingAnalytics = true;
  bool _isUploading = false;

  // Image Picker configuration for cloud upload
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchGlobalAnalytics();
  }

  @override
  void dispose() {
    _picIdController.dispose();
    _labelEnController.dispose();
    _labelMsController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🧠 J.A.R.V.I.S: CROSS-USER DATA AGGREGATION CIRCUIT
  // =========================================================
  // Fetches pre-aggregated statistics from global_analytics
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
      print("🚨 J.A.R.V.I.S Admin Error: Failed to fetch analytics -> $e");
      setState(() => _isLoadingAnalytics = false);
    }
  }

  // =========================================================
  // 📸 J.A.R.V.I.S: LOCAL MEDIA PICKER SYSTEM
  // =========================================================
  // Triggers native gallery interface to select pictogram image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // =========================================================
  // 💾 J.A.R.V.I.S: CENTRAL CMS COMPILER (STORAGE + FIRESTORE)
  // =========================================================
  // Uploads raw media file to Firebase Storage first, then binds URL to Firestore
  Future<void> _uploadGlobalPictogram() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Action Denied: Please select a pictogram image first!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String picId = _picIdController.text.trim().toLowerCase();

      // Step 1: Deploy media binary to Firebase Storage bucket
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('global_pictograms')
          .child('$_selectedCategory/$picId.png');

      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;

      // Step 2: Extract verified download token/URL from cloud storage
      String realDownloadUrl = await snapshot.ref.getDownloadURL();

      // Step 3: Inject metadata with the live network URL into global_pictograms table
      await FirebaseFirestore.instance.collection('global_pictograms').add({
        'pic_id': picId,
        'label_en': _labelEnController.text.trim(),
        'label_ms': _labelMsController.text.trim(),
        'category': _selectedCategory,
        'image_url': realDownloadUrl, // Live network token injected successfully
        'timestamp': FieldValue.serverTimestamp(),
        'uploaded_by': 'SUPERADMIN',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Success: New pictogram deployed to central database!')),
      );

      // Reset application state and clean UI forms
      _picIdController.clear();
      _labelEnController.clear();
      _labelMsController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 Critical Error: Deployment failed -> $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var sortedEntries = _globalPhraseFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SUPERADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          backgroundColor: Colors.indigo.shade900,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart_rounded), text: "Analytics & Core Data"),
              Tab(icon: Icon(Icons.cloud_upload_rounded), text: "CMS Deployment"),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            // 📊 TAB 1: DATA AGGREGATION & CROSS-USER ANALYSIS
            _isLoadingAnalytics
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _fetchGlobalAnalytics,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Frequency Signals Across Community Patients",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Aggregated summary metrics to evaluate cross-user health trends dynamically.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: sortedEntries.isEmpty
                          ? const Center(child: Text("No systemic logs discovered."))
                          : ListView.builder(
                        itemCount: sortedEntries.length,
                        itemBuilder: (context, index) {
                          var entry = sortedEntries[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: Text('Pictogram: ${entry.key.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Triggered ${entry.value} times by macro ecosystem patients'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Text('FREQ: ${entry.value}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ☁️ TAB 2: CENTRAL CMS COMPILER PIPELINE
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Deploy New Pictogram to Global Framework", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Media selection frame circuit
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.shade200, width: 2),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                                : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.indigo),
                                SizedBox(height: 8),
                                Text("Select Media", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _picIdController,
                        decoration: const InputDecoration(labelText: 'Pictogram Unique ID (e.g., mosquito, back_pain)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Identifier verification token required' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _labelEnController,
                        decoration: const InputDecoration(labelText: 'Label Name (English)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'English nomenclature layer required' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _labelMsController,
                        decoration: const InputDecoration(labelText: 'Label Name (Malay)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Malay nomenclature layer required' : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Target Category Directory', border: OutlineInputBorder()),
                        items: ['health', 'body', 'food_drinks', 'feelings', 'environment', 'hygiene']
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.toUpperCase())))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadGlobalPictogram,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900),
                          icon: _isUploading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.cloud_upload, color: Colors.white),
                          label: Text(_isUploading ? 'Executing Cloud Deployment...' : 'PUBLISH TO ECOSYSTEM', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}