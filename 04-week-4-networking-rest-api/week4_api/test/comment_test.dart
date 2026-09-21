import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai nilai default saat field hilang', () {
    // JSON parsial harus tetap menghasilkan model yang valid tanpa exception.
    final comment = Comment.fromJson({'id': 7});

    expect(comment.postId, 0);
    expect(comment.id, 7);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
