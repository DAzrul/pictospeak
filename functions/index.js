const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Hidupkan enjin Admin Firebase
admin.initializeApp();

exports.tembaksirensos = onDocumentCreated("sos_alerts/{alertId}", async (event) => {
    const snap = event.data;

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
        // 🚀 LITAR BARU: Geledah sub-collection 'device_tokens' (Ngam dengan Flutter!)
        const tokensSnapshot = await admin.firestore()
            .collection('caregivers')
            .doc(caregiverId)
            .collection('device_tokens')
            .get();

        if (tokensSnapshot.empty) {
            console.log(`🚨 Caregiver (ID: ${caregiverId}) takde token FCM dalam laci!`);
            return null;
        }

        // Kumpul semua token yang ada
        const tokens = [];
        tokensSnapshot.forEach((doc) => {
            tokens.push(doc.id);
        });

        // 2. Isi peluru berpandu (Payload Push Notification)
        const mesejKecemasan = {
            notification: {
                title: '🚨 KECEMASAN SOS!',
                body: `Pesakit ${patientName.toUpperCase()} sedang perlukan bantuan SEGERA!`
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default', // Bunyi biasa dulu, nanti kita buat bunyi siren
                    channelId: 'sos_channel'
                }
            },
            tokens: tokens // 🚀 Tembak peluru berpandu secara serentak ke semua token!
        };

        // 3. Lepaskan tembakan!
        const response = await admin.messaging().sendEachForMulticast(mesejKecemasan);
        console.log('✅ BOOM! Notifikasi selamat hinggap! Berjaya:', response.successCount);

        return null;

    } catch (error) {
        console.error('🚨 Misi tembakan gagal berderai:', error);
        return null;
    }
});