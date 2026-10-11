import 'dart:async';
import 'dart:convert';

import 'local/db.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';

class PostRepository {
  Future<List<Post>> readCachedPosts() async {
    final db = await openNotesDb();
    final rows = await db.query('cached_posts');

    return rows.map((row) {
      final payload = row['payload'] as String;
      final Map<String, dynamic> data = jsonDecode(payload);
      return Post.fromMap(data);
    }).toList();
  }

  Future<void> refreshPostsInBackground() async {
    // Implementasi fetch dari Dio / API di sini
  }

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts();
    unawaited(refreshPostsInBackground());
    return cached;
  }
}

Future<int> syncNotes(NoteRepository repository) async {
  final dirtyCount = await repository.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload; tandai bersih setelah server mengonfirmasi sukses.
  await Future.delayed(const Duration(seconds: 1));
  await repository.markAllSynced();
  return dirtyCount;
}
