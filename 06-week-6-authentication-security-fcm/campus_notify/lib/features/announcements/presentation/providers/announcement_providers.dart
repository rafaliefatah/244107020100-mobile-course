import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/announcement_remote_data_source.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

final announcementRemoteDataSourceProvider =
    Provider<AnnouncementRemoteDataSource>(
      (ref) => MockAnnouncementRemoteDataSource(),
    );
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(
    ref.watch(announcementRemoteDataSourceProvider),
  ),
);
final announcementListProvider =
    FutureProvider<({List<Announcement> announcements, String? message})>((
      ref,
    ) async {
      final result = await ref.watch(announcementRepositoryProvider).getAll();
      return (
        announcements: result.announcements,
        message: result.failure?.message,
      );
    });
final announcementDetailProvider =
    FutureProvider.family<({Announcement? announcement, String? message}), String>(
      (ref, id) async {
        final result = await ref
            .watch(announcementRepositoryProvider)
            .getById(id);
        return (
          announcement: result.announcement,
          message: result.failure?.message,
        );
      },
    );
