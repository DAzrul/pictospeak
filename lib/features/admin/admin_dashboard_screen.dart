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
      // --- 1. SUBJECTS (Keluarga & Kenalan) ---
      {'en': 'I', 'ms': 'Saya', 'cat': 'Subject', 'img': 'i', 'tags': ['person', 'me', 'myself']},
      {'en': 'You', 'ms': 'Awak', 'cat': 'Subject', 'img': 'you', 'tags': ['person', 'other']},
      {'en': 'Mother', 'ms': 'Emak', 'cat': 'Subject', 'img': 'mother', 'tags': ['family', 'woman', 'care']},
      {'en': 'Father', 'ms': 'Ayah', 'cat': 'Subject', 'img': 'father', 'tags': ['family', 'man', 'care']},
      {'en': 'Grandfather', 'ms': 'Datuk', 'cat': 'Subject', 'img': 'grandpa', 'tags': ['family', 'old', 'man']},
      {'en': 'Grandmother', 'ms': 'Nenek', 'cat': 'Subject', 'img': 'grandma', 'tags': ['family', 'old', 'woman']},
      {'en': 'Brother', 'ms': 'Abang', 'cat': 'Subject', 'img': 'brother', 'tags': ['family', 'boy', 'sibling']},
      {'en': 'Sister', 'ms': 'Kakak', 'cat': 'Subject', 'img': 'sister', 'tags': ['family', 'girl', 'sibling']},
      {'en': 'Friend', 'ms': 'Kawan', 'cat': 'Subject', 'img': 'friend', 'tags': ['person', 'play', 'school']},
      {'en': 'Family', 'ms': 'Keluarga', 'cat': 'Subject', 'img': 'family', 'tags': ['group', 'people', 'home']},
      {'en': 'Teacher', 'ms': 'Cikgu', 'cat': 'Subject', 'img': 'teacher', 'tags': ['school', 'learn', 'person']},
      {'en': 'Doctor', 'ms': 'Doktor', 'cat': 'Subject', 'img': 'doctor', 'tags': ['hospital', 'sick', 'help']},
      {'en': 'Nurse', 'ms': 'Jururawat', 'cat': 'Subject', 'img': 'nurse', 'tags': ['hospital', 'sick', 'help']},

      // --- 2. VERBS (Aktiviti Harian) ---
      {'en': 'Want', 'ms': 'Nak', 'cat': 'Verb', 'img': 'want', 'tags': ['desire', 'need', 'please']},
      {'en': 'Eat', 'ms': 'Makan', 'cat': 'Verb', 'img': 'eat', 'tags': ['hungry', 'food', 'meal']},
      {'en': 'Drink', 'ms': 'Minum', 'cat': 'Verb', 'img': 'drink', 'tags': ['thirsty', 'water', 'liquid']},
      {'en': 'Sleep', 'ms': 'Tidur', 'cat': 'Verb', 'img': 'sleep', 'tags': ['tired', 'bed', 'night']},
      {'en': 'Go', 'ms': 'Pergi', 'cat': 'Verb', 'img': 'go', 'tags': ['move', 'travel', 'place']},
      {'en': 'Watch', 'ms': 'Tengok', 'cat': 'Verb', 'img': 'watch', 'tags': ['see', 'look', 'tv']},
      {'en': 'Listen', 'ms': 'Dengar', 'cat': 'Verb', 'img': 'listen', 'tags': ['hear', 'music', 'sound']},
      {'en': 'Shower', 'ms': 'Mandi', 'cat': 'Verb', 'img': 'shower', 'tags': ['wash', 'clean', 'bathroom']},
      {'en': 'Play', 'ms': 'Main', 'cat': 'Verb', 'img': 'play', 'tags': ['fun', 'game', 'toy']},
      {'en': 'Study', 'ms': 'Belajar', 'cat': 'Verb', 'img': 'study', 'tags': ['school', 'read', 'book']},
      {'en': 'Work', 'ms': 'Kerja', 'cat': 'Verb', 'img': 'work', 'tags': ['job', 'office', 'busy']},
      {'en': 'Help', 'ms': 'Tolong', 'cat': 'Verb', 'img': 'help', 'tags': ['assist', 'support', 'need']},
      {'en': 'Call', 'ms': 'Panggil', 'cat': 'Verb', 'img': 'call', 'tags': ['talk', 'phone', 'chat']},
      {'en': 'Open', 'ms': 'Buka', 'cat': 'Verb', 'img': 'open', 'tags': ['door', 'box', 'start']},
      {'en': 'Close', 'ms': 'Tutup', 'cat': 'Verb', 'img': 'close', 'tags': ['door', 'shut', 'stop']},
      {'en': 'Stop', 'ms': 'Berhenti', 'cat': 'Verb', 'img': 'stop', 'tags': ['halt', 'end', 'no']},
      {'en': 'Start', 'ms': 'Mula', 'cat': 'Verb', 'img': 'start', 'tags': ['begin', 'go', 'now']},

      // --- 3. OBJECTS (Makanan & Barangan) ---
      {'en': 'Water', 'ms': 'Air', 'cat': 'Object', 'img': 'water', 'tags': ['drink', 'thirsty', 'liquid']},
      {'en': 'Rice', 'ms': 'Nasi', 'cat': 'Object', 'img': 'rice', 'tags': ['eat', 'food', 'hungry']},
      {'en': 'Bread', 'ms': 'Roti', 'cat': 'Object', 'img': 'bread', 'tags': ['eat', 'food', 'breakfast']},
      {'en': 'Pizza', 'ms': 'Piza', 'cat': 'Object', 'img': 'pizza', 'tags': ['eat', 'food', 'delicious']},
      {'en': 'Medicine', 'ms': 'Ubat', 'cat': 'Object', 'img': 'medicine', 'tags': ['sick', 'pain', 'doctor']},
      {'en': 'Toilet', 'ms': 'Tandas', 'cat': 'Object', 'img': 'toilet', 'tags': ['poop', 'pee', 'emergency']},
      {'en': 'Phone', 'ms': 'Telefon', 'cat': 'Object', 'img': 'phone', 'tags': ['call', 'talk', 'device']},
      {'en': 'Money', 'ms': 'Wang', 'cat': 'Object', 'img': 'money', 'tags': ['buy', 'pay', 'shop']},
      {'en': 'Clothes', 'ms': 'Baju', 'cat': 'Object', 'img': 'clothes', 'tags': ['wear', 'shirt', 'dress']},
      {'en': 'Bag', 'ms': 'Beg', 'cat': 'Object', 'img': 'bag', 'tags': ['carry', 'school', 'pack']},
      {'en': 'Home', 'ms': 'Rumah', 'cat': 'Object', 'img': 'home', 'tags': ['place', 'family', 'house']},
      {'en': 'Hospital', 'ms': 'Hospital', 'cat': 'Object', 'img': 'hospital', 'tags': ['sick', 'doctor', 'emergency']},
      {'en': 'Chair', 'ms': 'Kerusi', 'cat': 'Object', 'img': 'chair', 'tags': ['sit', 'rest', 'furniture']},
      {'en': 'Table', 'ms': 'Meja', 'cat': 'Object', 'img': 'table', 'tags': ['eat', 'work', 'furniture']},
      {'en': 'Computer', 'ms': 'Komputer', 'cat': 'Object', 'img': 'computer', 'tags': ['work', 'play', 'screen']},
      {'en': 'Key', 'ms': 'Kunci', 'cat': 'Object', 'img': 'key', 'tags': ['door', 'open', 'lock']},

      // --- 4. ADJECTIVES (Emosi & Fizikal) ---
      {'en': 'Happy', 'ms': 'Gembira', 'cat': 'Adjective', 'img': 'happy', 'tags': ['good', 'smile', 'mood']},
      {'en': 'Sad', 'ms': 'Sedih', 'cat': 'Adjective', 'img': 'sad', 'tags': ['bad', 'cry', 'mood']},
      {'en': 'Angry', 'ms': 'Marah', 'cat': 'Adjective', 'img': 'angry', 'tags': ['bad', 'mad', 'mood']},
      {'en': 'Pain', 'ms': 'Sakit', 'cat': 'Adjective', 'img': 'pain', 'tags': ['hurt', 'injury', 'doctor']},
      {'en': 'Tired', 'ms': 'Letih', 'cat': 'Adjective', 'img': 'tired', 'tags': ['sleep', 'rest', 'weak']},
      {'en': 'Hungry', 'ms': 'Lapar', 'cat': 'Adjective', 'img': 'hungry', 'tags': ['eat', 'food', 'want']},
      {'en': 'Thirsty', 'ms': 'Dahaga', 'cat': 'Adjective', 'img': 'thirsty', 'tags': ['drink', 'water', 'want']},
      {'en': 'Cold', 'ms': 'Sejuk', 'cat': 'Adjective', 'img': 'cold', 'tags': ['freeze', 'ice', 'feel']},
      {'en': 'Hot', 'ms': 'Panas', 'cat': 'Adjective', 'img': 'hot', 'tags': ['fire', 'burn', 'feel']},
      {'en': 'Scared', 'ms': 'Takut', 'cat': 'Adjective', 'img': 'scared', 'tags': ['afraid', 'panic', 'emotion']},
      {'en': 'Bored', 'ms': 'Bosan', 'cat': 'Adjective', 'img': 'bored', 'tags': ['dull', 'tired', 'emotion']},
      {'en': 'Loud', 'ms': 'Bising', 'cat': 'Adjective', 'img': 'loud', 'tags': ['noise', 'sound', 'angry']},
      {'en': 'Quiet', 'ms': 'Senyap', 'cat': 'Adjective', 'img': 'quiet', 'tags': ['silent', 'peace', 'calm']},

      // --- 5. EMERGENCY (Kritikal) ---
      {'en': 'Danger', 'ms': 'Bahaya', 'cat': 'Emergency', 'img': 'danger', 'tags': ['warning', 'safe', 'help']},
      {'en': 'Fire', 'ms': 'Api', 'cat': 'Emergency', 'img': 'fire', 'tags': ['burn', 'hot', 'danger']},
      {'en': 'Police', 'ms': 'Polis', 'cat': 'Emergency', 'img': 'police', 'tags': ['help', 'danger', 'safe']},
      {'en': 'Ambulance', 'ms': 'Ambulans', 'cat': 'Emergency', 'img': 'ambulance', 'tags': ['hospital', 'sick', 'help']},
      {'en': 'Blood', 'ms': 'Darah', 'cat': 'Emergency', 'img': 'blood', 'tags': ['hurt', 'pain', 'danger']},

      // --- 6. HYGIENE & HEALTH ---
      {'en': 'Soap', 'ms': 'Sabun', 'cat': 'Hygiene', 'img': 'soap', 'tags': ['wash', 'clean', 'shower']},
      {'en': 'Toothbrush', 'ms': 'Berus Gigi', 'cat': 'Hygiene', 'img': 'toothbrush', 'tags': ['teeth', 'clean', 'mouth']},
      {'en': 'Poop', 'ms': 'Berak', 'cat': 'Hygiene', 'img': 'poop', 'tags': ['toilet', 'bathroom', 'dirty']},
      {'en': 'Pee', 'ms': 'Kencing', 'cat': 'Hygiene', 'img': 'pee', 'tags': ['toilet', 'bathroom', 'liquid']},
      {'en': 'Fever', 'ms': 'Demam', 'cat': 'Hygiene', 'img': 'fever', 'tags': ['sick', 'hot', 'medicine']},
      {'en': 'Cough', 'ms': 'Batuk', 'cat': 'Hygiene', 'img': 'cough', 'tags': ['sick', 'throat', 'medicine']},

      // --- 7. TIME (Masa & Hari) ---
      {'en': 'Now', 'ms': 'Sekarang', 'cat': 'Time', 'img': 'now', 'tags': ['urgent', 'quick', 'time']},
      {'en': 'Later', 'ms': 'Nanti', 'cat': 'Time', 'img': 'later', 'tags': ['wait', 'delay', 'time']},
      {'en': 'Today', 'ms': 'Hari Ini', 'cat': 'Time', 'img': 'today', 'tags': ['now', 'day', 'time']},
      {'en': 'Tomorrow', 'ms': 'Esok', 'cat': 'Time', 'img': 'tomorrow', 'tags': ['next', 'day', 'time']},
      {'en': 'Yesterday', 'ms': 'Semalam', 'cat': 'Time', 'img': 'yesterday', 'tags': ['past', 'day', 'time']},
      {'en': 'Morning', 'ms': 'Pagi', 'cat': 'Time', 'img': 'morning', 'tags': ['start', 'day', 'sun']},
      {'en': 'Night', 'ms': 'Malam', 'cat': 'Time', 'img': 'night', 'tags': ['sleep', 'dark', 'moon']},
      {'en': 'Finish', 'ms': 'Siap', 'cat': 'Time', 'img': 'finish', 'tags': ['done', 'end', 'complete']},
      {'en': 'Always', 'ms': 'Selalu', 'cat': 'Time', 'img': 'always', 'tags': ['often', 'every', 'time']},
      {'en': 'Never', 'ms': 'Tidak Pernah', 'cat': 'Time', 'img': 'never', 'tags': ['not', 'zero', 'time']},

      // --- 8. QUESTIONS ---
      {'en': 'What', 'ms': 'Apa', 'cat': 'Question', 'img': 'what', 'tags': ['ask', 'thing', 'inquire']},
      {'en': 'Where', 'ms': 'Mana', 'cat': 'Question', 'img': 'where', 'tags': ['ask', 'place', 'location']},
      {'en': 'Who', 'ms': 'Siapa', 'cat': 'Question', 'img': 'who', 'tags': ['ask', 'person', 'people']},
      {'en': 'Why', 'ms': 'Kenapa', 'cat': 'Question', 'img': 'why', 'tags': ['ask', 'reason', 'cause']},
      {'en': 'How', 'ms': 'Bagaimana', 'cat': 'Question', 'img': 'how', 'tags': ['ask', 'method', 'way']},
      {'en': 'When', 'ms': 'Bila', 'cat': 'Question', 'img': 'when', 'tags': ['ask', 'time', 'date']},

      // --- 9. OTHERS (Pergaulan & Arah) ---
      {'en': 'Yes', 'ms': 'Ya', 'cat': 'Others', 'img': 'yes', 'tags': ['agree', 'ok', 'good']},
      {'en': 'No', 'ms': 'Tidak', 'cat': 'Others', 'img': 'no', 'tags': ['disagree', 'reject', 'bad']},
      {'en': 'Hello', 'ms': 'Helo', 'cat': 'Others', 'img': 'person', 'tags': ['greet', 'hi', 'welcome']},
      {'en': 'Thanks', 'ms': 'Terima Kasih', 'cat': 'Others', 'img': 'heart', 'tags': ['grateful', 'kind', 'happy']},
      {'en': 'Sorry', 'ms': 'Maaf', 'cat': 'Others', 'img': 'sad', 'tags': ['apologize', 'regret', 'sad']},
      {'en': 'Up', 'ms': 'Atas', 'cat': 'Others', 'img': 'up', 'tags': ['high', 'above', 'direction']},
      {'en': 'Down', 'ms': 'Bawah', 'cat': 'Others', 'img': 'down', 'tags': ['low', 'below', 'direction']},
      {'en': 'In', 'ms': 'Dalam', 'cat': 'Others', 'img': 'in', 'tags': ['inside', 'enter', 'direction']},
      {'en': 'Out', 'ms': 'Luar', 'cat': 'Others', 'img': 'out', 'tags': ['outside', 'exit', 'direction']},

      // --- 10. ANIMALS (Ujian Visual) ---
      {'en': 'Cat', 'ms': 'Kucing', 'cat': 'Others', 'img': 'cat', 'tags': ['animal', 'pet', 'meow']},
      {'en': 'Dog', 'ms': 'Anjing', 'cat': 'Others', 'img': 'dog', 'tags': ['animal', 'pet', 'bark']},
      {'en': 'Bird', 'ms': 'Burung', 'cat': 'Others', 'img': 'bird', 'tags': ['animal', 'fly', 'sky']},
    ];

    setState(() => _isSeeding = true);

    try {
      // 🚨 Protocol: Bersihkan library_v2 dulu kalau kau nak start fresh
      // (Optional: Kalau tak nak bertindih, kau kena delete manual kat Firestore dulu)

      for (var item in masterPictograms) {
        await _firestore.collection('library_v2').add({
          'label_en': item['en'],
          'label_ms': item['ms'],
          'category': item['cat'],
          'image_url': item['img'],
          'tags': item.containsKey('tags') ? item['tags'] : [], // 🚨 INI YANG KAU KENA TAMBAH BABI!
          'ownerId': 'GLOBAL',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Master Data Injected! 🚀'), backgroundColor: Colors.purple),
        );
      }
    } catch (e) {
      print("Error Gila: $e");
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