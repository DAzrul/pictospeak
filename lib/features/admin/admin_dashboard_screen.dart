import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _picIdController = TextEditingController();
  final _labelEnController = TextEditingController();
  final _labelMsController = TextEditingController();

  final _newMainController = TextEditingController();
  final _newSubController = TextEditingController();

  // 🚀 LITAR SEARCH J.A.R.V.I.S
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _selectedMainCategory = 'health';
  String _selectedSubCategory = 'none';

  bool _isCreatingNewMain = false;
  bool _isCreatingNewSub = false;

  List<String> _mainCategories = ['health', 'body', 'food_drinks', 'feelings', 'environment', 'hygiene'];
  // 🚀 Enjin penyimpan anak-anak folder
  Map<String, Set<String>> _subCategories = {};

  Map<String, int> _globalPhraseFrequency = {};
  int _totalActivePatients = 0;
  int _totalSelections = 0;

  // 🚀 Litar Trend Indicators
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

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose(); // 🚀 WAJIB DISPOSE
    super.dispose();
  }

  // 🚀 Helper: Kira beza masa untuk paparkan "12m ago", "1h ago" kat Tiket
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

  // 🚀 Litar Tambahan Untuk Simpan Hits Bulanan (12 Bulan)
  List<int> _monthlyHits = List.generate(12, (_) => 0);

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

      int currentActive = 0, pastActive = 0;
      String pTrendText = "+0.0%";
      Color pTrendColor = const Color(0xFF0D652D), pTrendBg = const Color(0xFFE6F4EA);

      try {
        DateTime thirtyAgo = DateTime.now().subtract(const Duration(days: 30));
        DateTime sixtyAgo = DateTime.now().subtract(const Duration(days: 60));

        final curActSnap = await FirebaseFirestore.instance.collectionGroup('patients').where('last_active', isGreaterThan: Timestamp.fromDate(thirtyAgo)).count().get();
        currentActive = curActSnap.count ?? 0;

        final pastActSnap = await FirebaseFirestore.instance.collectionGroup('patients').where('last_active', isGreaterThan: Timestamp.fromDate(sixtyAgo)).where('last_active', isLessThanOrEqualTo: Timestamp.fromDate(thirtyAgo)).count().get();
        pastActive = pastActSnap.count ?? 0;

        double pGrowth = 0;
        if (pastActive == 0 && currentActive > 0) pGrowth = 100.0;
        else if (pastActive > 0) pGrowth = ((currentActive - pastActive) / pastActive) * 100;

        if (pGrowth >= 0) {
          pTrendText = "+${pGrowth.toStringAsFixed(1)}%";
        } else {
          pTrendText = "${pGrowth.toStringAsFixed(1)}%";
          pTrendColor = Colors.red.shade700; pTrendBg = Colors.red.shade50;
        }
      } catch (e) { debugPrint("🚨 Ralat Trend Pesakit: $e"); }

      // =======================================================
      // 🚀 LITAR DEWA: KIRAAN TREND & GRAF BULANAN (REAL DATA)
      // =======================================================
      int currentMonthClicks = 0, pastMonthClicks = 0;
      String sTrendText = "+0.0%";
      Color sTrendColor = const Color(0xFF0D652D), sTrendBg = const Color(0xFFE6F4EA);

      List<int> tempMonthlyHits = List.generate(12, (_) => 0);

      try {
        DateTime now = DateTime.now();
        DateTime startOfThisYear = DateTime(now.year, 1, 1);
        DateTime startOfThisMonth = DateTime(now.year, now.month, 1);
        DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);

        final yearlyLogsSnap = await FirebaseFirestore.instance.collection('usage_logs')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfThisYear))
            .get();

        for (var doc in yearlyLogsSnap.docs) {
          final data = doc.data();
          if (data['timestamp'] != null) {
            DateTime logDate = (data['timestamp'] as Timestamp).toDate();
            int monthIndex = logDate.month - 1;

            tempMonthlyHits[monthIndex]++;

            if (logDate.isAfter(startOfThisMonth) || logDate.isAtSameMomentAs(startOfThisMonth)) {
              currentMonthClicks++;
            } else if ((logDate.isAfter(startOfLastMonth) || logDate.isAtSameMomentAs(startOfLastMonth)) && logDate.isBefore(startOfThisMonth)) {
              pastMonthClicks++;
            }
          }
        }

        double sGrowth = 0;
        if (pastMonthClicks == 0 && currentMonthClicks > 0) sGrowth = 100.0;
        else if (pastMonthClicks > 0) sGrowth = ((currentMonthClicks - pastMonthClicks) / pastMonthClicks) * 100;

        if (sGrowth >= 0) {
          sTrendText = "+${sGrowth.toStringAsFixed(1)}%";
        } else {
          sTrendText = "${sGrowth.toStringAsFixed(1)}%";
          sTrendColor = Colors.red.shade700; sTrendBg = Colors.red.shade50;
        }
      } catch (e) { debugPrint("🚨 Ralat Litar Bulanan: $e"); }

      String sessionText = "0m 0s";
      String sessionTText = "+0.0%";
      Color sessionTColor = const Color(0xFF0D652D), sessionTBg = const Color(0xFFE6F4EA);

      try {
        if (currentActive > 0 && currentMonthClicks > 0) {
          int totalSecondsThisMonth = currentMonthClicks * 65;
          int avgSecondsPerPatient = totalSecondsThisMonth ~/ currentActive;

          int minutes = avgSecondsPerPatient ~/ 60;
          int seconds = avgSecondsPerPatient % 60;
          sessionText = "${minutes}m ${seconds}s";

          if (pastActive > 0 && pastMonthClicks > 0) {
            int totalSecondsPast = pastMonthClicks * 65;
            int avgSecondsPast = totalSecondsPast ~/ pastActive;

            double sessionGrowth = ((avgSecondsPerPatient - avgSecondsPast) / (avgSecondsPast > 0 ? avgSecondsPast : 1)) * 100;
            if (sessionGrowth >= 0) {
              sessionTText = "+${sessionGrowth.toStringAsFixed(1)}%";
            } else {
              sessionTText = "${sessionGrowth.toStringAsFixed(1)}%";
              sessionTColor = Colors.red.shade700; sessionTBg = Colors.red.shade50;
            }
          } else if (pastMonthClicks == 0 && currentMonthClicks > 0) {
            sessionTText = "+100.0%";
          }
        }
      } catch (e) { debugPrint("🚨 Ralat Proxy Session: $e"); }

      if (mounted) {
        setState(() {
          _globalPhraseFrequency = frequencyMap;
          _totalSelections = totalHits;
          _totalActivePatients = currentActive;

          _patientTrendText = pTrendText; _patientTrendColor = pTrendColor; _patientTrendBg = pTrendBg;
          _selectionsTrendText = sTrendText; _selectionsTrendColor = sTrendColor; _selectionsTrendBg = sTrendBg;
          _monthlyHits = tempMonthlyHits;

          _avgSessionText = sessionText; _sessionTrendText = sessionTText;
          _sessionTrendColor = sessionTColor; _sessionTrendBg = sessionTBg;

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

  Future<void> _uploadGlobalPictogram() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚨 Action Denied: Please select an image!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String picId = _formatToId(_picIdController.text);
      String labelEn = _labelEnController.text.trim();

      String finalMain = _isCreatingNewMain ? _formatToId(_newMainController.text) : _formatToId(_selectedMainCategory);
      String? finalSub = (_selectedSubCategory != 'none') ? (_selectedSubCategory == 'ADD_NEW' ? _formatToId(_newSubController.text) : _formatToId(_selectedSubCategory)) : null;
      String actualCategory = finalSub ?? finalMain;

      Reference storageRef = FirebaseStorage.instance.ref().child('global_pictograms/$actualCategory/$picId.png');
      UploadTask uploadTask = kIsWeb ? storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg')) : storageRef.putFile(File(_selectedImage!.path));

      TaskSnapshot snapshot = await uploadTask;
      String realDownloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('global_pictograms').add({
        'pic_id': picId, 'label_en': labelEn, 'label_ms': _labelMsController.text.trim(),
        'category': actualCategory, 'parent_folder': finalSub != null ? finalMain : null,
        'image_url': realDownloadUrl, 'timestamp': FieldValue.serverTimestamp(), 'uploaded_by': 'SUPERADMIN',
      });

      await _logAdminActivity("Deployed new pictogram: $labelEn to $actualCategory");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Deployed!'), backgroundColor: Colors.green));
        _picIdController.clear(); _labelEnController.clear(); _labelMsController.clear();
        setState(() { _selectedImage = null; _webImageBytes = null; _scanGlobalFolders(); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚨 Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var sortedEntries = _globalPhraseFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 👈 SIDEBAR
          Container(
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

                const Spacer(),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Text("AZ", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14))),
                  title: const Text("Admin Root", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Super User", style: TextStyle(color: Colors.indigoAccent, fontSize: 12)),
                ),
              ],
            ),
          ),

          // 👉 MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        children: [
                          // 🚀 SEARCH BAR BERFUNGSI
                          Container(
                            width: 250,
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
                          const SizedBox(width: 16),

                          // 🚀 NOTIFICATION BELL BERFUNGSI (LIVE BADGE DARI FIREBASE)
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
                                    alignment: const Alignment(0.6, -0.6), // Kedudukan titik merah
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 22),
                                      onPressed: () {
                                        if (pendingCount > 0) {
                                          // 🚀 Kalau tekan loceng, auto lompat pergi Tab Support Tickets!
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title, String subtitle) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          // Kosongkan search bar bila tukar tab supaya tak sangkut filter
          _searchQuery = "";
          _searchController.clear();
        });
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
      default: return "";
    }
  }

  String _getPageSubtitle() {
    switch (_selectedIndex) {
      case 0: return "Real-time usage across the PictoSpeak ecosystem";
      case 1: return "Upload and route new pictograms";
      case 2: return "Manage user feedback and bug reports";
      case 3: return "Control critical platform settings";
      default: return "";
    }
  }

  Widget _buildCurrentScreen(List<MapEntry<String, int>> sortedEntries) {
    switch (_selectedIndex) {
      case 0: return _buildAnalyticsTab(sortedEntries);
      case 1: return _buildCmsTab();
      case 2: return _buildTicketsTab();
      case 3: return _buildConfigTab();
      default: return Container();
    }
  }

  // =======================================================
  // 📊 TAB 1: ANALYTICS
  // =======================================================
  Widget _buildAnalyticsTab(List<MapEntry<String, int>> sortedEntries) {
    if (_isLoadingAnalytics) return const Center(child: CircularProgressIndicator(color: Colors.indigo));

    final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    // 🚀 LITAR PENAPISAN SEARCH UNTUK PICTOGRAMS
    List<MapEntry<String, int>> displayEntries = sortedEntries;
    if (_searchQuery.isNotEmpty) {
      displayEntries = sortedEntries.where((entry) => _formatToDisplay(entry.key).toLowerCase().contains(_searchQuery)).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        // Hero Chart
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.show_chart, color: Colors.amberAccent, size: 24)),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Global Usage Trends", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Pictogram selections across all devices · last 12 months", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
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

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: "$hits selections",
                                child: Container(
                                    width: 35,
                                    height: barHeight,
                                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4))
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(months[index], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))
                            ],
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

        Row(
          children: [
            _buildStatCard("Active Patients", _totalActivePatients.toString(), Icons.people_outline, Colors.indigo.shade400, _patientTrendText, _patientTrendColor, _patientTrendBg),
            const SizedBox(width: 20),
            _buildStatCard("Daily Selections", _totalSelections.toString(), Icons.show_chart, Colors.indigo.shade400, _selectionsTrendText, _selectionsTrendColor, _selectionsTrendBg),
            const SizedBox(width: 20),
            _buildStatCard("Avg. Session", _avgSessionText, Icons.trending_up, Colors.indigo.shade400, _sessionTrendText, _sessionTrendColor, _sessionTrendBg),
          ],
        ),
        const SizedBox(height: 24),

        // Top Performing Pictograms
        Container(
          padding: const EdgeInsets.all(24),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Top Performing Pictograms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text("Most selected symbols this period", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
                                Text(_formatToDisplay(entry.key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, String badgeText, Color badgeTextColor, Color badgeBgColor) {
    return Expanded(
      child: Container(
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
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // ☁️ TAB 2: CMS DEPLOYMENT
  // =======================================================
  Widget _buildCmsTab() {
    List<String> dynamicSubFolders = ['none'];
    String currentMainKey = _formatToId(_selectedMainCategory);

    if (!_isCreatingNewMain && _subCategories.containsKey(currentMainKey)) {
      dynamicSubFolders.addAll(_subCategories[currentMainKey]!.toList());
    }
    dynamicSubFolders.add('ADD_NEW');

    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(30),
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
                                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.indigo.shade600),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("New Pictogram Upload", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  Text("Add a symbol to the library", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
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
                    ),
                  ),

                  const SizedBox(width: 30),

                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(30),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Directory Routing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  Text("Choose where this symbol lives", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
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
                          const SizedBox(height: 40),

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
                                Text(_destinationPath, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadGlobalPictogram,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E236C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2
                  ),
                  icon: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.rocket_launch, color: Colors.amber),
                  label: Text(_isUploading ? 'Deploying...' : 'PUBLISH TO ECOSYSTEM', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.indigo.shade400, width: 2)),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items.map((cat) => DropdownMenuItem(value: cat, child: Text(cat == 'ADD_NEW' ? '➕ Create New' : _formatToDisplay(cat), style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // =======================================================
  // 🎫 TAB 3: TICKETS
  // =======================================================
  Widget _buildTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('support_tickets').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E236C)));

        var docs = snapshot.data!.docs;

        // 🚀 LITAR PENAPISAN SEARCH UNTUK SUPPORT TICKETS
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
          padding: const EdgeInsets.all(30),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: isResolved ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isResolved ? const Color(0xFFBBF7D0) : Colors.grey.shade200, width: 1.5),
                      boxShadow: [if (!isResolved) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                        const SizedBox(width: 20),
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

  // =======================================================
  // ⚙️ TAB 4: SYSTEM CONFIG
  // =======================================================
  Widget _buildConfigTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system_configs').doc('general').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E236C)));

        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return ListView(
          padding: const EdgeInsets.all(30),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Kill Switches", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text("Critical system overrides", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
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
                          subtitle: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                              const SizedBox(width: 4),
                              Text("Blocks patient access during server updates.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
              padding: const EdgeInsets.all(24),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.campaign_outlined, color: Colors.orange.shade500, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Global Announcement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text("Banner shown to all users", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
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
            )
          ],
        );
      },
    );
  }
}