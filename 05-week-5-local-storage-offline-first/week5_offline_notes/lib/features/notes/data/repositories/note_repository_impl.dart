import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../../../data/local/db.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows
          .map((row) => NoteModel.fromMap(row).toEntity())
          .toList(growable: false);
      return (notes: notes, failure: null);
    } on Exception catch (error) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $error'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final note = NoteModel(
        title: title,
        body: body,
        updatedAt: DateTime.now(),
        dirty: true,
      );
      final id = await db.insert('notes', note.toMap());
      return (
        note: NoteModel(
          id: id,
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          dirty: true,
        ).toEntity(),
        failure: null,
      );
    } on Exception catch (error) {
      return (
        note: null,
        failure: LocalFailure('Gagal menyimpan catatan: $error'),
      );
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      final db = await _openDb();
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
      );
      return (count: (rows.first['c'] as num).toInt(), failure: null);
    } on Exception catch (error) {
      return (
        count: 0,
        failure: LocalFailure('Gagal menghitung catatan tertunda: $error'),
      );
    }
  }

  @override
  Future<Failure?> markAllSynced() async {
    try {
      final db = await _openDb();
      await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
      return null;
    } on Exception catch (error) {
      return LocalFailure('Gagal memperbarui status sinkronisasi: $error');
    }
  }
}
