import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int count, Failure? failure})> call() async {
    final dirtyResult = await _repository.countDirty();
    if (dirtyResult.failure != null) {
      return (count: 0, failure: dirtyResult.failure);
    }
    if (dirtyResult.count == 0) {
      return (count: 0, failure: null);
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    final failure = await _repository.markAllSynced();
    return (count: dirtyResult.count, failure: failure);
  }
}
