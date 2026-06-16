import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Kontroler untuk CMS Form
  final _formKey = GlobalKey<FormState>();
  final _picIdController = TextEditingController();
  final _labelEnController = TextEditingController();
  final _labelMsController = TextEditingController();
  String _selectedCategory = 'health';

  Map<String, int> _globalPhraseFrequency = {};
  bool _isLoadingAnalytics = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _analyzeCrossUserLogs();
  }

  @override
  void dispose() {
    _picIdController.dispose();
    _labelEnController.dispose();
    _labelMsController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🧠 J.A.R.V.I.S: LITAR DATA AGGREGATION (Tuntutan SV)
  // =========================================================
  // Membaca data merentas User 1, User 2, User 3 secara sulit
  Future<void> _analyzeCrossUserLogs() async {
    setState(() => _isLoadingAnalytics = true);
    try {
      // Guna collectionGroup untuk terus tarik sub-collection 'communication_logs'
      // yang berada di bawah mana-mana dokumen pesakit/caregiver!
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('communication_logs')
          .orderBy('timestamp', descending: true)
          .limit(300) // Ambil 300 log terkini dalam sistem untuk analisis trend
          .get();

      Map<String, int> frequencyMap = {};

      for (var doc in snapshot.docs) {
        List<dynamic> items = doc.data()['items'] ?? [];
        for (var item in items) {
          String picId = item.toString();
          frequencyMap[picId] = (frequencyMap[picId] ?? 0) + 1;
        }
      }

      setState(() {
        _globalPhraseFrequency = frequencyMap;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      print("🚨 J.A.R.V.I.S Admin Error: Gagal tarik data silang user -> $e");
      setState(() => _isLoadingAnalytics = false);
    }
  }

  // =========================================================
  // 💾 J.A.R.V.I.S: LITAR CMS (SuperAdmin Upload Global)
  // =========================================================
  Future<void> _uploadGlobalPictogram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // Masukkan ke dalam collection pusat 'global_pictograms'
      await FirebaseFirestore.instance.collection('global_pictograms').add({
        'pic_id': _picIdController.text.trim().toLowerCase(),
        'label_en': _labelEnController.text.trim(),
        'label_ms': _labelMsController.text.trim(),
        'category': _selectedCategory,
        'image_url': 'assets/Pictogram/Environment/light.png', // Peringkat awal guna placeholder asset / link web
        'timestamp': FieldValue.serverTimestamp(),
        'uploaded_by': 'SUPERADMIN',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pictogram baru berjaya disuntik ke Cloud!')),
      );

      _picIdController.clear();
      _labelEnController.clear();
      _labelMsController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 Gagal upload: $e')),
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
              Tab(icon: Icon(Icons.bar_chart_rounded), text: "Analisis & Perbandingan"),
              Tab(icon: Icon(Icons.cloud_upload_rounded), text: "CMS Upload"),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            // 📊 TAB 1: PERBANDINGAN DATA (USER 1, USER 2, USER 3)
            _isLoadingAnalytics
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _analyzeCrossUserLogs,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kekerapan Isu / Isyarat Merentas Semua Pesakit",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Data ditarik secara agregat untuk melihat trend kesihatan/keselesaan semasa.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: sortedEntries.isEmpty
                          ? const Center(child: Text("Tiada data log dijumpai."))
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
                              subtitle: Text('Digunakan sebanyak ${entry.value} kali oleh komuniti pesakit'),
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

            // ☁️ TAB 2: SUPERADMIN CMS UPLOAD
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tambah Pictogram Baharu ke Sistem Pusat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _picIdController,
                        decoration: const InputDecoration(labelText: 'Pictogram ID (Contoh: nyamuk, gatal_bahu)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Wajib isi ID' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _labelEnController,
                        decoration: const InputDecoration(labelText: 'Label (English)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Wajib isi label Inggeris' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _labelMsController,
                        decoration: const InputDecoration(labelText: 'Label (Bahasa Melayu)', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Wajib isi label Melayu' : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategori Folder', border: OutlineInputBorder()),
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
                          label: Text(_isUploading ? 'Sedang Menyuntik Data...' : 'PUBLISH KE SEMUA USER', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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