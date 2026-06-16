const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Hidupkan enjin Admin Firebase
admin.initializeApp();

exports.tembaksirensos = onDocumentCreated("sos_alerts/{alertId}", async (event) => {
    // Dalam v2, data duduk dalam event.data
    const snap = event.data;

    // Kalau dokumen tu kosong (mustahil, tapi langkah berjaga-jaga)
    if (!snap) {
        console.log("🚨 Ralat: Tiada snapshot data dijumpai.");
        return null;
    }

    const sosData = snap.data();

    // Kalau status bukan ACTIVE, kita buat bodoh je
    if (sosData.status !== 'ACTIVE') {
        console.log('Isyarat bukan ACTIVE. Batal tembakan.');
        return null;
    }

    const caregiverId = sosData.caregiver_id;
    const patientName = sosData.patient_name || 'Pesakit';

    console.log(`[J.A.R.V.I.S] Radar kesan SOS baru dari ${patientName}. Target Caregiver: ${caregiverId}`);

    try {
        // 1. Geledah pangkalan data untuk cari token fon Caregiver
        const caregiverDoc = await admin.firestore().collection('caregivers').doc(caregiverId).get();

        if (!caregiverDoc.exists) {
            console.log('🚨 Babi, profil Caregiver ni tak wujud dalam sistem!');
            return null;
        }

        const fcmToken = caregiverDoc.data().fcm_token;

        if (!fcmToken) {
            console.log(`🚨 Caregiver (ID: ${caregiverId}) takde token FCM. Mungkin dia tak pernah login!`);
            return null;
        }

        // 2. Isi peluru berpandu (Payload Push Notification)
        const mesejKecemasan = {
            token: fcmToken,
            notification: {
                title: '🚨 KECEMASAN SOS!',
                body: `Pesakit ${patientName.toUpperCase()} sedang nazak perlukan bantuan SEGERA!`
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default', // Boleh tukar bunyi custom nanti
                    channelId: 'sos_channel' // Wajib untuk tembus mode DND
                }
            }
        };

        // 3. Tembak terus ke kepala Caregiver!
        const response = await admin.messaging().send(mesejKecemasan);
        console.log('✅ BOOM! Notifikasi selamat hinggap kat fon Caregiver! Message ID:', response);

        return null;

    } catch (error) {
        console.error('🚨 Misi tembakan gagal berderai:', error);
        return null;
    }
});