import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

void main() {
  testWidgets('NoteTile menampilkan badge untuk catatan dirty', (tester) async {
    final note = Note(
      title: 'Tes',
      body: 'Isi catatan',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NoteTile(note: note)),
      ),
    );

    expect(find.text('Tes'), findsOneWidget);
    expect(find.text('Isi catatan'), findsOneWidget);
    expect(find.text('Belum tersinkron'), findsOneWidget);
  });
}
