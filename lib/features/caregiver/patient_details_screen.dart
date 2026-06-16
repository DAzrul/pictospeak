import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 🚀 TAMBAH INI UNTUK FORMAT MASA
import '../../core/theme/app_theme.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({super.key, required this.patientData});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _currentData;

  bool _isUploadingPic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentData = Map.from(widget.patientData);
  }

  Future<void> _uploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() => _isUploadingPic = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        File imageFile = File(pickedFile.path);

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('patient_profiles/${user!.uid}/${_currentData['patient_id']}.jpg');

        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(user.uid)
            .collection('patients')
            .doc(_currentData['patient_id'])
            .update({'profile_url': downloadUrl});

        setState(() {
          _currentData['profile_url'] = downloadUrl;
          _isUploadingPic = false;
        });

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Profile Picture Success"), backgroundColor: Colors.green));
        }
      } catch (e) {
        setState(() => _isUploadingPic = false);
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _currentData['name']);
    final ageCtrl = TextEditingController(text: _currentData['age'].toString());
    final conditionCtrl = TextEditingController(text: _currentData['condition']);
    final pinCtrl = TextEditingController(text: _currentData['pin_code']);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit Patient Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                  TextField(controller: conditionCtrl, decoration: const InputDecoration(labelText: 'Condition')),
                  TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN Code (4 Digit)'), maxLength: 4, keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('caregivers')
                      .doc(user!.uid)
                      .collection('patients')
                      .doc(_currentData['patient_id'])
                      .update({
                    'name': nameCtrl.text,
                    'age': ageCtrl.text,
                    'condition': conditionCtrl.text,
                    'pin_code': pinCtrl.text,
                  });

                  setState(() {
                    _currentData['name'] = nameCtrl.text;
                    _currentData['age'] = ageCtrl.text;
                    _currentData['condition'] = conditionCtrl.text;
                    _currentData['pin_code'] = pinCtrl.text;
                  });

                  Navigator.pop(context);
                  if(mounted){
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Data Success"), backgroundColor: Colors.blue));
                  }
                },
                child: const Text("SAVE"),
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(_currentData['name'] ?? 'Patient Details', style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.person_outline)),
            Tab(text: 'Insights', icon: Icon(Icons.auto_graph_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInsightsTab(), // 🚀 Tab Analitik Pintar
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _currentData['profile_url'] != null ? NetworkImage(_currentData['profile_url']) : null,
                child: _currentData['profile_url'] == null
                    ? const Icon(Icons.person_rounded, size: 60, color: Colors.white)
                    : null,
              ),
              if (_isUploadingPic) const Positioned.fill(child: CircularProgressIndicator()),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadProfilePic,
                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildInfoCard("Condition", _currentData['condition'] ?? 'No data', Icons.medical_services_outlined),
        _buildInfoCard("Age", "${_currentData['age']} Years Old", Icons.cake_outlined),
        _buildInfoCard("Relationship", _currentData['relationship'], Icons.family_restroom),
        _buildInfoCard("Access PIN", _currentData['pin_code'], Icons.lock_outline),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showEditDialog,
          icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue),
          label: const Text("EDIT PATIENT DETAILS", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        )
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ],
      ),
    );
  }

  // =========================================================
  // 🧠 J.A.R.V.I.S: TAB INSIGHTS (VERSI SEDUT DATA REAL-TIME)
  // =========================================================
  Widget _buildInsightsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("User not logged in"));

    // 🚀 Stream paip terus ke Firebase
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('caregivers')
          .doc(user.uid)
          .collection('patients')
          .doc(_currentData['patient_id'])
          .collection('communication_logs')
          .orderBy('timestamp', descending: true) // Susun log terbaharu kat atas
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];

        // --- 1. LITAR KIRA STATISTIK (ENJIN DATA) ---
        int totalSentencesToday = 0;
        int positiveMood = 0;
        int negativeMood = 0;
        Map<String, int> keywordCounts = {};

        DateTime today = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          if (timestamp != null && timestamp.day == today.day && timestamp.month == today.month && timestamp.year == today.year) {
            totalSentencesToday++;
          }

          String mood = data['mood'] ?? 'Neutral';
          if (mood == 'Positive') positiveMood++;
          if (mood == 'Negative') negativeMood++;

          // Kira perkataan paling kerap ditekan
          List<dynamic> items = data['items'] ?? [];
          for (var item in items) {
            String wordId = item.toString();
            keywordCounts[wordId] = (keywordCounts[wordId] ?? 0) + 1;
          }
        }

        // Tentukan dominasi mood
        String overallMood = "Neutral";
        Color moodColor = Colors.grey;
        IconData moodIcon = Icons.sentiment_neutral_rounded;

        if (positiveMood > negativeMood) {
          overallMood = "Positive"; moodColor = Colors.green; moodIcon = Icons.sentiment_very_satisfied_rounded;
        } else if (negativeMood > positiveMood) {
          overallMood = "Distressed"; moodColor = Colors.red; moodIcon = Icons.sentiment_very_dissatisfied_rounded;
        }

        // Cari Top 4 Keperluan Pesakit (Untuk Graf Bar)
        var sortedKeys = keywordCounts.keys.toList()..sort((a, b) => keywordCounts[b]!.compareTo(keywordCounts[a]!));
        List<String> top4Items = sortedKeys.take(4).toList();
        List<int> top4Values = top4Items.map((k) => keywordCounts[k]!).toList();

        // Cari max Y untuk graf (supaya tak cacat kalau data naik sampai 50 kali)
        double maxYGraph = top4Values.isNotEmpty ? top4Values.reduce((a, b) => a > b ? a : b).toDouble() : 10;
        if (maxYGraph < 10) maxYGraph = 10; // Kekalkan saiz graf standard 10 kalau data sikit

        // --- 2. LUKIS UI ---
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. KAD SUMMARY
              Row(
                children: [
                  _buildSummaryCard(totalSentencesToday.toString(), "Sentences Today", Icons.chat_bubble_outline_rounded, Colors.blue),
                  const SizedBox(width: 16),
                  _buildSummaryCard(overallMood, "Mood Trend", moodIcon, moodColor),
                ],
              ),
              const SizedBox(height: 16),

              // 2. KAD GRAF BAR (DINAMIK)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insert_chart_outlined, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Most Frequent Needs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 200,
                      child: top4Items.isEmpty
                          ? const Center(child: Text("Tiada data cukup untuk graf", style: TextStyle(color: Colors.grey)))
                          : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxYGraph + 2, // Tambah ruang bernafas sikit kat atas
                          barGroups: List.generate(top4Items.length, (index) {
                            return _makeDynamicBarGroup(index, top4Values[index].toDouble());
                          }),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= top4Items.length) return const Text('');
                                  String titleRaw = top4Items[value.toInt()];
                                  // Capitalize huruf pertama
                                  String titleFormat = "${titleRaw[0].toUpperCase()}${titleRaw.substring(1).toLowerCase()}";
                                  return Text(titleFormat, style: const TextStyle(color: Colors.grey, fontSize: 10));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  // Tunjuk gandaan ikut skala Y axis (kalau bawah 20 tunjuk semua, kalau tinggi sangat tunjuk gandaan)
                                  if (value % (maxYGraph > 20 ? 5 : 2) == 0) {
                                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. KAD COMMUNICATION LOG (SENARAI SEBENAR)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Communication Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (docs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text("Tiada log dikesan.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      )
                    else
                    // 🚀 Litar gelung untuk susun log sejarah pesakit
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Scroll ikut parent luar
                        itemCount: docs.length > 5 ? 5 : docs.length, // Tunjuk max 5 log terkini je
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final sentence = data['sentence'] ?? '';
                          final moodStr = data['mood'] ?? 'Neutral';

                          // Format Masa (Cth: 12:45 PM)
                          String timeText = "Just now";
                          Timestamp? ts = data['timestamp'] as Timestamp?;
                          if (ts != null) {
                            timeText = DateFormat('h:mm a, d MMM').format(ts.toDate());
                          }

                          Color tagColor = Colors.grey;
                          if (moodStr == 'Positive') tagColor = Colors.green;
                          if (moodStr == 'Negative') tagColor = Colors.red;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon penanda masa
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                  child: const Icon(Icons.record_voice_over, size: 14, color: AppTheme.primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('"$sentence"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                      const SizedBox(height: 4),
                                      Text(timeText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                // Tag mood kecik
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(moodStr, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String value, String title, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // Litar graf untuk lukis bar berdasaarkan data sebenar
  BarChartGroupData _makeDynamicBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: AppTheme.primaryBlue, width: 16, borderRadius: BorderRadius.circular(4))],
    );
  }
}