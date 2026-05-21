import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 🚀 LITAR TUKAR GAMBAR PROFIL
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

        // 🚨 Standard Text (No swearing)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Update Profile Picture Success"), backgroundColor: Colors.green)
        );
      } catch (e) {
        setState(() => _isUploadingPic = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // 🚀 POP-UP EDIT DATA
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
                  // 🚨 Standard Text
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Update Data Success"), backgroundColor: Colors.blue)
                  );
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
      backgroundColor: const Color(0xFFF1F5F9), // Warna background sejuk macam dlm design
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
          _buildInsightsTab(), // 🚀 Litar UI baru
        ],
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
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
              if (_isUploadingPic)
                const Positioned.fill(child: CircularProgressIndicator()),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadProfilePic,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
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
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: INSIGHTS (IKUT DESIGN GAMBAR) ---
  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. KAD SUMMARY (ATAS)
          Row(
            children: [
              _buildSummaryCard("0", "Sentences Today", Icons.chat_bubble_outline_rounded, Colors.blue),
              const SizedBox(width: 16),
              _buildSummaryCard("Neutral", "Mood Trend", Icons.sentiment_neutral_rounded, Colors.green),
            ],
          ),
          const SizedBox(height: 16),

          // 2. KAD GRAF BAR (TENGAH)
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

                // GRAF BAR KOSONG (Ikut gambar)
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10, // Maksimum Y-Axis
                      barGroups: [
                        _makeEmptyBarGroup(0), // Water
                        _makeEmptyBarGroup(1), // Food
                        _makeEmptyBarGroup(2), // Toilet
                        _makeEmptyBarGroup(3), // Home
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(color: Colors.grey, fontSize: 10);
                              switch (value.toInt()) {
                                case 0: return const Text('Water', style: style);
                                case 1: return const Text('Food', style: style);
                                case 2: return const Text('Toilet', style: style);
                                case 3: return const Text('Home', style: style);
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value % 2 == 0) { // Tunjuk nombor genap je (0, 2, 4...)
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

          // 3. KAD COMMUNICATION LOG (BAWAH)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Communication Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text("Tiada log dikesan.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER UNTUK UI INSIGHTS ---
  Widget _buildSummaryCard(String value, String title, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
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
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeEmptyBarGroup(int x) {
    // Graf data 0 buat masa sekarang sebab tunggu litar Firebase sedut log sebenar
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))],
    );
  }
}