import 'package:cloud_firestore/cloud_firestore.dart';

class Pictogram {
  final String id;
  final String labelEn;
  final String labelMs;
  final String category;
  final String imageUrl;
  final String ownerId;
  final List<String> tags; // 🚨 J.A.R.V.I.S: LACI TAGS DAH WUJUD!
  final DateTime createdAt;

  Pictogram({
    required this.id,
    required this.labelEn,
    required this.labelMs,
    required this.category,
    required this.imageUrl,
    required this.ownerId,
    required this.tags, // 🚨 WAJIB ADA!
    required this.createdAt,
  });

  // --- CONVERT DARI FIRESTORE (CLOUD) KE OBJECT ---
  factory Pictogram.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 🚨 Handle tags dari Firebase (List<dynamic> ke List<String>)
    List<String> parsedTags = [];
    if (data['tags'] != null) {
      parsedTags = List<String>.from(data['tags']);
    }

    return Pictogram(
      id: doc.id,
      labelEn: data['label_en'] ?? '',
      labelMs: data['label_ms'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['image_url'] ?? '',
      ownerId: data['ownerId'] ?? 'GLOBAL',
      tags: parsedTags, // 👈 Tembak masuk!
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- CONVERT DARI MAP (UNTUK SQLITE / LOCAL) KE OBJECT ---
  factory Pictogram.fromMap(Map<String, dynamic> map, String docId) {
    // 🚨 Handle tags dari SQLite (Tukar String "pedas, lapar" jadi List balik)
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      parsedTags = map['tags'].toString().split(',').map((e) => e.trim()).toList();
    }

    return Pictogram(
      id: docId,
      labelEn: map['label_en'] ?? '',
      labelMs: map['label_ms'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['image_url'] ?? '',
      ownerId: map['ownerId'] ?? 'GLOBAL',
      tags: parsedTags, // 👈 Tembak masuk!
      createdAt: DateTime.now(),
    );
  }

  // --- CONVERT DARI OBJECT KE MAP (UNTUK SIMPAN) ---
  Map<String, dynamic> toMap() {
    return {
      'label_en': labelEn,
      'label_ms': labelMs,
      'category': category,
      'image_url': imageUrl,
      'ownerId': ownerId,
      'tags': tags, // 👈 Simpan balik!
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}