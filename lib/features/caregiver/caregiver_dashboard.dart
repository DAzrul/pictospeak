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
  int _selectedIndex = 0; // SUIS TAB KITA (0 = Analytics, 1 = Library)

  // Tajuk AppBar yang akan bertukar ikut tab
  final List<String> _appBarTitles = [
    'Caregiver Dashboard',
    'Pictogram Library',
    'Security & Privacy',
    'Settings'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPatientName();
  }

  Future<void> _fetchPatientName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() => _patientName = doc.data()!['patientName'] ?? "Unknown Patient");
        } else {
          setState(() => _patientName = "Patient Not Set");
        }
      } catch (e) {
        setState(() => _patientName = "Error Loading");
      }
    }
  }

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SplashScreen()), (route) => false);
    }
  }

  // LOGIK TUKAR TAB KAT BAWAH NI
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Senarai skrin yang akan disumbat dalam Body
    final List<Widget> _pages = [
      _buildAnalyticsTab(), // Tab 0
      const LibraryScreen(), // Tab 1
      const SecurityScreen(), //Tab 2
      const SettingsScreen(), // Tab 3
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            // Tajuk berubah ikut tab apa kau tekan
            Text(_appBarTitles[_selectedIndex], style: const TextStyle(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            // Nama patient hanya tunjuk kat tab Analytics
            if (_selectedIndex == 0)
              Text('Patient: $_patientName', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to securely log out from the dashboard?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleSignOut(context);
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // INI JANTUNG DIA: Body akan tukar ikut index yang dipilih
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex, // Beritahu Nav bar mana satu tengah aktif
        onTap: _onItemTapped,         // Panggil fungsi tukar tab bila ditekan
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), label: 'Security'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  // --- SEMUA BENDA GRAF MASUK SINI ---
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryCard('12', 'Sentences Today', Icons.chat_bubble_outline, Colors.blue),
              const SizedBox(width: 12),
              _buildSummaryCard('Good', 'Mood Trend', Icons.sentiment_satisfied_alt, Colors.green),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Most Frequent Needs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 200,
                  child: _buildBarChart(),
                ),
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
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Communication Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLogItem('10:45 AM', ['I', 'want', 'water'], 'neutral'),
                _buildLogItem('10:32 AM', ['I', 'feel', 'pain'], 'distressed'),
                _buildLogItem('09:58 AM', ['I', 'need', 'toilet'], 'urgent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String val, String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: words.map((w) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(w, style: const TextStyle(fontSize: 12)),
            )).toList(),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'distressed') color = Colors.red;
    if (status == 'urgent') color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 24,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _barGroup(0, 24, Colors.blue),
          _barGroup(1, 18, Colors.orange),
          _barGroup(2, 15, Colors.green),
          _barGroup(3, 12, Colors.purple),
          _barGroup(4, 9, Colors.pink),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 22, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}