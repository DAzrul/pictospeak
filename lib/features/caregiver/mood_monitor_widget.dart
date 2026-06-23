import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodMonitorWidget extends StatefulWidget {
  final String patientId;

  const MoodMonitorWidget({super.key, required this.patientId});

  @override
  State<MoodMonitorWidget> createState() => _MoodMonitorWidgetState();
}

class _MoodMonitorWidgetState extends State<MoodMonitorWidget> {
  // Simpan data untuk 7 hari. Index 0 = Hari ni, 1 = Semalam, dsb.
  List<Map<String, int>> _weeklyMoodData = List.generate(7, (index) => {'happy': 0, 'sad': 0});
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMoodData();
  }

  Future<void> _fetchMoodData() async {
    try {
      DateTime now = DateTime.now();
      DateTime sevenDaysAgo = now.subtract(const Duration(days: 6));
      // Reset masa ke pukul 12 pagi untuk kiraan tepat
      DateTime startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

      // Sedut data dari Firestore (bypass index error dengan filter di client jika tiada composite index)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('communication_logs')
          .where('patient_id', isEqualTo: widget.patientId)
          .get();

      List<Map<String, int>> tempData = List.generate(7, (index) => {'happy': 0, 'sad': 0});

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (data['timestamp'] != null && data['mood'] != null) {
          DateTime logDate = (data['timestamp'] as Timestamp).toDate();

          // Hanya ambil data 7 hari terkini
          if (logDate.isAfter(startDate) || logDate.isAtSameMomentAs(startDate)) {
            // Cari beza hari antara logDate dan hari ini (0 = hari ini, 6 = 6 hari lepas)
            int dayDifference = now.difference(DateTime(logDate.year, logDate.month, logDate.day)).inDays;

            if (dayDifference >= 0 && dayDifference < 7) {
              String mood = data['mood'].toString().toLowerCase();

              // 🚀 LITAR PENGESAN MOOD
              if (mood == 'positive' || mood == 'happy' || mood == 'joy') {
                tempData[dayDifference]['happy'] = (tempData[dayDifference]['happy'] ?? 0) + 1;
              } else if (mood == 'negative' || mood == 'sad' || mood == 'angry') {
                tempData[dayDifference]['sad'] = (tempData[dayDifference]['sad'] ?? 0) + 1;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          // Terbalikkan list supaya carta bermula dari hari terlama di kiri, hari ini di kanan
          _weeklyMoodData = tempData.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("🚨 J.A.R.V.I.S Error: Gagal sedut data mood -> $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Pemantauan Mood (7 Hari)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🚀 LITAR CARTA BAR FL_CHART
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(), // Dynamic height
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // value is 0 to 6
                        DateTime date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('EEE').format(date), // Cth: Mon, Tue
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PETUNJUK (LEGEND)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green.shade400, "Happy/Positif"),
              const SizedBox(width: 20),
              _buildLegend(Colors.red.shade400, "Sad/Negatif"),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double maxVal = 0;
    for (var day in _weeklyMoodData) {
      if ((day['happy'] ?? 0) > maxVal) maxVal = (day['happy'] ?? 0).toDouble();
      if ((day['sad'] ?? 0) > maxVal) maxVal = (day['sad'] ?? 0).toDouble();
    }
    // Tambah sikit ruang kosong atas carta
    return maxVal < 5 ? 5 : maxVal + 2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      int happyCount = _weeklyMoodData[index]['happy'] ?? 0;
      int sadCount = _weeklyMoodData[index]['sad'] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: happyCount.toDouble(),
            color: Colors.green.shade400,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: sadCount.toDouble(),
            color: Colors.red.shade400,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}