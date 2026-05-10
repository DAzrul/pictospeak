import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../auth/splash_screen.dart';
import 'library_screen.dart';
import 'security_screen.dart';
import 'settings_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  String _patientName = "Loading...";
  String? _patientId; // 🚨 J.A.R.V.I.S: Kita perlukan UID pesakit, bukan UID kita!
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // 🚨 J.A.R.V.I.S: Ambil data profile Caregiver & ID Pesakit
  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _patientName = doc.data()!['patientName'] ?? "Unknown";
            _patientId = doc.data()!['patientId'] ?? user.uid; // Fallback ke UID sendiri kalau tak set
          });
        }
      } catch (e) {
        print("J.A.R.V.I.S [ERROR]: $e");
      }
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildAnalyticsTab(),
      const LibraryScreen(),
      const SecurityScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SplashScreen()), (route) => false),
        ),
        title: Column(
          children: [
            const Text('Caregiver Dashboard', style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_selectedIndex == 0)
              Text('Patient: $_patientName', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), label: 'Security'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    // 🚨 J.A.R.V.I.S: Tunggu sampai _patientId dah ready baru sedut log
    if (_patientId == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usage_logs')
          .where('userId', isEqualTo: _patientId) // 👈 Guna patientId!
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // 🚨 J.A.R.V.I.S: Kalau keluar error Index kat sini, klik link dlm terminal!
          print("FIREBASE ERROR: ${snapshot.error}");
          return Center(child: Text("Error sedut data babi: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data?.docs ?? [];

        // 1. Kira Sentences Today (Logic simple: jumlah doc dlm list)
        int sentencesToday = allDocs.length;

        // 2. Mood Trend
        String moodTrend = "Neutral";
        if (allDocs.isNotEmpty) moodTrend = allDocs.first['mood'] ?? "Neutral";

        // 3. Frequency Graf
        Map<String, double> freqMap = {'Water': 0, 'Food': 0, 'Toilet': 0, 'Home': 0, 'Computer': 0};
        for (var doc in allDocs) {
          String lastObj = doc['last_object'] ?? '';
          if (freqMap.containsKey(lastObj)) freqMap[lastObj] = freqMap[lastObj]! + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildSummaryCard(sentencesToday.toString(), 'Sentences Today', Icons.chat_bubble_outline, Colors.blue),
                  const SizedBox(width: 12),
                  _buildSummaryCard(moodTrend, 'Mood Trend', Icons.sentiment_satisfied_alt, moodTrend == "DISTRESSED" ? Colors.red : Colors.green),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.analytics_outlined, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Most Frequent Needs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 30),
                    SizedBox(height: 200, child: _buildDynamicBarChart(freqMap)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.access_time, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Communication Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 16),
                    if (allDocs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Tiada log dikesan babi."))),
                    ...allDocs.take(5).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      return _buildLogItem(
                          "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                          List<String>.from(data['phrase'].toString().split(' ')),
                          data['mood'].toString().toLowerCase()
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI HELPER METHODS ---
  Widget _buildSummaryCard(String val, String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(String time, List<String> words, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)), _buildStatusBadge(status)]),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: words.map((w) => Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(w, style: const TextStyle(fontSize: 12)))).toList())),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'distressed' ? Colors.red : status == 'urgent' ? Colors.orange : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDynamicBarChart(Map<String, double> freqMap) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (freqMap.values.reduce((a, b) => a > b ? a : b) + 5).clamp(10, 100),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 10);
                String text = '';
                switch (value.toInt()) {
                  case 0: text = 'Water'; break;
                  case 1: text = 'Food'; break;
                  case 2: text = 'Toilet'; break;
                  case 3: text = 'Home'; break;
                }
                return SideTitleWidget(meta: meta, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _barGroup(0, freqMap['Water']!, Colors.blue),
          _barGroup(1, freqMap['Food']!, Colors.orange),
          _barGroup(2, freqMap['Toilet']!, Colors.green),
          _barGroup(3, freqMap['Home']!, Colors.purple),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
  }
}