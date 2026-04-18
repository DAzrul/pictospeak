import 'package:cloud_firestore/cloud_firestore.dart';

class Pictogram {
  final String id;
  final String labelEn;
  final String labelMs;
  final String category;
  final String imageUrl;
  final DateTime createdAt;


  Pictogram({
    required this.id,
    required this.labelEn,
    required this.labelMs,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  // Convert dari JSON (Firestore) ke Object
  factory Pictogram.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Pictogram(
      id: doc.id,
      labelEn: data['label_en'] ?? '',
      labelMs: data['label_ms'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['image_url'] ?? '',
      createdAt: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert dari Object ke JSON untuk simpan dlm Firestore
  Map<String, dynamic> toMap() {
    return {
      'label_en': labelEn,
      'label_ms': labelMs,
      'category': category,
      'image_url': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}