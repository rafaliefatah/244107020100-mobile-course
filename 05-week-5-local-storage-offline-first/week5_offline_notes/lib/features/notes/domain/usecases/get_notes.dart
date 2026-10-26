import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/failures.dart';

class GetNotes {
  const GetNotes(this._repository);

  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
