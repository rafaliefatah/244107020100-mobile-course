import '../../../../core/failures/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final List<Note> _notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      return (notes: List<Note>.unmodifiable(_notes), failure: null);
    } catch (_) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('Catatan gagal dimuat. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return (
        note: null,
        failure: const LocalFailure('Judul catatan tidak boleh kosong.'),
      );
    }
    try {
      final note = Note(
        title: trimmedTitle,
        body: body,
        updatedAt: DateTime.now(),
      );
      _notes.insert(0, note);
      return (note: note, failure: null);
    } catch (_) {
      return (
        note: null,
        failure: const LocalFailure(
          'Catatan gagal disimpan. Silakan coba lagi.',
        ),
      );
    }
  }
}
