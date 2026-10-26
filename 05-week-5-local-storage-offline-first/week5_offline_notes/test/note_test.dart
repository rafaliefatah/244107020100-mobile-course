import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/data/models/note_model.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.failure});

  final List<Note> items;
  final Failure? failure;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: items, failure: failure);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    return (
      note: Note(title: title, body: body, updatedAt: DateTime.now()),
      failure: failure,
    );
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    return (count: items.where((note) => note.dirty).length, failure: failure);
  }

  @override
  Future<Failure?> markAllSynced() async => failure;
}

void main() {
  test('fromMap aman terhadap field yang hilang', () {
    final note = NoteModel.fromMap({'title': 'Belanja'}).toEntity();
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty bertahan pada serialisasi', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = NoteModel.fromMap(NoteModel.fromEntity(note).toMap());
    expect(restored.dirty, isTrue);
  });

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [Note(title: 'Tes', updatedAt: DateTime.now())],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            failure: const LocalFailure('db locked (simulasi)'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
