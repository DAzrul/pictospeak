import 'package:cloud_firestore/cloud_firestore.dart';

class Pictogram {
  final String id;
  final String labelEn;
  final String labelMs;
  final String category;
  final String imageUrl;
  final String ownerId; // 🚨 J.A.R.V.I.S: Identiti tuan punya piktogram
  final DateTime createdAt;

  Pictogram({
    required this.id,
    required this.labelEn,
    required this.labelMs,
    required this.category,
    required this.imageUrl,
    required this.ownerId, // 🚨 J.A.R.V.I.S: Wajib ada!
    required this.createdAt,
  });

  // --- CONVERT DARI FIRESTORE (CLOUD) KE OBJECT ---
  factory Pictogram.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pictogram(
      id: doc.id,
      labelEn: data['label_en'] ?? '',
      labelMs: data['label_ms'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['image_url'] ?? '',
      ownerId: data['ownerId'] ?? 'GLOBAL', // 🚨 INI YANG KAU TERLEPAS TADI!
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- CONVERT DARI MAP (UNTUK SQLITE / LOCAL) KE OBJECT ---
  factory Pictogram.fromMap(Map<String, dynamic> map, String docId) {
    return Pictogram(
      id: docId,
      labelEn: map['label_en'] ?? '',
      labelMs: map['label_ms'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['image_url'] ?? '',
      ownerId: map['ownerId'] ?? 'GLOBAL',
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
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}