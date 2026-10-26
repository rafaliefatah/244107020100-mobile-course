import '../../../../core/failures/failure.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../data_sources/announcement_remote_data_source.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._remoteDataSource);

  final AnnouncementRemoteDataSource _remoteDataSource;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
      getAll() async {
    try {
      return (
        announcements: await _remoteDataSource.getAnnouncements(),
        failure: null,
      );
    } catch (error) {
      return (
        announcements: const <Announcement>[],
        failure: failureFromException(error),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getById(
    String id,
  ) async {
    final result = await getAll();
    if (result.failure case final failure?) {
      return (announcement: null, failure: failure);
    }

    for (final announcement in result.announcements) {
      if (announcement.id == id) {
        return (announcement: announcement, failure: null);
      }
    }
    return (
      announcement: null,
      failure: const LocalFailure('Pengumuman tidak ditemukan.'),
    );
  }
}
