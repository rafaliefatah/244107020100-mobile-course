import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/format.dart';
import '../../../../app/routes.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import '../providers/announcement_providers.dart';

class AnnouncementListPage extends ConsumerWidget {
  const AnnouncementListPage({super.key});

  String _formatToken(String? token) {
    if (token == null || token.isEmpty) return 'Memuat token...';
    if (token.length <= 12) return token;
    return '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: announcements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Pengumuman gagal dimuat. Silakan coba lagi.'),
        ),
        data: (result) {
          if (result.message != null) {
            return Center(child: Text(result.message!));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<String?>(
                future: FirebaseMessaging.instance.getToken(),
                builder: (context, snapshot) => Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade200,
                  child: Text(
                    'FCM Token (Debug): ${_formatToken(snapshot.data)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Daftar Pengumuman Terbaru:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (final announcement in result.announcements)
                ListTile(
                  title: Text(announcement.title),
                  subtitle: Text(
                    'Diterbitkan ${formatDate(announcement.publishedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.announcementDetail(announcement.id),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Catatan Lokal:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ref.watch(notesProvider).when(
                data: (notesResult) {
                  if (notesResult.failure case final failure?) {
                    return ListTile(title: Text(failure.message));
                  }
                  if (notesResult.notes.isEmpty) {
                    return const ListTile(title: Text('Belum ada catatan.'));
                  }
                  return Column(
                    children: [
                      for (final note in notesResult.notes)
                        ListTile(
                          title: Text(note.title),
                          subtitle: Text(
                            '${note.body.isEmpty ? '' : '${note.body}\n'}'
                            'Diperbarui ${formatDate(note.updatedAt)}',
                          ),
                        ),
                    ],
                  );
                },
                error: (_, _) => const ListTile(
                  title: Text('Catatan gagal dimuat. Silakan coba lagi.'),
                ),
                loading: () => const ListTile(
                  title: Text('Memuat catatan...'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
