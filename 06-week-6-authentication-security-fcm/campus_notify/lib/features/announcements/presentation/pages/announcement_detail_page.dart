import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/announcement_providers.dart';

class AnnouncementDetailPage extends ConsumerWidget {
  const AnnouncementDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(announcementDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Pengumuman gagal dimuat. Silakan coba lagi.'),
        ),
        data: (result) {
          final announcement = result.announcement;
          if (announcement == null) {
            return Center(
              child: Text(
                result.message ?? 'Pengumuman tidak ditemukan.',
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Diterbitkan ${formatDate(announcement.publishedAt)}'),
                const SizedBox(height: 16),
                Text(announcement.body),
              ],
            ),
          );
        },
      ),
    );
  }
}
