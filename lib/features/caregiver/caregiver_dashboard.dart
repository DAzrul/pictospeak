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
  int _selectedIndex = 0;

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
          setState(() {
            // Kita guna '??' kalau field patientName tu tak wujud dalam dokumen tu.
            _patientName = doc.data()!['patientName'] ?? "Patient Name Not Set";
          });
        } else {
          // Dokumen tak wujud langsung dalam Firestore
          setState(() => _patientName = "No Profile Found");
          print("J.A.R.V.I.S [WARNING]: Dokumen UID ${user.uid} tiada dalam collection 'caregivers'");
        }
      } catch (e) {
        setState(() => _patientName = "Connection Error");
        print("J.A.R.V.I.S [ERROR FETCHING PATIENT]: $e"); // 🚨 Buka terminal, baca error ni!
      }
    } else {
      setState(() => _patientName = "Guest Mode");
    }
  }

  void _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
              (route) => false
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 J.A.R.V.I.S: Buang underscore kat depan '_pages' (Fix Warning)
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
          onPressed: () {
            // Kita "buang" semua skrin (termasuk Login) dan letak Splash sebagai skrin utama.
            // Sesi Firebase kau TIDAK terjejas. Kau masih logged in secara senyap.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false, // Ini yang bunuh semua skrin kat belakang tu
            );
          },
        ),
        title: Column(
          children: [
            Text(_appBarTitles[_selectedIndex],
                style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_selectedIndex == 0)
              Text('Patient: $_patientName',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: pages[_selectedIndex], // Guna variable baru tanpa underscore
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

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to securely log out? This will end your active session.'),
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
  }

  // --- ANALYTICS TAB CONTENT ---
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
                SizedBox(height: 200, child: _buildBarChart()),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: words.map((w) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(w, style: const TextStyle(fontSize: 12)),
              )).toList(),
            ),
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
      // 🚨 J.A.R.V.I.S: Tukar ke withValues supaya Flutter 3.x tak bising (Fix Warning)
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 25,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontSize: 10);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Water'; break;
                  case 1: text = 'Food'; break;
                  case 2: text = 'Toilet'; break;
                  case 3: text = 'Home'; break;
                  default: text = ''; break;
                }
                // 🚨 J.A.R.V.I.S: Tembak error fl_chart kat sini! Guna meta: meta
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
          _barGroup(0, 22, Colors.blue),
          _barGroup(1, 18, Colors.orange),
          _barGroup(2, 14, Colors.green),
          _barGroup(3, 10, Colors.purple),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}