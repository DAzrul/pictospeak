import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🚨 J.A.R.V.I.S: Litar ni WAJIB duduk kat luar kelas. Ini dipanggil "Top-Level Function".
// Otak Android akan pakai litar ni bila app kau dah kena kill/tutup.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🚨 J.A.R.V.I.S [BACKGROUND]: Mesej awan masuk mat! -> ${message.messageId}");
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Minta kebenaran kat User (Wajib untuk Android 13 ke atas)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("J.A.R.V.I.S: Kebenaran Notifikasi -> ${settings.authorizationStatus}");

    // 2. Daftar Litar Background (Masa skrin mati/app kena kill)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Bilik Kebal Notifikasi Tempatan
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
    );

    // 4. 🚀 J.A.R.V.I.S: BINA TEROWONG SIREN (Ini paling penting babi!)
    const AndroidNotificationChannel sosChannel = AndroidNotificationChannel(
      'sos_emergency_channel', // Nama ID ni wajib SAMA sebijik dengan AndroidManifest!
      'Kecemasan SOS',
      description: 'Channel khas untuk jeritan siren pesakit',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('siren'), // Dia akan cari siren.mp3 dalam folder raw
      playSound: true,
      enableVibration: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(sosChannel);

    // 5. 🚀 J.A.R.V.I.S: Tangkap Token Unik & Tanam Terus Dalam Profil Penjaga!
    String? token = await FirebaseMessaging.instance.getToken();
    print("🚀 J.A.R.V.I.S [DEVICE TOKEN]: $token");

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      try {
        // Sumbat token ni ke dalam bilik kebal 'caregivers'
        await FirebaseFirestore.instance.collection('caregivers').doc(user.uid).set({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Guna merge supaya tak padam data profil lain
        print("✅ J.A.R.V.I.S: Token FCM berjaya ditanam kat awan!");
      } catch (e) {
        print("🚨 J.A.R.V.I.S ERROR: Gagal tanam token -> $e");
      }
    }

    // 6. Litar masa app tengah terbuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🚨 J.A.R.V.I.S [FOREGROUND]: SOS Masuk masa app tengah bukak!");
      // Nanti kita tambah pop-up merah gergasi kat sini
    });
  }
}