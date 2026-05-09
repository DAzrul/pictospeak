import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart'; // 🚨 J.A.R.V.I.S: Wajib ada untuk 'debugPrint'

class LocalDB {
  static Database? _database;

  // Nama table kita
  final String tableName = 'pictograms';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Cari lokasi nak simpan database dalam memori fon
    String path = join(await getDatabasesPath(), 'pictospeak_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint("J.A.R.V.I.S: Membina peti besi SQLite buat kali pertama...");
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            label_en TEXT,
            label_ms TEXT,
            category TEXT,
            image_url TEXT,
            ownerId TEXT
          )
        ''');
      },
    );
  }

  // Fungsi nak sumbat data dari Awan masuk ke Fon
  Future<void> insertOrUpdatePictogram(Map<String, dynamic> data, String docId) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        'id': docId,
        'label_en': data['label_en'] ?? '',
        'label_ms': data['label_ms'] ?? '',
        'category': data['category'] ?? 'Others',
        'image_url': data['image_url'] ?? '',
        'ownerId': data['ownerId'] ?? 'GLOBAL',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fungsi untuk budak (SVO Builder) baca data bila nak bina ayat
  Future<List<Map<String, dynamic>>> getPictogramsByCategory(String category) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  // 🚨 J.A.R.V.I.S: Protocol Clean Slate (Nuclear Reset)
  Future<void> deleteAllPictograms() async {
    final db = await database;
    try {
      await db.delete(tableName); // Guna variable tableName lagi selamat
      debugPrint("J.A.R.V.I.S: Database lokal telah dikosongkan. Licin gila babi!");
    } catch (e) {
      debugPrint("Error masa nak delete: $e");
    }
  }
}