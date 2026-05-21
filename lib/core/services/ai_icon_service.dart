import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AiIconService {
  // API KEY GROQ KAU
  static const String _apiKey = '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';
  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';

  // 🔥 UPDATE: Kita tambah kosa kata FontAwesome dalam otak Groq
  static const String _masterCategories = "tv, car, bus, bike, plane, boat, pet, water, food, coffee, cake, toilet, hospital, school, shop, book, music, phone, camera, money, clothes, bag, clock, key, toy, happy, sad, angry, pain, home, bed, hand, face, body, eye, ear, sun, moon, fire, tree, star, walk, run, search, chat, work, play, sport, person, man, woman, baby, family, cat, dog, fish, bird, burger, apple, brain, tooth, ghost, gift, heart, poop, wheelchair";

  static final Map<String, String> _smartCache = {};

  Future<String> getRecommendedIcon(String text) async {
    String input = text.toLowerCase().trim();

    // 1. PUKAT TUNDA OFFLINE
    String offlineResult = checkOfflineDictionary(input);
    if (offlineResult != 'extension') {
      debugPrint("⚡ J.A.R.V.I.S (Offline) jumpa: $offlineResult");
      return offlineResult;
    }

    // 2. CHECK OTAK KEDUA
    if (_smartCache.containsKey(input)) {
      debugPrint("🧠 Otak Kedua ingat! Terus bagi: ${_smartCache[input]}");
      return _smartCache[input]!;
    }

    // 3. TANYA AI GROQ
    try {
      debugPrint("🤖 Perkataan pelik ('$input'). Tanya AI Groq...");

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are a highly intelligent semantic icon matcher for an AAC app. The user inputs a word (Malay or English). Your job is to conceptually map it to ONE WORD from this exact list: [$_masterCategories]. For example, if user says 'sneakers', reply 'clothes'. If 'ocean', reply 'water'. Reply ONLY with the single matching word. If completely alien, reply 'extension'."
            },
            {
              "role": "user",
              "content": input
            }
          ],
          "temperature": 0.1,
          "max_tokens": 10
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String result = data['choices'][0]['message']['content'].toString().trim().toLowerCase();
        result = result.replaceAll(RegExp(r'[^a-z_]'), '');

        if (result != 'extension' && result.isNotEmpty) {
          _smartCache[input] = result;
          debugPrint("🎓 AI baru belajar: '$input' = '$result'");
        }

        debugPrint("🔥 AI Result (Groq): $result");
        return result;
      }
    } catch (e) {
      debugPrint("💀 AI Groq Crash: $e");
    }

    return 'extension';
  }

  // --- MEGA KAMUS OFFLINE J.A.R.V.I.S (UPDATED DENGAN FONT AWESOME) ---
  String checkOfflineDictionary(String input) {

    // 🔥 Ikon FontAwesome Baru (Spesifik)
    if (['cat', 'kucing', 'meow'].any((w) => input.contains(w))) return 'cat';
    if (['dog', 'anjing', 'puppy', 'bark'].any((w) => input.contains(w))) return 'dog';
    if (['fish', 'ikan', 'jerung', 'shark'].any((w) => input.contains(w))) return 'fish';
    if (['bird', 'burung', 'ayam', 'duck', 'itik'].any((w) => input.contains(w))) return 'bird';
    if (['burger', 'mcd', 'kfc', 'fast food', 'junk food'].any((w) => input.contains(w))) return 'burger';
    if (['apple', 'epal', 'buah', 'fruit', 'orange'].any((w) => input.contains(w))) return 'apple';
    if (['brain', 'otak', 'fikir', 'think', 'smart', 'pandai'].any((w) => input.contains(w))) return 'brain';
    if (['tooth', 'gigi', 'dentist', 'gusi'].any((w) => input.contains(w))) return 'tooth';
    if (['ghost', 'hantu', 'scary', 'takut', 'monster'].any((w) => input.contains(w))) return 'ghost';
    if (['gift', 'hadiah', 'present', 'suprise'].any((w) => input.contains(w))) return 'gift';
    if (['heart', 'hati', 'cinta', 'love', 'sayang', 'rindu'].any((w) => input.contains(w))) return 'heart';
    if (['poop', 'tahi', 'berak'].any((w) => input.contains(w))) return 'poop';
    if (['wheelchair', 'kerusi roda', 'oku', 'cacat', 'disable'].any((w) => input.contains(w))) return 'wheelchair';

    // Manusia, Keluarga & Kata Ganti Nama
    if (['mother', 'ibu', 'mama', 'mak', 'woman', 'perempuan', 'wanita', 'girl', 'aunt'].any((w) => input.contains(w))) return 'woman';
    if (['father', 'ayah', 'bapa', 'papa', 'man', 'lelaki', 'boy', 'uncle'].any((w) => input.contains(w))) return 'man';
    if (['baby', 'bayi', 'anak'].any((w) => input.contains(w))) return 'baby';
    if (['family', 'keluarga', 'adik', 'abang', 'kakak'].any((w) => input.contains(w))) return 'family';
    if (['i', 'saya', 'aku', 'me', 'you', 'awak', 'kau', 'he', 'dia', 'person', 'orang', 'kawan', 'friend'].any((w) => input.contains(w))) return 'person';

    // Kenderaan & Transport
    if (['car', 'kereta', 'drive', 'pandu', 'vehicle', 'grab'].any((w) => input.contains(w))) return 'car';
    if (['bus', 'bas', 'van', 'lori', 'truck'].any((w) => input.contains(w))) return 'bus';
    if (['bike', 'basikal', 'motor', 'motosikal', 'ride'].any((w) => input.contains(w))) return 'bike';
    if (['plane', 'kapal terbang', 'terbang', 'fly', 'airport'].any((w) => input.contains(w))) return 'plane';
    if (['boat', 'bot', 'kapal', 'ship', 'laut', 'ferry'].any((w) => input.contains(w))) return 'boat';

    // Makanan & Minuman (Ikan dah pindah atas)
    if (['water', 'air', 'minum', 'drink', 'haus', 'thirsty', 'hujan', 'rain', 'mandi', 'bath'].any((w) => input.contains(w))) return 'water';
    if (['food', 'makan', 'nasi', 'lapar', 'hungry', 'eat', 'sayur', 'mee'].any((w) => input.contains(w))) return 'food';
    if (['coffee', 'kopi', 'teh', 'tea', 'cafe', 'milo'].any((w) => input.contains(w))) return 'coffee';
    if (['cake', 'kek', 'manis', 'sweet', 'dessert', 'biskut'].any((w) => input.contains(w))) return 'cake';

    // Alam & Haiwan (Kucing, anjing, burung dah pindah atas. Tinggal haiwan random)
    if (['pet', 'haiwan', 'animal', 'lembu', 'kambing'].any((w) => input.contains(w))) return 'pet';
    if (['sun', 'matahari', 'panas', 'siang', 'cerah', 'hot'].any((w) => input.contains(w))) return 'sun';
    if (['moon', 'bulan', 'malam', 'gelap', 'night'].any((w) => input.contains(w))) return 'moon';
    if (['fire', 'api', 'bakar', 'terbakar', 'burn', 'mancis'].any((w) => input.contains(w))) return 'fire';
    if (['tree', 'pokok', 'daun', 'kayu', 'hutan', 'nature', 'rumput'].any((w) => input.contains(w))) return 'tree';
    if (['star', 'bintang'].any((w) => input.contains(w))) return 'star';

    // Tempat
    if (['home', 'rumah', 'balik', 'stay', 'bilik', 'room'].any((w) => input.contains(w))) return 'home';
    if (['hospital', 'klinik', 'clinic', 'doctor', 'doktor', 'nurse', 'sick', 'sakit', 'ubat'].any((w) => input.contains(w))) return 'hospital';
    if (['school', 'sekolah', 'belajar', 'study', 'cikgu', 'teacher', 'kelas', 'class'].any((w) => input.contains(w))) return 'school';
    if (['shop', 'kedai', 'beli', 'buy', 'shopping', 'mall', 'pasar', 'market'].any((w) => input.contains(w))) return 'shop';
    if (['toilet', 'tandas', 'kencing', 'pee', 'bilik air'].any((w) => input.contains(w))) return 'toilet'; // 'berak' dah pindah 'poop'

    // Emosi
    if (['happy', 'gembira', 'senyum', 'smile', 'suka', 'seronok', 'laugh', 'gelak'].any((w) => input.contains(w))) return 'happy';
    if (['sad', 'sedih', 'nangis', 'cry', 'kecewa', 'duka'].any((w) => input.contains(w))) return 'sad';
    if (['angry', 'marah', 'bengang', 'geram', 'amuk', 'mad', 'hate'].any((w) => input.contains(w))) return 'angry';
    if (['pain', 'luka', 'pedih', 'cedera', 'darah', 'sakit'].any((w) => input.contains(w))) return 'pain';

    // Anggota Badan (Gigi, Otak dah pindah atas)
    if (['hand', 'tangan', 'jari', 'pegang', 'hold', 'sentuh', 'touch'].any((w) => input.contains(w))) return 'hand';
    if (['face', 'muka', 'wajah', 'hidung', 'mulut', 'pipi'].any((w) => input.contains(w))) return 'face';
    if (['body', 'badan', 'perut', 'belakang', 'dada'].any((w) => input.contains(w))) return 'body';
    if (['eye', 'mata', 'lihat', 'nampak', 'see', 'look', 'tengok'].any((w) => input.contains(w))) return 'eye';
    if (['ear', 'telinga', 'dengar', 'hear', 'listen'].any((w) => input.contains(w))) return 'ear';

    // Objek
    if (['tv', 'television', 'movie', 'video'].any((w) => input.contains(w))) return 'tv';
    if (['phone', 'telefon', 'call', 'mobile', 'hp', 'tepon', 'mesej'].any((w) => input.contains(w))) return 'phone';
    if (['book', 'buku', 'baca', 'read', 'majalah'].any((w) => input.contains(w))) return 'book';
    if (['music', 'muzik', 'lagu', 'song', 'sing', 'nyanyi'].any((w) => input.contains(w))) return 'music';
    if (['camera', 'kamera', 'gambar', 'photo', 'picture', 'selfie'].any((w) => input.contains(w))) return 'camera';
    if (['money', 'duit', 'wang', 'cash', 'pay', 'bayar', 'harga'].any((w) => input.contains(w))) return 'money';
    if (['clothes', 'baju', 'seluar', 'pakaian', 'shirt', 'pants', 'wear', 'pakai'].any((w) => input.contains(w))) return 'clothes';
    if (['bag', 'beg', 'pouch', 'luggage'].any((w) => input.contains(w))) return 'bag';
    if (['clock', 'jam', 'masa', 'time', 'waktu', 'pukul', 'lewat', 'cepat'].any((w) => input.contains(w))) return 'clock';
    if (['key', 'kunci', 'buka', 'lock'].any((w) => input.contains(w))) return 'key';
    if (['toy', 'mainan', 'play', 'main', 'game'].any((w) => input.contains(w))) return 'toy';

    // Kata Kerja (Verbs)
    if (['bed', 'tidur', 'sleep', 'rest', 'rehat', 'bantal', 'katil', 'ngantuk'].any((w) => input.contains(w))) return 'bed';
    if (['walk', 'jalan', 'kaki', 'step', 'pergi'].any((w) => input.contains(w))) return 'walk';
    if (['run', 'lari', 'laju', 'jogging', 'cepat'].any((w) => input.contains(w))) return 'run';
    if (['search', 'cari', 'find', 'hilang', 'mana'].any((w) => input.contains(w))) return 'search';
    if (['chat', 'borak', 'cakap', 'bual', 'say', 'tanya', 'soal'].any((w) => input.contains(w))) return 'chat';
    if (['work', 'kerja', 'buat', 'bina', 'job'].any((w) => input.contains(w))) return 'work';
    if (['sport', 'sukan', 'bola', 'football', 'badminton'].any((w) => input.contains(w))) return 'sport';

    return 'extension';
  }
}