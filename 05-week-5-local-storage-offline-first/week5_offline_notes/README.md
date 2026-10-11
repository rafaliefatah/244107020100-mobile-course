# Rafazian Alief Fatah - P4 - Local Storage & Offline First

## Praktikum
### Matikan Wi-Fi / aktifkan mode pesawat, buka kembali aplikasi: catatan tetap tampil, badge dirty tetap akurat.
![alt text](screenshots/praktikum_sebelum.png)
### Nyalakan kembali koneksi, jalankan syncNotes: badge kembali ke 0.
![!alt text](screenshots/praktikum_sesudah.png)

## AI Challenge

### Perbandingan penyimpanan untuk Offline Notes

Kebutuhan aplikasi ini terdiri dari dua jenis data yang berbeda: preferensi tema hanya berupa nilai kecil (misalnya `light`/`dark`/`system`), sedangkan catatan perlu CRUD, daftar yang dapat diurutkan/dicari, dan berpotensi berkembang menjadi relasi. Karena itu, penyimpanan preferensi dan catatan tidak harus memakai teknologi yang sama.

| Opsi | Kompleksitas query | Relasi | Reaktivitas (stream) | Type-safety | Boilerplate | Kemudahan testing | Trade-off / kecocokan |
|---|---|---|---|---|---|---|---|
| **SharedPreferences** | Sangat terbatas: baca/tulis nilai berdasarkan key; bukan untuk filter atau query daftar | Tidak ada | Tidak menyediakan stream perubahan data yang cocok untuk daftar catatan; perubahan perlu dikelola aplikasi | Tipe primitif dasar, tetapi key dan makna nilainya tidak dikompilasi sebagai model | Paling sedikit | Mudah diuji lewat wrapper/mock plugin; uji integrasi tetap bergantung pada plugin | Ringan dan sederhana untuk preferensi tema. Jangan menyimpan seluruh catatan sebagai JSON: update parsial, pencarian, migrasi, dan konsistensi menjadi tanggung jawab aplikasi. |
| **Hive** | Rendah–menengah: akses box/key dan filter objek di Dart; tidak ada SQL atau query relasional | Tidak ada foreign key/join; relasi dikelola sendiri | `box.watch()` memberi notifikasi perubahan box, tetapi pemetaan ke state aplikasi tetap perlu dibuat | Model dapat menggunakan adapter dan tipe Dart, tetapi validasi query tidak setara compile-time SQL | Rendah–menengah; perlu adapter untuk model kompleks | Box dapat diarahkan ke direktori sementara; pengujian relatif mudah | Nyaman untuk objek lokal dan operasi sederhana. Untuk pencarian/filter yang makin kompleks, aplikasi harus memuat/memfilter data sendiri; relasi dan migrasi skema lebih manual. |
| **sqflite (SQLite)** | Tinggi: SQL untuk filter, sort, pencarian, agregasi, transaksi, dan pagination | Mendukung foreign key dan join | Tidak menyediakan stream query otomatis; perlu memancarkan perubahan sendiri atau memakai solusi tambahan | SQL/model umumnya ditulis manual; kesalahan kolom dan mapping sering baru terlihat saat runtime | Menengah–tinggi: schema, mapping, migration, dan invalidasi state manual | Baik: gunakan database in-memory/temporary dan dependency injection untuk repository | Pilihan langsung dan fleksibel untuk SQL. Lebih banyak kode manual, dan menjaga agar UI tetap sinkron setelah setiap mutasi adalah tanggung jawab aplikasi. |
| **Drift** | Tinggi: SQL atau DSL bertipe, termasuk filter, join, transaksi, dan pagination | Mendukung relasi SQLite, foreign key, serta join | Stream query tersedia; hasil query diperbarui saat tabel terkait berubah | Kuat: API query dan hasil dibuat dari schema saat build, sehingga banyak kesalahan tertangkap lebih awal | Menengah: perlu deklarasi tabel dan code generation; lebih sedikit mapping/invalidasi manual dibanding sqflite | Sangat baik: database in-memory untuk test repository/query, tanpa database produksi | Direkomendasikan untuk catatan yang butuh query dan UI reaktif. Ada setup generator/build, tetapi memberi API terjaga tipe dan stream yang lebih terintegrasi. |

### Rekomendasi akhir

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| Preferensi tema | **SharedPreferences** | Nilainya kecil, berdiri sendiri, dan hanya perlu dibaca/ditulis berdasarkan key. SQLite/Drift akan menambah setup tanpa manfaat berarti. Bungkus akses dalam repository/service agar mudah diuji dan ganti implementasi bila diperlukan. |
| Catatan offline | **Drift (SQLite)** | Catatan memerlukan CRUD yang konsisten, pengurutan/filter/pencarian, pagination saat jumlah data bertambah, serta pembaruan UI melalui stream. SQLite menyediakan transaksi dan jalur untuk relasi; Drift mengurangi kesalahan query dan pekerjaan sinkronisasi manual dibanding sqflite. |

### Skema catatan untuk 1000+ item

Seribu catatan masih tergolong kecil bagi SQLite. Simpan satu catatan per baris, bukan satu dokumen JSON besar. Ambil data bertahap (`LIMIT`/`OFFSET`, atau keyset pagination untuk daftar yang terus berubah), dan tambahkan indeks hanya pada kolom yang benar-benar sering dipakai untuk filter/sort.

```text
+----------------------+       +----------------------+       +----------------------+
| notes                | 1   * | note_tags (opsional) | *   1 | tags (opsional)      |
|----------------------|-------|----------------------|-------|----------------------|
| id PK                |       | note_id PK, FK       |       | id PK                |
| title                |       | tag_id  PK, FK       |       | name UNIQUE          |
| body                 |       +----------------------+       +----------------------+
| created_at           |
| updated_at           |
| is_pinned            |
| is_archived          |
+----------------------+
```

Relasi tag bersifat opsional untuk fitur awal; tabel penghubung memungkinkan satu catatan memiliki banyak tag dan satu tag digunakan banyak catatan. Skema dasar SQLite yang dapat dinyatakan sebagai tabel Drift:

```sql
CREATE TABLE notes (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  is_pinned   INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_pinned_updated
  ON notes(is_pinned DESC, updated_at DESC);
```

Simpan waktu sebagai epoch (misalnya milidetik UTC) secara konsisten. Indeks kedua membantu daftar pin/terbaru; bila query aktual tidak memakai filter pin, indeks itu dapat dihilangkan. Untuk daftar terbaru, query dapat memakai `ORDER BY updated_at DESC LIMIT 50 OFFSET ?`; untuk pencarian teks sederhana, `LIKE` cukup, sedangkan pencarian skala lebih besar dapat memakai SQLite FTS. `updated_at` dan indeksnya juga dapat membantu menyiapkan sinkronisasi, tetapi sinkronisasi multi-perangkat memerlukan metadata/status tambahan dan kebijakan konflik tersendiri.

### Trade-off pilihan

- **SharedPreferences:** paling sederhana untuk tema, tetapi bukan database catatan. Menaruh daftar catatan di sana membuat setiap perubahan membaca/menulis blob besar dan mengorbankan query serta migrasi terstruktur.
- **Hive:** praktis untuk model lokal dan watch box. Namun, filter biasanya dikerjakan di Dart dan relasi tidak dijaga database; tetap layak bila aplikasi memang hanya perlu akses objek sederhana dan tidak membutuhkan query SQL.
- **sqflite:** memberi kontrol penuh atas SQLite, transaksi, dan SQL. Imbalannya adalah mapping manual, migrasi, invalidasi cache/state, dan stream harus dirawat sendiri; cocok bila tim menginginkan SQL langsung tanpa code generation.
- **Drift:** menambah dependensi generator dan langkah build, tetapi query bertipe, hasil query reaktif, dan dukungan test in-memory mengurangi pekerjaan berulang untuk layar CRUD. Untuk kebutuhan catatan yang akan berkembang, manfaat tersebut lebih besar daripada setup tambahannya.

### AI Verification Checklist
#### - Apakah AI menempatkan daftar catatan di SharedPreferences? (menolak: rapuh untuk koleksi).
AI menolak penggunaan SharedPreferences untuk menyimpan daftar catatan karena menyimpan koleksi catatan sebagai JSON blob di SharedPreferences sangat rapuh, tidak efisien untuk update parsial, serta tidak mendukung querying maupun migrasi terstruktur
#### - Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?
Sebagian besar hanya CRUD polos
#### - Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?
Klaim AI menjelaskan bahwa Drift memiliki dukungan stream yang otomatis memancarkan data terbaru ke UI setiap kali terjadi perubahan tabel
#### - Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (flutter pub add + migrasi skema)?
Estimasi AI masuk akal

## Refactoring Challenge
- Ekstrak baris catatan menjadi widget `NoteTile` tersendiri yang menampilkan badge "Belum tersinkron" bila `dirty == true`.
- Pindahkan logika cache posts dan `syncNotes` ke `lib/data/sync.dart` agar repository tetap fokus pada CRUD.
- Tambahkan halaman detail catatan dengan GoRouter (`/note/:id`) yang membaca dari repository lokal, bukan dari state halaman list.
### Testing
- `test/note_test.dart` menguji mapping model, persistensi flag `dirty`, serta provider sukses/error memakai repository palsu tanpa SQLite sungguhan.

## Refleksi
##### - Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?
Karena akan merusak Separation of Concerns dan Single Responsibility Principle. Yang rusak adalah coupling ketat ke HTTP library, pengujiannya, duplikasi kode dan parsing, dan manajemen status menjadi berantakan
##### - Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (_page/_limit)?
Pagination client-side saja cukup saat dataset di bawah 100–500 item, datanya relatif statis, dan dapat diunduh sekaligus di awal tanpa mengganggu performa. Sedangkan pagination server dapat diandalkan saat menangani dataset berukuran besar, terus bertambah, atau berubah secara real-time
##### - Bagaimana exception repository berubah menjadi AsyncError tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?
Adanya mekanisme deklaratif dari manajer status modern seperti Riverpod. try/catch eksplisit tetap dibutuhkan pada aksi-aksi imperatif untuk memicu efek samping tanpa mengganti seluruh tampilan layar menjadi pesan kesalahan
##### - Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
Tidak ada