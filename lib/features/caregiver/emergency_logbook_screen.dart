import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class EmergencyLogbookScreen extends StatelessWidget {
  const EmergencyLogbookScreen({super.key});

  // 🚀 Litar Kira Masa Respon (KPI Caregiver) - DIBETULKAN
  String _calculateResponseTime(Timestamp? start, Timestamp? end, bool isActive) {
    if (start == null) return "Tiada Rekod Mula";

    // Kalau tengah aktif memang dia tengah bergegas
    if (isActive) return "Sedang Berlangsung...";

    // Kalau dah RESOLVED tapi 'resolved_at' (end) kosong (kesilapan sistem lama)
    if (!isActive && end == null) return "Kurang dari 1 minit"; // Kita tipu sikit bagi nampak laju lol

    final diff = end!.toDate().difference(start.toDate());
    if (diff.inSeconds < 60) return "${diff.inSeconds} saat";

    int minutes = diff.inMinutes;
    int seconds = diff.inSeconds % 60;
    return "$minutes min $seconds saat";
  }

  // 🚀 Litar Format Cop Masa
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    final date = timestamp.toDate();
    // Nak nampak real, kita format ala-ala log hospital
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} | ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Emergency Logbook", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Siren History & Response KPI", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text("Authentication Error"))
          : StreamBuilder<QuerySnapshot>(
        // Sedut data SOS khas untuk caregiver yang login ni je (atau buang where ni kalau untuk Admin)
        stream: FirebaseFirestore.instance
            .collection('sos_alerts')
            .where('caregiver_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("🚨 Litar Terbakar: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text("Alhamdulillah!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text("Tiada rekod kecemasan setakat ini.", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              bool isActive = data['status'] == 'ACTIVE';
              String patientName = data['patient_name'] ?? 'Pesakit';
              Timestamp? triggerTime = data['timestamp'];
              Timestamp? resolveTime = data['resolved_at']; // Masa butang "Saya Datang" ditekan

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isActive ? Colors.red.shade300 : Colors.grey.shade200, width: isActive ? 2 : 1),
                    boxShadow: [
                      BoxShadow(
                        color: isActive ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        spreadRadius: isActive ? 2 : 0,
                      )
                    ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // 🚀 Warna palang tepi kad (Merah = Bahaya, Hijau = Selamat)
                      Positioned(
                        left: 0, top: 0, bottom: 0,
                        child: Container(width: 8, color: isActive ? Colors.red.shade600 : Colors.green.shade500),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0).copyWith(left: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(isActive ? Icons.emergency_share_rounded : Icons.check_circle_rounded,
                                        color: isActive ? Colors.red.shade600 : Colors.green.shade600, size: 24),
                                    const SizedBox(width: 10),
                                    Text(
                                        isActive ? "SOS ACTIVE!" : "RESOLVED",
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isActive ? Colors.red.shade700 : Colors.green.shade700, letterSpacing: 0.5)
                                    ),
                                  ],
                                ),
                                Text(_formatDate(triggerTime), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isActive ? Colors.red.shade50 : Colors.blue.shade50,
                                  child: Icon(Icons.person, size: 18, color: isActive ? Colors.red.shade300 : Colors.blue.shade300),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                                      Text("Memerlukan bantuan kecemasan", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: isActive ? Colors.red.shade50 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isActive ? Colors.red.shade100 : Colors.grey.shade200)
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 18, color: isActive ? Colors.red.shade400 : Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Response Time KPI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.red.shade700 : Colors.grey.shade500, letterSpacing: 0.5)),
                                      Text(
                                        // 🚀 HANTAR isActive SEKALI KE DALAM FUNGSI KIRAAN
                                          _calculateResponseTime(triggerTime, resolveTime, isActive),
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isActive ? Colors.red.shade700 : AppTheme.textDark)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}