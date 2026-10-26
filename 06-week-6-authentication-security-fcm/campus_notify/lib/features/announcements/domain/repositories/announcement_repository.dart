import '../../../../core/failures/failure.dart';
import '../entities/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})> getAll();

  Future<({Announcement? announcement, Failure? failure})> getById(
    String id,
  );
}
