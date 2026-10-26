import 'package:go_router/go_router.dart';

import 'features/notes/presentation/pages/note_detail_page.dart';
import 'features/notes/presentation/pages/notes_page.dart';

abstract final class AppRoutes {
  static const notes = '/';
  static const noteDetail = 'note/:id';
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.notes,
      builder: (context, state) => const NotesPage(),
      routes: [
        GoRoute(
          path: AppRoutes.noteDetail,
          builder: (context, state) =>
              NoteDetailPage(noteId: int.parse(state.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);
