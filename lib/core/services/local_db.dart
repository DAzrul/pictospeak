import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class LocalDB {
  static Database? _database;
  final String tableName = 'pictograms';
  final String historyTable = 'usage_history'; // 🚨 J.A.R.V.I.S: Laci memori baru

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'pictospeak_offline_v2.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint("J.A.R.V.I.S: Membina peti besi SQLite V2 (Kini dengan Memori!)...");

        // Table 1: Piktogram (Library)
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            label_en TEXT,
            label_ms TEXT,
            category TEXT,
            image_url TEXT,
            ownerId TEXT,
            tags TEXT,
            frequency INTEGER DEFAULT 0 -- 🚨 J.A.R.V.I.S: Laci kekerapan baru
          )
        ''');

        // 🚨 Table 2: Usage History (Tempat AI belajar tabiat)
        await db.execute('''
          CREATE TABLE $historyTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phrase TEXT UNIQUE, 
            frequency INTEGER DEFAULT 1,
            last_used DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  // --- 🚨 FUNGSI BARU: Tambah Kekerapan Bila Klik ---
  Future<void> incrementFrequency(String id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE $tableName SET frequency = frequency + 1 WHERE id = ?',
        [id]
    );
    debugPrint("J.A.R.V.I.S: Ikon $id makin popular! Kekerapan bertambah.");
  }

  // --- LOGIK PIKTOGRAM (MACAM BIASA) ---
  Future<void> insertOrUpdatePictogram(Map<String, dynamic> data, String docId) async {
    final db = await database;
    String tagsString = "";
    if (data['tags'] != null && data['tags'] is List) {
      tagsString = (data['tags'] as List).join(', ');
    }

    await db.insert(
      tableName,
      {
        'id': docId,
        'label_en': data['label_en'] ?? '',
        'label_ms': data['label_ms'] ?? '',
        'category': data['category'] ?? 'Others',
        'image_url': data['image_url'] ?? '',
        'ownerId': data['ownerId'] ?? 'GLOBAL',
        'tags': tagsString,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPictogramsByCategory(String category) async {
    final db = await database;
    return await db.query(tableName, where: 'category = ?', whereArgs: [category]);
  }

  Future<List<Map<String, dynamic>>> getAllPictograms() async {
    final db = await database;
    return await db.query(tableName);
  }

  // --- 🚨 J.A.R.V.I.S: LOGIK BELAJAR TABIAT (NEW!) ---

  // Fungsi untuk simpan ayat yang Azrul selalu sebut
  Future<void> logUsage(String phrase) async {
    final db = await database;
    debugPrint("J.A.R.V.I.S: Merakam memori baru -> $phrase");

    // Kalau ayat dah ada, kita cuma tambah frequency (ON CONFLICT)
    await db.rawInsert('''
      INSERT INTO $historyTable (phrase, frequency, last_used) 
      VALUES(?, 1, CURRENT_TIMESTAMP)
      ON CONFLICT(phrase) DO UPDATE SET 
        frequency = frequency + 1,
        last_used = CURRENT_TIMESTAMP
    ''', [phrase]);
  }

  // Fungsi untuk AI tengok apa yang paling popular
  Future<List<Map<String, dynamic>>> getTopPhrases() async {
    final db = await database;
    return await db.query(
        historyTable,
        orderBy: 'frequency DESC, last_used DESC',
        limit: 10 // Ambil 10 teratas
    );
  }

  // Nuclear Reset
  Future<void> deleteAllPictograms() async {
    final db = await database;
    try {
      await db.delete(tableName);
      await db.delete(historyTable); // Cuci memori sekali babi
      debugPrint("J.A.R.V.I.S: Database & Memori dibersihkan. Clean gila!");
    } catch (e) {
      debugPrint("Error masa nak delete: $e");
    }
  }
}