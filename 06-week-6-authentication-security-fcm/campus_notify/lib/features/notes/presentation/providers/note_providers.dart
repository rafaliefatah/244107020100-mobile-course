import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures/failure.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/use_cases/get_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(),
);
final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);
final notesProvider =
    FutureProvider<({List<Note> notes, Failure? failure})>((ref) {
      return ref.watch(getNotesProvider).call();
    });
