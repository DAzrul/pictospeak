import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSeeding = false;

  // 🚨 J.A.R.V.I.S: MASTER DATA RE-CALIBRATED (DECIMAL VERSION)
  // Semua ID di bawah adalah Decimal ID rasmi untuk Material Icons Flutter 3.x
  Future<void> _seedMasterData() async {
    final List<Map<String, dynamic>> masterPictograms = [
      // --- SUBJECTS ---
      {'en': 'I', 'ms': 'Saya', 'cat': 'Subject', 'img': '58714'}, // person
      {'en': 'You', 'ms': 'Awak', 'cat': 'Subject', 'img': '58714'},
      {'en': 'Mother', 'ms': 'Emak', 'cat': 'Subject', 'img': '59640'}, // woman
      {'en': 'Father', 'ms': 'Ayah', 'cat': 'Subject', 'img': '59639'}, // man
      {'en': 'Brother', 'ms': 'Abang', 'cat': 'Subject', 'img': '58095'}, // child_care
      {'en': 'Sister', 'ms': 'Kakak', 'cat': 'Subject', 'img': '58095'},
      {'en': 'Family', 'ms': 'Keluarga', 'cat': 'Subject', 'img': '58039'}, // groups

      // --- VERBS ---
      {'en': 'Want', 'ms': 'Nak', 'cat': 'Verb', 'img': '58849'}, // touch_app
      {'en': 'Eat', 'ms': 'Makan', 'cat': 'Verb', 'img': '58732'}, // restaurant
      {'en': 'Drink', 'ms': 'Minum', 'cat': 'Verb', 'img': '58716'}, // local_cafe
      {'en': 'Go', 'ms': 'Pergi', 'cat': 'Verb', 'img': '58160'}, // directions_run
      {'en': 'Sleep', 'ms': 'Tidur', 'cat': 'Verb', 'img': '58253'}, // bed
      {'en': 'Shower', 'ms': 'Mandi', 'cat': 'Verb', 'img': '58746'}, // water_drop
      {'en': 'Help', 'ms': 'Tolong', 'cat': 'Verb', 'img': '59543'}, // warning_amber

      // --- OBJECTS ---
      {'en': 'Water', 'ms': 'Air', 'cat': 'Object', 'img': '58746'},
      {'en': 'Rice', 'ms': 'Nasi', 'cat': 'Object', 'img': '58732'},
      {'en': 'Toilet', 'ms': 'Tandas', 'cat': 'Object', 'img': '59613'}, // wc
      {'en': 'Home', 'ms': 'Rumah', 'cat': 'Object', 'img': '58130'}, // home
      {'en': 'School', 'ms': 'Sekolah', 'cat': 'Object', 'img': '58380'}, // school
      {'en': 'Medicine', 'ms': 'Ubat', 'cat': 'Object', 'img': '61473'}, // medical_services
      {'en': 'Phone', 'ms': 'Telefon', 'cat': 'Object', 'img': '58259'}, // smartphone

      // --- ADJECTIVES ---
      {'en': 'Happy', 'ms': 'Gembira', 'cat': 'Adjective', 'img': '58830'}, // sentiment_satisfied
      {'en': 'Sad', 'ms': 'Sedih', 'cat': 'Adjective', 'img': '58831'}, // sentiment_dissatisfied
      {'en': 'Angry', 'ms': 'Marah', 'cat': 'Adjective', 'img': '58399'}, // mood_bad
      {'en': 'Hungry', 'ms': 'Lapar', 'cat': 'Adjective', 'img': '58732'},
      {'en': 'Pain', 'ms': 'Sakit', 'cat': 'Adjective', 'img': '60139'}, // personal_injury
      {'en': 'Hot', 'ms': 'Panas', 'cat': 'Adjective', 'img': '59087'}, // whatshot
      {'en': 'Cold', 'ms': 'Sejuk', 'cat': 'Adjective', 'img': '60179'}, // ac_unit

      // --- OTHERS ---
      {'en': 'Yes', 'ms': 'Ya', 'cat': 'Others', 'img': '58826'}, // check_circle
      {'en': 'No', 'ms': 'Tidak', 'cat': 'Others', 'img': '58824'}, // cancel
    ];

    setState(() => _isSeeding = true);

    try {
      for (var item in masterPictograms) {
        await _firestore.collection('library_v2').add({
          'label_en': item['en'],
          'label_ms': item['ms'],
          'category': item['cat'],
          'image_url': item['img'],
          'ownerId': 'GLOBAL',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Master Data Calibrated & Injected! 🚀'), backgroundColor: Colors.purple),
        );
      }
    } catch (e) {
      print("Gagal: $e");
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  // 🚨 J.A.R.V.I.S: RENDER ICON FIX (DECIMAL VERSION)
  Widget _renderIcon(String imageUrl, String labelEn, {double size = 30, Color color = AppTheme.primaryBlue}) {
    try {
      // Kita cuba parse decimal string yang kita simpan tadi
      int? codePoint = int.tryParse(imageUrl);

      if (codePoint != null) {
        return Icon(
            IconData(codePoint, fontFamily: 'MaterialIcons'),
            size: size,
            color: color
        );
      }
    } catch (e) {
      debugPrint("Icon error: $e");
    }
    // Fallback kalau data rosak
    return FaIcon(FontAwesomeIcons.circleQuestion, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('PictoSpeak Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSeeding ? null : _seedMasterData,
            icon: _isSeeding
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.bolt, color: Colors.amber),
            label: const Text('INJECT MASTER DATA', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() {})),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community Submissions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Review and approve pictograms to be available for all users.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                _buildStatTile('Pending', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('community_submissions').where('status', isEqualTo: 'pending').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, size: 64, color: Colors.green.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text('All clear! No pending submissions.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildSubmissionCard(data, docs[index].id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> data, String docId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _renderIcon(data['image_url'] ?? '', data['label_en'] ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['label_en'] ?? 'No Label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(data['label_ms'] ?? 'Tiada Label', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Chip(label: Text(data['category'] ?? 'Others', style: const TextStyle(fontSize: 10)), backgroundColor: Colors.blue.shade50),
            ],
          ),
          const Spacer(),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _rejectSubmission(docId),
                  child: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                  onPressed: () => _approveSubmission(data, docId),
                  child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approveSubmission(Map<String, dynamic> data, String docId) async {
    try {
      await _dbService.approveSubmission(data, docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved & Published to Global!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void _rejectSubmission(String docId) async {
    await _firestore.collection('community_submissions').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission Rejected.'), backgroundColor: Colors.red),
      );
    }
  }
}