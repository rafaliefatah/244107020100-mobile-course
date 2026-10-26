import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openDb: openNotesDb),
);

final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);

final addNoteProvider = Provider<AddNote>(
  (ref) => AddNote(ref.watch(noteRepositoryProvider)),
);

final syncNotesUseCaseProvider = Provider<SyncNotes>(
  (ref) => SyncNotes(ref.watch(noteRepositoryProvider)),
);

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure case final failure?) {
    throw Exception(failure.message);
  }
  return result.notes;
}, retry: (_, _) {
  return null;
});

final syncNotesProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(syncNotesUseCaseProvider).call();
  if (result.failure case final failure?) {
    throw Exception(failure.message);
  }
  return result.count;
}, retry: (_, _) {
  return null;
});
