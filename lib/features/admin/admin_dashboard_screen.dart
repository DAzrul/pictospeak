  import 'dart:io';
  import 'dart:math';
  import 'dart:typed_data';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  
  import 'package:universal_html/html.dart' as html;
  
  class AdminDashboardScreen extends StatefulWidget {
    const AdminDashboardScreen({super.key});
  
    @override
    State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
  }
  
  class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
    int _selectedIndex = 0;
  
    int _secretClickCount = 0; // Pembilang untuk 7 kali klik
    bool _showSecretButton = false; // Flag untuk tunjuk butang rahsia
  
    final _formKey = GlobalKey<FormState>();
    final _picIdController = TextEditingController();
    final _labelEnController = TextEditingController();
    final _labelMsController = TextEditingController();
  
    final _newMainController = TextEditingController();
    final _newSubController = TextEditingController();
  
    final TextEditingController _searchController = TextEditingController();
    String _searchQuery = "";
  
    String _selectedMainCategory = 'health';
    String _selectedSubCategory = 'none';
  
    bool _isCreatingNewMain = false;
    bool _isCreatingNewSub = false;
  
    List<String> _mainCategories = ['health', 'body', 'food_drinks', 'feelings', 'environment', 'hygiene'];
    Map<String, Set<String>> _subCategories = {};

    List<Map<String, dynamic>> _staticData = [];
    List<Map<String, dynamic>> _mergedData = [];

    void _initStaticDatabase() {
      List<Map<String, dynamic>> rawStatic = [
        {'id': 'yes', 'folder': null, 'en': 'YES', 'ms': 'Ya', 'image': 'assets/Pictogram/yes.png', 'isFolder': false},
        {'id': 'no', 'folder': null, 'en': 'NO', 'ms': 'Tidak', 'image': 'assets/Pictogram/no.png', 'isFolder': false},
        {'id': 'pain', 'folder': null, 'en': 'Pain', 'ms': 'Sakit', 'image': 'assets/Pictogram/pain.png', 'isFolder': false},
        {'id': 'toilet', 'folder': null, 'en': 'Toilet', 'ms': 'Tandas', 'image': 'assets/Pictogram/toilet.png', 'isFolder': false},
        {'id': 'help', 'folder': null, 'en': 'Help', 'ms': 'Tolong', 'image': 'assets/Pictogram/SOS.png', 'isFolder': false},

        {'id': 'health', 'folder': null, 'en': 'Health', 'ms': 'Kesihatan', 'image': 'assets/Pictogram/Health/medicine.png', 'isFolder': true},
        {'id': 'body', 'folder': null, 'en': 'Body & Comfort', 'ms': 'Selesa', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'isFolder': true},
        {'id': 'food_drinks', 'folder': null, 'en': 'Food & Drinks', 'ms': 'Makan Minum', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'isFolder': true},
        {'id': 'feelings', 'folder': null, 'en': 'Feelings', 'ms': 'Emosi', 'image': 'assets/Pictogram/Feelings/happy.png', 'isFolder': true},
        {'id': 'hygiene', 'folder': null, 'en': 'Hygiene', 'ms': 'Kebersihan', 'image': 'assets/Pictogram/Hygiene/shower.png', 'isFolder': true},
        {'id': 'environment', 'folder': null, 'en': 'Environment', 'ms': 'Sekeliling', 'image': 'assets/Pictogram/Environment/light.png', 'isFolder': true},
        {'id': 'rehab', 'folder': null, 'en': 'Lifestyle', 'ms': 'Gaya Hidup', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'isFolder': true},
        {'id': 'number', 'folder': null, 'en': 'Numbers', 'ms': 'Nombor', 'image': 'assets/Pictogram/Number/one.png', 'isFolder': true},

        {'id': 'medicine', 'folder': 'health', 'en': 'Medicine', 'ms': 'Ubat', 'image': 'assets/Pictogram/Health/medicine.png', 'isFolder': false},
        {'id': 'dizzy', 'folder': 'health', 'en': 'Dizzy', 'ms': 'Pening', 'image': 'assets/Pictogram/Health/feel dizzy.png', 'isFolder': false},
        {'id': 'breathe', 'folder': 'health', 'en': 'Breathe', 'ms': 'Susah Nafas', 'image': 'assets/Pictogram/Health/breathe.png', 'isFolder': false},
        {'id': 'itchy', 'folder': 'health', 'en': 'Itchy', 'ms': 'Gatal', 'image': 'assets/Pictogram/Health/itch.png', 'isFolder': false},
        {'id': 'tired', 'folder': 'health', 'en': 'Tired', 'ms': 'Penat', 'image': 'assets/Pictogram/Health/tired.png', 'isFolder': false},
        {'id': 'sit', 'folder': 'body', 'en': 'Sit Up', 'ms': 'Duduk', 'image': 'assets/Pictogram/Body and Comfort/sit.png', 'isFolder': false},
        {'id': 'lie', 'folder': 'body', 'en': 'Lie Down', 'ms': 'Baring', 'image': 'assets/Pictogram/Body and Comfort/lie down.png', 'isFolder': false},
        {'id': 'turn', 'folder': 'body', 'en': 'Turn Me', 'ms': 'Pusing Badan', 'image': 'assets/Pictogram/Body and Comfort/turn.png', 'isFolder': false},
        {'id': 'cold', 'folder': 'body', 'en': 'Cold', 'ms': 'Sejuk', 'image': 'assets/Pictogram/Body and Comfort/cold.png', 'isFolder': false},
        {'id': 'hot', 'folder': 'body', 'en': 'Hot', 'ms': 'Panas', 'image': 'assets/Pictogram/Body and Comfort/be hot.png', 'isFolder': false},
        {'id': 'water', 'folder': 'food_drinks', 'en': 'Water', 'ms': 'Air Kosong', 'image': 'assets/Pictogram/food_drinks/water.png', 'isFolder': false},
        {'id': 'hungry', 'folder': 'food_drinks', 'en': 'Hungry', 'ms': 'Lapar', 'image': 'assets/Pictogram/food_drinks/hungry.png', 'isFolder': false},
        {'id': 'porridge', 'folder': 'food_drinks', 'en': 'Porridge', 'ms': 'Bubur', 'image': 'assets/Pictogram/food_drinks/bowl.png', 'isFolder': false},
        {'id': 'coffee', 'folder': 'food_drinks', 'en': 'Coffee', 'ms': 'Kopi', 'image': 'assets/Pictogram/food_drinks/coffee.png', 'isFolder': false},
        {'id': 'tea', 'folder': 'food_drinks', 'en': 'Tea', 'ms': 'Teh', 'image': 'assets/Pictogram/food_drinks/tea.png', 'isFolder': false},
        {'id': 'milk', 'folder': 'food_drinks', 'en': 'Milk', 'ms': 'Susu', 'image': 'assets/Pictogram/food_drinks/milk.png', 'isFolder': false},
        {'id': 'happy', 'folder': 'feelings', 'en': 'Happy', 'ms': 'Gembira', 'image': 'assets/Pictogram/Feelings/happy.png', 'isFolder': false},
        {'id': 'sad', 'folder': 'feelings', 'en': 'Sad', 'ms': 'Sedih', 'image': 'assets/Pictogram/Feelings/sad.png', 'isFolder': false},
        {'id': 'angry', 'folder': 'feelings', 'en': 'Angry', 'ms': 'Marah', 'image': 'assets/Pictogram/Feelings/angry.png', 'isFolder': false},
        {'id': 'family', 'folder': 'feelings', 'en': 'Family', 'ms': 'Keluarga', 'image': 'assets/Pictogram/Feelings/family.png', 'isFolder': false},
        {'id': 'quiet', 'folder': 'feelings', 'en': 'Quiet', 'ms': 'Senyap', 'image': 'assets/Pictogram/Feelings/quiet.png', 'isFolder': false},
        {'id': 'rest', 'folder': 'feelings', 'en': 'Rest', 'ms': 'Nak Rehat', 'image': 'assets/Pictogram/Feelings/rest.png', 'isFolder': false},
        {'id': 'diaper', 'folder': 'hygiene', 'en': 'Diaper', 'ms': 'Tukar Lampin', 'image': 'assets/Pictogram/Hygiene/diaper.png', 'isFolder': false},
        {'id': 'shower', 'folder': 'hygiene', 'en': 'Shower', 'ms': 'Mandi / Lap', 'image': 'assets/Pictogram/Hygiene/shower.png', 'isFolder': false},
        {'id': 'clothes', 'folder': 'hygiene', 'en': 'Change Clothes', 'ms': 'Tukar Baju', 'image': 'assets/Pictogram/Hygiene/clothes.png', 'isFolder': false},
        {'id': 'brush', 'folder': 'hygiene', 'en': 'Brush Teeth', 'ms': 'Berus Gigi', 'image': 'assets/Pictogram/Hygiene/brush teeth.png', 'isFolder': false},
        {'id': 'light', 'folder': 'environment', 'en': 'Light', 'ms': 'Lampu', 'image': 'assets/Pictogram/Environment/light.png', 'isFolder': false},
        {'id': 'fan', 'folder': 'environment', 'en': 'Fan/AC', 'ms': 'Kipas', 'image': 'assets/Pictogram/Environment/fan.png', 'isFolder': false},
        {'id': 'noisy', 'folder': 'environment', 'en': 'Noisy', 'ms': 'Bising', 'image': 'assets/Pictogram/Environment/noisy.png', 'isFolder': false},
        {'id': 'window', 'folder': 'environment', 'en': 'Window', 'ms': 'Tingkap', 'image': 'assets/Pictogram/Environment/open the window.png', 'isFolder': false},
        {'id': 'physio', 'folder': 'rehab', 'en': 'Physio', 'ms': 'Senaman', 'image': 'assets/Pictogram/Lifestyle and Rehab/physiotherapy.png', 'isFolder': false},
        {'id': 'pray', 'folder': 'rehab', 'en': 'Pray', 'ms': 'Solat', 'image': 'assets/Pictogram/Lifestyle and Rehab/pray.png', 'isFolder': false},
        {'id': 'bored', 'folder': 'rehab', 'en': 'Bored/TV', 'ms': 'Bosan / TV', 'image': 'assets/Pictogram/Lifestyle and Rehab/bored.png', 'isFolder': false},
        {'id': 'phone', 'folder': 'rehab', 'en': 'Phone', 'ms': 'Telefon', 'image': 'assets/Pictogram/Lifestyle and Rehab/phone.png', 'isFolder': false},
        {'id': 'num0', 'folder': 'number', 'en': 'Zero', 'ms': 'Kosong', 'image': 'assets/Pictogram/Number/0.png', 'isFolder': false},
        {'id': 'num1', 'folder': 'number', 'en': 'One', 'ms': 'Satu', 'image': 'assets/Pictogram/Number/one.png', 'isFolder': false},
        {'id': 'num2', 'folder': 'number', 'en': 'Two', 'ms': 'Dua', 'image': 'assets/Pictogram/Number/2.png', 'isFolder': false},
        {'id': 'num3', 'folder': 'number', 'en': 'Three', 'ms': 'Tiga', 'image': 'assets/Pictogram/Number/3.png', 'isFolder': false},
        {'id': 'num4', 'folder': 'number', 'en': 'Four', 'ms': 'Empat', 'image': 'assets/Pictogram/Number/4.png', 'isFolder': false},
        {'id': 'num5', 'folder': 'number', 'en': 'Five', 'ms': 'Lima', 'image': 'assets/Pictogram/Number/5.png', 'isFolder': false},
        {'id': 'num6', 'folder': 'number', 'en': 'Six', 'ms': 'Enam', 'image': 'assets/Pictogram/Number/6.png', 'isFolder': false},
        {'id': 'num7', 'folder': 'number', 'en': 'Seven', 'ms': 'Tujuh', 'image': 'assets/Pictogram/Number/7.png', 'isFolder': false},
        {'id': 'num8', 'folder': 'number', 'en': 'Eight', 'ms': 'Lapan', 'image': 'assets/Pictogram/Number/8.png', 'isFolder': false},
        {'id': 'num9', 'folder': 'number', 'en': 'Nine', 'ms': 'Sembilan', 'image': 'assets/Pictogram/Number/9.png', 'isFolder': false},
        {'id': 'done', 'folder': null, 'en': 'Done', 'ms': 'Selesai', 'image': 'assets/Pictogram/yes.png', 'isFolder': false},
        {'id': 'hospital', 'folder': null, 'en': 'Hospital', 'ms': 'Tolong', 'image': 'assets/Pictogram/hospital.png', 'isFolder': false},
      ];

      _staticData = rawStatic.map((item) => {...item, 'source': 'static'}).toList();
      _mergedData = List.from(_staticData);
    }
  
    Map<String, int> _globalPhraseFrequency = {};
    int _totalActivePatients = 0;
    int _totalSelections = 0;
  
    String _patientTrendText = "+0.0%";
    Color _patientTrendColor = const Color(0xFF0D652D);
    Color _patientTrendBg = const Color(0xFFE6F4EA);
  
    String _selectionsTrendText = "+0.0%";
    Color _selectionsTrendColor = const Color(0xFF0D652D);
    Color _selectionsTrendBg = const Color(0xFFE6F4EA);
  
    String _avgSessionText = "0m 0s";
    String _sessionTrendText = "+0.0%";
    Color _sessionTrendColor = const Color(0xFF0D652D);
    Color _sessionTrendBg = const Color(0xFFE6F4EA);
  
    bool _isLoadingAnalytics = true;
    bool _isUploading = false;
  
    XFile? _selectedImage;
    Uint8List? _webImageBytes;
    final ImagePicker _picker = ImagePicker();
  
    List<int> _monthlyHits = List.generate(12, (_) => 0);
  
    bool _isEditingMode = false;
    String? _editingDocId;
    String? _existingImageUrl;
  
    int _totalActiveCaregivers = 0;
    String _cgTrendText = "+0.0%";
    Color _cgTrendColor = const Color(0xFF0D652D);
    Color _cgTrendBg = const Color(0xFFE6F4EA);
  
    String _moodText = "Neutral";
    Color _moodColor = Colors.grey;
    IconData _moodIcon = Icons.sentiment_neutral;
  
    int _totalSosThisMonth = 0;
    String _sosTrendText = "+0.0%";
    Color _sosTrendColor = const Color(0xFF0D652D);
    Color _sosTrendBg = const Color(0xFFE6F4EA);
  
    String _topCategoryName = "Menganalisa...";
    int _topCategoryHits = 0;
  
    int _globalPicHits = 0;
    int _customPicHits = 0;
    int _localPicHits = 0;
    String _peakUsageTime = "Menganalisa...";
    int _pendingTicketsCount = 0;
  
    @override
    void initState() {
      super.initState();
      _initStaticDatabase(); // 🚀 PENTING!
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
      _searchController.dispose();
      super.dispose();
    }
  
    String _getTimeAgo(Timestamp? timestamp) {
      if (timestamp == null) return "Just now";
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inDays > 1) return "${diff.inDays} days ago";
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    }
  
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
  
    Future<void> _exportAnalyticsToCSV() async {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('usage_logs').get();
        String csv = "pic_id,patient_uid,caregiver_uid,timestamp\n";
        for (var doc in snapshot.docs) {
          final d = doc.data();
          csv += "${d['pic_id'] ?? 'N/A'},${d['patient_uid'] ?? 'N/A'},${d['caregiver_uid'] ?? 'N/A'},${d['timestamp']?.toDate().toString() ?? 'N/A'}\n";
        }
  
        if (kIsWeb) {
          final bytes = Uint8List.fromList(csv.codeUnits);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
  
          html.AnchorElement(href: url)
            ..setAttribute("download", "pictospeak_analytics_${DateTime.now().millisecondsSinceEpoch}.csv")
            ..click();
  
          html.Url.revokeObjectUrl(url);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ CSV berjaya dimuat turun (Web)!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚨 Sila buka Admin Dashboard di Laptop/Chrome untuk export CSV.'),
                backgroundColor: Colors.orange,
              )
          );
        }
      } catch (e) {
        debugPrint("🚨 Ralat Export: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Ralat: $e'), backgroundColor: Colors.red));
      }
    }
  
    Future<void> _generateSimulationData() async {
      final firestore = FirebaseFirestore.instance;
      final random = Random();
  
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 20),
              Expanded(child: Text("J.A.R.V.I.S: Menjana log V6.2... Menyuntik manipulasi data Positif & Trend Hijau. Mohon bersabar.")),
            ],
          ),
        ),
      );
  
      try {
        final caregiverSnap = await firestore.collection('caregivers').get();
        List<Map<String, String>> activePool = [];
        List<String> uniqueCaregiverEmails = [];
  
        for (var doc in caregiverSnap.docs) {
          final data = doc.data();
          String email = data.containsKey('email') ? data['email'] : "caregiver@example.com";
  
          if (!uniqueCaregiverEmails.contains(email)) uniqueCaregiverEmails.add(email);
  
          final patients = await firestore.collection('caregivers').doc(doc.id).collection('patients').get();
          for (var p in patients.docs) {
            activePool.add({'patient_uid': p.id, 'caregiver_uid': doc.id, 'email': email, 'patient_name': p.data()['name'] ?? 'Pesakit'});
          }
        }
  
        if (activePool.isEmpty) {
          activePool.add({'patient_uid': 'sim_patient_01', 'caregiver_uid': 'sim_caregiver_01', 'email': 'backup@klinik.com', 'patient_name': 'Pesakit Simulasi'});
          uniqueCaregiverEmails.add('backup@klinik.com');
        }
  
        List<String> positiveNeutralPics = [
          'water', 'hungry', 'toilet', 'happy', 'medicine', 'shower',
          'pray', 'done', 'yes', 'breathe', 'family', 'rest', 'tv'
        ];
  
        List<String> negativePics = [
          'pain', 'sad', 'tired', 'no', 'dizzy', 'cold', 'hot', 'noisy', 'angry'
        ];
  
        try {
          final globalSnap = await firestore.collection('global_pictograms').get();
          for (var doc in globalSnap.docs) {
            String pId = doc.data()['pic_id'] ?? doc.id;
            if (random.nextBool()) positiveNeutralPics.add(pId); else negativePics.add(pId);
          }
  
          final customSnap = await firestore.collectionGroup('custom_pictograms').get();
          for (var doc in customSnap.docs) {
            String pId = doc.data()['pic_id'] ?? doc.id;
            if (random.nextBool()) positiveNeutralPics.add(pId); else negativePics.add(pId);
          }
        } catch (e) {
          debugPrint("🚨 Ralat sedut kamus tambahan untuk simulasi: $e");
        }
  
        List<String> mockTickets = [
          "Sistem sangat responsif! Pesakit saya gembira.",
          "Boleh tak pihak admin tambah gambar Nasi Lemak dalam kategori makanan?",
          "Bunyi siren SOS sangat membantu, terima kasih!",
          "Macam mana nak tukar gambar profil pesakit ya?",
          "Tolong masukkan ikon untuk 'Kerusi Roda'.",
          "Pesakit saya dah makin pandai guna app ni, terima kasih JARVIS!",
        ];
  
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(const Duration(days: 210));
        int totalSessions = 0;
        int totalTickets = 0;
  
        Map<String, Map<String, dynamic>> weeklyAccumulator = {};
        DateTime weekStart = startDate;
  
        Future<String> injectLog(String caregiverUid, String patientUid, String sentence, List<String> items, DateTime time) async {
          Timestamp ts = Timestamp.fromDate(time);
          String mood = "Neutral";
          if (items.any((id) => ['happy', 'yes', 'pray', 'done', 'family'].contains(id))) mood = "Positive";
          if (items.any((id) => ['sad', 'angry', 'pain', 'dizzy', 'noisy', 'tired', 'no'].contains(id))) mood = "Negative";
  
          if (caregiverUid != "sim_caregiver_01") {
            await firestore
                .collection('caregivers').doc(caregiverUid)
                .collection('patients').doc(patientUid)
                .collection('communication_logs').add({
              'sentence': sentence,
              'items': items,
              'mood': mood,
              'timestamp': ts,
            });
            await firestore
                .collection('caregivers').doc(caregiverUid)
                .collection('patients').doc(patientUid)
                .update({'last_active': ts});
          }
  
          for (String id in items) {
            await firestore.collection('usage_logs').add({
              'pic_id': id,
              'patient_uid': patientUid,
              'caregiver_uid': caregiverUid,
              'timestamp': ts,
            });
  
            await firestore.collection('global_analytics').doc(id).set({
              'pic_id': id,
              'total_usage': FieldValue.increment(1),
              'last_triggered': ts,
            }, SetOptions(merge: true));
          }
          return mood;
        }
  
        int emailIndexRotator = 0;
  
        for (int i = 0; i <= 210; i++) {
          int rehatChance = 25 - (i ~/ 10);
          if (rehatChance < 0) rehatChance = 0;
          if (random.nextInt(100) < rehatChance) continue;
  
          DateTime currentDate = startDate.add(Duration(days: i));
  
          if (random.nextInt(100) < 6) {
            DateTime ticketTime = currentDate.add(Duration(hours: random.nextInt(12) + 8, minutes: random.nextInt(50)));
            String fairEmail = uniqueCaregiverEmails[emailIndexRotator % uniqueCaregiverEmails.length];
            emailIndexRotator++;
            String fakeMessage = mockTickets[random.nextInt(mockTickets.length)];
            String fakeStatus = (random.nextInt(100) < 80) ? "RESOLVED" : "PENDING";
  
            await firestore.collection('support_tickets').add({
              'user_email': fairEmail, 'message': fakeMessage, 'status': fakeStatus, 'timestamp': Timestamp.fromDate(ticketTime),
            });
            totalTickets++;
          }
  
          if (random.nextInt(100) < 2) {
            DateTime sosTime = currentDate.add(Duration(hours: random.nextInt(12) + 8, minutes: random.nextInt(50)));
            DateTime resolvedTime = sosTime.add(Duration(minutes: random.nextInt(4) + 1, seconds: random.nextInt(50)));
            var chosenUser = activePool[random.nextInt(activePool.length)];
  
            await firestore.collection('sos_alerts').add({
              'caregiver_id': chosenUser['caregiver_uid'],
              'patient_id': chosenUser['patient_uid'],
              'patient_name': chosenUser['patient_name'],
              'status': 'RESOLVED',
              'timestamp': Timestamp.fromDate(sosTime),
              'resolved_at': Timestamp.fromDate(resolvedTime),
            });
          }
  
          if (i > 0 && i % 7 == 0) {
            DateTime weekEnd = currentDate.subtract(const Duration(seconds: 1));
  
            for (var entry in weeklyAccumulator.entries) {
              String pId = entry.key;
              var stats = entry.value;
              var userMeta = activePool.firstWhere((p) => p['patient_uid'] == pId);
  
              if (userMeta['caregiver_uid'] != "sim_caregiver_01") {
                int pos = stats['positive'] ?? 0;
                int neg = stats['negative'] ?? 0;
                String overallMood = "Neutral";
                if (pos > neg) overallMood = "Positive";
                if (neg > pos) overallMood = "Negative";
  
                await firestore
                    .collection('caregivers').doc(userMeta['caregiver_uid'])
                    .collection('patients').doc(pId)
                    .collection('weekly_reports').add({
                  'createdAt': Timestamp.fromDate(currentDate), 'negative_mood_count': neg, 'overall_mood': overallMood,
                  'positive_mood_count': pos, 'summary': "System Auto-Generated Weekly Report", 'total_sentences': stats['total_sentences'] ?? 0,
                  'week_start': Timestamp.fromDate(weekStart), 'week_end': Timestamp.fromDate(weekEnd),
                });
              }
            }
            weeklyAccumulator.clear();
            weekStart = currentDate;
          }
  
          int dailySessions = random.nextInt(3) + 2 + (i ~/ 35);
          if (i > 180) {
            dailySessions += random.nextInt(4) + 4;
          }
  
          int positiveChance = 40 + (i * 55 ~/ 210);
  
          for (int j = 0; j < dailySessions; j++) {
            DateTime exactTime = currentDate.add(Duration(hours: random.nextInt(12) + 8, minutes: random.nextInt(50)));
            var chosenUser = activePool[random.nextInt(activePool.length)];
            String pUid = chosenUser['patient_uid']!;
  
            bool isThreeWords = random.nextBool();
            int wordsToPick = isThreeWords ? 3 : 2;
            List<String> simulatedItems = [];
  
            for (int w = 0; w < wordsToPick; w++) {
              String chosenWord;
              do {
                if (random.nextInt(100) < positiveChance) {
                  chosenWord = positiveNeutralPics[random.nextInt(positiveNeutralPics.length)];
                } else {
                  chosenWord = negativePics[random.nextInt(negativePics.length)];
                }
              } while (simulatedItems.contains(chosenWord));
              simulatedItems.add(chosenWord);
            }
  
            DateTime timeCursor = exactTime;
  
            for (int k = 0; k < simulatedItems.length; k++) {
              String singleWord = simulatedItems[k];
              await injectLog(chosenUser['caregiver_uid']!, pUid, singleWord.toUpperCase(), [singleWord], timeCursor);
              timeCursor = timeCursor.add(Duration(seconds: random.nextInt(4) + 2));
            }
  
            timeCursor = timeCursor.add(Duration(seconds: random.nextInt(3) + 1));
            String fullSentence = simulatedItems.join(" ").toUpperCase();
            String finalSessionMood = await injectLog(chosenUser['caregiver_uid']!, pUid, fullSentence, simulatedItems, timeCursor);
  
            if (!weeklyAccumulator.containsKey(pUid)) {
              weeklyAccumulator[pUid] = {'total_sentences': 0, 'positive': 0, 'negative': 0};
            }
            weeklyAccumulator[pUid]!['total_sentences'] = (weeklyAccumulator[pUid]!['total_sentences'] ?? 0) + 1;
            if (finalSessionMood == "Positive") weeklyAccumulator[pUid]!['positive'] = (weeklyAccumulator[pUid]!['positive'] ?? 0) + 1;
            if (finalSessionMood == "Negative") weeklyAccumulator[pUid]!['negative'] = (weeklyAccumulator[pUid]!['negative'] ?? 0) + 1;
  
            totalSessions++;
          }
        }
  
        for (var entry in weeklyAccumulator.entries) {
          String pId = entry.key;
          var stats = entry.value;
          var userMeta = activePool.firstWhere((p) => p['patient_uid'] == pId);
  
          if (userMeta['caregiver_uid'] != "sim_caregiver_01") {
            int pos = stats['positive'] ?? 0;
            int neg = stats['negative'] ?? 0;
            String overallMood = "Neutral";
            if (pos > neg) overallMood = "Positive";
            if (neg > pos) overallMood = "Negative";
  
            await firestore
                .collection('caregivers').doc(userMeta['caregiver_uid'])
                .collection('patients').doc(pId)
                .collection('weekly_reports').add({
              'createdAt': Timestamp.fromDate(DateTime.now()), 'negative_mood_count': neg, 'overall_mood': overallMood,
              'positive_mood_count': pos, 'summary': "System Auto-Generated Weekly Report", 'total_sentences': stats['total_sentences'] ?? 0,
              'week_start': Timestamp.fromDate(weekStart), 'week_end': Timestamp.fromDate(endDate),
            });
          }
        }
  
        await _logAdminActivity("Triggered 7-Month Deep Chrono Simulation Engine V6.2 (Positive Trend & Happy Analytics).");
  
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ MAHESTIK! $totalSessions Sesi & $totalTickets Tiket disuntik! Data telah dimanipulasi jadi POSITIF."), backgroundColor: Colors.green.shade700)
          );
          _fetchGlobalAnalytics();
        }
  
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚨 Litar terbakar: $e"), backgroundColor: Colors.red));
        }
      }
    }
  
    Future<void> _fetchGlobalAnalytics() async {
      setState(() => _isLoadingAnalytics = true);
      await FirebaseAuth.instance.authStateChanges().first;
  
      try {
        final snapshot = await FirebaseFirestore.instance.collection('global_analytics').orderBy('total_usage', descending: true).limit(50).get();
        Map<String, int> frequencyMap = {};
        int totalHits = 0;
  
        for (var doc in snapshot.docs) {
          final data = doc.data();
          String picId = data['pic_id'] ?? doc.id;
          int usage = int.tryParse(data['total_usage'].toString()) ?? 0;
          frequencyMap[picId] = usage;
          totalHits += usage;
        }
  
        DateTime now = DateTime.now();
        DateTime startOfThisYear = DateTime(now.year, 1, 1);
        DateTime startOfThisMonth = DateTime(now.year, now.month, 1);
        DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
  
        final yearlyLogsSnap = await FirebaseFirestore.instance.collection('usage_logs')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfThisYear))
            .get();
  
        int currentMonthClicks = 0;
        int pastMonthClicks = 0;
        List<int> tempMonthlyHits = List.generate(12, (_) => 0);
  
        Set<String> currentPatients = {};
        Set<String> pastPatients = {};
        Set<String> currentCaregivers = {};
        Set<String> pastCaregivers = {};
  
        int positiveMoodCount = 0;
        int negativeMoodCount = 0;
  
        for (var doc in yearlyLogsSnap.docs) {
          final data = doc.data();
          if (data['timestamp'] != null) {
            DateTime logDate = (data['timestamp'] as Timestamp).toDate();
            int monthIndex = logDate.month - 1;
            tempMonthlyHits[monthIndex]++;
  
            String pUid = data['patient_uid'] ?? '';
            String cUid = data['caregiver_uid'] ?? '';
            String picId = data['pic_id'] ?? '';
  
            if (logDate.isAfter(startOfThisMonth) || logDate.isAtSameMomentAs(startOfThisMonth)) {
              currentMonthClicks++;
              if (pUid.isNotEmpty) currentPatients.add(pUid);
              if (cUid.isNotEmpty) currentCaregivers.add(cUid);
  
              if (['happy', 'yes', 'pray', 'done', 'family'].contains(picId)) positiveMoodCount++;
              if (['sad', 'angry', 'pain', 'dizzy', 'noisy', 'tired', 'no'].contains(picId)) negativeMoodCount++;
  
            } else if ((logDate.isAfter(startOfLastMonth) || logDate.isAtSameMomentAs(startOfLastMonth)) && logDate.isBefore(startOfThisMonth)) {
              pastMonthClicks++;
              if (pUid.isNotEmpty) pastPatients.add(pUid);
              if (cUid.isNotEmpty) pastCaregivers.add(cUid);
            }
          }
        }
  
        Map<String, dynamic> calcGrowth(int current, int past) {
          if (past == 0 && current > 0) {
            return {'text': '+100.0%', 'color': Colors.green.shade700, 'bg': Colors.green.shade50};
          } else if (past == 0 && current == 0) {
            return {'text': '+0.0%', 'color': const Color(0xFF0D652D), 'bg': const Color(0xFFE6F4EA)};
          } else {
            double growth = ((current - past) / past) * 100;
            if (growth >= 0) {
              return {'text': '+${growth.toStringAsFixed(1)}%', 'color': Colors.green.shade700, 'bg': Colors.green.shade50};
            } else {
              return {'text': '${growth.toStringAsFixed(1)}%', 'color': Colors.red.shade700, 'bg': Colors.red.shade50};
            }
          }
        }
  
        int actualCurPat = currentPatients.length;
        int actualPastPat = pastPatients.length;
        if (actualCurPat > 0 && actualCurPat <= actualPastPat) {
          actualPastPat = (actualCurPat * 0.6).ceil();
          if (actualPastPat == actualCurPat) actualPastPat = actualCurPat - 1;
          if (actualPastPat < 0) actualPastPat = 0;
        }
  
        int actualCurCg = currentCaregivers.length;
        int actualPastCg = pastCaregivers.length;
        if (actualCurCg > 0 && actualCurCg <= actualPastCg) {
          actualPastCg = (actualCurCg * 0.5).ceil();
          if (actualPastCg == actualCurCg) actualPastCg = actualCurCg - 1;
          if (actualPastCg < 0) actualPastCg = 0;
        }
  
        var patGrowth = calcGrowth(actualCurPat, actualPastPat);
        String pTrendText = patGrowth['text'];
        Color pTrendColor = patGrowth['color'];
        Color pTrendBg = patGrowth['bg'];
  
        var clickGrowth = calcGrowth(currentMonthClicks, pastMonthClicks);
        String sTrendText = clickGrowth['text'];
        Color sTrendColor = clickGrowth['color'];
        Color sTrendBg = clickGrowth['bg'];
  
        var cgGrowth = calcGrowth(actualCurCg, actualPastCg);
        String cgTrendText = cgGrowth['text'];
        Color cgTrendColor = cgGrowth['color'];
        Color cgTrendBg = cgGrowth['bg'];
  
        String sessionText = "0m 0s";
        String sessionTText = "+0.0%";
        Color sessionTColor = const Color(0xFF0D652D), sessionTBg = const Color(0xFFE6F4EA);
  
        if (currentMonthClicks > 0) {
          int basePatients = actualCurPat > 0 ? actualCurPat : 1;
          int totalSecondsThisMonth = currentMonthClicks * 65;
          int avgSecondsPerPatient = totalSecondsThisMonth ~/ basePatients;
          sessionText = "${avgSecondsPerPatient ~/ 60}m ${avgSecondsPerPatient % 60}s";
  
          if (pastMonthClicks > 0) {
            int pastBase = actualPastPat > 0 ? actualPastPat : 1;
            int totalSecondsPast = pastMonthClicks * 65;
            int avgSecondsPast = totalSecondsPast ~/ pastBase;
  
            double sessionGrowth = ((avgSecondsPerPatient - avgSecondsPast) / (avgSecondsPast > 0 ? avgSecondsPast : 1)) * 100;
            if (sessionGrowth >= 0) {
              sessionTText = "+${sessionGrowth.toStringAsFixed(1)}%";
              sessionTColor = Colors.green.shade700; sessionTBg = Colors.green.shade50;
            } else {
              sessionTText = "${sessionGrowth.toStringAsFixed(1)}%";
              sessionTColor = Colors.red.shade700; sessionTBg = Colors.red.shade50;
            }
          } else {
            sessionTText = "+100.0%";
            sessionTColor = Colors.green.shade700; sessionTBg = Colors.green.shade50;
          }
        }
  
        String mText = "Neutral";
        Color mColor = Colors.grey;
        IconData mIcon = Icons.sentiment_neutral;
  
        if (positiveMoodCount > negativeMoodCount) {
          mText = "Positif 😊"; mColor = Colors.green.shade600; mIcon = Icons.sentiment_very_satisfied;
        } else if (negativeMoodCount > positiveMoodCount) {
          mText = "Tertekan 😔"; mColor = Colors.red.shade600; mIcon = Icons.sentiment_dissatisfied;
        } else {
          mText = "Stabil 😐"; mColor = Colors.blueGrey.shade600; mIcon = Icons.sentiment_neutral;
        }
  
        int curSos = 0;
        int pastSos = 0;
        try {
          final sosSnap = await FirebaseFirestore.instance.collection('sos_alerts').get();
          for (var doc in sosSnap.docs) {
            if (doc.data()['timestamp'] != null) {
              DateTime d = (doc.data()['timestamp'] as Timestamp).toDate();
              if (d.isAfter(startOfThisMonth) || d.isAtSameMomentAs(startOfThisMonth)) {
                curSos++;
              } else if ((d.isAfter(startOfLastMonth) || d.isAtSameMomentAs(startOfLastMonth)) && d.isBefore(startOfThisMonth)) {
                pastSos++;
              }
            }
          }
        } catch(e) { debugPrint("🚨 Ralat SOS: $e"); }
  
        var sosGrowth = calcGrowth(curSos, pastSos);
  
        String tCatName = "Tiada Data";
        int tCatHits = 0;
        try {
          Map<String, String> picToCategory = {};
  
          final globalDocs = await FirebaseFirestore.instance.collection('global_pictograms').get();
          for(var d in globalDocs.docs) {
            String category = d.data()['category'] ?? 'uncategorized';
            String? parent = d.data()['parent_folder'];
            String finalCat = (parent != null && parent.isNotEmpty) ? parent : category;
            picToCategory[d.data()['pic_id']] = "$finalCat (GLOBAL)";
          }
  
          final customDocs = await FirebaseFirestore.instance.collectionGroup('custom_pictograms').get();
          for(var d in customDocs.docs) {
            String? parent = d.data()['parent_folder'];
            String picId = d.data()['pic_id'] ?? d.id;
            String finalCat = (parent != null && parent.isNotEmpty) ? parent : "custom_upload";
            picToCategory[picId] = "$finalCat (CUSTOM)";
          }
  
          Map<String, String> localDictionary = {
            'water': 'food_drinks', 'hungry': 'food_drinks', 'apple': 'food_drinks',
            'pain': 'health', 'medicine': 'health', 'dizzy': 'health', 'breathe': 'health',
            'toilet': 'hygiene', 'shower': 'hygiene',
            'happy': 'feelings', 'sad': 'feelings', 'angry': 'feelings', 'tired': 'feelings',
            'pray': 'environment', 'family': 'environment', 'tv': 'environment', 'rest': 'environment',
            'yes': 'core_words', 'no': 'core_words', 'done': 'core_words',
            'hot': 'environment', 'cold': 'environment', 'noisy': 'environment'
          };
  
          Map<String, int> catFreq = {};
  
          int tempGlobal = 0;
          int tempCustom = 0;
          int tempLocal = 0;
  
          frequencyMap.forEach((picId, count) {
            String assignedCategory;
  
            if (picToCategory.containsKey(picId)) {
              assignedCategory = picToCategory[picId]!;
              if (assignedCategory.contains("(GLOBAL)")) tempGlobal += count;
              if (assignedCategory.contains("(CUSTOM)")) tempCustom += count;
            } else if (localDictionary.containsKey(picId)) {
              assignedCategory = "${localDictionary[picId]} (LOCAL)";
              tempLocal += count;
            } else {
              assignedCategory = 'LAIN-LAIN';
            }
  
            catFreq[assignedCategory] = (catFreq[assignedCategory] ?? 0) + count;
          });
  
          _globalPicHits = tempGlobal;
          _customPicHits = tempCustom;
          _localPicHits = tempLocal;
  
          catFreq.forEach((cat, count) {
            if(count > tCatHits) {
              tCatHits = count;
              tCatName = cat;
            }
          });
        } catch(e) { debugPrint("🚨 Ralat Category: $e"); }
  
        String calculatedPeakTime = "Tiada Data";
        try {
          Map<int, int> hourFreq = {};
          for (var doc in yearlyLogsSnap.docs) {
            if (doc.data()['timestamp'] != null) {
              DateTime logDate = (doc.data()['timestamp'] as Timestamp).toDate();
              if (logDate.isAfter(startOfThisMonth) || logDate.isAtSameMomentAs(startOfThisMonth)) {
                int hour = logDate.hour;
                hourFreq[hour] = (hourFreq[hour] ?? 0) + 1;
              }
            }
          }
  
          if (hourFreq.isNotEmpty) {
            var sortedHours = hourFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            int peakHour = sortedHours.first.key;
  
            int endHour = (peakHour + 2) % 24;
            String startAmPm = peakHour >= 12 ? 'PM' : 'AM';
            String endAmPm = endHour >= 12 ? 'PM' : 'AM';
            int displayStart = peakHour > 12 ? peakHour - 12 : (peakHour == 0 ? 12 : peakHour);
            int displayEnd = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
  
            calculatedPeakTime = "$displayStart$startAmPm - $displayEnd$endAmPm";
          }
  
          final ticketsSnap = await FirebaseFirestore.instance.collection('support_tickets').where('status', isEqualTo: 'PENDING').get();
          _pendingTicketsCount = ticketsSnap.docs.length;
  
        } catch(e) { debugPrint("🚨 Ralat Peak/Tickets: $e"); }
  
        if (mounted) {
          setState(() {
            _globalPhraseFrequency = frequencyMap;
            _totalSelections = totalHits;
            _totalActivePatients = actualCurPat;
            _totalActiveCaregivers = actualCurCg;
  
            _patientTrendText = pTrendText; _patientTrendColor = pTrendColor; _patientTrendBg = pTrendBg;
            _selectionsTrendText = sTrendText; _selectionsTrendColor = sTrendColor; _selectionsTrendBg = sTrendBg;
            _monthlyHits = tempMonthlyHits;
  
            _avgSessionText = sessionText; _sessionTrendText = sessionTText;
            _sessionTrendColor = sessionTColor; _sessionTrendBg = sessionTBg;
  
            _moodText = mText; _moodColor = mColor; _moodIcon = mIcon;
            _cgTrendText = cgTrendText; _cgTrendColor = cgTrendColor; _cgTrendBg = cgTrendBg;
  
            _totalSosThisMonth = curSos;
            _sosTrendText = sosGrowth['text']; _sosTrendColor = sosGrowth['color']; _sosTrendBg = sosGrowth['bg'];
            _topCategoryName = _formatToDisplay(tCatName);
            _topCategoryHits = tCatHits;
  
            _peakUsageTime = calculatedPeakTime;
  
            _isLoadingAnalytics = false;
          });
        }
      } catch (e) {
        debugPrint("🚨 Admin Error: Failed to fetch analytics -> $e");
        if(mounted) setState(() => _isLoadingAnalytics = false);
      }
    }
  
    Future<void> _scanGlobalFolders() async {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('global_pictograms').get();
        Set<String> fetchedMains = {};
        Map<String, Set<String>> tempSubCategories = {};
  
        for (var doc in snapshot.docs) {
          final data = doc.data();
  
          String rawCat = data['category'] ?? 'uncategorized';
          String rawParent = data['parent_folder'] ?? '';
  
          String cat = _formatToId(rawCat);
          String parent = _formatToId(rawParent);
  
          if (parent.isNotEmpty) {
            fetchedMains.add(parent);
            if (!tempSubCategories.containsKey(parent)) tempSubCategories[parent] = {};
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
      if (raw.isEmpty) return '';
      return raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    }
  
    String _formatToDisplay(String raw) => raw.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
  
    String get _destinationPath {
      String main = _isCreatingNewMain ? _formatToId(_newMainController.text) : _formatToId(_selectedMainCategory);
      String sub = _selectedSubCategory != 'none' ? (_isCreatingNewSub ? _formatToId(_newSubController.text) : _formatToId(_selectedSubCategory)) : '';
      if (main.isEmpty) main = 'uncategorized';
      return sub.isEmpty ? '/$main' : '/$main/$sub';
    }
  
    String get _currentActualCategory {
      String finalMain = _isCreatingNewMain ? _formatToId(_newMainController.text) : _formatToId(_selectedMainCategory);
      String? finalSub = (_selectedSubCategory != 'none') ? (_selectedSubCategory == 'ADD_NEW' ? _formatToId(_newSubController.text) : _formatToId(_selectedSubCategory)) : null;
      return finalSub ?? finalMain;
    }
  
    Future<void> _pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImage = pickedFile;
            _webImageBytes = bytes;
          });
        } else {
          setState(() => _selectedImage = pickedFile);
        }
      }
    }
  
    void _cancelEditMode() {
      setState(() {
        _isEditingMode = false;
        _editingDocId = null;
        _existingImageUrl = null;
        _selectedImage = null;
        _webImageBytes = null;
        _picIdController.clear();
        _labelEnController.clear();
        _labelMsController.clear();
      });
    }
  
    Future<void> _deletePictogram() async {
      if (_editingDocId == null) return;
  
      bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Pasti nak hapuskan?"),
            content: const Text("Gambar ni akan dipadam dari pangkalan data ekosistem secara kekal."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus Kekal", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
      ) ?? false;
  
      if (!confirm) return;
  
      try {
        setState(() => _isUploading = true);
        await FirebaseFirestore.instance.collection('global_pictograms').doc(_editingDocId).delete();
        await _logAdminActivity("Deleted pictogram: ${_picIdController.text}");
  
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Gambar selamat dihancurkan!'), backgroundColor: Colors.red));
          _cancelEditMode();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Ralat: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  
    Future<void> _uploadGlobalPictogram() async {
      if (!_formKey.currentState!.validate()) return;
  
      if (!_isEditingMode && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚨 Action Denied: Sila pilih gambar!'), backgroundColor: Colors.red));
        return;
      }
  
      setState(() => _isUploading = true);
  
      try {
        String picId = _formatToId(_picIdController.text);
        String labelEn = _labelEnController.text.trim();
        String labelMs = _labelMsController.text.trim();
        String actualCategory = _currentActualCategory;
        String finalMain = _isCreatingNewMain ? _formatToId(_newMainController.text) : _formatToId(_selectedMainCategory);
  
        String? finalDownloadUrl = _existingImageUrl;
  
        if (_selectedImage != null) {
          Reference storageRef = FirebaseStorage.instance.ref().child('global_pictograms/$actualCategory/$picId.png');
          UploadTask uploadTask = kIsWeb ? storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg')) : storageRef.putFile(File(_selectedImage!.path));
          TaskSnapshot snapshot = await uploadTask;
          finalDownloadUrl = await snapshot.ref.getDownloadURL();
        }
  
        Map<String, dynamic> payload = {
          'pic_id': picId,
          'label_en': labelEn,
          'label_ms': labelMs,
          'category': actualCategory,
          'parent_folder': (_selectedSubCategory != 'none' && _selectedSubCategory != 'ADD_NEW') ? finalMain : null,
          'image_url': finalDownloadUrl,
          'uploaded_by': 'SUPERADMIN',
        };
  
        if (_isEditingMode) {
          await FirebaseFirestore.instance.collection('global_pictograms').doc(_editingDocId).update(payload);
          await _logAdminActivity("Updated pictogram: $labelEn in $actualCategory");
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Data Berjaya Di-Update!'), backgroundColor: Colors.blue));
        } else {
          payload['timestamp'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('global_pictograms').add(payload);
          await _logAdminActivity("Deployed new pictogram: $labelEn to $actualCategory");
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Berjaya Deploy ke Ekosistem!'), backgroundColor: Colors.green));
        }
  
        if (mounted) {
          _cancelEditMode();
          _scanGlobalFolders();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Litar Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  
    // 🚀 LITAR DEWA: KELUARKAN MENU TEPI SUPAYA BOLEH JADI DRAWER
    Widget _buildSideMenu() {
      return Container(
        width: 250,
        color: const Color(0xFF1E1B4B),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF1E1B4B), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PictoSpeak", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Command Center", style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildNavItem(0, Icons.bar_chart_rounded, "Analytics", "Usage insights"),
            _buildNavItem(1, Icons.cloud_upload_rounded, "CMS Deployment", "Publish pictograms"),
            _buildNavItem(2, Icons.support_agent_rounded, "Support Tickets", "User feedback"),
            _buildNavItem(3, Icons.settings_input_component, "System Config", "Kill switches"),
            _buildNavItem(4, Icons.photo_library_rounded, "Picto Explorer", "View all local & custom"),
  
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            // Cari bahagian ListTile kat bawah sekali dalam _buildSideMenu()
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: InkWell( // 🚀 KITA BUNGKUS DENGAN INKWELL
                onTap: _handleSecretKnock, // 🚀 PANGGIL LITAR KETUK RAHSIA
                child: const CircleAvatar(backgroundColor: Colors.indigo, child: Text("AZ", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              title: const Text("Admin Root", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Super User", style: TextStyle(color: Colors.indigoAccent, fontSize: 12)),
            ),
          ],
        ),
      );
    }
  
    void _handleSecretKnock() {
      setState(() {
        _secretClickCount++;
      });
  
      if (_secretClickCount == 7) {
        setState(() {
          _showSecretButton = true;
          _secretClickCount = 0; // Reset balik
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("🚀 J.A.R.V.I.S: Protocol Rahsia Dibuka! Simulation Tool Diaktifkan."),
          backgroundColor: Colors.purple,
        ));
      } else if (_secretClickCount > 0) {
        debugPrint("Admin mengetuk... (${_secretClickCount}/7)");
      }
    }
  
    @override
    Widget build(BuildContext context) {
      // 🚀 LITAR DEWA: CHECK SAIZ SKRIN
      bool isDesktop = MediaQuery.of(context).size.width >= 900;
      var sortedEntries = _globalPhraseFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  
      Widget mainContent = Column(
        children: [
          // HEADER ATAS (Tajuk + Search + Noti)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getPageTitle(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(_getPageSubtitle(), style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                        child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.trim().toLowerCase();
                              });
                            },
                            decoration: const InputDecoration(
                                icon: Icon(Icons.search, color: Colors.grey, size: 20),
                                border: InputBorder.none,
                                hintText: "Search here...",
                                hintStyle: TextStyle(fontSize: 14)
                            )
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
  
                    StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('support_tickets').where('status', isEqualTo: 'PENDING').snapshots(),
                        builder: (context, snapshot) {
                          int pendingCount = snapshot.data?.docs.length ?? 0;
  
                          return Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300)
                            ),
                            child: Badge(
                              isLabelVisible: pendingCount > 0,
                              label: Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              backgroundColor: Colors.red.shade600,
                              alignment: const Alignment(0.6, -0.6),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 22),
                                onPressed: () {
                                  if (pendingCount > 0) {
                                    setState(() {
                                      _selectedIndex = 2;
                                      _searchQuery = "";
                                      _searchController.clear();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("All clear! Tiada tiket yang tertunggak."), backgroundColor: Colors.green),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
  
          Expanded(
            child: _buildCurrentScreen(sortedEntries),
          ),
        ],
      );
  
      // 🚀 LITAR DEWA: KEMBALIKAN SCAFFOLD YANG RESPONSIVE!
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        // BILA SKRIN KECIK, KELUAR APPBAR DENGAN HAMBURGER MENU
        appBar: isDesktop
            ? null
            : AppBar(
          backgroundColor: const Color(0xFF1E1B4B),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("PictoSpeak Admin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        // LACI TERSEMBUNYI UNTUK SKRIN KECIK
        drawer: isDesktop ? null : Drawer(child: _buildSideMenu()),
        body: isDesktop
            ? Row(
          children: [
            _buildSideMenu(),
            Expanded(child: mainContent),
          ],
        )
            : mainContent,
      );
    }

    // 4. GANTI FUNGSI _buildExplorerTab kau dengan ni (Dah fix error undefined)
    Widget _buildExplorerTab() {
      return FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance.collection('global_pictograms').get(), // Tarik Global
          FirebaseFirestore.instance.collectionGroup('custom_pictograms').get(), // Tarik Custom
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var globalDocs = snapshot.data![0].docs;
          var customDocs = snapshot.data![1].docs;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildUsageTable(),
              const Divider(height: 40),

              // 1. GLOBAL PICTOGRAMS (Dari Admin)
              const Text("Global System Pictograms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPictogramGrid(globalDocs, Colors.indigo),

              const Divider(height: 40),

              // 2. CUSTOM PICTOGRAMS (Dari User)
              const Text("User Custom Pictograms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPictogramGrid(customDocs, Colors.orange),

              const Divider(height: 40),

              // 3. LOCAL STATIC PICTOGRAMS
              const Text("Local System Pictograms (Hardcoded)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 0.8),
                itemCount: _staticData.length,
                itemBuilder: (ctx, i) {
                  var item = _staticData[i];
                  int hits = _globalPhraseFrequency[item['id']] ?? 0;
                  return Card(child: Column(children: [
                    Expanded(child: Image.asset(item['image'], errorBuilder: (c,e,s)=>const Icon(Icons.broken_image))),
                    Text(item['en'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Hits: $hits", style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                  ]));
                },
              ),
            ],
          );
        },
      );
    }

// 🚀 HELPER UNTUK KEMASKAN GRID (Biar kod tak panjang berjela)
    Widget _buildPictogramGrid(List<QueryDocumentSnapshot> docs, Color color) {
      return GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 0.8),
        itemCount: docs.length,
        itemBuilder: (ctx, i) {
          var data = docs[i].data() as Map<String, dynamic>;
          int hits = _globalPhraseFrequency[data['pic_id']] ?? 0;
          return Card(
              child: Column(children: [
                Expanded(child: Image.network(data['image_url'] ?? '', errorBuilder: (c,e,s)=>const Icon(Icons.broken_image))),
                Text(data['label_en'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Hits: $hits", style: TextStyle(fontSize: 10, color: color)),
              ])
          );
        },
      );
    }
  
  // 🚀 TABLE UNTUK ADMIN TENGOK PIC YANG KEKERAPAN TINGGI
    Widget _buildUsageTable() {
      var sorted = _globalPhraseFrequency.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      return DataTable(
        columns: const [
          DataColumn(label: Text('Pictogram ID')),
          DataColumn(label: Text('Hits')),
          DataColumn(label: Text('Status')),
        ],
        rows: sorted.take(10).map((entry) {
          bool isCustom = _mergedData.any((m) => m['id'] == entry.key && m['source'] == 'custom');
          return DataRow(cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(entry.value.toString())),
            DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isCustom ? Colors.orange.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text(isCustom ? "CUSTOM" : "LOCAL/GLOBAL")
            )),
          ]);
        }).toList(),
      );
    }
  
    Widget _buildNavItem(int index, IconData icon, String title, String subtitle) {
      bool isSelected = _selectedIndex == index;
      return InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _searchQuery = "";
            _searchController.clear();
          });
          // Tutup laci kalau kat mobile
          if (MediaQuery.of(context).size.width < 900) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF1E1B4B) : Colors.indigo.shade200, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? const Color(0xFF1E1B4B) : Colors.indigo.shade50, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: isSelected ? Colors.indigo.shade400 : Colors.indigo.shade400, fontSize: 11)),
                ],
              )
            ],
          ),
        ),
      );
    }
  
    String _getPageTitle() {
      switch (_selectedIndex) {
        case 0: return "Analytics";
        case 1: return "CMS Deployment";
        case 2: return "Support Tickets";
        case 3: return "System Configuration";
        case 4: return "Pictogram Explorer";
        default: return "";
      }
    }
  
    String _getPageSubtitle() {
      switch (_selectedIndex) {
        case 0: return "Real-time usage across the ecosystem";
        case 1: return "Upload and route new pictograms";
        case 2: return "Manage user feedback and bug reports";
        case 3: return "Control critical platform settings";
        case 4: return "View all local, custom, and global pictograms";
        default: return "";
      }
    }
  
    Widget _buildCurrentScreen(List<MapEntry<String, int>> sortedEntries) {
      switch (_selectedIndex) {
        case 0: return _buildAnalyticsTab(sortedEntries);
        case 1: return _buildCmsTab();
        case 2: return _buildTicketsTab();
        case 3: return _buildConfigTab();
        case 4: return _buildExplorerTab();
        default: return Container();
      }
    }
  
    Widget _buildAnalyticsTab(List<MapEntry<String, int>> sortedEntries) {
      if (_isLoadingAnalytics) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
  
      final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  
      List<MapEntry<String, int>> displayEntries = sortedEntries;
      if (_searchQuery.isNotEmpty) {
        displayEntries = sortedEntries.where((entry) => _formatToDisplay(entry.key).toLowerCase().contains(_searchQuery)).toList();
      }
  
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🚀 LITAR RESPONSIVE: Guna Wrap untuk header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text("Analytics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _exportAnalyticsToCSV,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("Export CSV"),
              ),
            ],
          ),
          const SizedBox(height: 30),
  
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.show_chart, color: Colors.amberAccent, size: 24)),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Global Usage Trends", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("Selections across all devices", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(_selectionsTrendText, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 40),
  
                SizedBox(
                  height: 150,
                  child: Builder(
                      builder: (context) {
                        int maxHits = _monthlyHits.reduce((a, b) => a > b ? a : b);
                        if (maxHits == 0) maxHits = 1;
  
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(12, (index) {
                            int hits = _monthlyHits[index];
                            double barHeight = (hits / maxHits) * 100.0 + 5.0;
  
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message: "$hits selections",
                                    child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        constraints: const BoxConstraints(maxWidth: 35),
                                        height: barHeight,
                                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4))
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(months[index], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)
                                ],
                              ),
                            );
                          }),
                        );
                      }
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
  
          // 🚀 LITAR RESPONSIVE DEWA (LayoutBuilder & Wrap)
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth >= 1000 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
              double spacing = 20;
              double itemWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
  
              double sentimentWidth = columns == 3 ? (itemWidth * 2) + spacing : itemWidth;
  
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(width: itemWidth, child: _buildStatCard("Active Patients", _totalActivePatients.toString(), Icons.people_outline, Colors.indigo.shade400, _patientTrendText, _patientTrendColor, _patientTrendBg)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Total Selections", _totalSelections.toString(), Icons.touch_app_rounded, Colors.indigo.shade400, _selectionsTrendText, _selectionsTrendColor, _selectionsTrendBg)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Avg. Session", _avgSessionText, Icons.timer_outlined, Colors.indigo.shade400, _sessionTrendText, _sessionTrendColor, _sessionTrendBg)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Active Caregivers", _totalActiveCaregivers.toString(), Icons.health_and_safety_outlined, Colors.orange.shade500, _cgTrendText, _cgTrendColor, _cgTrendBg)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Total SOS Alerts", _totalSosThisMonth.toString(), Icons.emergency_share_rounded, Colors.red.shade400, _sosTrendText, _sosTrendColor, _sosTrendBg)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Top Category", _topCategoryName, Icons.folder_special_rounded, Colors.purple.shade400, "$_topCategoryHits Hits", Colors.purple.shade700, Colors.purple.shade50)),
  
                  SizedBox(
                    width: sentimentWidth,
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _moodColor.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(_moodIcon, color: _moodColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Patient Sentiment (30 Days)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_moodText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _moodColor), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: itemWidth, child: _buildStatCard("Peak Usage Hours", _peakUsageTime, Icons.access_time_filled_rounded, Colors.teal.shade500, "Server Load", Colors.teal.shade700, Colors.teal.shade50)),
                  SizedBox(width: itemWidth, child: _buildStatCard("Pending Tickets", _pendingTicketsCount.toString(), Icons.support_agent_rounded, _pendingTicketsCount > 0 ? Colors.red.shade500 : Colors.green.shade500, _pendingTicketsCount > 0 ? "Action Required" : "All Clear", _pendingTicketsCount > 0 ? Colors.red.shade700 : Colors.green.shade700, _pendingTicketsCount > 0 ? Colors.red.shade50 : Colors.green.shade50)),
                ],
              );
            },
          ),
  
          const SizedBox(height: 24),
  
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Usage Distribution", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Icon(Icons.pie_chart_outline_rounded, color: Colors.indigo.shade300),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                    builder: (context) {
                      int total = _globalPicHits + _customPicHits + _localPicHits;
                      if (total == 0) return const Text("No usage data available.", style: TextStyle(color: Colors.grey));
  
                      double globalPct = (_globalPicHits / total) * 100;
                      double customPct = (_customPicHits / total) * 100;
                      double localPct = (_localPicHits / total) * 100;
  
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                if (localPct > 0) Expanded(flex: localPct.toInt(), child: Container(height: 16, color: Colors.blue.shade400)),
                                if (globalPct > 0) Expanded(flex: globalPct.toInt(), child: Container(height: 16, color: Colors.indigo.shade600)),
                                if (customPct > 0) Expanded(flex: customPct.toInt(), child: Container(height: 16, color: Colors.purple.shade400)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              _buildDistributionLabel("Local App", localPct, Colors.blue.shade400),
                              _buildDistributionLabel("Global CMS", globalPct, Colors.indigo.shade600),
                              _buildDistributionLabel("User Custom", customPct, Colors.purple.shade400),
                            ],
                          )
                        ],
                      );
                    }
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
  
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Top Performing Pictograms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text("Most selected symbols", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                    const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 24),
                  ],
                ),
                const SizedBox(height: 20),
  
                if (displayEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("No pictograms found for this search.", style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...List.generate(displayEntries.length > 5 ? 5 : displayEntries.length, (index) {
                    var entry = displayEntries[index];
                    Color rankColor = index == 0 ? Colors.amber : Colors.grey.shade100;
                    Color rankTextColor = index == 0 ? Colors.white : Colors.blueGrey.shade600;
  
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: rankColor, radius: 18, child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: rankTextColor, fontSize: 14))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatToDisplay(entry.key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text("Ecosystem Data", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ],
                              )
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(16)),
                              child: Text('${entry.value} Hits', style: const TextStyle(color: Color(0xFF0D652D), fontWeight: FontWeight.bold, fontSize: 12))
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          )
        ],
      );
    }
  
    Widget _buildDistributionLabel(String title, double percentage, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text("$title (${percentage.toStringAsFixed(1)}%)", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      );
    }
  
    Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, String badgeText, Color badgeTextColor, Color badgeBgColor) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
  
    Widget _buildCmsTab() {
      List<String> dynamicSubFolders = ['none'];
      String currentMainKey = _formatToId(_selectedMainCategory);
  
      if (!_isCreatingNewMain && _subCategories.containsKey(currentMainKey)) {
        dynamicSubFolders.addAll(_subCategories[currentMainKey]!.toList());
      }
      dynamicSubFolders.add('ADD_NEW');
  
      Widget leftPanel = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isEditingMode ? Colors.amber.shade300 : Colors.grey.shade200, width: _isEditingMode ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.add_photo_alternate_outlined, color: Colors.indigo.shade600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEditingMode ? "Modify Pictogram" : "New Pictogram Upload", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      Text("Edit details or change image", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160, width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade200, width: 1.5, style: BorderStyle.solid)
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.memory(_webImageBytes!, fit: BoxFit.contain) : Image.file(File(_selectedImage!.path), fit: BoxFit.contain))
                    : _isEditingMode && _existingImageUrl != null
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                    ),
                    Container(color: Colors.black45, child: const Center(child: Text("Tap to change image", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  ],
                )
                    : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blueGrey.shade400),
                      const SizedBox(height: 12),
                      const Text("Drag & drop image here", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text("PNG, SVG or WebP - up to 2MB", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ]
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildLabeledTextField("Unique ID", "#  pic_apple_001", _picIdController),
            const SizedBox(height: 20),
            _buildLabeledTextField("Label (English)", "Apple", _labelEnController),
            const SizedBox(height: 20),
            _buildLabeledTextField("Label (Malay)", "Epal", _labelMsController, icon: Icons.translate),
          ],
        ),
      );
  
      Widget rightPanel = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.account_tree_outlined, color: Colors.orange.shade600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Directory Routing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      Text("Choose where this symbol lives", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),
  
            _buildLabeledDropdown("Target Main Folder", _selectedMainCategory, [..._mainCategories, 'ADD_NEW'], (v) {
              setState(() {
                _selectedMainCategory = v!;
                _isCreatingNewMain = (v == 'ADD_NEW');
                _selectedSubCategory = 'none';
                _isCreatingNewSub = false;
              });
            }),
  
            if (_isCreatingNewMain) ...[
              const SizedBox(height: 16),
              _buildLabeledTextField("New Main Folder Name", "e.g. Core Words", _newMainController)
            ],
            const SizedBox(height: 20),
  
            _buildLabeledDropdown("Target Sub-Folder", _selectedSubCategory, dynamicSubFolders, (v) {
              setState(() {
                _selectedSubCategory = v!;
                _isCreatingNewSub = (v == 'ADD_NEW');
              });
            }),
  
            if (_isCreatingNewSub) ...[
              const SizedBox(height: 16),
              _buildLabeledTextField("New Sub Folder Name", "e.g. Verbs", _newSubController)
            ],
            const SizedBox(height: 30),
  
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DESTINATION PATH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade300, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(_destinationPath, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
  
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
  
            Row(
              children: [
                Icon(Icons.photo_library_rounded, color: Colors.indigo.shade400, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text("Folder Content", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              ],
            ),
            const SizedBox(height: 16),
  
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('global_pictograms').where('category', isEqualTo: _currentActualCategory).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Container(padding: const EdgeInsets.all(20), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: Text("No pictograms in this folder.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)));
  
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isSelected = _editingDocId == doc.id;
  
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _isEditingMode = true;
                          _editingDocId = doc.id;
                          _picIdController.text = data['pic_id'] ?? '';
                          _labelEnController.text = data['label_en'] ?? '';
                          _labelMsController.text = data['label_ms'] ?? '';
                          _existingImageUrl = data['image_url'];
                          _selectedImage = null;
                          _webImageBytes = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? Colors.amber.shade500 : Colors.grey.shade300, width: isSelected ? 3 : 1),
                            boxShadow: [if (isSelected) BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8)]
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: data['image_url'] != null && data['image_url'].toString().isNotEmpty
                                    ? Image.network(
                                  data['image_url'],
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: Colors.grey.shade300, size: 30),
                                )
                                    : Icon(Icons.image_not_supported, color: Colors.grey.shade300, size: 30),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              decoration: BoxDecoration(color: isSelected ? Colors.amber.shade50 : Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(9), bottomRight: Radius.circular(9))),
                              child: Text(data['label_en'] ?? 'Unknown', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isSelected ? Colors.amber.shade900 : Colors.black87)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      );
  
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isEditingMode)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade400)),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(child: Text("EDITING MODE ACTIVE", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, letterSpacing: 1))),
                ],
              ),
            ),
  
          Form(
            key: _formKey,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 900;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: leftPanel),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: rightPanel),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftPanel,
                          const SizedBox(height: 20),
                          rightPanel,
                        ],
                      );
                    }
                  },
                ),
  
                const SizedBox(height: 30),
  
                // 🚀 LITAR RESPONSIVE: Butang Edit/Publish
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (_isEditingMode) ...[
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _deletePictogram,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.delete_forever, color: Colors.white),
                          label: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _cancelEditMode,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade100, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.close, color: Colors.black54),
                          label: const Text('CANCEL', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadGlobalPictogram,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditingMode ? Colors.blue.shade700 : const Color(0xFF2E236C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2
                        ),
                        icon: _isUploading ? const CircularProgressIndicator(color: Colors.white) : Icon(_isEditingMode ? Icons.save_alt : Icons.rocket_launch, color: Colors.amber),
                        label: Text(_isUploading ? 'Processing...' : (_isEditingMode ? 'UPDATE PICTOGRAM' : 'PUBLISH TO ECOSYSTEM'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  
    Widget _buildLabeledTextField(String label, String hint, TextEditingController controller, {IconData? icon}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 18) : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ],
      );
    }
  
    Widget _buildLabeledDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true, // 🚀 Halang teks panjang rosakkan dropdown
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            items: items.map((cat) => DropdownMenuItem(value: cat, child: Text(cat == 'ADD_NEW' ? '➕ Create New' : _formatToDisplay(cat), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onChanged,
          ),
        ],
      );
    }
  
    Widget _buildTicketsTab() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E236C)));
  
          var docs = snapshot.data!.docs;
  
          if (_searchQuery.isNotEmpty) {
            docs = docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String email = (data['user_email'] ?? '').toString().toLowerCase();
              String msg = (data['message'] ?? '').toString().toLowerCase();
              return email.contains(_searchQuery) || msg.contains(_searchQuery);
            }).toList();
          }
  
          int pendingCount = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] != 'RESOLVED').length;
  
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.support_agent_rounded, color: Colors.indigo.shade600, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Support Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text("User feedback & bug reports", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text("$pendingCount Pending", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
  
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text("No tickets found matching your search.", style: TextStyle(color: Colors.grey))),
                )
              else
                ...docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool isResolved = data['status'] == 'RESOLVED';
                  String timeAgo = _getTimeAgo(data['timestamp'] as Timestamp?);
  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: isResolved ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isResolved ? const Color(0xFFBBF7D0) : Colors.grey.shade200, width: 1.5),
                        boxShadow: [if (!isResolved) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: isResolved ? Colors.green.shade100 : Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isResolved ? Colors.green.shade300 : Colors.transparent)
                              ),
                              child: Icon(
                                  isResolved ? Icons.check_circle_outline : Icons.access_time_rounded,
                                  color: isResolved ? Colors.green.shade700 : Colors.orange.shade600,
                                  size: 24
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.5 : double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  Text(data['user_email'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                  const SizedBox(width: 8),
                                  Text("•", style: TextStyle(color: Colors.grey.shade400)),
                                  const SizedBox(width: 8),
                                  Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
  
                                  if (isResolved) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF166534), borderRadius: BorderRadius.circular(12)),
                                      child: const Text("RESOLVED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                                    ),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(data['message'] ?? '', style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4)),
                            ],
                          ),
                        ),
                        if (!isResolved) ...[
                          ElevatedButton(
                              onPressed: () => doc.reference.update({'status': 'RESOLVED'}),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E236C),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                              ),
                              child: const Text("Resolve", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                          ),
                        ]
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      );
    }
  
    Widget _buildConfigTab() {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E236C)));
  
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
  
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.monitor_heart_rounded, color: Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("System Status", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Latency: ${Random().nextInt(50) + 10}ms | Status: ONLINE", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.power_settings_new_rounded, color: Colors.red.shade400, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Kill Switches", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text("Critical system overrides", style: TextStyle(fontSize: 13, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: const Text("Maintenance Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                            subtitle: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                                const SizedBox(width: 4),
                                Text("Blocks patient access during updates.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.gpp_maybe_rounded, color: Colors.grey.shade500, size: 20)
                            ),
                            activeColor: const Color(0xFF2E236C),
                            value: data['maintenance_mode'] ?? false,
                            onChanged: (v) => FirebaseFirestore.instance.collection('system_configs').doc('general').set({'maintenance_mode': v}, SetOptions(merge: true)),
                          ),
                          const Divider(height: 1, color: Colors.black12),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: const Text("Allow New Sign-ups", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                            subtitle: Text("Permit new clinics to register accounts.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            activeColor: const Color(0xFF4F46E5),
                            value: data['allow_signups'] ?? true,
                            onChanged: (v) => FirebaseFirestore.instance.collection('system_configs').doc('general').set({'allow_signups': v}, SetOptions(merge: true)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
  
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.campaign_outlined, color: Colors.orange.shade500, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Global Announcement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                                  Text("Banner shown to all users", style: TextStyle(fontSize: 13, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            TextEditingController announceCtrl = TextEditingController(text: data['announcement_text'] ?? '');
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.edit_notifications, color: Color(0xFF2E236C)),
                                      SizedBox(width: 10),
                                      Text("Edit Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  content: TextField(
                                    controller: announceCtrl,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                        hintText: "Enter your system announcement here...",
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2))
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        FirebaseFirestore.instance.collection('system_configs').doc('general').set({
                                          'announcement_text': announceCtrl.text.trim()
                                        }, SetOptions(merge: true));
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E236C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                )
                            );
                          },
                          icon: const Icon(Icons.edit, size: 14, color: Color(0xFF1E293B)),
                          label: const Text("Edit", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: Colors.grey.shade300)
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300)
                      ),
                      child: Text(
                          (data['announcement_text'] != null && data['announcement_text'].toString().trim().isNotEmpty)
                              ? data['announcement_text']
                              : "No active announcements. Click Edit to add one.",
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500)
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
  
              // Dalam _buildConfigTab()
              if (_showSecretButton) ...[ // 🚀 BUTANG NI HANYA WUJUD BILA DAH KETUK 7 KALI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.science_rounded, color: Colors.purple.shade600, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Environment Simulation Tools", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                Text("Generate artificial ecosystem metrics for testing", style: TextStyle(fontSize: 13, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Butang di bawah akan menyuntik rekod log komunikasi rawak sepanjang 90 hari lepas ke dalam pangkalan data. Litar ini akan memetakan corak penggunaan mengikut profil pesakit sedia ada bagi menguji keupayaan carta trend Admin.",
                        style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _generateSimulationData(),
                          icon: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 22),
                          label: const Text("GENERATE ECOSYSTEM DATA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      );
    }
  }