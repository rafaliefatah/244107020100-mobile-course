import '../../domain/entities/announcement.dart';

abstract interface class AnnouncementRemoteDataSource {
  Future<List<Announcement>> getAnnouncements();
}

class MockAnnouncementRemoteDataSource
    implements AnnouncementRemoteDataSource {
  @override
  Future<List<Announcement>> getAnnouncements() async {
    return [
      Announcement(
        id: '101',
        title: 'Pengumuman Libur Akademik',
        body: 'Informasi libur akademik kampus.',
        publishedAt: DateTime(2026, 9, 27),
      ),
      Announcement(
        id: '102',
        title: 'Jadwal Ujian Akhir Semester',
        body: 'Jadwal ujian akhir semester telah tersedia.',
        publishedAt: DateTime(2026, 9, 28),
      ),
    ];
  }
}
