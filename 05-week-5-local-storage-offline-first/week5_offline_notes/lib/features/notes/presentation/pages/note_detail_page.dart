import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure case final failure?) {
    throw Exception(failure.message);
  }
  for (final note in result.notes) {
    if (note.id == id) {
      return note;
    }
  }
  return null;
}, retry: (_, _) {
  return null;
});

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(noteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: noteAsync.when(
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(note.body),
                const SizedBox(height: 16),
                Text('Diperbarui: ${note.updatedAt}'),
                if (note.dirty)
                  const Chip(
                    avatar: Icon(Icons.cloud_upload, size: 18),
                    label: Text('Belum tersinkron'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
