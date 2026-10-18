# Rafazian Alief Fatah - P6 - Authentication, Security & FCM

## Praktikum
### Memperbarui token
![alt text](screenshots/token.png)
### Uji Notif
![alt text](screenshots/fcm-console-test.png)

## AI Challenge
### AI Verification Checklist
#### - Apakah background handler berupa fungsi top-level dengan @pragma('vm:entry-point')? (tolak jika berupa method kelas).
Fungsi firebaseMessagingBackgroundHandler sudah ditulis dengan benar sebagai fungsi top-level dan menggunakan anotasi @pragma('vm:entry-point')
#### - Apakah onTokenRefresh benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?
Event _messaging.onTokenRefresh memicu _registerTokenAndReport yang memanggil metode _registerToken. Metode ini langsung melakukan HTTP POST ke backend melalui _dio.post('/devices', data: {'fcm_token': token, 'platform': platform})
#### - Apakah foreground memakai local notification manual? (tanpa ini banner tidak muncul saat aplikasi terbuka).
Iya, karena FCM secara default memblokir heads-up banner saat aplikasi aktif di layar
#### - Apakah klik dari ketiga state (foreground/background/terminated) masuk ke rute yang benar? Buktikan dengan tabel pengujian.
Sudah masuk ke rute yang benar
| State | Pemicu dan Handler | Routing |
|---|---|---|
| Foreground | Klik dari local notification banner. Ditangani oleh onDidReceiveNotificationResponse di konfigurasi lokal | Membaca response.payload dan menjalankan _navigate(route) |
| Background | Klik dari system tray. Ditangani oleh FirebaseMessaging.onMessageOpenedApp.listen | Membaca message.data['route'] dan menjalankan _navigate(route) |
| Terminated | Klik peluncuran awal. Ditangani secara ganda: _messaging.getInitialMessage() dan _localNotifications.getNotificationAppLaunchDetails() | Membaca payload awal aplikasi dan menjalankan _navigate(route) |
#### - Apakah token/secret tidak di-hardcode dan tidak di-log penuh? Perbaiki bila AI melanggarnya.
Tidak ada token FCM yang di-hardcode dan di-log penuh di dalam kode

## Refactoring Challenge
- Pindahkan semua string rute (/login, /pengumuman/:id) ke satu file lib/routes.dart agar deep link dari FCM dan GoRouter memakai konstanta yang sama.
- Ekstrak parsing RemoteMessage -> route ke fungsi murni routeFromMessage(Map<String, dynamic> data) agar bisa diunit-test tanpa Firebase.
- Pindahkan pemetaan DioException -> pesan ramah pengguna (401, timeout, offline) ke lib/data/api_errors.dart agar UI hanya menerima pesan, bukan exception mentah.

### Testing
![alt text](screenshots/testing.png)

## Refleksi
#### - Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?
Karena SharedPreferences menyimpan data dalam bentuk plaintext tanpa enkripsi. Risikonya bila bocor adalah penyerang dapat mencuri token tersebut untuk membuat access token baru tanpa batas waktu yang berujung pada pengambilalihan akun secara total
#### - Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?
Bila onTokenRefresh diabaikan selama satu semester, backend kampus akan terus mengirimkan notifikasi ke token yang sudah mati, sehingga user sekali tidak akan menerima informasi krusial sampai akhirnya mereka melakukan login ulang
#### - Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.
- Topik: Digunakan untuk komunikasi broadcast ke kelompok besar di mana pengguna opt-in secara kolektif dan backend tidak perlu melacak siapa saja penerimanya. Contoh: Notifikasi libur nasional ke topik pengumuman-kampus
- Token perangkat: Digunakan untuk pesan yang bersifat sangat personal, rahasia, atau menargetkan satu individu spesifik. Contoh: Pemberitahuan persetujuan KRS oleh DPA atau pengingat tenggat waktu pembayaran UKT
#### - Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?
Tidak ada, karena semua sudah sesuai dengan checklist verifikasi